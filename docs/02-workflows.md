# 02 — Workflows

Every journey is written from the user's point of view as numbered steps. **[Proven]** marks behaviour carried over unchanged. **[New]** marks a deliberate change; the reasons are in [10-design-history.md](10-design-history.md). Capabilities are defined in [03-identity-access.md](03-identity-access.md).

---

## W0. First run (operator)

1. The operator starts the container with only `DATABASE_URL`, `SECRET_KEY` and `PUBLIC_URL` set. Migrations run automatically.
2. With no admin yet, the server prints a one-time **setup URL** to the log: `https://<host>/setup?token=…`, valid for 24 hours. `ochre setup-link` prints a fresh one. **[New]** In v0 the first admin had to be inserted in SQL.
3. The wizard asks, one screen at a time. Steps 3.3, 3.4 and 3.5 can be skipped and revisited in Settings; 3.1, 3.2 and 3.6 cannot.
   1. **Organisation**: name, logo, **timezone** (pre-filled from the browser), default locale, careers-site locales, contact email for candidates.
   2. **Sign-in**: pick a profile (`microsoft`, `google`, `standard` OIDC, or `solo` local accounts) and fill in its fields. *Test sign-in* opens the provider in a popup and shows the claims it received.
   3. **Mail**: outbound (Graph, Gmail API, SMTP, or *log only*) and the optional Intake Mailbox (Graph, Gmail API, IMAP). *Send test* and *Read test* report the result inline.
   4. **AI**: add one or more Providers, each with one or more keys, and pick a model per AI Task, or "AI off". *Test* runs a 1-token call per route.
   5. **Careers site**: theme colours (pre-filled with the default palette), hero text, privacy notice, captcha provider or none.
   6. **First admin**: sign in through the chosen provider, or create a local password. That User becomes `admin`, and the setup token is burned.
4. The wizard ends on a checklist: create a Job Position, invite teammates, publish.

## W1. Create and publish a Job Position (admin, recruiter)

1. Recruitment → **New position**.
2. Fill in the form:
   - Title (required), department, location, **remote policy** (`on_site`, `hybrid`, `remote`), employment type (`full_time`, `part_time`, `contract`, `internship`, `apprenticeship`).
   - Optional salary range with currency and period. A *show on careers site* switch, off by default.
   - Description and requirements in Markdown, with a live preview.
   - **[New]** One **Translations** tab per extra careers locale (v0 hard-coded a French copy). An empty translated field falls back to the default locale.
