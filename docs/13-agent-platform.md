# 13 — Agent platform: automate everything, decide nothing alone

This document is normative. It adds, **within v1.0** (roadmap M12):
- structured application questions;
- outbound webhooks;
- agent identities;
- the Proposals inbox;
- Autopilot policies;
- MCP v2 with OAuth;
- AI-transparency features.

It also gives the design direction for the v1.x AI features (§9). Its tables belong to the reference schema in the same way as 04's tables.

## 1. The rule that makes full automation safe

Every action belongs to exactly one **action class**. The class decides who can trigger the action and how.

| Class | Examples | Human | Autopilot rule (deterministic) | Agent (LLM-driven, via MCP or built in) |
|---|---|---|---|---|
| **Observe** | read boards, candidates, scorecards (blind rules apply), reports | yes | — | yes, within its scopes |
| **Routine** | add a Note; tag; assign interviewers; send a **template** email (invitation, reminder, question request); move between *non-outcome* Stages; schedule | yes | yes, when the position's policy enables the rule | yes **if** the agent's scopes allow it directly; otherwise a Proposal |
| **Consequential** | reject, withdraw, hire, transfer, reopen; send a **free-text** email to a candidate; create or publish a position; change a Pipeline | yes | **never** | **Proposal only** |
| **Irreversible / administrative** | erase or export a candidate; delete a position; users, roles, settings, secrets, webhooks, agents | yes (admin) | never | **never** (no tool exists) |

Principle 3 ("the human decides; the model reads") is refined, not weakened. Software may *do* routine work on its own, but every consequential decision about a person is confirmed by a human. This keeps Ochre clear of GDPR Art. 22 ("solely automated decisions") and gives deployers the human oversight that the AI Act requires for high-risk recruiting AI. The class of each service function is declared in code (`@action_class(...)`), and the policy matrix test (09 §8) checks it.

## 2. Structured application questions

### Model
```sql
CREATE TABLE position_questions (
  id           uuid PRIMARY KEY,
  position_id  uuid NOT NULL REFERENCES positions(id) ON DELETE CASCADE,
  ord          smallint NOT NULL,
  kind         text NOT NULL CHECK (kind IN ('short_text','long_text','yes_no','single_choice','multi_choice','number','url','file')),
  label        jsonb NOT NULL,                 -- {"en": "...", "fr": "..."}; default locale required
  help         jsonb NOT NULL DEFAULT '{}',
  options      jsonb NOT NULL DEFAULT '[]',    -- choices: [{"value":"eu_work_permit","label":{"en":"…"}}]
  required     boolean NOT NULL DEFAULT false,
  knockout     jsonb,                          -- NULL, or {"accept": ["yes"]} | {"accept": ["a","b"]} | {"min": 3, "max": null}
  sensitive    boolean NOT NULL DEFAULT false, -- hides the answer from blind roles and from webhooks/AI
  UNIQUE (position_id, ord) DEFERRABLE INITIALLY DEFERRED
);
CREATE TABLE application_answers (
  application_id uuid NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  question_id    uuid NOT NULL REFERENCES position_questions(id) ON DELETE CASCADE,
  value          jsonb NOT NULL,               -- 🔒 typed by kind; files: {"file_id": "…"}
  answered_at    timestamptz NOT NULL DEFAULT now(),
  via            text NOT NULL CHECK (via IN ('apply_form','question_request','recruiter')),
  PRIMARY KEY (application_id, question_id)
);
ALTER TABLE applications ADD COLUMN knockout_state text NOT NULL DEFAULT 'none'
  CHECK (knockout_state IN ('none','pending','passed','failed'));   -- 'pending' = questions unanswered
```

