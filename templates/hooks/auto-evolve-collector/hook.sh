#!/bin/bash
# auto-evolve-collector.sh — Forge runtime hook
#
# Event:    Stop (fires once per Claude Code session end)
# Purpose:  Extract error / correction signals from the session's jsonl
#           transcript and persist them in three places so future sessions
#           can learn from them:
#
#             1. Raw daily jsonl       → $EVOLVE_COLLECT_DIR/<date>.jsonl
#             2. Crucible failed-dirs  → $EVOLVE_CRUCIBLE_FD_DIR/<fp>.yaml
#                                        + sidecar <fp>.occurrences.jsonl
#             3. (Optional) Obsidian   → $EVOLVE_OBSIDIAN_DIR/<date>.md
#                                        (only when env var is set)
#
# Budget:   < 5 s wall time, no LLM in path, failure never blocks session end.
# Schema:   The fingerprint formula and yaml shape MUST match
#           templates/crucible/schemas/failed-direction.schema.yaml and
#           scripts/crucible-bookkeep.sh — these are sister artifacts.
#
# Environment overrides (all optional):
#   EVOLVE_COLLECT_DIR        default: $HOME/.claude/auto-lessons
#   EVOLVE_CRUCIBLE_FD_DIR    default: $HOME/.claude/crucible/failed-directions
#   EVOLVE_OBSIDIAN_DIR       default: <empty>  (disable Obsidian digest)
#
# Privacy: The Obsidian digest is opt-in because most users do not run an
# Obsidian vault; everything that matters for cross-session learning is
# captured in the jsonl + Crucible outputs, which are local-only and
# git-friendly.

set -e

# 1. Read hook stdin payload (contains session_id).
PAYLOAD=$(cat)
SESSION_ID=$(echo "$PAYLOAD" | python3 -c "import json,sys; print(json.load(sys.stdin).get('session_id',''))" 2>/dev/null || echo "")
[ -z "$SESSION_ID" ] && exit 0

# 2. Locate the matching session jsonl on disk.
JSONL=$(find "$HOME/.claude/projects" -name "${SESSION_ID}*.jsonl" -type f 2>/dev/null | head -1)
[ -z "$JSONL" ] || [ ! -f "$JSONL" ] && exit 0

# 3. Resolve output paths (env-overridable).
DATE=$(date +%Y-%m-%d)
COLLECT_DIR="${EVOLVE_COLLECT_DIR:-$HOME/.claude/auto-lessons}"
CRUCIBLE_FD_DIR="${EVOLVE_CRUCIBLE_FD_DIR:-$HOME/.claude/crucible/failed-directions}"
OBSIDIAN_DIR="${EVOLVE_OBSIDIAN_DIR:-}"

mkdir -p "$COLLECT_DIR" "$CRUCIBLE_FD_DIR"
[ -n "$OBSIDIAN_DIR" ] && mkdir -p "$OBSIDIAN_DIR"

COLLECT_FILE="$COLLECT_DIR/$DATE.jsonl"
OBSIDIAN_FILE=""
[ -n "$OBSIDIAN_DIR" ] && OBSIDIAN_FILE="$OBSIDIAN_DIR/$DATE.md"

# 4. Inline Python: extract signals, write to all three sinks.
#    All failures swallowed (|| exit 0) — Stop hook must never block.
python3 - "$JSONL" "$SESSION_ID" "$COLLECT_FILE" "$CRUCIBLE_FD_DIR" "$OBSIDIAN_FILE" <<'PYEOF' 2>/dev/null || exit 0
import json
import sys
import hashlib
from datetime import datetime
from pathlib import Path

jsonl_path, session_id, collect_file, crucible_fd_dir, obsidian_file = sys.argv[1:6]

tool_calls = 0
errors = []          # [{"kind": str, "snippet": str, "tool_name": str, "fingerprint": str}]
corrections = []     # [str]
retries = {}         # tool_name -> count
first_user_msg = None
cwd = ""
started_at = None
ended_at = None
last_tool_name = ""  # binds tool_use → next tool_result

# Correction keywords — bilingual on purpose. The hook should catch users who
# correct the agent in either language. Extend freely; ordering does not matter
# because we match by substring.
CORRECTION_KEYS = [
    # zh
    "不对", "错了", "别", "不要",
    # en
    "wrong", "no, don't", "no don't", "stop",
]


def classify_error_kind(text):
    """Map a raw error snippet to a canonical error_kind so that semantically
    equivalent failures aggregate under one fingerprint. List ordered by
    specificity — more specific patterns first."""
    s = (text or "").lower()
    if "file has not been read" in s:
        return "read-before-edit"
    if ("permission" in s and "denied" in s) or "has been denied" in s:
        return "permission denied"
    if "no such file" in s or "does not exist" in s:
        return "no such file"
    if "command not found" in s:
        return "command not found"
    if "tls handshake timeout" in s or "tls handshake failed" in s:
        return "tls handshake timeout"
    if "traceback" in s:
        return "traceback"
    if "exception" in s:
        return "exception"
    if "failed" in s:
        return "failed"
    return "error"  # catchall


# Allowed error_kind values — kept here for documentation and to make it easy
# to validate that classify_error_kind returns from this set only.
ERROR_KEYS = [
    "read-before-edit",
    "permission denied",
    "no such file",
    "command not found",
    "tls handshake timeout",
    "traceback",
    "exception",
    "failed",
    "error",
]


def make_fingerprint(error_kind: str, tool_name: str) -> str:
    """12-char sha1. MUST match scripts/crucible-bookkeep.sh gen-fingerprint
    and templates/crucible/schemas/failed-direction.schema.yaml."""
    raw = f"{error_kind[:30].lower()}|{tool_name or 'unknown'}"
    return hashlib.sha1(raw.encode("utf-8")).hexdigest()[:12]


