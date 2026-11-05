# 01 — Glossary

This file is the shared vocabulary. Code identifiers, UI labels, API paths and docs all use these words. Each entry lists terms to *avoid*: do not introduce them as synonyms anywhere. The code name is in `monospace` where it differs from the UI word.

## Recruitment

**Organisation** (`org`)
The single company an instance serves. It holds the name, logo, careers-site theme, locales, contact address and privacy notice.

**Job Position** (`position`)
An open or past role that the Organisation recruits for. Each one has its own Pipeline, Members and Applications.
_Avoid_: job offer, posting, vacancy, requisition. In code it is `position`, never `job`, which reads as a background job.

**Pipeline**
The ordered list of Stages of one Job Position. A new Job Position gets a copy of the Organisation's **Default Pipeline**, which recruiters can then edit per Job Position.
_Avoid_: workflow, funnel (the funnel is a *metric*).

**Stage**
One ordered step of a Pipeline. A Stage has a **kind** (`applied`, `screening`, `interview`, `offer`, `custom`), a name, a colour, default interviewers and **Stage Actions**. Behaviour never depends on a Stage's *name*, only on its kind.
_Avoid_: step, column, phase.

**Stage Action**
Something done automatically when an Application enters a Stage. Examples: assign the Stage's default interviewers, send the default email template for the Stage's kind. Email actions run only while the Job Position's **automation** switch is on.
_Avoid_: trigger, rule, hook.