### Rules
- **Editing.** Questions are edited in the Position form, under a **Questions** tab: drag to order, per-locale labels, and a "knockout" toggle with the accepted answers. A question can only be added or changed while the Position has no Applications; after that, a new version is needed (v1.x). Until then the editor is read-only with an explanation.
- **Apply Form.** The form renders the questions after the standard fields. Validation follows the question kind, and `required` is enforced.
- **Knockout state.** On submit it becomes `passed` when every knockout question is accepted, `failed` when any is not, and `none` when the Position has no knockout questions.
- **Applications that arrive without answers** (mailbox, manual) start as `pending` when the Position has required or knockout questions. A **question request** (§5 rule `request_answers`) emails the Candidate a magic link, valid 14 days, to `/careers/{locale}/answers/{token}`. That page shows only the questions; it needs no account and no captcha, but it is rate-limited.
- **Knockouts never reject.** `failed` shows a ⚠ badge on the card and a board filter. Autopilot may file **rejection Proposals** for failed knockouts (§5), and a human approves them, usually in bulk.
- **Blind scoring** does not hide answers, except those of questions marked `sensitive` (for example, salary expectations), which are hidden from blind roles.
- **Sensitive answers** are never sent to any AI Task and never put in webhook payloads.

## 3. Agent identities

```sql
CREATE TABLE agents (
  id            uuid PRIMARY KEY,
  name          text NOT NULL UNIQUE,          -- "Morning triage", "Claude (Ada's laptop)"
  description   text,
  owner_id      uuid NOT NULL REFERENCES users(id) ON DELETE RESTRICT,   -- accountable human
  kind          text NOT NULL CHECK (kind IN ('external','builtin')),
  scopes        text[] NOT NULL,               -- see below
  position_ids  uuid[],                        -- NULL = every position the owner can reach
  daily_llm_budget_usd numeric(8,2),           -- builtin agents only
  max_actions_per_hour integer NOT NULL DEFAULT 200,
  enabled       boolean NOT NULL DEFAULT true, -- the kill switch
  created_at    timestamptz NOT NULL DEFAULT now(),
  disabled_at   timestamptz
);
ALTER TABLE access_tokens DROP CONSTRAINT access_tokens_kind_check,
  ADD CONSTRAINT access_tokens_kind_check CHECK (kind IN ('pat','scim','agent','oauth'));
ALTER TABLE access_tokens ADD COLUMN agent_id uuid REFERENCES agents(id) ON DELETE CASCADE;
ALTER TABLE access_tokens ADD CONSTRAINT access_tokens_principal CHECK (
  (kind = 'agent' AND agent_id IS NOT NULL AND user_id IS NULL) OR
  (kind = 'oauth' AND (user_id IS NOT NULL) <> (agent_id IS NOT NULL)) OR
  kind IN ('pat','scim'));
ALTER TABLE events DROP CONSTRAINT events_actor_kind_check,
  ADD CONSTRAINT events_actor_kind_check CHECK (actor_kind IN ('user','system','applicant','ai','agent'));
ALTER TABLE events ADD COLUMN agent_id uuid REFERENCES agents(id) ON DELETE SET NULL;
```

- **Scopes**:
  - `read` (Observe);
  - `routine` (Routine actions applied directly);
  - `propose` (file Proposals for Routine and Consequential actions);
  - `library` (CV Library and Needs Triage);
  - `reports`.
  There is deliberately no scope for the irreversible or administrative class.
- **Effective permission** = the agent's scopes ∩ the owner's current Capability (03 §4) ∩ `position_ids`. If the owner loses access or is deactivated, the agent loses it with them.
- **Blind Scoring** applies to agents too: an agent reads through its owner's `blind` flag. An agent never submits Scorecards; it can only draft them (§9 notetaker).
- **Accountability**:
  - every Event an agent causes has `actor_kind='agent'`, `agent_id`, and `actor_id` = the owner;
  - the timeline shows "✦ Morning triage (for Ada)";
  - rate limits use `max_actions_per_hour`; going over returns 429 and alerts the owner once per hour.
- **Kill switch**: Settings → Agents → **Disable** revokes every token of that agent at once. **Disable all agents** is one admin button.
- **Tokens**: an `external` agent authenticates with an `agent` access token (`ochre_agt_…`) or through OAuth (§6). A `builtin` agent runs in-process (§7).

