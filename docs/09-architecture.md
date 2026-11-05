# 09 — Architecture and operations

## 1. Decisions (each one replaces something v0 did)

| # | Decision | Instead of (v0) | Why |
|---|---|---|---|
| D1 | **One image, one process by default**: FastAPI serves the API, the SPA's static build, the server-rendered careers pages and the background-work runner | backend and frontend containers, Prefect server, ECS workers | "One box" (principle 1). Scales out by running more replicas, with `OCHRE_WORKER=only` for dedicated workers |
| D2 | **Postgres is the only stateful dependency**: data, queue (`SKIP LOCKED`), schedules (advisory locks), search (`pg_trgm`), rate limits | Postgres plus Prefect plus nginx rate limits | Fewer moving parts. Every self-hoster already has Postgres |
| D3 | **SPA (Vite + React) for the app, server-rendered Jinja for the careers site** | Next.js for both, with a Node runtime | The app sits behind a login (SEO is useless, SSR adds no value). The careers site needs SEO, no-JS operation and speed: plain HTML is the leanest way to get all three |
| D4 | **Generated API client** from OpenAPI | 1,600-line hand-written client | One source of truth for the API shape |
| D5 | **TanStack Query** with optimistic mutations | `useEffect` plus `useState`, refetch everything | Cache, invalidation and rollback |
| D6 | **Stage kinds plus Stage Actions** | stage-name string comparisons | Renaming or translating Stages must never break behaviour |
| D7 | **Event log written in the service layer, same transaction** | 4 of 10 history types actually written | One trace for timeline, dashboard and audit |
| D8 | **Outbox for every email** | sending inside requests, Graph only | Crash-safe, retryable, transport-agnostic |
| D9 | **OIDC with PKCE, ID-token validation, DB sessions** | auth-code flow without state, nonce or PKCE, Graph `/me`, stateless JWT | Security and revocation |
| D10 | **LLM gateway with key pools, routes and budgets** over pydantic-ai's OpenAI-compatible model | private library pinned to OpenRouter | Any provider, local models, multiple keys |
| D11 | **Sandboxed Jinja templates validated on save** | regex `{{var}}` substitution that sent `{% if %}` literally | Correctness |
| D12 | **One policy module** for reach and capability | three diverging reach rules | Fixes the leaks listed in 10-design-history |

## 2. Stack (pin exact versions in lockfiles; these are minimums)

**Licence rule.** Ochre is MIT, so every runtime dependency must be permissive (MIT, BSD, Apache-2.0, ISC, MPL-2.0 or PSF). GPL, LGPL and AGPL packages are refused. This is why the PDF library is `pypdfium2`, not PyMuPDF (AGPL). CI enforces it with `pip-licenses --fail-on` and `license-checker --failOn` (09 §8). Optional sidecars run as separate containers and are exempt.

**Server**: Python **3.13**, managed with `uv`.

| Area | Libraries |
|---|---|
| Web | `fastapi`, `uvicorn[standard]` (one worker per container; scale with replicas) |
| Data | `sqlalchemy[asyncio]` 2.x, `asyncpg`, `alembic` |
| Models and config | `pydantic` 2.x, `pydantic-settings` |
| AI | `pydantic-ai-slim[openai]` (gateway transport) |
| HTTP and auth | `httpx`, `authlib` or `joserfc` (OIDC, JWKS), `argon2-cffi` |
| Documents | `pypdfium2` (Apache-2.0/BSD-3; PDF text extraction), `python-docx` (MIT) |
| Templating | `jinja2`, `markdown-it-py`, `bleach` (sanitise inbound HTML for display) |
| Mail | `aiosmtplib` (MIT); IMAP through the standard library `imaplib`, run with `asyncio.to_thread`. This avoids a third-party async IMAP library whose licence must then be vetted |
| Storage | `aiobotocore` (S3) |
| Scheduling and logging | `croniter`, `structlog` |
| Google | `google-auth` (Gmail service-account tokens); Gmail REST is called directly with `httpx` |
| Tooling | `typer` (CLI), `ruff`, `mypy --strict`, `pytest`, `pytest-asyncio`, `respx`, `inline-snapshot`, `polyfactory` |

**Web** (built at image build time, never run with Node in production):