with open(jsonl_path) as f:
    for line in f:
        try:
            d = json.loads(line)
        except Exception:
            continue

        ts = d.get("timestamp")
        if ts and not started_at:
            started_at = ts
        if ts:
            ended_at = ts

        if not cwd:
            cwd = d.get("cwd", "")

        msg = d.get("message", {})
        if isinstance(msg, dict):
            content = msg.get("content")
            if isinstance(content, list):
                for c in content:
                    if isinstance(c, dict):
                        if c.get("type") == "tool_use":
                            tool_calls += 1
                            tn = c.get("name", "")
                            retries[tn] = retries.get(tn, 0) + 1
                            last_tool_name = tn
                        elif c.get("type") == "tool_result":
                            # Primary signal: the standard `is_error` flag on
                            # tool_result. Keyword scan only refines the kind
                            # of real errors — never invents an error.
                            if not c.get("is_error"):
                                continue
                            raw_content = c.get("content", "")
                            content_str = raw_content if isinstance(raw_content, str) else json.dumps(raw_content, ensure_ascii=False)
                            snippet = content_str[:200]
                            if not snippet:
                                continue
                            error_kind = classify_error_kind(content_str)
                            fp = make_fingerprint(error_kind, last_tool_name)
                            errors.append({
                                "kind": error_kind,
                                "snippet": snippet,
                                "tool_name": last_tool_name,
                                "fingerprint": fp,
                            })
            elif isinstance(content, str):
                role = msg.get("role", "")
                if role == "user":
                    if not first_user_msg:
                        first_user_msg = content[:120]
                    head = content[:200]
                    head_lower = head.lower()
                    for k in CORRECTION_KEYS:
                        if k in head_lower or k in head:
                            corrections.append(head)
                            break

# --- Sink 1: raw daily jsonl (always written) ---------------------------------
with open(collect_file, "a") as f:
    f.write(json.dumps({
        "session_id": session_id,
        "started_at": started_at,
        "ended_at": ended_at,
        "cwd": cwd,
        "tool_calls": tool_calls,
        "errors": errors,
        "corrections": corrections[:10],
        "first_user_msg": first_user_msg,
    }, ensure_ascii=False) + "\n")

# --- Sink 2: Crucible failed-directions (always written) ----------------------
# For each unique fingerprint in this session, ensure the yaml exists (create
# stub on first sight) and append one occurrence to the sidecar jsonl.
fd_dir = Path(crucible_fd_dir)
seen_in_this_session = set()

for e in errors:
    fp = e["fingerprint"]
    if fp in seen_in_this_session:
        continue
    seen_in_this_session.add(fp)

    yaml_path = fd_dir / f"{fp}.yaml"
    occ_path = fd_dir / f"{fp}.occurrences.jsonl"

    if not yaml_path.exists():
        safe_snippet = e["snippet"].replace("\n", " ").replace('"', "'")[:200]
        safe_trigger = f"{e['tool_name'] or 'unknown'} tool emitted '{e['kind']}'"
        yaml_content = f"""# Auto-generated by auto-evolve-collector.sh
# Schema: templates/crucible/schemas/failed-direction.schema.yaml
# User-editable fields below are never overwritten by subsequent hook runs.

fingerprint: {fp}
error_kind: {e['kind']}
tool_name: {e['tool_name'] or 'unknown'}
trigger: "{safe_trigger}"
sample_snippet: "{safe_snippet}"
created_at: "{datetime.now().strftime('%Y-%m-%d')}"
status: active

# === User-editable below (hook will not overwrite) ===
content: ""
correct_action: ""
counterexamples: []
confidence: low
last_verified: ""
last_retrieved: ""
retrieval_count: 0
linked_golden_case: ""
"""
        yaml_path.write_text(yaml_content)

    with open(occ_path, "a") as f:
        f.write(json.dumps({
            "session": session_id[:8],
            "at": ended_at or started_at or datetime.now().isoformat(),
            "cwd": cwd,
            "snippet": e["snippet"][:200],
        }, ensure_ascii=False) + "\n")

# --- Sink 3: Obsidian digest (only when EVOLVE_OBSIDIAN_DIR is set) -----------
if obsidian_file:
    session_summary = f"""
---

## Session `{session_id[:8]}` · {started_at or 'unknown'}

- **cwd**: `{cwd}`
- **tool calls**: {tool_calls}
- **errors**: {len(errors)}
- **user corrections**: {len(corrections)}
- **first user msg**: {first_user_msg or '(none)'}

"""
    if errors:
        session_summary += "### Error signals\n\n"
        for e in errors[:5]:
            session_summary += f"- [{e['kind']}] `{e['tool_name'] or 'unknown'}` (fp:{e['fingerprint']}) {e['snippet'][:130]}\n"
        if len(errors) > 5:
            session_summary += f"- ... +{len(errors)-5} more\n"
        session_summary += "\n"

    if corrections:
        session_summary += "### User corrections\n\n"
        for c in corrections[:3]:
            session_summary += f"- {c[:150]}\n"
        if len(corrections) > 3:
            session_summary += f"- ... +{len(corrections)-3} more\n"
        session_summary += "\n"

    ob = Path(obsidian_file)
    if not ob.exists():
        ob.write_text(f"""---
date: {datetime.now().strftime('%Y-%m-%d')}
type: ai-evolution-session-log
sessions: 0
---

# AI session log · {datetime.now().strftime('%Y-%m-%d')}

Each Claude Code session appends one section on Stop. Aggregate analysis is left
to downstream tooling — this file is the human-readable digest.
""")

    with open(ob, "a") as f:
        f.write(session_summary)

PYEOF

exit 0
