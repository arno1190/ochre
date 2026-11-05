# 11 — Roadmap (the build agent's checklist)

Milestones are built **in order**: M0–M13 make v1.0, and M14–M20 follow. A milestone is done when every acceptance criterion passes in CI and `progress.txt` records it. Each criterion is a test, or a scripted check, that the agent writes **before** the implementation (TDD).

## Definition of done (every milestone)
- `make check` is green: lint, types, unit/service/policy tests, coverage gates (09 §8), web lint, type check and tests.
- New routes are in the policy matrix. New mutations emit their declared Event, and a test asserts it.
- New UI follows 08: tokens only, both themes, keyboard reachable, axe clean, copy per 08 §8, strings in i18n files (en and fr).
- The relevant docs here are updated **in the same commit** if behaviour diverged from the spec. A divergence needs a one-paragraph ADR in `docs/adr/` explaining why.
- No TODOs left in the code. Instead, open an issue in `docs/backlog.md` with a link.

---

### M0. Skeleton
**Build**: repo layout (09 §3); `uv` and `pnpm` workspaces; Dockerfile; compose for dev; CI (GitHub Actions); `create_app` with `/healthz` and `/readyz`; the first migration with the extensions and the `immutable_unaccent` function; settings and secrets (AES-GCM) with the typed registry; `events.emit`; problem+json errors; the background-work runner with a no-op Schedule; web shell (router, query client, generated client pipeline, Tailwind v4 tokens from 08 §7, fonts, theme switch, i18n setup, sidebar frame, ⌘K stub).
**Accept**:
- `docker compose up` serves `/healthz` 200 within 20 s on a clean machine.
- `alembic check` passes.
- The schema drift test runs.
- A secret round-trips encrypted. The API never returns it; the fingerprint matches `sha256[:8]`.
- Two workers running the same Schedule produce one run (an advisory-lock test).
- The web shell renders in light and dark with axe clean.

### M1. Identity
**Build**: users, identities, sessions, CSRF, local accounts (argon2id, invite, reset, rate limits), the setup token and wizard steps 1, 2 (`solo` and `standard`) and 6; OIDC with PKCE and JWKS for the generic, `microsoft` and `google` presets (tenant and `hd` checks); JIT and allowed domains; group → role mapping; PATs; `/api/me`; Settings → Users and Sign-in; `ochre setup-link` and `ochre users`.
**Accept**:
- An E2E test with the fake IdP covers: sign-in; a wrong `tid` or `hd` is refused with the right error code; a `nonce` mismatch is refused; a mapped group gives `recruiter` and the role shows as managed.
- Logout-all kills the other sessions.
- Deactivating a user kills their sessions.
- The last admin cannot be demoted or deactivated.
- A read-only PAT gets 403 on every non-GET route (generated test over the router).

### M2. Positions, pipeline, members
**Build**: positions, translations, stages with kinds and actions (stored but not executed yet), default interviewers, members, the Default Pipeline setting, the policy module with the full capability resolution, lists filtered by reach; screens for positions, pipeline, team and the position form.
**Accept**:
- Policy matrix for all position routes.
- The creator becomes owner.
- Last-owner guard.
- Exactly one `applied` Stage (DB index plus API error).
- A Stage that holds Applications cannot be deleted (`stage_not_empty` with counts).
- The status machine, including reopen (admin only).
- Re-publish keeps automation.

### M3. Candidates, applications, board, candidate page
**Build**: files (local and S3) with signed links; candidates with `resolve()`; applications with rank ordering, move, outcome, reopen and transfer; manual add (without AI: the upload stores the file, and `parsed` is `null` with a regex fallback); notes; timeline; board with dnd-kit, optimistic moves, filters in the URL and select mode with bulk move; candidate page with every tab except Emails and Scorecards; CV viewer (pdf.js); search.
**Accept**:
- `resolve()` table tests (all identity rules, 04 §5).
- Adding an existing candidate never overwrites their CV.
- The partial unique index blocks a second active Application.
- Moving an Application that has an Outcome returns 409.
- Every mutation emits its Event.
- Keyboard-only E2E moves a card across three Stages.
- An optimistic move rolls back on a 500.
- Previous/next and auto-advance work.
- Board p95 under 250 ms for 300 cards (a seeded perf test).

### M4. Assessment
**Build**: assignments; scorecard templates with locking; scorecards (draft and submit, weighted mean); blind redaction in serializers and Events; My interviews; template builder.
**Accept**:
- The blind matrix: interviewer, viewer and assignment-only users see redacted data in the scorecard list, the summary, the timeline, the dashboard and search, **until** they submit a complete Scorecard; an empty submission returns 422.
- Weighted mean golden tests.
- Editing a locked template's structure returns 409.
- The assignee may set their own time and meeting link, and nothing else.