**Candidate**
A person the Organisation considers. They are identified by email or, when sourced by hand without one, by their LinkedIn profile. A Candidate may have no CV and exists independently of any Job Position.
_Avoid_: applicant (that word is reserved for the public site's visitor), profile, lead.

**Application**
One Candidate's participation in one Job Position's Pipeline. A Candidate holds at most one *active* Application per Job Position. An Application is either `active` (sitting in a Stage) or has an **Outcome**.
_Avoid_: candidature, submission.

**Outcome**
How an Application ended: `hired`, `rejected` (with a reason) or `withdrawn` (the candidate stepped back, or the Application was transferred). An Application with an Outcome leaves the board's Stage columns for an outcome lane. It remembers the Stage it left, and reopening puts it back there, active.
_Avoid_: terminal stage, status column.

**CV Library**
The Candidates with no active Application who are kept for later, such as spontaneous applications and sourced profiles. They are tagged and searchable.
_Avoid_: pool, talent pool, vivier.

**Tag**
A coloured label on a Candidate, used to retrieve people from the CV Library.

**Note**
A dated, signed comment on a Candidate, optionally attached to one Application. The author can edit or delete a Note for 15 minutes, then it is final. Admins can delete any Note.
_Avoid_: comment, internal notes.

**Event**
One immutable entry in the log of what happened to an Application or a Candidate. The timeline, the dashboard activity feed and the audit are all views of Events.
_Avoid_: history row, activity.

## Assessment

**Interviewer Assignment** (`assignment`)
The link between a user and one Application that gives the user a part in assessing it. The UI calls it an "interview". It has a status (`pending`, `scheduled`, `done`, `cancelled`), an optional time and an optional meeting URL.
_Avoid_: interview (as an entity), panel slot.

**Screener**
The member who makes first contact on a Job Position. Their screening booking link goes out in the screening invitation. A Job Position has at most one **default Screener**. An Application may name its own Screener through an Assignment of role `screener`.
_Avoid_: recruiter, first interviewer.

**Scorecard Template** (`scorecard_template`)
A rubric made of weighted Sections, each holding Criteria, that are scored from 1 to 5.
_Avoid_: interview template, trame.

**Scorecard**
One user's assessment of one Application against one Scorecard Template: a score per Criterion, a Recommendation and comments. It is a *draft* until submitted.
_Avoid_: evaluation, review, feedback.

**Recommendation**
`strong_yes`, `yes`, `maybe`, `no`, `strong_no`.

**Blind Scoring**
Members with the `interviewer` or `viewer` role, and people who reach an Application only through an Interviewer Assignment, cannot see peers' Scorecards or the Application's rating (scores, recommendation, comments, stars, or anything derived from them) until they have submitted a complete Scorecard of their own on that Application.

## Intake

**Intake Mailbox**
A mailbox that applications are emailed to. It is polled on a schedule, and each message becomes an **Intake Item**.
_Avoid_: recruitment inbox, joinus.

**Intake Item**
The record of one received message, with a status (`pending`, `imported`, `needs_triage`, `ignored`, `dismissed`), a reason, and a retry count. It is the idempotency key that stops a message being imported twice.
_Avoid_: import log.

**Matching**
Deciding which open Job Position an emailed application names. A message that matches becomes an Application. A CV that names no position is a **spontaneous application** and joins the CV Library.
_Avoid_: routing, classification.

**Needs Triage**
An Intake Item that nobody could place, because matching failed or was ambiguous, there was no readable CV, or the message was not a CV. It waits for a human, and **no Candidate exists for it yet**. A spontaneous application is *not* Needs Triage.

**Apply Form**
The public page where an Applicant sends a CV, choosing a Job Position or applying spontaneously. It never modifies a Candidate it did not create.
_Avoid_: careers form.

**Applicant**
The anonymous visitor of the careers site. They become a Candidate on submission.

**Consent**
The versioned privacy notice that an Applicant accepted, stored with each submission.

## AI

**LLM Gateway** (`llm`)
The single module that every model call goes through. It owns Providers, Key Pools, Task Routes, budgets and the call log.

**Provider**
An OpenAI-compatible endpoint (`base_url`) such as OpenRouter, OpenAI, Mistral, Groq, Ollama or vLLM.

**Key Pool**
The one or more API keys of a Provider, used in rotation. A key that hits a rate limit or a quota is cooled down.

**Task Route**
The ordered list of `provider/model` pairs used for one **AI Task**. The first healthy entry wins and the rest are fallbacks.

**AI Task**
A named model use: `cv_parse`, `job_match`, `first_read`. ("Task" is reserved for these; `test` appears in the call log for connection tests.)

**Grounding**
The rule that any fact an AI Task returns (an email, a name, an employer, a "requirement met") must be found verbatim in the source text. Otherwise it is nulled or marked unmet.

**First Read**
The AI's rubric-based assessment of a spontaneous application. It produces a **Verdict** (`standout`, `worth_a_look`, `pass`). The Verdict is computed by code from the rubric scores, never chosen by the model.
_Avoid_: AI score, ranking, triage (which belongs to Needs Triage). The per-user morning email is the **daily summary**, never a digest.

**Rubric**
The Organisation-defined scoring dimensions, families and signals that First Read uses.

**Digest**
The weekly email to recruiters that lists the past week's spontaneous applications grouped by Verdict.

## Access

**User**
A person who signs in to Ochre. It is not a Candidate.

**Identity Provider** (`idp`)
Where Users authenticate: an OIDC issuer, or `local`.

**Global Role**
An organisation-wide grant: `admin`, `recruiter` or `member`. Every User has exactly one.
_Avoid_: scope, permission.

**Job Member** (`member`)
A User granted a **Job Role** on one Job Position: `owner`, `hiring_manager`, `screener`, `interviewer` or `viewer`.

**Capability**
What someone may do on one Job Position: `read` or `manage`. It is derived from the Global Role, the Job Role, or an Interviewer Assignment. A closed Job Position caps everyone at `read`.

**Managed Role**
A Global Role that the Identity Provider decides, through group-to-role mapping or SCIM. It is recomputed at each sign-in and cannot be changed by hand in Ochre.

**Personal Access Token** (`pat`)
A token a User creates to let a script or agent act as them through the API or MCP. It can be restricted to read-only.

**Scheduling Link**
A User's booking-page URL, such as Microsoft Bookings, Google appointment schedules, Cal.com or Calendly. A User has two kinds: `screening` (short call) and `interview` (long call).

## Operations

**Background work** (`work`)
Anything the server does outside a request: polling the Intake Mailbox, sending queued email, enriching Apply Form submissions, the Digest, the retention purge. A **Schedule** is a recurring one (a cron expression in the Organisation's timezone). A **Work item** is one queued unit, and a **Run** is one execution, with counters.
_Avoid_: flow, task (both are orchestrator words, and "task" belongs to AI Tasks), job (ambiguous with Job Position).
