# Architecture decision records

One file per decision taken while building, named `NNNN-short-title.md` and numbered from `0001`. The spec in `docs/` stays the source of truth. An ADR explains why the spec was read a certain way, or why it was changed. When an ADR changes behaviour, the commit that adds it also updates the spec.

Format, five lines or fewer per section:

```markdown
# NNNN. Title

Date: YYYY-MM-DD · Milestone: Mx

## Context
What was ambiguous, wrong or missing, citing the spec section.

## Decision
What we do.

## Consequence
What changes in the spec or code, and what it rules out.
```

The decisions made while writing the spec are listed in [09 §1](../09-architecture.md).
