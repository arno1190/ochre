# Ochre: build agent guide

You build Ochre from its specification, starting from an empty codebase. `docs/` is the **single source of truth**. The code answers to it, and when the two must differ, the spec changes first, through an ADR.

## Where things are

- The whole design in one page: `docs/overview.md`. Read it once at the start of every iteration.
- Vocabulary for every identifier, label and message: `docs/01-glossary.md`. Use its words and none of its *Avoid* list.
- What to build next, its acceptance criteria and the definition of done: `docs/11-roadmap.md`.
- Before touching a milestone's code, read its spec:
  - tables: `docs/04-data-model.md`;
  - endpoints: `docs/06-api.md`;
  - screens: `docs/07-screens.md`;
  - journeys: `docs/02-workflows.md`.
- Permissions, sign-in and providers: `docs/03-identity-access.md`. Every route goes through `ochre/policy.py`.
- Model calls, mail, intake and background work: `docs/05-automation.md`. Prompts there are verbatim templates.
- Colours, type, components and motion: `docs/08-design-system.md`. Only tokens, in both themes.
- Stack, layout, config, security, tests and the licence rule: `docs/09-architecture.md`.
- Why something differs from the v0 prototype: `docs/10-design-history.md`.
- Loop state: `progress.txt`. Read it first and update it last.

## How you work

1. **One milestone at a time, in roadmap order.** Inside a milestone, take one acceptance criterion at a time: write its test, see it **red**, implement until **green**, refactor, commit.
2. A commit holds one criterion or one coherent slice. Use conventional commits (`feat(intake): …`), run `make check` first, and include the `progress.txt` update.
3. **Lean**: the smallest design that meets the spec. Prefer deleting code to adding it, and prefer one function over a new abstraction. 09 §3 has the code rules.
4. When the spec is ambiguous, pick the reading most consistent with the glossary and the principles (00 §Principles, in order). Record the choice in `docs/adr/NNNN-title.md` (format in `docs/adr/README.md`) and carry on.
5. When the spec is wrong (contradictory, or impossible as written), fix the spec in the same commit as the code, with an ADR.
6. Work noticed outside the current criterion goes in `docs/backlog.md`, never in a TODO comment.
7. Every dependency you add is permissively licensed (MIT, BSD, Apache-2.0, ISC, MPL-2.0, PSF). Check before adding it. Ochre is MIT.
8. External services are fakes in tests: a fake IdP, aiosmtpd, GreenMail, respx, `FunctionModel`. Tests make no real network calls.
9. Credentials are named by their environment variable or secret name only. Test values are obviously fake (`test-secret-not-real`). Real keys, tokens and passwords appear nowhere in code, tests, logs, commits or `progress.txt`.

## Blocked

Set `## Current State: BLOCKED` in `progress.txt`, write the exact question under `## Blocked on`, and stop. Do this only when a decision needs the maintainer: a real account or credential, a licence or naming choice, or a spec contradiction that an ADR cannot settle without changing product intent. Everything else you decide yourself.