3. **Create**. The Job Position is a **draft**. The Pipeline is copied from the Default Pipeline, and the creator becomes its `owner` **[New: v0 created no owner]**.
4. Optionally open **Pipeline** settings (W2) and **Team** (W12).
5. **Publish** always opens the same dialog, whichever button started it **[New: v0's list menu skipped the dialog]**:
   - **Default Screener**: Screener-eligible users only (03 §4: a screening Scheduling Link, and either recruiter or admin, or a member with owner, hiring_manager or screener role). If nobody qualifies, the dialog explains how to add a link in Settings → Profile.
   - **Automation**: on or off. The dialog lists exactly which emails will go out automatically, read from the Stage Actions (for example "Entering *Screening* sends *Screening invitation*").
6. The Job Position is **open**. It appears on the careers site and becomes a target for Matching.
7. Later, from the header menu:
   - **Pause**: hidden from the careers site and from Matching.
   - **Close**: confirmation required. Every member drops to read-only and active Applications stay as they are.
   - **Reopen** **[New]**: `admin` only. A closed Job Position returns to *paused*.
   - Re-publishing keeps the automation setting that was in force **[New: v0 reset it to off]**.

## W2. Configure the Pipeline (owner, hiring manager, recruiter) [New]

v0 had seven fixed Stages and keyed behaviour on their names. In Ochre the Pipeline is editable:

1. Job Position → **Pipeline** tab: a vertical list of Stages.
2. For each Stage you can:
   - edit its name, kind and colour (from the stage palette, 08-design-system);
   - set its **default interviewers**;
   - set its **Stage Actions**: *assign default interviewers* (all of them, or only when there is exactly one, for screening) and *send template* (picker filtered to the Stage's kind).
3. Add a Stage, delete a Stage (refused while it holds active Applications; the error says how many), or reorder by drag or with ↑/↓ on the focused row.
4. Constraints: exactly one `applied` Stage, always first. At most one `offer` Stage. Outcomes are not Stages.
5. **Save as Default Pipeline** (admin) copies this Pipeline into the Organisation's default.

The seed Default Pipeline matches v0:

| # | Name | Kind | Stage Actions |
|---|---|---|---|
| 0 | Applied | applied | none |
| 1 | Screening | screening | assign default interviewers *if exactly one*; send *screening invitation* |
| 2 | First interview | interview | assign all default interviewers; send *interview invitation* |
| 3 | Second interview | interview | same as above |
| 4 | Offer | offer | none |

## W3. Work the board (members with `manage`)

1. Job Position → **Board**. There is one column per Stage, showing a colour dot, the name and a count ("filtered / total" while filters are on). Three collapsed lanes on the right, **Hired**, **Rejected** and **Withdrawn**, each show its count; expanding a lane lists its Applications.
2. A card shows:
   - initials avatar, name, "title · company";
   - rating stars;
   - icons for CV, email, phone and LinkedIn;
   - a *Notes* pill when Notes exist;
   - a days-in-stage chip: neutral under 7 days, warning from 7, alert from 14. **[Proven]**
3. **Move** a card by:
   - dragging it (mouse, touch or keyboard: Space to lift, arrows to move, Space to drop) **[New: v0 used native drag and drop with no keyboard or touch support]**;
   - clicking the card's "›" to send it to the next Stage **[Proven]**;
   - pressing `]` / `[` on a focused card.
   The move is applied **optimistically** and rolled back with a toast if it fails **[New]**. Reordering within a column is persisted.
4. Dropping on **Rejected** opens the reject dialog (W5). Dropping on **Hired** opens the hire confirmation, and dropping on **Withdrawn** opens the withdraw confirmation.
5. Stage Actions run after the move. A toast reports what happened: "Screening invitation sent to Ada" or "Not sent: no screener on this application. Assign one". Auto-email failures never undo the move.
6. **Filters** (stored in the URL, so a filtered view can be shared): Outcome (`active` by default; `active`, `hired`, `rejected`, `withdrawn`, `all`; any choice other than `active` expands the matching lanes), minimum rating, days in stage over N, applied between two dates, source (mailbox, careers site, manual), tag, and "has unsubmitted scorecards".
7. **Select mode** (`s`, or the *Select* button): checkboxes appear on cards, each column gets a select-all box, and a sticky bar offers **Reject**, **Move to…** **[New]** and **Send template…**.

## W4. Bulk email (manage)

1. Select Applications, then **Send template…**, or with automation off use the header shortcuts *Send screening invitations* and *Send interview invitations* **[Proven]**.
2. The **preview** step lists every recipient with their Stage and the resolved Screener or interviewers:
   - greyed and unchecked if already sent (same template kind, already sent on this Application);
   - shown in red with the reason if it cannot be sent: no email, no Screener, an interviewer without a Scheduling Link.
3. **Send N emails**. The results step shows sent, skipped and failed, with a status per row. **[Proven]**

## W5. Reject (manage)

1. Reject from any of:
   - the candidate page header (**Reject**, also the `r` key) **[New: v0 only rejected in bulk from the board]**;
   - dropping onto the Rejected lane;
   - bulk selection.
2. The dialog:
   - **reason**: chips (*not a fit for the role*, *position filled*, *no response*, *other*) plus free text. A candidate who steps back is **withdrawn**, not rejected;
   - a **Send rejection email** switch, on by default, with a template picker limited to the `rejection` kind and pre-set to the default for the candidate's locale;
   - **Include the reason in the email**: off by default; when on, the free text becomes `rejection.reason_text`;
   - a **delay** **[New]**: *now* or *tomorrow at 9:00* (Organisation timezone), so rejections do not land a minute after an interview.
3. Confirm. The Outcome becomes `rejected`. If the email is due, it is sent at once or queued for later. A queued email can be cancelled from the timeline until it leaves.
4. **Reopen** from the candidate page (manage) puts the Application back, active, in the Stage it left **[New: the route was missing in v0]**. Reopening **cancels any queued rejection email** for that Application. If the Candidate meanwhile holds another active Application on the same Position, reopen fails with `duplicate_active_application`.

## W6. Add a candidate by hand (manage)

1. Board → **Add candidate**.
2. **With a CV** (PDF/DOCX up to 10 MB): drop the file. *Reading CV…* shows while AI parsing runs (synchronously, timeout 30 s, with a regex fallback). A review form follows, pre-filled and editable, with detected skills and education shown read-only.
3. **Without a CV**: an empty form. You can upload a CV later.
4. Validation: first and last name, plus email **or** LinkedIn profile URL.
5. If the email or LinkedIn profile matches an existing Candidate:
   - **You can reach them, or you are Rc**: the dialog names them ("Ada Lovelace is already a candidate (CV Library, added 3 Mar)") and offers **Add them to this position**, which keeps their record (the new CV becomes an attachment and never overwrites their CV), or **Cancel**.
   - **You cannot reach them**: the dialog does not name them. It says "This person is already in Ochre. Ask a recruiter to add them to this position" and offers Cancel only.
   - The email matches one Candidate and the LinkedIn another: `identity_conflict`; fix the input.
   **[New]** v0 silently overwrote the existing candidate's CV and parsed data.
6. **Add**. The Application is created in the `applied` Stage with source `manual`, and an Event is written.

## W7. Candidate page (anyone who can read the Application)

**Header**
- Back to the board.
- **Previous / Next** within the Stage, shown as "3 / 12 in Screening", also with the `k` / `j` keys **[Proven + keys]**. After you move the candidate out, the page jumps automatically to the next candidate in the original Stage ("Gmail-style") **[Proven]**.
- Outcome pill.
- Actions: **Move**, **Reject** / **Reopen**, **Hire**, **Withdraw**, **Transfer** to another Job Position, **Delete candidate** (admin).

**Left column, profile card**
- Name, title · company, email and phone with copy buttons, LinkedIn.
- Rating stars (manage, optimistic update).
- Stage and days in stage.
- Source.
- Tags.
- **Edit profile** and **Email**.

**Notes callout** **[Proven]**
If Notes exist, the latest one sits above the tabs in a warm callout, so interviewers read the context first.

**Tabs** (the open tab is kept in `?tab=`)

1. **Overview**: key information, the AI summary of experience, skills and education (labelled "Read from CV"), the cover letter or the message from the Apply Form, and the **First Read** verdict if any, visible to `admin` and `recruiter` only.
2. **Notes**: a thread, newest last, with author and time, Markdown, and `@mention` of members (the mention notifies them by email).
3. **Interviews**: the Interviewer Assignments, each showing:
   - the person, role, status, time and meeting link;
   - a warning when they have no Scheduling Link;
   - **Send invitation** (screening link or interview link);
   - **Mark done**, **Cancel**, **Remove** (with confirmation);
   - **Score** (only for the assigned person);
   - a *Scored* badge.
   **Assign** opens a picker of members and recruiters, with role and optional notes.
4. **Scorecards**: the overall weighted average, per-section bars, and a collapsible card per evaluator. Under Blind Scoring the tab reads "3 scorecards submitted. Scores stay hidden until you submit yours", followed by the evaluators' names.
5. **Emails** **[New]**: the thread with this Candidate, sent and received, including the original application email. Each message can be expanded to read it in full.
6. **Timeline**: every Event, newest first, with an icon, a sentence, the actor and a relative time (exact time on hover). Verdicts are hidden under Blind Scoring.

**Right column: documents**
- CV viewer: inline PDF, download for DOCX, open in a new tab. DOCX files are converted to PDF for preview **[New]** when the optional converter is available; see 09.
- Tabs for attachments.
- **Upload / Replace CV** and **Remove CV** (confirmation lists what goes and what stays).
- Files are fetched through 5-minute signed links **[Proven]**.

## W8. Email a candidate (manage)

1. **Email** on the candidate page opens the composer.
   - The recipient is filled in.
   - The subject is "Re: <original subject>" when the Candidate's application email is still in the Intake Mailbox, so the message goes out *as a reply in that thread*. Otherwise it is "Your application: <position>". **[Proven]**
   - The body is Markdown, up to 20,000 characters.
   - A **template** picker inserts a rendered template.
2. **Review**: a rendered preview, with "Once sent it cannot be recalled." **[Proven]**
3. **Send**. The confirmation names the sending mailbox. The message appears in the Emails tab and in the Timeline.
4. If the composer is closed by accident, the draft is kept per Application in the browser. **[Proven]**

## W9. Interviewer journey (interviewer)

1. The **home** page shows *My interviews*: upcoming and to-score, each with time, meeting link, candidate and a Notes pill. The same list has its own page, **My interviews**, in the navigation **[New: v0's "view all" opened everyone's interviews]**.
2. Opening a candidate shows the Notes callout first.
3. **Score**:
   - pick a template (defaults to the Stage's template, else the Job Position's, else the Organisation default);
   - each Section shows its weight;
   - give each Criterion 1 to 5 stars, with an optional comment;
   - add general comments and a Recommendation.
4. All Criteria are required to submit. **Save draft** is allowed at any time.
5. Submitting unlocks peers' Scorecards for this person on this Application.
6. Interviewers cannot move, rate, email, edit or see the First Read.

## W10. Read-only member (viewer, or anyone on a closed Job Position)

- Sees the board with no drag, no "›", no selection, no add and no actions.
- On the candidate page: no Actions and no edits. Blind Scoring applies to `viewer`. A viewer cannot fill in a Scorecard unless they also hold an Interviewer Assignment on that Application.
- Can add Notes **[New]**: a Note is a contribution, not a decision.

## W11. CV Library (admin, recruiter)

1. Recruitment → **CV Library**. A table shows name, current title, tags, source, date, and the First Read verdict chip.
2. Search (debounced) and tag filter (any of the chosen tags), both stored in the URL.
3. Each row opens a **Candidate drawer** **[New: v0 had no detail view for library candidates]**. It holds the profile, CV, notes, emails and timeline, and offers **Move to position**, tag editing, and **Remove from library**.
4. **Move to position** lists open and paused Job Positions only. The Candidate lands in the `applied` Stage.
5. **Manage tags**: name and colour from the 12-colour tag palette, rename, delete (admin).
6. **Needs Triage** tab:
   - Each row shows subject, sender, received time, reason in plain words, and retry count.
   - Actions:
     - **Retry** runs the item again now;
     - **Assign to position…** manually picks the Job Position, which creates the Application from the stored CV **[New]**;
     - **Send to CV Library**;
     - **Dismiss**.
   - Empty state: "Nothing to triage".
7. **Check mailbox now** (Rc) polls immediately and reports the counts.

## W12. Team of a Job Position (owner, admin)

1. Job Position → **Team**. A table shows member, role, capability badge, and who granted the access and when.
2. **Add someone**: a user picker plus a role, with the role's description shown underneath.
3. Change a role inline. Remove a member (confirmation).
4. The last `owner` cannot be removed or demoted.

## W13. Templates (admin)

**Email templates** (Settings → Email templates)
1. A list grouped by kind:
   - `screening_invitation`, `interview_invitation`, `rejection`, `application_received`, `offer`, `custom`;
   - each with one default per kind and locale.
2. The editor has:
   - name, kind, locale, subject;
   - a **Markdown** body (HTML is generated from it, and the plain-text part is the Markdown);
   - a variable palette that inserts at the cursor;
   - a live preview against a sample, or against a real Application chosen in a picker.
3. Saving validates the template: an unknown variable or an unclosed `{% if %}` is reported at its line. **[New]**
4. **Send test** goes to your own address only. **[New: v0 accepted any recipient]**

**Scorecard templates**
5. A builder with sections (name, weight 0.5 to 3) and criteria (name, guidance). Both can be reordered by drag or with ↑/↓.
6. A template that already has submitted Scorecards cannot change its structure. **Duplicate** it instead.

## W14. ⌘K search (anyone with recruitment access)

1. Open with ⌘K or Ctrl+K anywhere.
2. Type at least 2 characters. The search is debounced at 150 ms, cancels the previous request, and is accent- and case-insensitive. It matches name, email, company, title, phone and **tags**. **[Proven + phone/tags]**
3. Results are one row per Application ("Name · Position · Stage") plus one row per CV Library hit, limited to what you can reach.
4. ↑/↓ to move, Enter to open. The same palette also offers *Go to…* commands for positions and settings. **[New]**

## W15. Dashboard (anyone with recruitment access)

Recruitment home → **Dashboard** tab. Sections, all limited to what you can reach:

1. **Needs attention**: each group shows a count and the 5 oldest items **[Proven]**:
   - *New and untouched*: in the `applied` Stage for more than 3 days;
   - *Invitation not booked*: invitation sent more than 5 days ago and still not scheduled;
   - *Scorecard missing*: interview more than 1 day ago and less than 60 days ago, with no submitted Scorecard from that interviewer;
   - *Stalled*: active, past the first Stage, and unchanged for more than 14 days;
   - *Needs Triage* (admin and recruiter).
2. **Upcoming interviews**: next 14 days.
3. **Positions**, one card per open or paused Job Position:
   - days open, total, last 7 and last 30 days;
   - an 8-week sparkline;
   - a funnel: applied → screened → interviewed → offer → hired;
   - sources;
   - median days to first response;
   - number awaiting a first response.
4. **Activity**: the latest 20 Events, never showing a Scorecard verdict.

## W16. Applicant on the careers site

1. `/careers` redirects to `/careers/<locale>`. The locale comes from `Accept-Language`, using the first configured locale that matches. A switcher keeps the same page in another language.
2. The **list page** shows:
   - a hero (Organisation name, tagline, optional image or video, with a still image when reduced motion is preferred);
   - a **spontaneous application** row first, then the open positions with location, remote policy and type.
3. The **position page** shows:
   - a hero with the title and facts, and an *Apply* button that scrolls to the form;
   - the description and requirements rendered from Markdown;
   - the salary, if published;
   - a sticky form beside them (below them on mobile).
   A closed or unknown position shows "This position is no longer open" with links to open positions and to apply spontaneously.
4. The **form**:
   - first name, last name and email (required); phone and LinkedIn (optional);
   - a message (3,000 characters, with a counter);
   - a **CV** (PDF/DOCX, 10 MB), read into memory as soon as it is picked so that a cloud-synced file cannot fail the upload **[Proven]**;
   - consent with a link to the privacy notice;
   - a captcha if configured, and a hidden honeypot.
5. Errors are mapped to friendly localised messages: verification failed, file too large, wrong type, invalid field, position closed, too many attempts, network error. If the position closes while the form is being filled in, the form offers **Send as a spontaneous application** and keeps everything typed. **[Proven]**
6. **Success**: "Thank you, we have received your application." A receipt email follows, in the Applicant's locale, at most one per address per 24 hours.
7. The **privacy** page renders the Organisation's notice for the locale, with its version and date.

## W17. Weekly digest (recruiter, admin)

1. Every Monday at 09:00 in the Organisation's timezone, the people chosen in Settings → AI → Digest get an email covering the past week's spontaneous applications (careers site and mailbox), counted per Verdict.
2. The email has:
   - a **Standout** section first;
   - one section per family or matched position, sorted by Verdict, then confidence, then name;
   - a card per candidate with role, education, location, source, a rationale with quoted evidence, and a link to the candidate in the CV Library.
3. Each Verdict is computed once and reused. A run can be re-sent or previewed from Settings → AI → Digest → *Preview last week*.

## W18. Operator and agent administration

1. **Users** (admin): list, invite (local mode or JIT providers), change Global Role (unless managed), deactivate, reactivate, and see role history.
2. **Integrations** (admin): status and test buttons for sign-in, mail, intake, AI, storage and captcha.
3. **Background work** (admin): Schedules with last Run, next run, the counters of the last run, and *Run now*.
4. **AI usage** (admin): calls per day per Task and model, tokens, cost estimate, errors, and remaining budget.
5. **Personal access tokens**: any User can create one for themselves, read-only or read-write, with an optional expiry. The token is shown once.
6. **CLI** inside the container: `ochre setup-link`, `ochre users list|add|role|deactivate`, `ochre work run <name>`, `ochre llm test`, `ochre purge --dry-run`, `ochre export candidate <email>`.
7. **MCP**: `https://<host>/mcp`, authenticated with a token. Tools mirror the API, limited by the token's permissions. See 09.
