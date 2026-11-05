# 00 — Product

## One sentence

Ochre is a self-hosted recruitment platform that a 5-to-300-person company can run on one small server. It reads applications from the company's mailbox and careers page and puts them in configurable pipelines. A team assesses candidates with blind scorecards, and an AI first reader does the sorting without ever making a decision for the team.

## Who it is for

| Persona | What they need | Global role |
|---|---|---|
| **Talent lead / HR** | Runs every pipeline, owns templates, the CV Library and the intake | `admin` or `recruiter` |
| **Hiring manager** | Owns one or a few Job Positions: moves candidates, emails them, rejects them | Job member `owner` / `hiring_manager` |
| **Screener** | Makes first contact; their booking link goes out in the screening invitation | Job member `screener` |
| **Interviewer** | Reads the notes and the CV, then fills in a scorecard without seeing peers' scores first | Job member `interviewer`, or holder of one Interviewer Assignment |
| **Observer** | Follows a pipeline read-only (a founder, a future teammate) | Job member `viewer` |
| **Applicant** | Applies in two minutes from a phone, in their language, and gets a receipt | none (public) |
| **Operator** | Installs, upgrades and wires the instance to the workspace, often through a Claude agent | `admin` + CLI |

## Principles

These decide every trade-off. When a choice is unclear, apply them in this order.

1. **One box.** A single container image plus Postgres is a complete install. It needs no Redis, no workflow server and no Node at runtime. Every external service (identity provider, mail, model, captcha, calendar, S3) is an optional adapter with a working default or a clean "off" state.
2. **Your workspace, not ours.** People sign in with what the company already uses. Ochre never becomes the identity provider of record unless the operator chooses local accounts.
3. **The human decides; the model reads.** The AI parses, matches and sorts. It never rejects, hires or emails anyone on its own. Every AI output that names a fact must quote it from the source document, otherwise it is discarded.
4. **Blind before biased.** Interviewers score before they see their peers' scores. Nothing in the product leaks a verdict around that rule: not history, not stats, not the dashboard.
5. **Everything leaves a trace.** Every mutation writes one event. The timeline, the dashboard and the audit all read the same event log.
6. **Lean code.** Write fewer concepts, fewer tables and fewer endpoints, but finish each one properly. A feature that cannot be explained in the glossary does not ship.
7. **Candidates are people.** Consent is versioned, retention is enforced by a job (not promised in a privacy notice), and erasure removes every copy, including in logs.

## Scope of v1

- **Jobs:** Job Positions with translations, a configurable pipeline, members and roles, and a status machine: draft → open ⇄ paused; any of them → closed; closed → paused (reopen, admin).
- **Board:** a Kanban board with accessible drag and drop, filters, bulk actions, and days-in-stage urgency.
- **Candidate page:** profile, CV viewer and attachments, a notes thread, a timeline, assignments, scorecards, the email thread, and next/previous navigation within a stage.
- **Intake:** a polled mailbox (Microsoft Graph, Gmail API or IMAP) with AI matching to an open position, and a **Needs Triage** queue.
- **Careers site:** public, themeable and multilingual, with an apply form, versioned consent, a captcha, a honeypot and rate limits.
- **CV Library:** the talent pool, with tags and move-to-job.
- **Scorecards:** templates with weighted sections and blind scoring.
- **Email:** templates (sandboxed Jinja, per locale), automatic stage-entry actions, threaded replies, and a sent and received log per candidate.
- **AI:** CV parsing, job matching, and a weekly spontaneous-applications digest with a configurable rubric. All of it runs through the **LLM gateway**, which supports several providers, several keys per provider, fallback chains and budgets.
- **Identity:** OIDC (with Microsoft Entra, Google, Okta, Keycloak, Authentik and Zitadel presets) and local accounts. Optional group → role mapping. Optional SCIM 2.0 provisioning.
- **Administration:** a first-run wizard, a CLI, personal access tokens, and an MCP endpoint so that a Claude agent can operate the instance.
- **GDPR:** retention purge, export and erasure.
- **⌘K search** and the **recruitment dashboard** ("needs attention", funnel per position).

## Non-goals (v1)

- No other HR modules: no surveys, feedback, reviews or payroll.
- No job-board multiposting (LinkedIn, Indeed) and no sourcing extension. A public JSON feed and a schema.org `JobPosting` are enough for aggregators to pick jobs up.
- No built-in calendar. Interviews are booked through each person's scheduling link. Calendar sync (Cal.com, Calendly, Microsoft Bookings) is a v1.x adapter.
- No offer letters, e-signature or onboarding.
- No multi-tenant SaaS mode. One instance serves one organisation.
- No AI auto-rejection and no AI "score" shown on the candidate card. The AI verdict lives in the weekly digest and the CV Library only.

## Name

**Ochre**: the oldest pigment people ever used, earth dug up and refined into colour. Here, raw applications are refined into a team. The name is short, warm and spelled the same in every language. It gives the design system its theme (08) and the logo its idea: three brush strokes in the three primaries.

- Packages: `ochre-hire` on PyPI (the bare `ochre` name is taken by an unrelated project).
- Image: `ghcr.io/arno1190/ochre`.
- Alternatives considered: Gouache, Hirefold, Madder, Tandem.

## The workspace question: "is there really another one?"

For identity, mail and calendars together, two suites cover the large majority of companies Ochre targets: **Microsoft 365** and **Google Workspace**. The rest of the market is real but small and splits into three families:

1. **All-in-one alternatives**: Zoho Workplace, and in Europe kSuite (Infomaniak), Proton Business and Open-Xchange-based hosts. They offer OIDC or SAML for identity at best, and plain IMAP/SMTP for mail.
2. **Identity-only providers**, used next to any mail host: Okta, JumpCloud, OneLogin, Auth0, Keycloak, Authentik and Zitadel. All of them speak OIDC, and most speak SCIM.
3. **No workspace at all**: a founder with a Fastmail or OVH mailbox, or a team in the evaluation phase.

So Ochre does not need a separate integration per suite. It needs **three adapters per concern**: *Microsoft*, *Google* and a *standard protocol* (OIDC for identity, IMAP/SMTP for mail, a plain link for scheduling). It also needs a **local** mode so that it runs with nothing configured. [03-identity-access.md](03-identity-access.md) defines four setup profiles built from these: `microsoft`, `google`, `standard`, `solo`.

## Open questions (for the maintainer, not for the build agent)

The agent applies these defaults unless they are changed here.

| Question | Default applied |
|---|---|
| Licence | **Decided: MIT** for code and docs. Consequence: no copyleft (GPL/AGPL) dependency may ship in the image (09 §2) |
| Default UI language | English. French also ships complete in v1 (UI, careers site, seed templates) |
| Telemetry | None. No phone-home of any kind |
| Hosted demo | Out of scope for v1 |