### M5. Mail and templates
**Build**: the outbox and `mail.dispatch` (crash-safety); transports `log`, `smtp`, `graph`, `gmail`; Settings → Mail with tests; the template engine (sandboxed Jinja + Markdown) with validation, preview and test-to-self; seed templates in en and fr; Stage Actions execution; the composer with threaded replies; bulk invitations with preview; reject (single and bulk, delayed send, cancel); `MAIL_REDIRECT_TO`.
**Accept**:
- A `sending` row older than 10 min becomes `failed: uncertain` and is never resent automatically.
- SMTP threading headers are correct (aiosmtpd).
- Graph `createReply` path, and the fallback on 404 (respx).
- A template using an unknown variable is rejected at save, with its line number.
- `{% if %}` works.
- Already-sent detection survives template deletion.
- Stage Actions follow 05 §6.5, including "a pending screener is never in an interview invite".
- A delayed rejection can be cancelled until it is sent.

### M6. Careers site and Apply Form
**Build**: public API; server-rendered pages (list, position, spontaneous, privacy, thanks) with theme settings; locales and fallback; JSON-LD; sitemap; feed; the form (progressive enhancement); captcha adapters (turnstile, hcaptcha, recaptcha_v3, none); in-app rate limits; submission handling (05 §5.1); receipt; consent versioning; the Settings → Careers editor with preview.
**Accept**:
- Every rejection path of 05 §5.1 has a test, plus the rate limits.
- A known address never modifies the Candidate.
- The receipt never echoes input and is throttled per address per day.
- The form works with JS disabled (Playwright, `javaScriptEnabled: false`).
- Lighthouse on mobile: accessibility 100 and performance ≥ 95.
- A closed position returns 410 with alternatives.

### M7. LLM gateway and CV parsing
**Build**: providers, key pools, routes, budgets, `llm_calls`; Settings → AI with test and usage; `cv_parse` with grounding and fallback; enrichment of manual uploads and Apply Form submissions; the "Read from CV" UI; `ochre llm test|eval`.
**Accept**:
- A 429 on key 1 rotates to key 2; a cooled key is skipped; a 401 disables the key and alerts once.
- Route fallback after 2 transient errors.
- An over-budget provider is skipped.
- Every grounding rule has a failing-output test (hallucinated email, unseen phone, fake LinkedIn, ungrounded skills).
- An injection fixture does not change the output.
- With AI off, manual add and the Apply Form still work.

### M8. Intake and CV Library
**Build**: readers (`graph`, `gmail`, `imap`); `intake.poll` with copy-first idempotency and checkpoints; the decision tree (05 §4.2); CV choice; `job_match` plus keyword fallback; automatic retries; reply threading; Needs Triage UI (retry, assign, to library, dismiss; no Candidate exists before resolution); CV Library (search, tags, drawer, move).
**Accept**:
- Each decision-tree row has a test.
- Running the poll twice imports nothing twice. Two concurrent polls produce one run.
- A transient `llm_error` is retried at +15 min, then left in triage.
- A reply to an outbound message lands in the candidate's thread.
- A re-application by email turns the old CV into `previous_cv`.
- A LinkedIn slug collision on intake creates the Candidate without the slug and flags `possible_duplicate`.
- GreenMail E2E: send a mail with a PDF and see the candidate appear.

### M9. Dashboard and notifications
**Build**: the dashboard endpoint and UI (05 §7); `first_response_at`; Upcoming; Home; notifications (mentions, assignments, overdue scorecard, daily summary, admin alerts).
**Accept**:
- A golden dataset with fixed clock gives exact metric values for each needs-attention group and the funnel.
- No verdict appears in the activity feed for any persona.
- A mention emails the mentioned member once.

### M10. First Read and digest
**Build**: the rubric settings and editor; `first_read` with the validator and `decide()`; storing `first_reads`; on-demand assessment; `digest.weekly` with test mode and preview; verdict chips in the library (Rc only).
**Accept**:
- `decide()` table tests cover every branch of 05 §3.4 (standout, worth a look, pass, competitor lift, position credit threshold).
- The DST week-window test.
- Verdicts are reused across runs.
- A week is never sent twice without `force`.
- Test mode stores nothing.
- The model input never contains name, email, phone or LinkedIn (asserted on the captured request).

