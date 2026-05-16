---
name: glossary
description: Maintain a project's ubiquitous language — a DDD-style glossary structured as one or more bounded contexts with an optional context map. Defines and sharpens domain terms, flags ambiguities, and updates CONTEXT.md / CONTEXT-MAP.md files. Use when documenting domain language, refining terms, or bootstrapping a glossary from existing code.
---

# Glossary

This skill maintains a project's **ubiquitous language**: a shared vocabulary used identically in code, docs, and conversation. It is grounded in Domain-Driven Design (DDD), the few concepts you need are below.

## DDD essentials

- **Ubiquitous language**: a set of terms with precise, agreed meanings, used the same way in code, docs, and conversation. Removes the constant translation between "what the team says" and "what the code says".
- **Bounded context**: a part of the system in which one consistent language applies. The word "Customer" in Billing may mean something different than "Customer" in Support — each lives in its own bounded context, and the difference is intentional.
- **Context map**: the relationships between bounded contexts in a multi-context system (who emits events to whom, what types are shared, where translation happens).

Most repos are a single bounded context. Only larger systems — often monorepos — split into multiple.

## Modes

Pick a mode based on how the skill was invoked:

- **Interactive (default)**: the user wants to add, refine, or clarify terms. Ask what to add or change, then update the files inline.
- **Bootstrap / scan**: if the user says "bootstrap", "scan", or invokes `/glossary scan`, explore the codebase first to draft a starter glossary from domain types, module names, and entity definitions. Then hand off to interactive refinement with the user.

## File layout

### Single bounded context (most repos)

```
/
└── CONTEXT.md
```

### Multiple bounded contexts

The contexts can live wherever the team naturally splits the code — they don't have to follow `src/<context>/`. A monorepo may use `services/`, `apps/`, `modules/`, or a custom layout.

```
/
├── CONTEXT-MAP.md
├── services/ordering/CONTEXT.md
├── apps/billing/CONTEXT.md
└── packages/fulfillment/CONTEXT.md
```

`CONTEXT-MAP.md` at the repo root lists the contexts and how they relate.

### Detecting the structure

- If `CONTEXT-MAP.md` exists at the root → multi-context. Read it to find each context's `CONTEXT.md`.
- If only `CONTEXT.md` exists at the root → single context.
- If neither exists → assume single context. Create `CONTEXT.md` at the root lazily, when the first term is added.

When working in multi-context mode, infer which context the current topic belongs to. If unclear, ask.

## Templates

- **CONTEXT.md**: [templates/context.md](./templates/context.md) — sections for description, language (terms with aliases to avoid), relationships, example dialogue, and flagged ambiguities.
- **CONTEXT-MAP.md**: [templates/context-map.md](./templates/context-map.md) — lists the bounded contexts and their inter-context relationships.

Read the relevant template, substitute the placeholders, and write the file. These are the formats this skill defines — don't deviate.

## Rules

- **Be opinionated.** When multiple words exist for the same concept, pick the best one and list the others as aliases to avoid. The whole point of a ubiquitous language is to converge.
- **Flag conflicts explicitly.** If a term is used ambiguously, call it out under "Flagged ambiguities" with a clear resolution.
- **Keep definitions tight.** One sentence max. Define what the term IS, not what it does.
- **Show relationships.** Use bold term names and express cardinality where obvious.
- **Only include domain-specific terms.** General programming concepts (timeouts, error types, utility patterns) don't belong even if the project uses them extensively. Before adding a term, ask: is this unique to this domain, or generic?
- **Group terms under subheadings** when natural clusters emerge. If all terms belong to one cohesive area, a flat list is fine.
- **Write an example dialogue.** A short conversation between a dev and a domain expert that demonstrates how the terms interact and clarifies boundaries between related concepts.
- **The glossary is a glossary.** Not a spec, not a scratch pad, not a place for implementation decisions. Implementation decisions belong in ADRs.

## Bootstrap mode

When invoked with `scan` / `bootstrap`:

1. Explore the codebase to find domain-shaped concepts: module names, top-level entities, aggregate roots, named events, repository names.
2. Draft a starter `CONTEXT.md` (or per-context files plus a `CONTEXT-MAP.md` if the layout clearly splits into multiple contexts).
3. Mark every drafted term as provisional — the user must confirm or refine each one before it's locked in.
4. Switch to interactive mode and walk through the draft with the user one term at a time.

Bootstrap is for getting unstuck on a fresh repo, not for skipping the conversation. The user is still the source of truth for what each term means.