## 4. Proposals

```sql
CREATE TABLE proposals (
  id             uuid PRIMARY KEY,
  agent_id       uuid REFERENCES agents(id) ON DELETE SET NULL,   -- NULL = autopilot rule
  rule           text,                         -- autopilot rule name when agent_id IS NULL
  kind           text NOT NULL CHECK (kind IN ('move','reject','withdraw','hire','transfer','reopen',
                                               'send_email','assign','create_position','publish_position',
                                               'library_add','intake_assign','tag')),
  position_id    uuid REFERENCES positions(id) ON DELETE CASCADE,
  application_id uuid REFERENCES applications(id) ON DELETE CASCADE,
  candidate_id   uuid REFERENCES candidates(id) ON DELETE CASCADE,
  payload        jsonb NOT NULL,               -- exactly the request body of the matching API call (06)
  rationale      text NOT NULL CHECK (length(rationale) <= 1000),   -- 🔒
  evidence       jsonb NOT NULL DEFAULT '[]',  -- 🔒 [{"source":"cv"|"answers"|"note"|"email"|"scorecard_summary","quote":"…"}]
  base_version   timestamptz NOT NULL,         -- target's updated_at when proposed
  status         text NOT NULL DEFAULT 'pending'
                 CHECK (status IN ('pending','approved','rejected','expired','superseded','failed')),
  decided_by     uuid REFERENCES users(id) ON DELETE SET NULL,
  decided_at     timestamptz,
  decision_note  text,
  edited         boolean NOT NULL DEFAULT false,   -- approver changed the payload
  result         jsonb,                        -- API response or error
  expires_at     timestamptz NOT NULL,         -- default now() + 7 days
  created_at     timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX ON proposals (status, position_id, created_at);
```

- **Filing.**
  - `POST /api/proposals` (scope `propose`) and the MCP tool `propose`.
  - The payload is validated **at filing time** against the target endpoint's schema, so invalid proposals never reach a human.
  - **Evidence quotes are grounded**: each `quote` must be found in the cited source with the same `quote_found` rule as 05 §3.4. Ungrounded evidence returns 422 `evidence_not_found`.
  - At most one pending proposal per (`kind`, `application_id`). Filing a new one supersedes the old.
- **Inbox.**
  - **Proposals** is a sidebar item with a count. Each user sees the proposals on positions where they hold `manage`.
  - Each card shows the agent or rule, the action in plain words ("Reject Ada Lovelace: not a fit, email *Rejection (EN)* tomorrow 9:00"), the rationale, the evidence quotes (with ✓ found), and links to the candidate.
  - Actions: **Approve**, **Edit & approve** (the same dialog as the real action, pre-filled), **Decline** (optional note, which goes back to the agent through MCP and the webhook).
  - Bulk-approve works for a selection of the same kind.
  - Keyboard: `a` approve, `e` edit, `d` decline, `j`/`k` move.
- **Approval.**
  - Approval runs the **same service function** as the UI, with the approver as actor and `via='proposal:<id>'`. The Event records both the agent and the approver.
  - **Staleness**: if the target's `updated_at` ≠ `base_version`, the card shows "Changed since proposed" and approval requires *Edit & approve*.
  - A pending proposal expires after 7 days (`housekeeping`).
- **Learning signal.** Decline rates per agent and per kind are shown in Settings → Agents, so a noisy agent is visible.

## 5. Autopilot (per position)

`positions.autopilot jsonb NOT NULL DEFAULT '{"rules": []}'`. Rules are deterministic, configured by `manage` holders on the Position's **Automation** tab, and run by the system worker (`actor_kind='system'`, `via='autopilot:<rule>'`). This tab replaces and extends v1's single automation switch: `automation_enabled` stays, and it governs Stage Action emails. Rules:

