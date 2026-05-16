<!-- SECTION: Error Recovery Circuit Breaker (Full tier only)
  What: Automatic escalation when the same approach keeps failing
  Why: Prevents infinite retry loops that waste tokens and time
  Customize: Adjust failure counts and max rounds -->

## Error Recovery

- Same approach fails 2x consecutively → **must re-plan**, cannot continue same path
- Re-plan still fails → escalate to user with attempts tried and failure reasons
- Maximum 3 recovery rounds, then circuit breaker stops execution
- Recovery branches can also fail — don't allow infinite loops in recovery
