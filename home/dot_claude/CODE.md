# Code rules

Governs all code you write and every file you touch, not only new code.
Writing Rust or Python: read `~/.claude/LANGUAGES.md` before the first edit.

- **DRY.** One authority per fact or behavior. Reuse what already does it here. When the same logic appears twice, lift it to where both callers route.
- **KISS.** The boring version a reader follows at a glance.
  e.g. no indirection, generality, or cleverness the current problem doesn't demand.
- **YAGNI.** Build what is asked.
  e.g. no interface with one implementation, no config for a value that never changes, no scaffolding for later.
- **Let errors bubble up.** A built-in exception that already pinpoints the failure beats your reword. Write a message only for recovery guidance, context the caller can't see, or a user-facing trust boundary.
