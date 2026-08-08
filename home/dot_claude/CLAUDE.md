@RTK.md

These rules govern all code you write and every file you touch, not only new code.

## Docstrings & comments

- **Concise docstrings.** One line saying what the thing _is_, not a walkthrough of its behavior, parameters, or edge cases. If a docstring runs to several paragraphs, most of it is noise: cut it.
- **No duplication.** Never restate what the code, its names, or its type signature already say. Don't describe what the type declares (key/value types, container kind, `Option`/`Result`-ness): for `stack_names: HashMap<WindowId, String>` write `/// Custom names for stack items.`, not `/// ..., keyed by window id` (the `HashMap<WindowId, _>` already says that). Delete comments that narrate the line below them, and docstrings that merely repeat the filename.
- **Don't restate the obvious `None`/`Err`.** The `Option`/`Result` signature already says it can be absent or fail, so skip `/// None if <thing> isn't found.` For `fn split_pane(...) -> Option<Node>`, the doc is just what it does. Document the absent/error case only when it carries what the signature can't: a non-obvious trigger (`None` if Accessibility permission is missing), a meaningful outcome (`None` means the subtree collapsed to empty, not that it failed), or a tri-state (`Option<bool>`: `None` = couldn't read, not `false`).
- **Say intent in code when the language can.** For a call kept only for its side effect, write `let _ = f();` (the `let _` states the result is deliberately dropped), not a named-but-unused binding plus a comment. Caveat: an RAII guard that must outlive the statement needs a real binding (`let _guard = f();`); comment only the non-obvious reason it must stay alive.
- **Name the step in code, don't narrate flow.** A function body must not read like prose with comments as section headings (`// Sort the displays`, `// Now adopt the windows`, `// Step 2: reconcile`). Lift a labeled run of steps into a well-named function: the name is the label, the signature states its inputs and result. Reserve inline comments for the non-obvious _why_ (a quirk, a workaround). A reader follows the flow from names, signatures, and control structure alone.
- **Non-obvious behavior → a small inline comment at the logic**, not prose in the root docstring. Explain the surprising line where it sits, not up front where the reader can't yet map it to code.
- **Cite non-derivable sources.** When a value, format, protocol, or quirk can't be inferred from the code (an API contract, a spec, an upstream doc), link the official source in a comment so it's verifiable. Keep doc links.
- **Be consistent within a file and across the codebase.** Match the surrounding comment style, density, and width. When editing comments in one place, make the whole file consistent rather than patching a single spot.
- **No session narrative.** Never encode how the code was arrived at: no "this isn't coupled to X", "unlike the old approach", "now generic", "single source of truth", no notes on what was considered or rejected. Comments describe the code as it _is_, not the edit that produced it.

## Wrapping text (strings, comments, prose, Markdown)

Applies to **any** hard-wrapped text, not just strings: string literals, code comments, and prose in Markdown, docs, and commit messages.

- **Break at logical boundaries, not at the width limit.** Put the break where a reader pauses: end of sentence, at a comma, before a conjunction or preposition. Choose the _latest_ such boundary that still fits the limit. Never split a fixed term or a hyphenated compound, and never end a line on a dangling article ("a", "the") or a lone preposition. In `press the chord to bring it forward, press again to hide it.` don't break after `it` (that splits `bring it forward`); run on to the comma after `forward,` or the period after `hide it.` Only break mid-phrase when a single clause is itself longer than the limit, and then at its most natural sub-point.
- **Match the formatter's width; default 120 for standalone prose.** Wrap comments to the code's configured line length (e.g. rustfmt `max_width`, which a project may set wide, like 200). Never fall back to 80: a too-narrow target forces the mid-phrase breaks above. Avoiding a mid-phrase break beats hitting the width, so let a line run to the next natural boundary.
- **Prefer single-line comments.** If a comment fits on one line within the width, keep it on one line. Only wrap when it genuinely exceeds the width, and then at natural boundaries; collapse an existing multi-line comment that now fits onto one line.
- **Splitting a string literal: keep the trailing space on the left fragment** so the joined string reads correctly.

## Writing style

- **Don't hardcode a configurable value in a comment or message.** Refer to a keybinding or prefix by its role, not its current literal, since it can change or become user-configurable: say "the prefix" or the command's name (e.g. tmux-style `prefix-q`), never the literal chord like `⌥a`. The code that binds the key is the single source of truth; comments and messages describe the role.
- **No em-dashes.** Never use em-dashes (the U+2014 character) in prose, docs, comments, commit messages, or UI text. Use a colon, a comma, or a new sentence. A hyphen inside a compound word (`off-screen`, `read-only`) is fine; a hyphen standing in as a sentence dash is not, rewrite it.

## Let errors bubble up

- **Don't catch-and-rethrow.** If a built-in exception already pinpoints the failure, let it propagate; don't wrap an operation in a check that raises your own message saying the same thing. `token = tokens[key]` (raises `KeyError`) beats `token = tokens.get(key); if token is None: raise ValueError(f"unknown key: {key}")`.
- **Only craft a custom error when it adds something:** recovery guidance, context the caller can't see, or a trust-boundary message shown to a user. Otherwise the fewer lines, the better.
- **Don't type a panic message that adds nothing.** Prefer bare `.unwrap()` (or `?`) over `.expect("...")` when the string only restates the invariant or names the call; the panic already reports the location and type. `MainThreadMarker::new().unwrap()` beats `.expect("main thread")`. Reserve `expect`/a written message for a real recovery hint or a user-facing, trust-boundary message.