| Area | Libraries |
|---|---|
| Core | Vite 6, React 19, TypeScript 5 (strict) |
| Routing and data | `@tanstack/react-router` (file routes, typed search params for URL state), `@tanstack/react-query` |
| Styling | Tailwind CSS v4; `shadcn/ui` components (copied, restyled with 08 tokens); Radix primitives |
| Interaction | `@dnd-kit/core` and `sortable` (accessible drag and drop), `cmdk` |
| Documents and content | `react-pdf` (pdf.js), `react-markdown`, `dompurify` |
| Forms and i18n | `react-hook-form` and `zod`; `i18next` and `react-i18next` (ICU plurals); `@fontsource/instrument-sans`, `instrument-serif`, `jetbrains-mono` |
| API and tests | `openapi-typescript` and `openapi-fetch` (generated client); `vitest`, `@testing-library/react`, `playwright`, `@axe-core/playwright` |

**Careers site**: Jinja templates in `server/ochre/careers/templates`, styled by the same Tailwind build (a separate CSS entry). One small TypeScript entry (`careers.ts`, under 15 kB gzipped) handles the form's progressive enhancement and the captcha.

**Optional sidecars**, configured by URL and absent by default:
- **Gotenberg**: DOCX → PDF previews.
- **Ollama or vLLM**: local models.
- **Tesseract**: v1.x OCR, inside the image behind a build arg.

## 3. Code layout

```
ochre/
├── server/
│   ├── pyproject.toml
│   ├── ochre/
│   │   ├── app.py              # create_app(): routers, middleware, lifespan (migrations lock, worker start)
│   │   ├── config.py           # Settings (env) + typed DB settings registry
│   │   ├── db.py               # engine, session dependency, UUIDv7, base model
│   │   ├── policy.py           # capability(), reach filters (the ONLY place permissions are decided)
│   │   ├── events.py           # emit(type, ...) + catalogue + redaction
│   │   ├── errors.py           # problem+json, stable codes
│   │   ├── cli.py
│   │   ├── identity/           # oidc.py, local.py, sessions.py, scim.py, tokens.py, api.py
│   │   ├── positions/          # models.py, service.py, schemas.py, api.py, pipeline.py
│   │   ├── candidates/         # resolve.py (identity rules), service.py, files.py, library.py, api.py
│   │   ├── applications/       # service.py (move/outcome/transfer), board.py, stage_actions.py, api.py
│   │   ├── assessment/         # assignments.py, scorecards.py, templates.py, blind.py, api.py
│   │   ├── mail/               # transports/{graph,gmail,smtp,log}.py, readers/{graph,gmail,imap}.py, outbox.py, templates.py, api.py
│   │   ├── intake/             # poll.py, process.py, cv_choice.py, matching.py, api.py
│   │   ├── careers/            # public api, rendering, rate_limit.py, captcha.py, templates/
│   │   ├── ai/                 # gateway.py, keys.py, routes.py, budget.py, tasks/{cv_parse,job_match,first_read}.py, grounding.py, digest.py
│   │   ├── work/               # runner.py, registry.py, schedules.py
│   │   ├── dashboard/          # metrics.py, api.py
│   │   ├── gdpr/               # retention.py, erase.py, export.py
│   │   ├── settings/           # registry.py (typed keys), secrets.py (AES-GCM), api.py
│   │   └── mcp/                # server.py (tools → services)
│   ├── migrations/
│   └── tests/                  # mirrors ochre/; tests/ai/fixtures/; tests/policy/matrix.py
├── web/
│   ├── src/{routes,components,features,lib,i18n}/
│   └── src/lib/api.gen.ts      # generated, committed, CI checks it is fresh
├── skills/ochre-operator/SKILL.md
├── AGENTS.md, CLAUDE.md          # build-agent rules (CLAUDE.md imports AGENTS.md)
├── prompt.md, progress.txt       # Ralph loop entry and state
├── scripts/ralph-loop.sh
├── deploy/{compose.yaml, Caddyfile, .env.example, k8s/ (v1.x)}
├── docs/                       # this spec, kept current; ADRs in docs/adr/
├── Dockerfile
└── Makefile                    # setup, dev, check, test, e2e, build
```

Rules for lean code:
- Each domain package exposes a `service.py` of plain async functions taking `(session, actor, …)`. API handlers are three lines: parse, call the service, serialise.
- The services own transactions, call `policy`, and emit Events. The MCP tools and the CLI call the same services.
- No repository layer and no DI container. SQLAlchemy is the data layer.
- Domain packages import each other only through `service.py`. A test (`import-linter`) enforces this.
- Files stay under 400 lines and functions under 50, except for justified data tables.
- No `Any` without a comment explaining why. No `print`; use `structlog`. No bare `except`.

