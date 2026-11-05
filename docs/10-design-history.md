# 10 — Design history: from v0 to Ochre

**v0** is the private prototype this specification was extracted from on 2026-11-05. Its recruitment module was in daily production use through 2026. Throughout the spec, **[Proven]** marks behaviour carried over from v0 unchanged, and **[New]** marks a deliberate change. This file records what Ochre **keeps**, **changes** and **drops**, so that the build agent knows which behaviour has been proven in production and which is new.

## Kept: proven in production, rebuild as specified

1. **Domain model.**
   - The Candidate exists independently of any position.
   - An Application is one Candidate in one Pipeline.
   - The CV Library holds spontaneous and set-aside people.
   - An Interviewer Assignment *is* the "interview".
   - Scorecard templates have sections and criteria.
2. **Per-position access**: Job Roles `owner`, `hiring_manager`, `screener` (manage) and `interviewer`, `viewer` (read). A single assignment grants read access to that Application only. A closed position is read-only for everyone (proven in v0).
3. **Blind scoring** for interviewers and viewers until they submit their own Scorecard. The activity feed never shows a verdict.
4. **Candidate identity rules**:
   - email or LinkedIn, at least one;
   - LinkedIn normalised to the profile slug;
   - LinkedIn matching only for recruiter-typed data;
   - the Apply Form never modifies a Candidate it did not create (proven in v0).
5. **Intake**:
   - an idempotency key per message;
   - the reason taxonomy;
   - spontaneous applications are a success, not triage (proven in v0);
   - CV versus cover-letter choice by filename;
   - names derived from the email address;
   - `job_match` sees subject and body but never the CV ("with it, the model matched on skills").
6. **AI grounding**:
   - every extracted fact must appear in the CV;
   - every "requirement met" needs a verbatim quote, checked by code;
   - the First Read verdict is computed by code from rubric scores, not chosen by the model;
   - the model never receives the applicant's name or contact details;
   - untrusted text goes only in the user message.
7. **Apply Form hardening**:
   - honeypot;
   - captcha that fails closed;
   - byte sniffing and a DOCX zip-bomb guard;
   - per-email cap returning a silent 202;
   - versioned consent;
   - no model call inside the request;
   - the receipt is throttled per address and never echoes what the visitor typed;
   - the file is read into memory at pick time;
   - fall back to a spontaneous application when the position closes while the form is being filled in.
8. **UX patterns**:
   - previous/next within a stage, with auto-advance after a move;
   - a Notes callout above the tabs;
   - days-in-stage urgency;
   - the "›" quick move;
   - preview → confirm → per-row results for every bulk action;
   - compose → review → send for candidate email, sent as a reply in the original thread;
   - destructive dialogs that list what is lost and offer the safer alternative;
   - short-lived signed file links;
   - ⌘K search with one row per Application;
   - the "Needs attention" dashboard with v0's thresholds (3, 5, 1/60 and 14 days).
9. **Weekly spontaneous digest**: the window maths, verdicts reused and committed before sending, idempotent per week, a test mode, and mail-client-safe HTML.

## Changed: same intent, better execution

