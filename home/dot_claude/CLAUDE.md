@RTK.md

## Docstrings & comments

- **Concise docstrings.** A module/class/function docstring is one line saying what the thing *is* — not a multi-paragraph walkthrough of its behavior, parameters, or edge cases. If a docstring runs to several paragraphs, most of it is noise: cut it.
- **Non-obvious behavior → a small inline comment at the logic**, not prose in the root docstring. Explain a specific line where it's surprising; don't front-load explanations that the reader can't yet map to code.
- **Cite non-derivable sources.** When a value, format, protocol, or quirk can't be inferred from the code (an API contract, a spec, an upstream doc), link the official source in a comment so it's verifiable — especially for AI-generated code that could otherwise hallucinate it. Keeping the doc link is good.
- **No session narrative.** Never encode how the code was arrived at: no comments about what was considered/rejected/refactored, no "this isn't coupled to X", "unlike the old approach", "now generic", "single source of truth", etc. These are the story of an editing session, irrelevant to the final code. Comments describe the code as it *is*, not the iteration that produced it.