## 4. Configuration

Environment variables (only these are needed to boot; everything else lives in `settings` and `secrets`, editable in the UI):

| Variable | Required | Default | Purpose |
|---|---|---|---|
| `DATABASE_URL` | yes | — | `postgresql://…` (`+asyncpg` is added automatically) |
| `SECRET_KEY` | yes | — | ≥ 32 random bytes, base64. Signs sessions, CSRF, file links; derives the secrets-encryption key. **Rotating it invalidates sessions and makes stored secrets unreadable**: `ochre secrets rekey --old … --new …` re-encrypts them |
| `PUBLIC_URL` | yes | — | `https://ats.example.com`. Used for OIDC redirect URIs, emails and links |
| `STORAGE_URL` | no | `file:///data/files` | or `s3://bucket/prefix?endpoint=…&region=…`, with credentials in `S3_ACCESS_KEY_ID` and `S3_SECRET_ACCESS_KEY` |
| `OCHRE_WORKER` | no | `embedded` | `embedded` \| `off` \| `only` |
| `OCHRE_WORKER_CONCURRENCY` | no | `4` | |
| `MAIL_REDIRECT_TO` | no | — | dev safety valve |
| `LOG_LEVEL`, `LOG_FORMAT` | no | `info`, `json` | |
| `TRUSTED_PROXIES` | no | `127.0.0.1/32` | for client IP (rate limits) from `X-Forwarded-For` |
| `OCHRE__<SECTION>__<KEY>` | no | — | overrides any DB setting (12-factor installs), for example `OCHRE__LLM__ENABLED=false`. Secrets: `OCHRE_SECRET__<NAME>` (for example `OCHRE_SECRET__LLM__OPENROUTER__KEY__1`) |
| `GOTENBERG_URL` | no | — | DOCX previews |

Typed settings keys. This is the canonical list: pydantic models, one per key, in `settings/registry.py`.

| Key | Holds |
|---|---|
| `org` | name, logo, website, address, timezone, default locale, sender name |
| `careers` | locales, theme, hero text, response-time text, privacy notice and consent version per locale |
| `auth` | providers (each with role mapping, `allow_private_network`), allowed domains, JIT, session timeouts |
| `mail` | outbound transport and its config, `allow_private_network` |
| `intake` | reader, mailbox, folder, after-import action |
| `llm` | 05 §2.1 (each provider has `allow_private_network`) |
| `digest` | recipients |
| `rubric` | 05 §3.4 |
| `retention` | 05 §8.1 |
| `default_pipeline` | 02 §W2 |
| `captcha` | provider, site key; the secret lives in `secrets` |
| `work` | `overrides[<schedule>] = {cron?, enabled?}` |
| `metrics` | `enabled`; the bearer token lives in `secrets` |
| `storage` | `allow_private_network` for the S3 endpoint; the URL comes from `STORAGE_URL` |

Each model has its defaults, its validation, and a `test()` where relevant. v1.x adds `ocr` and `calendar`.

Credentials are typed `SecretStr` with no default and no placeholder value. A missing secret means the integration reports "not configured". Ochre never substitutes a dummy value.

## 5. Deployment

### 5.1 Reference `compose.yaml`
```yaml
services:
  ochre:
    image: ghcr.io/arno1190/ochre:1
    env_file: .env                      # DATABASE_URL, SECRET_KEY, PUBLIC_URL
    volumes: [files:/data/files]
    depends_on: {db: {condition: service_healthy}}
    restart: unless-stopped
  db:
    image: postgres:17-alpine
    environment: {POSTGRES_DB: ochre, POSTGRES_USER: ochre, POSTGRES_PASSWORD_FILE: /run/secrets/db_password}
    secrets: [db_password]
    volumes: [pg:/var/lib/postgresql/data]
    healthcheck: {test: ["CMD", "pg_isready", "-U", "ochre"], interval: 5s}
  caddy:                                # TLS; optional if you already have a proxy
    image: caddy:2
    ports: ["80:80", "443:443"]
    volumes: [./Caddyfile:/etc/caddy/Caddyfile, caddy:/data]
secrets: {db_password: {file: ./db_password.txt}}
volumes: {files: {}, pg: {}, caddy: {}}
```
`Caddyfile`: `ats.example.com { reverse_proxy ochre:8000 }`. To serve the careers site on its own host, `careers.example.com` proxies only `/careers*`, `/api/public/*` and `/assets/careers*`, and returns 404 for everything else, which reproduces v0's split.

