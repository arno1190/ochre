# Ochre

**Open-source, self-hosted recruitment for small teams.** Ochre bundles a careers site, an intake mailbox, pipelines, blind scorecards, candidate email, and an AI first reader that never decides anything for you.

It runs as one container next to Postgres. People sign in with the workspace they already use (Microsoft 365, Google Workspace, any OIDC provider, or local accounts), and Ochre talks to any OpenAI-compatible model, including local ones.

> **Status: specification.** No application code exists yet. This repository holds a complete design and a build plan that an autonomous coding agent follows from an empty directory to v1.0. The code will grow next to these docs, in this same repository.

## Read the design

Start with **[docs/overview.md](docs/overview.md)**: the whole design in one page, with diagrams. Then go deeper where you need to:

| # | Document | Answers |
|---|---|---|
| 00 | [Product](docs/00-product.md) | Who it is for, principles, scope, non-goals, the workspace question |
| 01 | [Glossary](docs/01-glossary.md) | The exact vocabulary used by code, UI and docs |
| 02 | [Workflows](docs/02-workflows.md) | Every user journey, step by step |
| 03 | [Identity and access](docs/03-identity-access.md) | Sign-in adapters, the four setup profiles, roles, permissions, blind scoring, agent-managed IAM |
| 04 | [Data model](docs/04-data-model.md) | Reference Postgres schema, invariants, event catalogue, deletion rules |
| 05 | [Automation, AI and mail](docs/05-automation.md) | Background work, the LLM gateway, prompts, intake, outbox, digest, GDPR |
| 06 | [HTTP API](docs/06-api.md) | Endpoints and permissions, public careers API, SCIM, MCP |
| 07 | [Screens](docs/07-screens.md) | Every route and state, the careers site, emails |
| 08 | [Design system](docs/08-design-system.md) | The "Primaries on paper" palette, type, components, motion, tokens |
| 09 | [Architecture](docs/09-architecture.md) | Decisions, stack, code layout, configuration, deployment, security, tests |
| 10 | [Design history](docs/10-design-history.md) | What was kept from the v0 prototype, what changed and why |
| 11 | [Roadmap](docs/11-roadmap.md) | 13 milestones with testable acceptance criteria |

Decisions taken while building are recorded in [docs/adr/](docs/adr/).

## Build it with an agent (Ralph mode)

The repository can be picked up by an autonomous loop with no human in the room:

| File | Role |
|---|---|
| [`prompt.md`](prompt.md) | The prompt each iteration receives |
| [`progress.txt`](progress.txt) | Loop state (`INITIALIZING` → `IN_PROGRESS` → `COMPLETED`, or `BLOCKED`) plus the milestone checklist. The loop reads it to decide whether to continue |
| [`AGENTS.md`](AGENTS.md) (read through [`CLAUDE.md`](CLAUDE.md)) | The agent's operating rules: TDD per acceptance criterion, one milestone per iteration, specs before code, when to stop |
| [`scripts/ralph-loop.sh`](scripts/ralph-loop.sh) | A minimal loop: runs `claude -p "$(cat prompt.md)"` until `progress.txt` says `COMPLETED` or `BLOCKED` |

Run it inside a disposable container or VM, since the agent needs to run Docker, `uv`, `pnpm` and Playwright without permission prompts:

```bash
git clone https://github.com/arno1190/ochre && cd ochre
MAX_ITERATIONS=20 ./scripts/ralph-loop.sh        # uses `claude -p`; set CLAUDE_FLAGS for your sandbox
```

Requirements for the build machine: Docker, Python 3.13 with `uv`, Node 22 with `pnpm`, and the `claude` CLI. The build needs **no** real credentials. Every external service is faked in tests.

## Licence

[MIT](LICENSE). Because of it, every runtime dependency must be permissive too, and CI enforces this ([09 §2](docs/09-architecture.md)).
