---
name: adr
description: Generate a new Architecture Decision Record (ADR) for documenting architectural decisions.
---

# ADR Generation

Create a new Architecture Decision Record.

## Instructions

### Step 1: Check for Existing ADRs

Search `docs/adr/` to check if a similar decision already exists or find related ADRs to reference.

### Step 2: Gather Information

If the user provided a topic as argument (e.g., `/adr kafka migration`), use that as the title and skip the title question.

Otherwise, gather information **one question at a time**. Ask a single question, then STOP and wait for the user's response before asking the next question:

1. **First**: Ask for the **Title** - a short, descriptive title for the decision
2. **Second**: Ask for the **Context** - what problem requires a decision?
3. **Third**: Ask for the **Options** - what options are being considered? (2-3 minimum)
4. **Fourth** (optional): Ask if there is a **Recommendation** - is there already a preferred option?

Do NOT ask all questions at once. Ask one question, wait for the answer, then ask the next. Do NOT use the AskUserQuestion tool - just ask in plain text and wait for free text input from the user.

### Step 3: Create the ADR File

1. Read the template from `docs/adr/template.md`
2. Create file: `docs/adr/YYYY.MM.DD-kebab-case-title.md` (use today's date)
3. Fill in the template:
   - Status: `proposed`
   - Deciders: ask user
   - Proposal date: `DD/MM/YYYY` format
   - Leave decision date empty

### Naming Convention

- Date: `YYYY.MM.DD` (e.g., `2025.10.14`)
- Title: kebab-case, lowercase (e.g., `grafana-alerts-cleanup`)
- Example: `2025.10.14-grafana-alerts-cleanup.md`
