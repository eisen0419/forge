<!-- SECTION: Safety Rules
  What: Hard boundaries Claude must never cross without explicit permission
  Why: Prevents accidental data loss, security vulnerabilities, and runaway processes
  Customize: Add project-specific safety boundaries -->

## Safety Rules

- No destructive commands (`git reset --hard`, `rm -rf`) unless explicitly requested
- No `.git` manipulation outside of git commands
- No hardcoded secrets, credentials, or API keys in source code
- Use parameterized queries for database access
- No shell command or SQL injection from untrusted input
- No killing processes not started by the current task
