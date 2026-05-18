#!/usr/bin/env bash
# crucible-bookkeep.sh — minimal maintenance helper for ~/.claude/crucible/
#
# Subcommands:
#   hit <fingerprint>          Bump retrieval_count and set last_retrieved=today.
#                              Use this from the agent's pre-flight when a
#                              failed-direction matches the current task.
#   list                       List all fingerprints with their retrieval stats.
#   validate                   Check required-field completeness across all
#                              failed-directions/*.yaml and golden-cases/*.yaml.
#   gen-fingerprint <kind> <tool>
#                              Print the canonical 12-char sha1 fingerprint
#                              for a given (error_kind, tool_name) pair.
#
# Override the install location with CRUCIBLE_HOME if needed.

set -euo pipefail

CRUCIBLE_HOME="${CRUCIBLE_HOME:-$HOME/.claude/crucible}"
FAILED_DIR="$CRUCIBLE_HOME/failed-directions"
GOLDEN_DIR="$CRUCIBLE_HOME/golden-cases"

usage() {
  cat >&2 <<'USAGE'
Usage:
  crucible-bookkeep.sh hit <fingerprint>
  crucible-bookkeep.sh list
  crucible-bookkeep.sh validate
  crucible-bookkeep.sh gen-fingerprint <error_kind> <tool_name>

Environment:
  CRUCIBLE_HOME    Install location (default: ~/.claude/crucible)
USAGE
  exit 2
}

require_dir() {
  if [[ ! -d "$CRUCIBLE_HOME" ]]; then
    echo "crucible: $CRUCIBLE_HOME does not exist" >&2
    echo "  Install first; see templates/crucible/README.md." >&2
    exit 1
  fi
}

# Portable in-place sed (BSD on macOS, GNU on Linux).
sed_inplace() {
  if [[ "$(uname -s)" == "Darwin" ]]; then
    sed -i '' "$@"
  else
    sed -i "$@"
  fi
}

today() { date +%Y-%m-%d; }

cmd_hit() {
  local fp="${1:-}"
  [[ -z "$fp" ]] && usage
  require_dir
  local file="$FAILED_DIR/${fp}.yaml"
  if [[ ! -f "$file" ]]; then
    echo "crucible: not found: $file" >&2
    exit 1
  fi
  local count
  count=$(awk -F': ' '/^retrieval_count:/{print $2; exit}' "$file")
  count=$((count + 1))
  local stamp
  stamp=$(today)
  sed_inplace -E "s/^last_retrieved: .*/last_retrieved: \"${stamp}\"/" "$file"
  sed_inplace -E "s/^retrieval_count: .*/retrieval_count: ${count}/" "$file"
  echo "✓ ${fp}  retrieval_count=${count}  last_retrieved=${stamp}"
}

cmd_list() {
  require_dir
  if [[ ! -d "$FAILED_DIR" ]]; then
    echo "(no failed-directions yet)"
    return 0
  fi
  printf "%-14s  %5s  %-12s  %-10s  %s\n" "fingerprint" "count" "last_seen" "confidence" "trigger"
  printf "%-14s  %5s  %-12s  %-10s  %s\n" "------------" "-----" "----------" "----------" "-------"
  local f fp count last conf trig
  for f in "$FAILED_DIR"/*.yaml; do
    [[ -e "$f" ]] || continue
    fp=$(basename "$f" .yaml)
    count=$(awk -F': ' '/^retrieval_count:/{print $2; exit}' "$f")
    last=$(awk -F': ' '/^last_retrieved:/{gsub(/"/,"",$2); print $2; exit}' "$f")
    conf=$(awk -F': ' '/^confidence:/{print $2; exit}' "$f")
    trig=$(awk -F': ' '/^trigger:/{ $1=""; sub(/^ /, ""); gsub(/^"|"$/, ""); print; exit}' "$f")
    printf "%-14s  %5s  %-12s  %-10s  %s\n" "$fp" "${count:-0}" "${last:-—}" "${conf:-—}" "${trig:0:60}"
  done
}

cmd_validate() {
  require_dir
  local rc=0

  local fd_required=(fingerprint error_kind tool_name trigger sample_snippet created_at status \
                     content correct_action confidence last_verified last_retrieved \
                     retrieval_count linked_golden_case)
  local gc_required=(case_id title trigger correct_flow verification \
                     linked_failed_direction created_at last_verified status)

  if [[ -d "$FAILED_DIR" ]]; then
    local f field
    for f in "$FAILED_DIR"/*.yaml; do
      [[ -e "$f" ]] || continue
      for field in "${fd_required[@]}"; do
        if ! grep -q "^${field}:" "$f"; then
          echo "  ✗ $(basename "$f")  missing: $field"
          rc=1
        fi
      done
    done
  fi

  if [[ -d "$GOLDEN_DIR" ]]; then
    local f field
    for f in "$GOLDEN_DIR"/*.yaml; do
      [[ -e "$f" ]] || continue
      for field in "${gc_required[@]}"; do
        if ! grep -q "^${field}:" "$f"; then
          echo "  ✗ $(basename "$f")  missing: $field"
          rc=1
        fi
      done
    done
  fi

  if [[ $rc -eq 0 ]]; then
    echo "✓ all yamls pass required-field check"
  fi
  return $rc
}

cmd_gen_fingerprint() {
  local kind="${1:-}"
  local tool="${2:-}"
  [[ -z "$kind" || -z "$tool" ]] && usage
  # Mirror the hook's formula: lowercase, truncate kind to 30 chars, default tool to "unknown".
  local kind_part
  kind_part=$(printf '%s' "$kind" | tr '[:upper:]' '[:lower:]' | cut -c1-30)
  local tool_part="${tool:-unknown}"
  printf '%s|%s' "$kind_part" "$tool_part" | shasum | cut -c1-12
}

main() {
  local sub="${1:-}"
  shift || true
  case "$sub" in
    hit)             cmd_hit "$@" ;;
    list)            cmd_list ;;
    validate)        cmd_validate ;;
    gen-fingerprint) cmd_gen_fingerprint "$@" ;;
    -h|--help|help|"") usage ;;
    *) echo "crucible: unknown subcommand: $sub" >&2; usage ;;
  esac
}

main "$@"
