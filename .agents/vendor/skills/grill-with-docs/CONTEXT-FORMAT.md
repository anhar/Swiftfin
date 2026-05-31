# CONTEXT.md Format

This format is vendored from Matt Pocock's third-party `skills` library and adapted for Swiftfin's fork-only `.agents/` workspace:
https://github.com/mattpocock/skills

Fork-only agent glossary terms live in `.agents/CONTEXT.md`.

## Template

```md
# Context Name

One or two sentences describing the context.

## Language

**Canonical Term**: One or two sentences defining the term.
_Avoid_: Ambiguous synonym, overloaded phrase
```

## Rules

- Be opinionated. Pick the best term and list ambiguous alternatives under `_Avoid_`.
- Keep definitions tight.
- Define what the term is, not how it is implemented.
- Include only terms specific to this workspace and workflow.
- Do not use the glossary as a spec, todo list, or scratch pad.