| Rule | Trigger | Action | Class |
|---|---|---|---|
| `request_answers` | Application created with `knockout_state='pending'` | send the *question request* template (new email template kind `question_request`) | Routine |
| `advance_when_qualified` | `knockout_state` becomes `passed` while in `applied` | move to the first `screening` Stage (Stage Actions then send the invitation) | Routine |
| `propose_reject_failed_knockout` | `knockout_state='failed'` | file a `reject` Proposal (reason `not_a_fit`, default rejection template, `next_morning`) | Consequential → Proposal |
| `remind_unbooked` | invitation sent, nothing scheduled after N days (default 4) | send *invitation reminder* (kind `interview_reminder`, now actually used), once | Routine |
| `chase_scorecards` | interview held more than N days ago (default 1) without a Scorecard | notify the interviewer (05 §6.6) and, after N+2 days, their manager-role member | Routine |
| `propose_close_stalled` | active Application stalled more than N days (default 21) | file a `reject` Proposal with reason `no_response` or a `move` Proposal, with the history as evidence | Consequential → Proposal |
| `acknowledge_mailbox_applications` | intake creates an Application | send `application_received` (mailbox applicants get the same receipt as the form) | Routine |

Each rule has parameters, an on/off switch, and a "dry run for 7 days" mode that files `rule` Proposals instead of acting, so the team can see what it would have done. Rules run on the `autopilot.tick` Schedule (`*/5 * * * *`) and on the matching Events (enqueued work).

## 6. MCP v2

- **Transport**: Streamable HTTP at `/mcp` (MCP spec 2025-06-18 or later).
- **Authorization**:
  - **Bearer tokens**: PAT, read-only PAT, or agent token.
  - **OAuth 2.1**, as the MCP authorization spec expects, so hosted assistants (Claude, ChatGPT, Copilot connectors) can connect by URL:
    - Ochre is its own authorization server: `/.well-known/oauth-authorization-server`, plus protected-resource metadata;
    - authorization code + PKCE, Dynamic Client Registration (RFC 7591), refresh tokens;
    - consent screen: "Connect *Claude* to Ochre as **you** / as agent *X*", with scope checkboxes (`read`, `routine`, `propose`, `library`, `reports`);
    - tokens are stored as `access_tokens.kind='oauth'`.
  - An OAuth connection made "as you" acts with the user's Capability, restricted to the scopes granted. It still can't perform consequential actions directly: those always go through `propose`, even for an admin's assistant. A human acts directly in the UI.
- **Tools**: one per API capability, grouped. This is the only list of MCP tools.

| Group | Tools | Scope |
|---|---|---|
| Search and read | `search_candidates`, `get_candidate`, `get_application`, `list_positions`, `get_position`, `get_board`, `get_timeline`, `get_scorecards` (blind-aware), `get_answers`, `list_messages`, `my_interviews`, `list_library`, `list_needs_triage`, `dashboard` | read (library tools: library) |
| Reports | `report(name, params)` over the standard reports (§9.5), `pipeline_stats(position)` | reports |
| Routine | `add_note`, `tag_candidate`, `assign_interviewer`, `send_template(application, template_kind)`, `move_application` (non-outcome Stages only), `request_answers` | routine |
| Proposals | `propose(kind, target, payload, rationale, evidence)`, `list_proposals(status?)`, `get_proposal` | propose |
| Drafting | `draft_email(application, intent)` → `{subject, body_md}` (not sent), `draft_scorecard(assignment, transcript)` (§9.2) | read |
| Admin | `list_users`, `invite_user`, `set_user_role`, `deactivate_user`, `grant_member`, `revoke_member`, `integrations_status`, `llm_test`, `run_work` | **PAT of an admin only**, never agent or OAuth tokens |

- **Resources**:
  - `ochre://positions/{id}` (the position brief: description, requirements, questions, pipeline);
  - `ochre://candidates/{id}` (profile plus CV text, blind-filtered);
  - `ochre://rubric`;
  - `ochre://glossary`, which gives assistants the domain vocabulary.
