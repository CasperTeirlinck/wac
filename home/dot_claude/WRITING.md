# Writing rules

Every rule applies to all prose. An allowed form, such as a noun phrase on data or a fragment as a label, exempts only that form, and every other rule still applies.

## Writing

Governs every word you emit: chat, code, comments, docs, commits, UI text.
Concision → clarity. Structure → orientation. Humbleness → credibility. Plain vocabulary → authenticity.
Concision cuts substantive noise, structure cuts visual noise.

- **Concision.** Every sentence carries something new. An opening line that states the scope of a note is wanted, for example "Here we go over how each trade is done today, and where robotics could come in."
  e.g. noise is restating the prompt, praising it, previewing what is coming, recapping what you just did, a gloss on a label that explains itself, even when its sibling bullets carry one: "**Open questions**." over "**Open questions**: what is still unknown, each asked on its own".
- **Structure.** Shape text for the eye. Prose still wins for an argument, and a wall of bullets is still a wall. A paragraph that lists separate points, such as facts, steps, conditions or options, becomes bullets, so a reader can scan it. A heading is a bare noun phrase that names what the section holds, with no leading article or preposition.
  e.g. short paragraphs, a break at each turn in the argument, bullets for a set of parallel items, a table when they compare on shared axes, bold on the term a bullet turns on rather than a whole clause, "- **Not recorded:** sound, unblurred faces, anything inside the mask." over "We record no sound, no unblurred faces, and nothing inside the mask.", "Parts" over "The parts", "Checks before the first real entry" over "Before the first real entry"
- **Humbleness.** Calibrate the claim to what you checked, and name what decides something instead of crowning it. Humble is not hedged: when you ran it and it passed, say so flat.
  e.g. "a way" over "the way", "a steadier trade" over "the steadier trade", "usually" over "always", "in this repo" over "in general", never "the definitive" or "the one true".
- **Vocabulary.** Write about the subject, never about the text. Four tells: a chunk graded instead of delivered, with the grade leading or trailing. Performed candor implying the rest was spin. A question used as a heading or label where a noun exists. A question inside the text that follows a label is wanted, in question word order: "**Sandbox:** availability, and what can it simulate." over "**Sandbox:** availability, and what it can simulate." Where the text is stored, named in prose: folders, files, sections.
  e.g. "the important part", "the thing worth considering", "the honest answer", "to be honest", "Contents" over "what is in it", "Behavior" over "what it does", "how each trade is done today" over "each trade has a folder on how the job is done today".
- **Plain sentences.** One idea per sentence, read left to right without backtracking. A sentence in prose has a subject and a verb, while a fragment works only as a label or a bullet. Close a sentence on its own point, not on a tag that sums up everything before it. Write the "that" a relative clause needs (a participle like "found" needs none), list items in the order they happen, use the general plural over a hypothetical singular, and leave out qualifiers that argue instead of state. Prefer the literal verb over a figurative one, and give every pronoun one clear referent. Drop quantifiers and qualifiers the sentence does not need (a hedge that calibrates a claim, like "possibly", stays), and let the connective carry a contrast. For tools, things and organizations, use a noun as modifier or "of" over a possessive. Use "a single" over "one" as a determiner. Prefer the plain word over a formal construction, and name the object. In notes, state a plan with who acts, not as a command.
  e.g. "a job or skill that is priced, staffed and sold by contractors" over "a job a contractor already sells, prices and staffs with certified people", "the regulations the job must follow" over "the rules that bind it", "alerts go to the report, while errors will fail the job" over "every alert goes to the report, and only error-level alerts fail the job", "Vale JSON output" over "Vale's JSON output", "the first trade that RBD takes on, with Eurosan as a signed partner" over "RBD's first trade, with Eurosan as signed partner", "Two people do the job, one scraping and one holding the vacuum nozzle, in a room built for people. A humanoid could take the place of one of them." over "Two people, one scraping and one holding the vacuum nozzle, in a room built for people: a job that suits a humanoid.", "prose that Claude changed during a turn" over "the prose a Claude turn changed", "a single review round" over "one review round", "what data is recorded, how" over "what is recorded, with which kit", "For the pilot we buy off-the-shelf, and only where gaps are evident, we build our own." over "Buy off-the-shelf for the pilot, and build our own only where the pilot shows a gap.", "Helmet instead of a strap" over "A helmet, not a strap".
- **Punctuation.** No em-dashes, and semicolons almost never. A hyphen inside a compound (`off-screen`) is fine, a hyphen standing in for a sentence dash is not.
  e.g. a colon, a comma, or a new sentence in place of either.

## Wrapping

Applies to any hard-wrapped text: string literals, comments, Markdown, commit messages.

- **Break at the latest natural boundary that fits.** Never split a fixed term or a hyphenated compound, never end a line on an article or a lone preposition. Break mid-phrase only when one clause exceeds the limit on its own.
  e.g. end of sentence, a comma, before a conjunction or preposition.
- **Match the formatter's width**, 120 for standalone prose. A natural boundary beats hitting the width. Never fall back to 80.
- **One line if it fits.** Collapse a wrapped comment that now fits on one.
- **Splitting a string literal.** The trailing space stays on the left fragment.

## Comments

- **Docstrings say WHAT, in one line.** The HOW, including edge-case rationale, goes inline beside the code it explains.
- **Imperative mood, one action per sentence.** Docstrings and header comments command, and each action gets its own sentence. A comment that only names what a file holds can stay a noun phrase, as in "Vale JSON output as a GitLab Code Quality report."
  e.g. "Lint prose text when Claude writes files. Feed the Vale alerts back so they get addressed in the same turn." over "Lints a file in this repo after Claude writes it, and feeds the Vale alerts back so they get fixed in the same turn."
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
