<!-- SECTION: Git Conventions
  What: Branch naming, commit format, and safety rules
  Why: Consistent git hygiene prevents accidents and makes history readable
  Customize: Adjust branch prefix and commit format to your project -->

## Git

- Feature branches: `{{BRANCH_PREFIX}}<task-name>`
- Commit format: `<type>(scope): <summary>` — verb-first, ≤ 50 chars, no period
- Types: `feat` / `fix` / `docs` / `refactor` / `test` / `chore`
- **Never**: force push, modify pushed history, `--no-verify`
