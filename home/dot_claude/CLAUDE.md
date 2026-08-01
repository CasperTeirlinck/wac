@RTK.md

## Docstrings & comments

- **Concise docstrings.** A module/class/function docstring is one line saying what the thing _is_ — not a multi-paragraph walkthrough of its behavior, parameters, or edge cases. If a docstring runs to several paragraphs, most of it is noise: cut it.
- **Non-obvious behavior → a small inline comment at the logic**, not prose in the root docstring. Explain a specific line where it's surprising; don't front-load explanations that the reader can't yet map to code.
- **Cite non-derivable sources.** When a value, format, protocol, or quirk can't be inferred from the code (an API contract, a spec, an upstream doc), link the official source in a comment so it's verifiable — especially for AI-generated code that could otherwise hallucinate it. Keeping the doc link is good.
- **No session narrative.** Never encode how the code was arrived at: no comments about what was considered/rejected/refactored, no "this isn't coupled to X", "unlike the old approach", "now generic", "single source of truth", etc. These are the story of an editing session, irrelevant to the final code. Comments describe the code as it _is_, not the iteration that produced it.

## Wrapping long strings

- **Break at logical boundaries, not at the width limit.** When a string literal is split across lines (implicit concatenation to respect line length), put the break where a human reading aloud would pause: end of a sentence, at a comma, before a conjunction or preposition. Choose the _latest_ such boundary that still fits the line-length limit — do not break mid-phrase just because the next word would overflow.
- **Only break mid-phrase when a single clause is itself longer than the limit**, and then at the most natural sub-point (after a comma, before a preposition), never an arbitrary word.
- **Keep the trailing space on the left fragment** so the joined string reads correctly.

## Let errors bubble up

- **Don't catch-and-rethrow errors.** If a built-in exception already pinpoints the failure, let it propagate — don't wrap an operation in a check that raises your own message saying the same thing. `token = tokens[key]` (raises `KeyError`) beats `token = tokens.get(key); if token is None: raise ValueError(f"unknown key: {key}")`.
- **Only craft a custom error when it genuinely adds something** — recovery guidance, context the caller can't see, or a trust-boundary message shown to a user. Otherwise the fewer lines, the better.
