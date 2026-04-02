<!-- SECTION: Quality Gates
  What: Testing strategy that scales with risk
  Why: Not everything needs TDD; not everything can skip tests
  Customize: Adjust levels to match your project's testing culture -->

## Testing Strategy

| Level | Strategy | When to use |
|-------|----------|-------------|
| 0 | Targeted verification | Local, low-risk, small changes |
| 1 | Regression tests | Medium fixes, local behavior changes |
| 2 | TDD | New features, clear behavior changes, shared logic, high risk |
<!-- FULL_ONLY_START -->
| 3 | Code Review | Formal review before merge |
| 4 | Completion Verification | Pre-commit verification + change delivery gate |
<!-- FULL_ONLY_END -->

Default level for new tasks: {{DEFAULT_TEST_LEVEL}}
