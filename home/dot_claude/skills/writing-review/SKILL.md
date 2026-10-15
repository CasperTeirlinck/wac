---
name: writing-review
description: Review prose against writing rules and report each violation with a rewrite. Use when asked to review, check or proofread notes, comments or a diff for writing style.
---

Review prose against the writing rules in [WRITING.md](../../WRITING.md) (`~/.claude/WRITING.md`).

## Input

Review the diff or files you are given. Given nothing, review the uncommitted changes: `git diff` plus new files from `git status`. In a diff, review only the added lines, those starting with `+`.

Review prose only: Markdown text, and comments and docstrings in code. Skip code, front matter, URLs and quoted source text. Skip examples a rule quotes to show what it bans.

For a code comment, read the code it sits on when the input shows that code. The code decides whether the comment is a docstring, on a function, component or hook, or a comment on data, and whether the comment restates the code.

## Rules

Apply every rule in WRITING.md to every line of prose: the Writing, Wrapping and Comments sections alike. An allowed form, such as a noun phrase on data or a fragment as a label, exempts only that form. Check the rest of the sentence against every other rule.

## Output

Report every clear violation, one line each: the file, the quoted phrase, the rule it breaks, and a rewrite. A violation is clear when the text breaks a rule as written, or follows the pattern of a bad example that the rule gives. A rewrite covers the whole sentence and follows every rule itself. Report, do not edit, unless asked to fix.

With no violations, reply with the single word PASS and nothing else.

## Running the review

These instructions apply as written, whoever runs the review.

- **Delegating.** Pass these instructions unchanged to a subagent or another session. Never narrow the review to a subset of the rules, and never add an instruction that changes what gets reported, such as "leave it out when unsure".
- **Large input.** Split it into parts, and review each part against every rule. Review code comments as a part of their own, apart from Markdown.
- **Fixes.** After fixing the violations, review the changed lines again, and repeat until the review passes.