| Area | v0 | Ochre | Reason |
|---|---|---|---|
| Identity | Entra only. Login restricted to `firstname.lastname@<domain>`. Users mirrored from Entra; profile written back to Entra | OIDC presets, local accounts, domain allowlist, JIT/invite/SCIM, optional group → role mapping | Open-source portability |
| OAuth | no state, nonce or PKCE; ID token not validated; stateless 12 h JWT | state, nonce, PKCE, JWKS validation, DB sessions with revocation | Security |
| First admin | inserted in SQL | setup URL printed in the log, wizard | Self-hosting |
| Global scopes | 11 scopes, 3 "managed" by Entra for other modules | 3 Global Roles; managed only through IdP mapping or SCIM | Lean |
| Hire | `recruitment:admin` only | `manage` on the position | Hiring is routine; erasure is the irreversible act |
| Stages | 7 fixed Stages; behaviour keyed on English names; no stage API | editable Pipeline, Stage kinds, Stage Actions, a Default Pipeline | Renaming and translating must not break automation |
| Hired/Rejected | terminal *Stages* plus a status, which could diverge (dragging into "Hired" did not hire) | the Outcome is separate from Stages; outcome lanes on the board | One source of truth |
| Job creator | not made owner, so a position could have zero owners | the creator becomes owner | Fixes an orphaned-permission gap |
| Screener and hiring manager | columns on the position, duplicating member roles, not kept in sync | member roles, plus one `default_screener_id` validated as eligible | One source of truth |
| Re-publish | reset automation to off | keeps the setting | Bug |
| Close | irreversible, with no confirmation | confirmation; `admin` can reopen | Mistakes happen |
| History | 10 event types declared, 4 written; dashboard rebuilt events from `updated_at` | one `events` table written for every mutation, in the same transaction, enforced by a test | Trustworthy timeline and audit |
| Notes | two overwritable text fields | a thread of signed, dated Notes with mentions | Collaboration |
| Scorecards | section weights ignored; recommendation free text; any number per user; an empty submission lifted blindness; managers could overwrite someone else's | weighted mean; enum recommendation; one per user per Application; full submission required; only the author edits, for 24 h | Correctness |
| Blind leaks | the history endpoint exposed ratings and recommendations; `/stats` showed per-evaluator averages; "all interviews" listed every interview on a position to anyone with a single assignment | redaction in serializers; one reach policy; a matrix test | Fixes leaks |
| Transfer | moved the same row, carrying scorecards and notes to another position, and wrote no history | withdraws the old Application and creates a new one; an Event on both | Scorecards belong to the position they were made for |
| Adding an existing candidate | silently overwrote their CV and parsed data, even from positions the user didn't manage | shows the match and links; the new CV becomes an attachment | Data safety |
| Mailbox re-application | overwrote `cv_url`, leaving the old file orphaned | the old CV becomes an attachment `previous_cv` | Keep history |
| Intake retries | relied on the message staying unread; "lost message" detector | the message is copied to the DB first, the mailbox mark is cosmetic, automatic retries with backoff | Robustness |
| Replies without a CV | left unread, re-skipped every 4 h | threaded to the Candidate when possible, else Needs Triage | Visibility |
| Templates | regex `{{var}}`; `{% if %}` sent literally; unknown variables sent literally; `variables[]` unused; raw HTML body; test send to any address | sandboxed Jinja + Markdown, validated on save; per locale; one default per kind and locale (DB index); test to self only | Correctness and safety |
| Email sending | Graph only, inside requests; the no-template fallback sent from the interviewer's own mailbox | outbox with retries and crash-safety; Graph, Gmail, SMTP or log; `Reply-To` instead of sending from another mailbox | Portability and reliability |
| Interview auto-email | included pending assignments of any role (a pending screener landed in a 1st-round invite) | interviewers only | Bug |
| Bulk reject email | context not HTML-escaped; any template kind accepted | escaped by design (Markdown); `rejection` kind only; optional delay | Bug and kindness |
| Reject on the candidate page | only from board selection mode | a header button, the `r` key, or a drop on the lane | UX |
| `/recruitment/interviews` | "All interviews", linked as "my interviews", not in the navigation | a real **My interviews** page in the navigation | UX |
| CV Library detail | no detail view, only "View CV" | candidate drawer and page | UX |
| Triage link | `?candidate=` ignored by the page | works | Bug |
| Email preview | never loaded (dialog opened programmatically); "insert variable" lost focus | live preview; insertion at the cursor | Bugs |
| Evaluation form | race that reset scores when the template changed | a draft upserted on the server, so no race | Bug |
| Data fetching | `useEffect` everywhere, full-board refetch per move, home summary N+1 | TanStack Query, optimistic moves, a dashboard endpoint | Performance |
| Drag and drop | native HTML5: no touch, no keyboard, no reordering | dnd-kit, accessible, ordering persisted | Accessibility |
| URL state | filters and tabs lost on reload | in the URL | Shareable views |
| Confirmations | a mix of `confirm()`, AlertDialog and none | one Dialog pattern; every destructive act confirms | Consistency |
| Silent failures | many handlers only `console.error` | every mutation shows a toast on error, with rollback | UX |
| Dark mode | partial; light-only classes | tokens only; raw palette colours banned by lint | Quality |
| Fonts | Inter loaded but unused | self-hosted Instrument Sans / Serif | Fix and identity |
| Salary | `$` hard-coded, stored in cents | currency and period, optional public display | i18n |
| Languages | EN app; EN+FR careers; French copy as `*_fr` columns | i18n framework; any number of careers locales; a translation table | Portability |
| Careers site | a copy of one company's website chrome; rate limiting left to the reverse proxy | themeable server-rendered pages; in-app rate limit; JSON-LD; works without JS | Portability, SEO |
| Retention | promised in the privacy notice, not implemented | a purge job with dry-run reports | Compliance |
| PII in intake logs | sender and subject kept after erasure, ids with no FK | FKs plus erasure through `messages` | Compliance |
| Search | 5 fields, members only, orphans invisible | trigram on 6 fields plus tags; recruiters see all Candidates | Usability |
| Positions without an applied stage | silently fell back to a spontaneous application | impossible: exactly one `applied` Stage, enforced by an index | Correctness |

## Dropped (not in Ochre)

- Every non-recruitment v0 module (surveys, 360 feedback, growth plans, peer praise, gallery, gamification) and the user fields they needed: manager, direct reports, birthday, balance.
- Write-back of profile changes to Entra.
- Microsoft Bookings polling as a core feature. It becomes a v1.x calendar adapter; Scheduling Links cover v1.
- Teams-specific fields. `meeting_url` is generic.
- The external workflow orchestrator (Prefect) and everything around it.
- The private shared library and its OpenRouter-only client.
- Data-fix migrations, and templates seeded by migration (seeds are code).
- Login-page decoration generated at build time (an LLM quote and an Unsplash image).
- Hard-coded company strings: company name, office address, email-domain rules, competitor list, a sector-specific rubric. All of these become settings.

## v0 numbers worth knowing (for defaults)

| Number | Value |
|---|---|
| Max CV size | 10 MB |
| CV formats | PDF and DOCX |
| CV text sent to `cv_parse` | 8,000 characters |
| Mail body sent to `job_match` | 800 characters (cover letter 800) |
| Messages per poll | 50; Ochre uses 200 because it reads only metadata first |
| Apply Form | 3 submissions per email per 24 h; receipt at most once per 24 h; message limit 3,000 characters |
| Apply Form enrichment | 20 per run, 3 attempts per submission |
| Dashboard thresholds | 3 / 5 / 1–60 / 14 days |
| Bulk actions | at most 100 items |
| Search | minimum 2 characters, maximum 200; at most 8 results (Ochre: 10) |
| File links | 5-minute signed tickets |
| Session | 12 hours (Ochre: 7 days idle, 30 days absolute, revocable) |
| Model | `google/gemini-2.5-flash` for parse and match. No temperature was set; Ochre uses 0 |
