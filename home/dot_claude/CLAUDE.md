@RTK.md

## Writing

Governs every word you emit: chat, code, comments, docs, commits, UI text.
Concision → clarity. Structure → orientation. Humbleness → credibility. Plain vocabulary → authenticity.
Concision cuts substantive noise, structure cuts visual noise.

- **Concision.** Every sentence carries something new.
  e.g. noise is restating the prompt, praising it, previewing what is coming, recapping what you just did.
- **Structure.** Shape text for the eye. Prose still wins for an argument, and a wall of bullets is still a wall.
  e.g. short paragraphs, a break at each turn in the argument, bullets for a set of parallel items, a table when they compare on shared axes, bold on the term a bullet turns on rather than a whole clause.
- **Humbleness.** Calibrate the claim to what you checked, and name what decides something instead of crowning it. Humble is not hedged: when you ran it and it passed, say so flat.
  e.g. "a way" over "the way", "usually" over "always", "in this repo" over "in general", never "the definitive" or "the one true".
- **Vocabulary.** Write about the subject, never about the text. Two tells: grading a chunk instead of delivering it, the grade leading or trailing, and performed candor implying the rest was spin.
  e.g. "the important part", "the interesting bit", "the thing worth considering", "what it does" as a label, "the honest answer", "to be honest".
- **Punctuation.** No em-dashes, and semicolons almost never. A hyphen inside a compound (`off-screen`) is fine, a hyphen standing in for a sentence dash is not.
  e.g. a colon, a comma, or a new sentence in place of either.

### Wrapping

Applies to any hard-wrapped text: string literals, comments, Markdown, commit messages.

- **Break at the latest natural boundary that fits.** Never split a fixed term or a hyphenated compound, never end a line on an article or a lone preposition. Break mid-phrase only when one clause exceeds the limit on its own.
  e.g. end of sentence, a comma, before a conjunction or preposition.
- **Match the formatter's width**, 120 for standalone prose. A natural boundary beats hitting the width. Never fall back to 80.
- **One line if it fits.** Collapse a wrapped comment that now fits on one.
- **Splitting a string literal.** The trailing space stays on the left fragment.

## Code

Governs all code you write and every file you touch, not only new code.
Writing Rust or Python: read `~/.claude/languages.md` before the first edit.

- **DRY.** One authority per fact or behavior. Reuse what already does it here. When the same logic appears twice, lift it to where both callers route.
- **KISS.** The boring version a reader follows at a glance.
  e.g. no indirection, generality, or cleverness the current problem doesn't demand.
- **YAGNI.** Build what is asked.
  e.g. no interface with one implementation, no config for a value that never changes, no scaffolding for later.
- **Let errors bubble up.** A built-in exception that already pinpoints the failure beats your reword. Write a message only for recovery guidance, context the caller can't see, or a user-facing trust boundary.

### Comments

- **Docstrings say WHAT, in one line.** The HOW, including edge-case rationale, goes inline beside the code it explains.
- **Never restate the code, its names, or its types.**
- **Skip what the signature already declares.** Document an absent or failing case only when it carries what the signature can't: a non-obvious trigger, a meaningful outcome, or a tri-state.
- **Say intent in code where the language can**, over a binding plus a comment that says it in prose.
- **Name the step in code, don't narrate flow.** Lift a labeled run of steps into a named function. Inline comments carry the non-obvious why, a quirk or a workaround.
  e.g. no section headings in a body: `// Sort the displays`, `// Step 2: reconcile`.
- **Cite what the code can't derive.** Link the spec, API contract, or upstream doc behind any value, format, or quirk. Keep doc links.
- **Refer to a configurable by its role**, not its current literal.
  e.g. "the prefix" or `prefix-q`, never the chord it is bound to today.
- **Describe the code as it is.** No session narrative.
  e.g. no "unlike the old approach", "now generic", "single source of truth", no record of what was considered or rejected.
- **Match the file's existing comment style** when you touch it, and make the whole file consistent rather than patching one spot.
