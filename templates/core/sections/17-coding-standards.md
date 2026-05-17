<!-- SECTION: Coding Standards
  What: SOLID/DRY/YAGNI principles plus quantitative size thresholds and an explicit escape hatch
  Why: Hard numeric thresholds (function ≤ 50 lines, complexity ≤ 10) work as guardrails but become harmful when applied to state machines, dispatch tables, serialization code, or test fixtures. Without an escape hatch, agents will mechanically fragment code that should stay whole.
  Customize: Tune the four numbers (50/300/3/10) to your stack. Keep the 3-step exception protocol — that's the core mechanism. -->

## Coding Standards

- Follow SOLID, DRY, separation-of-concerns, and YAGNI.
- Name things clearly. Make edge cases explicit.
- Soft targets: function ≤ 50 lines, file ≤ 300 lines, nesting ≤ 3, positional args ≤ 3, cyclomatic complexity ≤ 10. No magic numbers.
- Refactors keep behavior unchanged first, then improve structure.

### Threshold Exceptions

The numbers above are **targets, not compliance gates**. When a unit exceeds a threshold, apply this 3-step protocol in order:

1. **Can extraction help?** Try to pull out sub-steps with real semantic boundaries. If yes → extract and re-measure.
2. **Is the size inherent to the problem?** State machines, dispatch tables, long `switch`/`match` blocks, data declarations, serializers/deserializers, and test fixtures are often **inherently over the limit**. Keep them whole. Add one comment line at the top stating the reason — e.g. `// state machine: extraction would leak state across functions`.
3. **Review by readability, not by the metric.** Don't reject code purely for exceeding a threshold. Ask: did the change make the code more or less readable?

The escape hatch is intentional. A 60-line state machine in one function is almost always more readable than the same state machine split across six functions sharing mutable state.