### M11. GDPR, SCIM, MCP, CLI, operator skill
**Build**: retention (report and purge modes); export zip; erasure through every 🔒 column (a test walks the schema for every table that has a `candidate_id` FK and asserts zero rows remain); SCIM Users and Groups; MCP server with the tools in 06; the full CLI; `skills/ochre-operator/SKILL.md`; the Background work, Audit and Outbox admin screens.
**Accept**:
- The erasure test passes: no row in any table references the Candidate or contains their email (a full-text scan of every text and jsonb column for the email in the test DB). Files are collected by `files.gc`.
- The purge sends its report 7 days before acting.
- The SCIM test suite (Entra checklist cases) passes.
- A read-only PAT on MCP cannot call a write tool.
- The operator skill dry-run: a fresh agent session following only the skill gets a `solo` instance to `/readyz` and creates the first admin in CI (scripted with `claude -p` in a nightly job, optional).

### M12. Agent platform
**Build**: everything in 13 §1–§8 and §10:
- action classes declared on every service function;
- position questions and the answers page;
- knockout state;
- agents with tokens and the kill switch;
- Proposals with the inbox UI;
- Autopilot rules with dry-run;
- MCP v2 tools, resources and prompts, plus the OAuth 2.1 authorization server with DCR;
- webhooks with signing and retries;
- `agent.morning_triage`;
- `skills/ochre-recruiter/SKILL.md`;
- the AI register, candidate notice and per-candidate AI log.
**Accept**:
- An agent token can never call a Consequential service directly. A generated test over every service function's action class and every MCP tool checks this.
- An admin's OAuth connection still has to `propose` a rejection.
- Disabling an agent makes its next call return 401 within 1 s.
- An agent's effective permission is lost when its owner is deactivated.
- A proposal with an ungrounded quote returns 422.
- Approving a stale proposal without editing it returns 409.
- An approved proposal writes one Event naming both the agent and the approver.
- A failed knockout never changes `outcome`, and with `propose_reject_failed_knockout` on, it yields exactly one pending Proposal.
- `advance_when_qualified` moves the application and the Stage Action sends the invitation.
- A rule's dry-run files proposals and acts on nothing.
- MCP: Claude Desktop and MCP Inspector both connect through OAuth with DCR (scripted with the Inspector CLI in CI). `get_scorecards` through MCP stays blind for a blind owner.
- Webhooks: the signature verifies with the documented algorithm; a delivery is retried on 500; the webhook is disabled after 3 days of failures; with `include_personal_data=false` a payload contains no email, name or answer (scan test).
- Sensitive answers never appear in any `llm_calls`-captured request.
- The AI register lists every enabled AI Task and agent.

### M13. Hardening and 1.0
**Build**: perf tuning to the 09 §8 targets on the seeded 10k/50k dataset; visual snapshots; the security checklist (09 §7) as tests where possible; a docs site (MkDocs Material) built from `docs/` plus operator guides for each profile; demo seed; release workflow (multi-arch, SBOM, cosign); `CHANGELOG.md`; licence headers.
**Accept**:
- Every 09 §8 target is met in CI on the reference runner.
- A ZAP baseline scan has no high findings.
- Fresh install → first position published → applicant applies → candidate reaches hired, in a single recorded E2E run.
- Tag `v1.0.0`.

---

## After 1.0: AI features (milestones, built in order once M13 is done)

Each starts by writing its spec section (turning 13 §9's direction into tables, endpoints and acceptance criteria) in the same style as M0–M13, and committing it before any code.

- **M14 Scheduling with free/busy** (13 §9.1)
- **M15 Transcript to scorecard draft** (13 §9.2)
- **M16 Job kickoff** (13 §9.3)
- **M17 Reports and reporting views** (13 §9.5)
- **M18 Rediscovery with pgvector** (13 §9.4)
- **M19 Offers and e-signature** (13 §9.6)
- **M20 Candidate status page, NPS, distribution feeds, Slack/Teams** (13 §9.7–§9.8)

## v1.x backlog (do not start before 1.0)
- Calendar adapters: Cal.com and Calendly webhooks, MS Bookings poll (v0's sync logic: match by staff = interviewer and customer = candidate email; follow a linked appointment; reset when a future appointment disappears).
- OCR for scanned CVs (Tesseract).
- Google Directory poll for group → role mapping.
- TOTP for local accounts.
- Inbound mail webhooks (Postmark, Mailgun).
- Share-target / PWA "share a CV into Ochre".
- Kubernetes manifests and a Helm chart.
- `ochre backup`.
- Additional UI locales (de, es, it) through community translation.
