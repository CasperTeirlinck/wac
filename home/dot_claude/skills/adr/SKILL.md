---
name: adr
description: Generate an Architecture Decision Record (ADR). Supports two modes — full deliberated ADRs (with Context/Options/Recommendation/Decision sections) and minimal ad-hoc ADRs (1-3 sentences) for decisions made on the fly. Auto-detects the repo's ADR folder under docs/.
---

# ADR Generation

Invocation of this skill implies the user has already decided to record an ADR — don't second-guess that. Focus on capturing the decision well.

## Step 1: Find the ADR folder

Search for an existing `adr` folder under `docs/`:

1. `docs/adr/` (most common)
2. `docs/*/adr/` (e.g., `docs/architecture/adr/`)

If none exists, create `docs/adr/`. Don't look outside `docs/` — keep ADRs together.

## Step 2: Choose the ADR mode

Two modes. Pick based on how the decision was reached. The sections must be **consistent within a file** — don't mix the two formats.

### Full ADR — deliberated decision

Records the reasoning while a decision is being made (or just after, while it's fresh). Sections: Context, Options, Recommendation, Decision. Frontmatter has `status` (`proposed` | `decided` | `deprecated` | `superseded by ADR-NNNN`), `proposal_date`, `decision_date` (empty until decided), and `deciders`.

Template: [templates/full.md](./templates/full.md)

### Minimal ad-hoc ADR — decision recorded after the fact

Captures a decision that was made on the fly so future readers know it was deliberate. Body is just title + 1-3 sentences: what was decided and why. Frontmatter has `status: decided`, both dates set to today, and `deciders: ad-hoc` to make it explicit that this ADR was not the product of a formal discussion.

Template: [templates/ad-hoc.md](./templates/ad-hoc.md)

## Step 3: Gather information

If the user supplied a topic as argument (e.g., `/adr kafka migration`), use it as the title and skip that question.

Ask remaining questions **one at a time** in plain text — do NOT use AskUserQuestion. Wait for each answer before asking the next.

**Full ADR** — ask in order:

1. Title (skip if provided)
2. Context (what problem requires a decision)
3. Options
4. Recommendation (optional — is there a preferred option?)
5. Deciders

**Minimal ad-hoc ADR** — ask only:

1. Title (skip if provided)
2. The 1-3 sentence body — what was decided and why

## Step 4: Write the file

- Path: `<adr-folder>/YYYY.MM.DD-kebab-slug.md` (e.g., `docs/adr/2026.05.16-kafka-migration.md`)
- Read the chosen template from [templates/full.md](./templates/full.md) or [templates/ad-hoc.md](./templates/ad-hoc.md)
- Substitute today's date for the `YYYY-MM-DD` placeholders and fill in the body
- Write the file

This naming convention and these templates are the ones this skill defines — do not try to detect or match a different convention from existing ADRs in the folder.
