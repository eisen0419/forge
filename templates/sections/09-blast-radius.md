<!-- SECTION: Blast Radius Protocol (Full tier only)
  What: Impact assessment before modifying shared code
  Why: Changing exported functions/interfaces can break callers you don't see
  Customize: Add project-specific shared surfaces (APIs, schemas, types) -->

## Blast Radius Protocol

Before modifying any exported function, interface, type, or core state structure:
1. Grep all callers and dependents — assess impact scope
2. Add affected modules to verification checklist
3. After changes, run verification on all impacted modules
