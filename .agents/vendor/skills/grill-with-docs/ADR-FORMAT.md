# ADR Format

This format is vendored from Matt Pocock's third-party `skills` library and adapted for Swiftfin's fork-only `.agents/` workspace:
https://github.com/mattpocock/skills

Fork-only agent ADRs live in `.agents/adr/` and use sequential numbering:

- `0001-short-slug.md`
- `0002-short-slug.md`

Create `.agents/adr/` lazily, only when the first ADR is needed.

## Template

```md
# Short Title

One to three sentences explaining the context, the decision, and why the decision was made.
```

That is enough for most ADRs. The value is recording that a decision was made and why.

## Optional Sections

Use these only when they add value:

- `Status`: `proposed`, `accepted`, `deprecated`, or `superseded by ADR-NNNN`.
- `Considered Options`: alternatives worth remembering.
- `Consequences`: non-obvious effects future agents should know.

## Numbering

Scan `.agents/adr/` for the highest existing number and increment by one.

## When To Write One

Write an ADR only when the decision is hard to reverse, surprising without context, and the result of a real tradeoff.
