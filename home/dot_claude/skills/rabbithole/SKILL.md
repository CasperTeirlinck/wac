---
name: rabbithole
description: Stress-test a plan against the codebase's existing domain. Interview the user relentlessly, challenge their language against the project glossary, surface contradictions with the code, and capture decisions as glossary updates and ADRs as they crystallise. Use when stress-testing a plan, going down a design rabbithole, or wanting decisions captured inline.
---

<what-to-do>

Interview me relentlessly about every aspect of this plan until we reach a shared understanding. Walk down each branch of the design tree, resolving dependencies between decisions one-by-one. For each question, provide your recommended answer.

Ask the questions one at a time, waiting for feedback on each question before continuing.

If a question can be answered by exploring the codebase, explore the codebase instead.

</what-to-do>

<supporting-info>

## Delegating to other skills

This skill delegates two responsibilities to standalone skills:

- **glossary** — for adding or refining domain terms (`CONTEXT.md` / `CONTEXT-MAP.md`, DDD-style bounded contexts and ubiquitous language)
- **adr** — for recording architectural decisions

For each, **prefer a project-local skill if the repo provides one**, in this order:

1. `<repo-root>/.claude/skills/<name>/SKILL.md`
2. A plugin-namespaced skill from the repo (e.g., `team:adr`)
3. The personal fallback at `~/.claude/skills/<name>/SKILL.md`

Teams ship their own versions when they have opinions about ADR format or glossary structure. Respect those.

## Domain awareness

Before starting the interview, find any existing domain documentation in the repo:

- **Glossary**: `CONTEXT.md` at the root, or `CONTEXT-MAP.md` (multi-context) pointing to per-context files. This is the project's ubiquitous language.
- **ADRs**: search for an `adr` folder under `docs/` (e.g. `docs/adr/`, `docs/architecture/adr/`). Past decisions and their reasoning.

These set the ground truth. Challenge the user's plan against them.

## During the session

### Challenge against the glossary

When the user uses a term that conflicts with the existing language in `CONTEXT.md`, call it out immediately. "Your glossary defines 'cancellation' as X, but you seem to mean Y — which is it?"

### Sharpen fuzzy language

When the user uses vague or overloaded terms, propose a precise canonical term. "You're saying 'account' — do you mean the Customer or the User? Those are different things."

### Discuss concrete scenarios

When domain relationships are being discussed, stress-test them with specific scenarios. Invent scenarios that probe edge cases and force the user to be precise about the boundaries between concepts.

### Cross-reference with code

When the user states how something works, check whether the code agrees. If you find a contradiction, surface it: "Your code cancels entire Orders, but you just said partial cancellation is possible — which is right?"

### Update the glossary inline

When a term is resolved, invoke the **glossary** skill to update `CONTEXT.md` right there. Don't batch these — capture them as they happen.

The glossary is a glossary, not a spec or scratch pad. Keep implementation details out — those belong in ADRs or in the code itself.

### Offer ADRs sparingly

Only offer to create an ADR when **all three** are true:

1. **Hard to reverse** — the cost of changing your mind later is meaningful.
2. **Surprising without context** — a future reader will look at the code and wonder "why on earth did they do it this way?"
3. **Result of a real trade-off** — there were genuine alternatives and you picked one for specific reasons.

If any of the three is missing, skip the ADR — you'll just reverse easy decisions, nobody wonders about unsurprising ones, and there's nothing to record when there was no real alternative.

When the gate passes, invoke the **adr** skill to record the decision. Because the decision was reached through deliberation in this session, prefer the full ADR mode (Context / Options / Recommendation / Decision sections) over the ad-hoc minimal form.

#### What qualifies for an ADR

- **Architectural shape.** "We're using a monorepo." "The write model is event-sourced, the read model is projected into Postgres."
- **Integration patterns between bounded contexts.** "Ordering and Billing communicate via domain events, not synchronous HTTP."
- **Technology choices that carry lock-in.** Database, message bus, auth provider, deployment target. Not every library — just the ones that would take a quarter to swap out.
- **Boundary and scope decisions.** "Customer data is owned by the Customer context; other contexts reference it by ID only." Explicit no's are as valuable as yes's.
- **Deliberate deviations from the obvious path.** "We're using manual SQL instead of an ORM because X." Anything where a reasonable reader would assume the opposite. These stop the next engineer from "fixing" something that was deliberate.
- **Constraints not visible in the code.** "We can't use AWS because of compliance requirements." "Response times must be under 200ms because of the partner API contract."
- **Rejected alternatives when the rejection is non-obvious.** If you considered GraphQL and picked REST for subtle reasons, record it — otherwise someone will suggest GraphQL again in six months.

</supporting-info>