### 5.2 Image
- A multi-stage build: `node:22` builds the web assets, then `python:3.13-slim` installs with `uv sync --frozen --no-dev` and copies the assets into `ochre/static`.
- Runs as a non-root user on port 8000.
- `HEALTHCHECK` on `/healthz`.
- Target size under 250 MB.
- Multi-arch (amd64, arm64).
- Published to GHCR on tag, with an SBOM and a cosign signature.

### 5.3 Start-up
1. Read the environment and fail fast if a required value is missing, naming it.
2. Take `pg_advisory_lock(hashtext('ochre-migrate'))`, run `alembic upgrade head`, then release.
3. Load settings.
4. Start the worker (unless `OCHRE_WORKER=off`).
5. Serve.
6. If there are no admins, log the setup URL (02 W0).

### 5.4 Health and observability
- `/healthz`: the process is up.
- `/readyz`: DB reachable, migrations at head, and storage writable.
- Logs: JSON via structlog with `request_id`, `user_id`, `route` and `latency_ms`.
  - **Never** log email addresses, names, CV text or message bodies. Where correlation is needed, log `email_hash = sha256(email)[:12]`.
- `/metrics` (Prometheus, off by default, enabled with a bearer token setting) exposes:
  - request histograms;
  - work queue depth;
  - work runs by outcome;
  - mail by status;
  - LLM calls by outcome and provider;
  - intake items by status.

### 5.5 Backups and upgrades
- Back up Postgres plus the files volume or bucket; that is all of Ochre's state. The docs ship a `pg_dump` cron example and an S3 sync example. `ochre backup` (v1.x) does both into one archive.
- Upgrades: pull the new tag and restart. Migrations are forward-only, and the release notes call out any that need downtime (none planned for 1.x).

## 6. Self-hosting with a Claude agent

`skills/ochre-operator/SKILL.md` is a Claude Code skill shipped in the repository. Its frontmatter description: *"Install, configure, upgrade and operate a self-hosted Ochre instance: Docker setup, Microsoft Entra or Google Workspace app registration, OIDC, mail, intake, LLM providers, users and roles. Use when the user wants to deploy Ochre, connect it to their workspace, or manage its users."* Its body, in at most 200 lines, gives:
1. **Discover**:
   - ask which workspace (`microsoft`, `google`, `standard`, `solo`), the domain, and where it will run (VM with Docker, existing Kubernetes, PaaS);
   - check `docker`, `az` and `gcloud` availability;
   - never ask the user to paste a secret into the chat; secrets go to the host's secret store or to the `.env` file the user edits.
2. **Install**: write `compose.yaml`, `Caddyfile` and `.env` (with `SECRET_KEY` generated on the host, `openssl rand -base64 48`), run `docker compose up -d`, wait for `/readyz`, read the setup URL from the logs.
3. **Wire the workspace**, as scripted recipes with the exact CLI commands, each followed by a verification step through `POST /api/settings/test/...` with a PAT:
   - **Microsoft**: `az ad app create` with redirect URI `${PUBLIC_URL}/auth/callback/microsoft`, optional app roles `Ochre.Admin` and `Ochre.Recruiter`, a client secret with a 12-month expiry (calendar reminder), application permissions `Mail.ReadWrite` and `Mail.Send`, admin consent, then **Exchange RBAC for Applications** limiting those to the recruitment mailbox (`New-ManagementScope` + `New-ManagementRoleAssignment`), then the optional SCIM provisioning configuration.
   - **Google**: an OAuth client (Internal) with redirect URI, a service account plus domain-wide delegation limited to the Gmail scopes, impersonating the recruitment mailbox.
   - **Standard**: the Keycloak, Authentik or Okta client settings, and SMTP/IMAP with app passwords.
4. **AI**: add providers and keys through `PUT /api/secrets/...`, then run `ochre llm test` and `ochre llm eval`.
5. **IAM operations** through PAT, MCP or CLI: invite, set role, grant membership, deactivate. Always state what the change does and confirm destructive steps with the user.
6. **Upgrade**: read the release notes, back up, pull, restart, check `/readyz`.
7. **Clean up**: revoke the PAT the agent used when the session ends, unless the user wants to keep it.

