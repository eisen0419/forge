<!-- SECTION: Compact Recovery (Full tier only)
  What: What to do after context compression (Claude's memory resets mid-session)
  Why: Without this, Claude loses track of what it was doing after a long session
  Customize: Adjust file paths if your project uses different task tracking -->

## Compact Recovery

After context compression, immediately:
1. Re-read task tracking file to confirm current progress
2. If a plan file exists, re-read it to restore execution context
3. If a skill was active, confirm skill state is not lost
4. Never trust the compression summary for file contents — re-read critical files