- **Prompts** (MCP prompts, so assistants offer them as commands):
  - `daily_triage`: walk Needs Triage and new applications, propose actions;
  - `screen(application)`: summarise against requirements with quotes, propose next step;
  - `weekly_report`;
  - `prepare_interview(assignment)`: a briefing for the interviewer with the notes, the CV highlights and questions not yet covered.
- **Webhook bridge**: `list_events(since_cursor)` lets an agent with no public URL poll the same Event stream that webhooks push.

## 7. Built-in agents and the daily run

`builtin` agents are scheduled LLM loops inside Ochre that use the LLM gateway. They act only through the same tools as external agents, with the same scopes and Proposals. v1.0 ships **one**:

- **Morning triage** (`agent.morning_triage`, weekdays 07:30 in the org timezone; off by default; scopes `read`, `propose`, `library`). For each live position it:
  1. summarises new applications against requirements, grounded, as a Note signed by the agent;
  2. files `intake_assign` Proposals for Needs Triage items whose subject or body names a position;
  3. files `move` Proposals for strong matches in `applied`, with evidence quotes;
  4. files a `reject` Proposal only for failed knockouts with `propose_reject_failed_knockout` off (it never invents rejection grounds from CV content).
  It ends with one summary email to the position owners: "4 proposals waiting". Each run's cost is capped by `daily_llm_budget_usd`.

The repository also ships **`skills/ochre-recruiter/SKILL.md`**, a Claude Code / Claude.ai skill for recruiters connected through MCP. It covers:
- running `daily_triage`;
- preparing interview briefings;
- drafting emails;
- explaining a pipeline;
- always filing Proposals for consequential actions;
- the rule to quote evidence, never infer protected characteristics, and never contact a candidate outside Ochre.

## 8. Webhooks

```sql
CREATE TABLE webhooks (
  id          uuid PRIMARY KEY,
  url         text NOT NULL CHECK (url ~ '^https://'),      -- http allowed only with allow_private_network
  description text,
  event_types text[] NOT NULL,              -- exact types or prefixes with '*': {'application.*','proposal.created'}
  include_personal_data boolean NOT NULL DEFAULT false,
  allow_private_network boolean NOT NULL DEFAULT false,
  enabled     boolean NOT NULL DEFAULT true,
  failing_since timestamptz,
  created_by  uuid REFERENCES users(id) ON DELETE SET NULL,
  created_at  timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE webhook_deliveries (            -- kept 30 days
  id           uuid PRIMARY KEY,
  webhook_id   uuid NOT NULL REFERENCES webhooks(id) ON DELETE CASCADE,
  event_id     bigint NOT NULL,              -- events.id (no FK: events may be erased)
  status       text NOT NULL CHECK (status IN ('pending','delivered','failed')),
  attempts     smallint NOT NULL DEFAULT 0,
  next_attempt_at timestamptz,
  response_status smallint,
  error        text,
  created_at   timestamptz NOT NULL DEFAULT now(),
  UNIQUE (webhook_id, event_id)
);
```

- **Configuration**: admin only, in Settings → Webhooks. The signing secret goes in `secrets` (`webhook.<id>.secret`) and is shown once.
- **Delivery**: one delivery row per (webhook, matching Event), created in the Event's transaction, and dispatched by the `webhooks.dispatch` Schedule (every minute, plus a nudge).
  - Body: `{"id": <event id>, "type": "...", "occurred_at": "...", "actor": {"kind","id","agent_id"}, "subject": {"position_id","candidate_id","application_id"}, "data": {...}}`.
  - Personal data (names, emails, CV text, message bodies, answers) is included **only** when `include_personal_data`, and never for `sensitive` answers or blind-redacted payloads.
  - Header `Ochre-Signature: t=<unix>,v1=<hex HMAC-SHA256(secret, "<t>.<body>")>`, plus `Ochre-Event-Id` for idempotency.
  - Retries at 1 min, 5 min, 30 min, 2 h, 6 h, 12 h, 24 h.
  - After 3 days of failures, the webhook is disabled and admins are alerted.
  - *Redeliver* and *Send test event* buttons; the delivery log shows the last 30 days.