## 7. Security checklist (the build must pass all of these)
- **CSRF**: header token for cookie sessions. **CORS**: same-origin only.
- **Headers**:
  - app: `Content-Security-Policy: default-src 'self'; img-src 'self' data: blob: <s3>; frame-ancestors 'none'; object-src 'none'`;
  - careers: CSP that allows the captcha origin only;
  - everywhere: HSTS (when https), `X-Content-Type-Options`, `Referrer-Policy: strict-origin-when-cross-origin`.
- **Uploads**:
  - size is checked while streaming;
  - type is sniffed from bytes;
  - storage keys are random;
  - original names are never used as paths;
  - signed links last 5 minutes;
  - served with `Content-Disposition` and `nosniff` from a CSP `sandbox` response.
- **Inbound email HTML** is sanitised before display. Images are proxied or blocked by default ("Show images" per message).
- **SSRF**: user-configurable URLs (OIDC issuer, LLM `base_url`, S3 endpoint, Gotenberg) are fetched only by the server.
  - Private network ranges are refused unless `allow_private_network: true` is set on that integration. It is needed for local Ollama and Keycloak, and the UI explains it.
  - Booking and meeting URLs are only rendered as links, never fetched.
- **Authorization**: the policy matrix test (§8) covers every route × persona.
- **Secrets**:
  - AES-GCM at rest;
  - never returned by the API;
  - fingerprints only in logs and audit;
  - the `.env.example` contains names and comments, never values;
  - gitleaks runs in CI.
- **Dependencies**: `uv` and `pnpm` lockfiles; `pip-audit` and `pnpm audit` in CI; Renovate weekly.
- **Prompt injection**: untrusted text goes only in user messages (05 §2.3); grounding validators; no tool use by models; the model never triggers side effects.

## 8. Testing and quality gates

| Layer | What | Tooling |
|---|---|---|
| Unit | pure functions: candidate resolution, LinkedIn normalisation, keyword matching, CV choice, `decide()`, `quote_found`, scorecard weighting, cron windows, template validation | pytest, `inline-snapshot` |
| Service | every service function against a **real Postgres**, in a transaction rolled back per test: state changes plus **the Event emitted** | pytest-asyncio, CI Postgres service / `testcontainers` locally |
| Policy matrix | `tests/policy/matrix.py`: for every route, 8 personas (anonymous, member without reach, viewer, interviewer member, assignment-only, hiring_manager, recruiter, admin) × open/closed position → the expected status; plus a blind-redaction check on every response that can carry a Scorecard | parametrised pytest (generated from the router plus a table) |
| Schema drift | the Alembic head equals the models (`alembic check`); a migration round trip | CI |
| AI | validators and decisions with `FunctionModel`; no network in tests (respx blocks everything) | pydantic-ai test models |
| Transports | SMTP against `aiosmtpd`; IMAP against a GreenMail container; Graph and Gmail against `respx` fixtures recorded from the documentation's examples | pytest |
| API contract | the OpenAPI snapshot is committed; the generated TS client is checked fresh | CI |
| Web unit | components and hooks: optimistic move and rollback, filters ↔ URL | vitest |
| End to end | journeys W0 (setup with `solo`), W1, W3, W5, W6, W7, W9, W11, W16, using `log` mail and a fake OIDC provider (a tiny test IdP built into the test harness) | Playwright, in CI on every PR |
| Accessibility | axe on every route in E2E (zero serious violations); keyboard-only run of W3 (move a card) | `@axe-core/playwright` |
| Visual | snapshots of 12 key screens × light and dark | Playwright screenshots |

Gates (`make check`, required on every PR):
- `ruff check`, `ruff format --check`, `mypy --strict`;
- `pytest` with **≥ 85% line coverage overall and 100% on `policy.py`, `events.py` and `gdpr/`**;
- `pnpm lint`, `tsc --noEmit`, `vitest`;
- Playwright E2E;
- `pip-audit`, `pnpm audit --prod`, gitleaks;
- licence check: no copyleft runtime dependency (§2).

Performance targets on a 2 vCPU / 4 GB VM with 10k Candidates and 50k Applications:
- board p95 under 250 ms for 300 cards;
- search p95 under 100 ms;
- candidate page p95 under 300 ms;
- careers list TTFB under 100 ms (cached 60 s in process).
