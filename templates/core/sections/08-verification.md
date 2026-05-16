<!-- SECTION: Verification Discipline
  What: Rules preventing Claude from claiming work is done when it isn't
  Why: AI assistants sometimes fabricate test results or claim completion prematurely
  Customize: These are universal safety rules — keep them as-is -->

## Verification Rules

- **Independence**: Never self-certify. Review must include actual run results (ran tests / checked build / manual inspection)
- **Delivery gate**: Before claiming done/commit/push/PR, complete verification and report honestly
- **Hard rules**:
  - Never fabricate commands, exit codes, or verification results
  - Verify referenced files still exist before recommending from memory
  - Without verification evidence, never claim "passing", "complete", or "ready to submit"
