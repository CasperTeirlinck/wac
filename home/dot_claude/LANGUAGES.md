Language-specific instances of the rules in `CLAUDE.md`. The general rule still applies where a language has no entry here.

## Rust

- **Types already speak.** For `stack_names: HashMap<WindowId, String>` write `/// Custom names for stack items.`, not `/// ..., keyed by window id`.
- **`Option`/`Result` already say it can be absent or fail**, so skip `/// None if <thing> isn't found.` Document the absent case for a non-obvious trigger (`None` if Accessibility permission is missing), a meaningful outcome (`None` means the subtree collapsed to empty, not that it failed), or a tri-state (`Option<bool>`: `None` = couldn't read, not `false`).
- **`let _ = f();`** for a call kept only for its side effect, over a named-but-unused binding plus a comment. An RAII guard that must outlive the statement needs a real binding (`let _guard = f();`), and only there a comment on why it must stay alive.
- **Bare `.unwrap()` or `?` over `.expect("main thread")`** when the string only restates the invariant or names the call. The panic already reports location and type. Reserve `expect` for a real recovery hint.
- **Wrap comments to rustfmt's `max_width`**, which a project may set wide (200).

## Python

- **`token = tokens[key]`** (raises `KeyError`) over `tokens.get(key)` plus a custom `raise` that says the same thing.