- **New Events** for this doc:
  - `proposal.created`, `proposal.approved`, `proposal.declined`, `proposal.expired`;
  - `agent.created`, `agent.disabled`;
  - `webhook.created`, `webhook.disabled`;
  - `application.answers_received`;
  - `application.knockout_evaluated`.

## 9. v1.x AI features (direction; each becomes a milestone with its own spec section before it is built)

1. **Scheduling with free/busy.**
   - With Graph or Google calendar access (the same app registration as mail, plus `Calendars.Read`, or Google `calendar.readonly` scoped to the interviewers), Ochre generates its own slot links per Assignment: panel-aware, honouring working hours, buffers and the candidate's timezone.
   - It creates the event with a Teams, Meet or plain link.
   - The personal booking links of v1 remain the fallback.
2. **Notetaker without a bot.**
   - Ingest a transcript: Graph online-meeting transcripts, Google Meet transcripts, Zoom cloud recordings, or an uploaded `.vtt`/`.txt`.
   - `draft_scorecard` returns per-criterion suggestions, each with a quote and timestamp. The interviewer edits and submits.
   - Drafts are invisible to anyone else, so blind scoring holds.
   - Transcripts are personal data with their own retention (default 90 days).
3. **Job kickoff.** Paste or dictate intake notes. The output is a draft Position (description, requirements, questions with suggested knockouts, a scorecard template from the library, a pipeline), all editable. It writes nothing until saved.
4. **Rediscovery.**
   - Embeddings (gateway `embeddings` route; pgvector, PostgreSQL licence) on `cv_text` and requirements.
   - On publish, *Suggested from your CV Library* lists up to 20 people. Each comes with grounded reasons (quotes) and **no numeric score**, plus *Move to position* or *Dismiss*.
   - Opt-in per instance, with an AI-register entry, because ranking is high-risk under the AI Act.
5. **Reports.**
   - Standard reports: time to hire, time in stage, source effectiveness, funnel conversion per stage, offer acceptance, interviewer load, proposals approval rate.
   - CSV export.
   - Read-only SQL views (`reporting.*`) for BI tools.
   - Chart Q&A happens in the user's own assistant through MCP `report()`, not inside Ochre.
6. **Offers.** Offer templates (Markdown → PDF), an approval chain, and e-signature adapters (Docuseal self-hosted first, then Yousign and DocuSign). `offer.signed` triggers the HRIS handoff webhook.
7. **Candidate status page and NPS**: a magic-link page "Where is my application?" (stage group only: received, in review, interviewing, decision), plus a one-question NPS after the outcome.
8. **Distribution**: Indeed XML and LinkedIn Limited Listings XML feeds, a referral form for employees, and Slack/Teams notification adapters.

## 10. AI transparency and the deployer toolkit (v1.0)

- **AI register** (Settings → AI → Register, also public at `/careers/ai` when enabled): generated from configuration. For each AI Task, built-in agent and connected external agent, it gives:
  - purpose;
  - inputs sent (with "never sent: name, contact, sensitive answers");
  - model and provider;
  - where a human decides;
  - log retention.
  Each entry carries a version and a date.
- **Candidate notice**:
  - the careers form and privacy page show a short localised notice: "We use AI to read applications and suggest next steps. A person makes every decision about you. You can ask for a human review: <contact>";
  - the text comes from `settings.careers` and is versioned with consent.
- **Per-candidate AI log**: a candidate-page section for Rc and admins, also included in the export. It lists every AI Task run on them (`llm_calls` with task and model), every First Read, and every agent Proposal with its decision.
- **Oversight metrics** (Settings → AI): Proposals approved, edited and declined per agent and per kind; knockout fail rates per question; stage pass-through rates for applications with and without AI-assisted steps. Ochre collects no protected attributes, so no demographic analysis is possible or attempted.
- **No dark automation**: every automated email footer to a candidate says it was sent automatically and names the contact address.
