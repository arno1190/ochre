# 03 — Identity, access and workspaces

v0 was locked to one Microsoft Entra tenant with a hard-coded email-domain rule. Users were mirrored from Entra, and mail and calendars went through the same app registration. Ochre separates these into four independent **concerns**, each with its own adapters:

| Concern | Adapters (v1) | Adapters (v1.x) | "Off" state |
|---|---|---|---|
| **Sign-in** | `oidc` (presets: `microsoft`, `google`, `okta`, `keycloak`, `authentik`, `zitadel`, `generic`), `local` | SAML (only if users ask for it) | not possible: at least one provider must be on |
| **Provisioning** | JIT (just-in-time, on first sign-in), invitations, SCIM 2.0 inbound | Google Directory poll, Entra Graph poll | JIT or invitations only |
| **Mail** (out and in) | `graph`, `gmail`, `smtp` (out), `imap` (in), `log` (out, dev) | inbound webhook (Postmark/Mailgun) | out: `log`; in: no Intake Mailbox |
| **Scheduling** | Scheduling Links (plain URLs, any vendor) | Cal.com and Calendly webhooks, MS Bookings poll (v0's sync) | links only, status set by hand |

## 1. Setup profiles

A profile is a pre-filled combination that the wizard offers. Every field can still be changed afterwards.

### `microsoft`: Microsoft 365 / Entra ID

| Concern | Choice |
|---|---|
| Sign-in | OIDC issuer `https://login.microsoftonline.com/<tenant>/v2.0`. Scopes `openid profile email offline_access`. Only users of this tenant are accepted: the `tid` claim must equal the tenant. The identity subject stored is the **`oid`** claim, which is stable across apps in the tenant, rather than the per-app `sub`. |
| Managed roles (optional) | Entra **App roles** `Ochre.Admin` and `Ochre.Recruiter`, assigned in *Enterprise applications → Users and groups*. They arrive in the `roles` claim. Ochre maps `roles` → Global Role. |
| Provisioning (optional) | Entra's built-in SCIM provisioning to `https://<host>/scim/v2` with a bearer token. Deactivating someone in Entra deactivates them in Ochre within about 40 minutes (Entra's provisioning cycle). |
| Mail out | `graph`: `POST /users/{mailbox}/sendMail` with an app-only token. Replies use `createReply`, then `PATCH`, then `send`. |
| Intake | `graph`: poll unread messages, mark as read. |
| Permissions | Application permissions `Mail.ReadWrite` and `Mail.Send`, **scoped to the recruitment mailbox only** with an Exchange *RBAC for Applications* management scope. The setup guide gives the PowerShell. v0 granted these tenant-wide; Ochre's guide must not. |
| Scheduling | Microsoft Bookings personal pages as Scheduling Links |

### `google`: Google Workspace

| Concern | Choice |
|---|---|
| Sign-in | OIDC issuer `https://accounts.google.com`. The OAuth client is an *Internal* consent screen. Ochre requires the `hd` claim to equal one of the configured domains, and `email_verified=true`. |
| Managed roles (optional) | Google ID tokens carry no groups. Two options: (a) no managed roles, assign them in Ochre; (b) v1.x: Admin SDK Directory poll with a service account, mapping Google Groups to Global Roles. |
| Provisioning | JIT (default), or invitations only. Google's SCIM only targets apps in its catalogue, so SCIM is not offered here. |
| Mail out and intake | `gmail`: a service account with **domain-wide delegation**, impersonating the recruitment mailbox only, with scopes `https://www.googleapis.com/auth/gmail.modify` and `.../gmail.send`. Alternative: `imap` + `smtp` with an app password. |
| Scheduling | Google Calendar appointment schedules as Scheduling Links |

### `standard`: any OIDC provider with any mail host

| Concern | Choice |
|---|---|
| Sign-in | OIDC discovery from the issuer URL (Okta, Keycloak, Authentik, Zitadel, Auth0, JumpCloud…). Claims mapping: `email`, `given_name`, `family_name`, `picture`, and a groups claim name (default `groups`). |
| Managed roles | group names → Global Role, recomputed at every sign-in |
| Provisioning | SCIM 2.0 when the IdP supports it, otherwise JIT |
| Mail | `smtp` out, `imap` in (TLS required; STARTTLS or implicit TLS) |
| Scheduling | Cal.com / Calendly / any link |

### `solo`: no workspace

| Concern | Choice |
|---|---|
| Sign-in | `local`: email and password (argon2id), invitations by link |
| Mail | `smtp` if available, otherwise `log` (emails show up in Admin → Mail outbox; nothing leaves the server) |
| Intake | off, or `imap` |

Several sign-in providers can be on at once, for example `microsoft` for staff plus `local` for an external recruiter. The login page shows one button per provider, plus the email/password form when `local` is on.

## 2. Authentication

### OIDC flow (all presets)
1. `GET /auth/login/{provider}`:
   - creates `state`, `nonce` and a PKCE `code_verifier`;
   - stores them in a signed, HttpOnly, 10-minute cookie;
   - redirects to `authorization_endpoint`.
   **[New]** v0 had no state, nonce or PKCE.
2. `GET /auth/callback/{provider}`:
   1. Check `state`.
   2. Exchange the code.
   3. **Validate the ID token**: signature against the cached JWKS, `iss`, `aud`, `exp`, `nonce`. **[New]** v0 trusted Graph `/me`.
   4. Read the claims.
3. **Access policy**, in order. Each failure goes to the login page with a plain-language error, and nothing else is revealed:
   1. The provider-specific checks pass (`tid`, or `hd` plus `email_verified`).
   2. The email domain is in `allowed_domains`, if that list is set.
   3. If an Identity link `(provider, subject)` exists, sign in that User.
   4. Else, if a User with this email exists with `provisioned_by` in (`invite`, `scim`) and has no identity yet for this provider, link the identity and sign them in. Linking by email never happens for an account created by JIT or by another provider's sign-in.
   5. Else, if `jit_provisioning` is on, create the User (`provisioned_by='jit'`) with Global Role `member`, or the mapped role.
   6. Else refuse with "Ask an admin to invite you".
   7. The User must be active.
4. **Managed roles**: if group mapping is configured for this provider, recompute the Global Role from the claim and write a `user.role_changed` Event (`source: 'idp'`) when it changed. The highest mapped role wins (admin > recruiter > member). A mapped User's role is shown as "Managed by <provider>" and is read-only in the UI.
5. **Session**:
   - insert a `sessions` row (random 256-bit id; only its SHA-256 is stored);
   - set the cookie `ochre_session` (HttpOnly, Secure, SameSite=Lax);
   - idle timeout 7 days, absolute timeout 30 days, both configurable;
   - every request bumps `last_seen_at` at most once a minute.
   - **[New]** v0 used a stateless 12-hour JWT with no revocation.
6. **Logout** deletes the session row. *Sign out everywhere* in the profile deletes all of the User's sessions. Deactivating a User deletes all of their sessions.

### Local accounts
- **Passwords**: argon2id (memory 64 MiB, 3 iterations). At least 12 characters, checked against a bundled list of the top 100k breached passwords.
- **Invitation**: an admin enters an email and a Global Role. The invitee gets a link valid 7 days and sets a password. If outbound mail is `log`, the link is shown to the admin to copy.
- **Password reset**: link valid 1 hour, single use. The response is identical whether or not the account exists.
- **Rate limits**: 10 failed logins per account per 15 minutes, and 50 per IP per 15 minutes. Then wait 15 minutes.
- **TOTP second factor**: v1.x.

### API and agent authentication
- **Personal Access Token**: `Authorization: Bearer ochre_pat_<32 bytes base62>`. Only the SHA-256 is stored, plus a prefix for display.
  - It acts as its User, with that User's permissions.
  - It can be *read-only*, which refuses every non-GET request and every MCP tool marked as a write.
  - It has an optional expiry and records `last_used_at`.
- **SCIM token**: a separate secret per provider, used only on `/scim/v2/*`.
- **CSRF**: cookie-authenticated non-GET requests require the `X-Ochre-CSRF` header, which must match the session's CSRF token (served by `/api/me`). Bearer requests are exempt.

## 3. Provisioning and lifecycle

| Event | Effect |
|---|---|
| JIT first sign-in | User created as `member` (or the mapped role). They see nothing until they are made a Job Member or given `recruiter`. |
| Invitation | User created in state `invited` with the chosen role. They become active at first sign-in. |
| SCIM `POST /Users` | User created as `active`, with external id and email. Groups go through `PATCH /Groups` → role mapping. |
| SCIM `active=false` / `DELETE` | User deactivated and sessions removed. Never hard-deleted: Events, Notes and Scorecards keep their author. |
| Admin deactivates a User | Same as above. Refused for the last active `admin`. |
| Reactivate | Admin, or SCIM `active=true`. |

The User profile holds:
- email (unique), display name, given name, family name, avatar (stored as a file, not inlined), job title, locale and timezone;
- Scheduling Links (`screening_url`, `interview_url`);
- notification preferences: mentions, assignments, daily summary.

v0 also synced manager, direct reports and birthday from Entra and wrote changes back to Entra. **Dropped.** Recruitment never read them.

## 4. Authorization

### Global Roles

| Role | May |
|---|---|
| `admin` | Everything: instance settings, integrations, users and roles, templates, the Default Pipeline, rubric and AI configuration. **Irreversible acts**: delete a Job Position, delete or erase a Candidate, export a Candidate's data, reopen a closed Job Position. Plus everything `recruiter` may do. |
| `recruiter` | `manage` on every Job Position. Create Job Positions. CV Library and Needs Triage. Tags. Sees First Read verdicts. v0's `recruitment:manager`. |
| `member` | Nothing by default. Reaches only the Job Positions where they are a Job Member, or Applications where they hold an Interviewer Assignment. |

v0's `recruitment:admin` is split: its *irreversible* acts go to `admin` and its daily acts go to `recruiter`. Template administration is `admin`, as in v0. Hiring becomes a `manage` act (see provenance).

### Job Roles

| Job Role | Capability | Also |
|---|---|---|
| `owner` | manage | grants, changes and revokes Job Roles on this Job Position |
| `hiring_manager` | manage | |
| `screener` | manage | |

**Screener-eligible** (the only definition; used by publish, the Position settings and the API): an active User with a `screening_url` who is `admin` or `recruiter`, **or** a member of this Position with role `owner`, `hiring_manager` or `screener`.
| `interviewer` | read | Blind Scoring |
| `viewer` | read | Blind Scoring |

### Resolving a Capability (one function, used everywhere)

`capability(user, position, application=None) -> {none, read, manage}` together with a `blind: bool` flag:

1. `admin` or `recruiter` → `manage`, `blind=false`.
2. Job Member → the Capability of the Job Role. `blind` is true for `interviewer` and `viewer`.
3. Else, if an `application` is given and the user holds a non-cancelled Interviewer Assignment **on that Application** → `read`, `blind=true`.
4. Else `none`.
5. Finally, if `position.status == closed`, the Capability is capped at `read`. Irreversible acts remain available to `admin`.

**Every list query uses the same reach rule**:
- Job Positions: global role, or membership, or holding a non-cancelled assignment *in that Job Position*. The last case shows the Job Position only as a container for "My interviews", never its board.
- Applications: Capability ≥ read.
- Candidates: via any reachable Application; the CV Library is reachable by `admin` and `recruiter` only.

**[New]** v0 had three slightly different reach rules (detail, lists and dashboard). Its "all interviews" list and its stats leaked candidates and verdicts across assignment-only reach. In Ochre a single policy module answers every reach question, and a test suite (09 §Testing) checks every endpoint against a persona × resource matrix.

### Permission matrix (actions)

`M` = Capability `manage` on the Job Position. `R` = `read`. `A` = Global Role admin. `Rc` = recruiter or admin.

| Action | Required |
|---|---|
| See a Job Position, its board, its team | R (assignment-only holders: no) |
| Create a Job Position | Rc |
| Edit a Job Position, its Pipeline, publish, pause, close | M |
| Reopen a closed Job Position, delete a Job Position | A |
| Grant, change or revoke Job Roles | A, or the Job Position's `owner` |
| Add a candidate, move, rate, email, reject, reopen an Application, hire, transfer (M on both Job Positions) | M |
| Assign interviewers, send invitations, cancel or complete an assignment | M |
| Write a Note (including `viewer`) | R |
| Read Applications, CV, attachments, Notes, Timeline | R (blind redaction applies) |
| Create or submit your own Scorecard | R **and** (a live Interviewer Assignment on this Application **or** M). A `viewer` with no assignment cannot score, so cannot lift Blind Scoring by scoring |
| Edit someone else's Scorecard | not allowed (v0 allowed managers; dropped) |
| Delete a Scorecard | A |
| Edit a Candidate profile | M on at least one of their Applications. Changing email or LinkedIn requires M on all of them, or Rc. |
| Remove or replace a CV | M on at least one of their Applications, or Rc |
| CV Library, create or rename tags, Needs Triage (retry, assign, to library, dismiss), poll mailbox now, move to position | Rc |
| Delete a tag | A |
| Erase a Candidate, export a Candidate | A |
| Email templates, scorecard templates, Default Pipeline, rubric, settings, users | A |
| See First Read verdicts and the Digest | Rc |
| See the dashboard | anyone with any reach; content filtered by reach |

### Blind Scoring rules

These apply when `blind=true`: Job Role `interviewer` or `viewer`, **or** reach through an Interviewer Assignment only. Redaction happens **on the server, in the serializers**, never in the UI.
- Peers' Scorecards return the evaluator's name and `submitted_at` only. Scores, Recommendation, comments and averages are `null`, with `redacted: true`.
- Timeline Events of type `scorecard.submitted`, `scorecard.edited` and `application.rated` drop their payload.
- The Application's `rating` (stars) is `null` with `redacted: true`, on the candidate page and on board cards. The rating is a manager's verdict too.
- The dashboard, stats and search never return a Recommendation or a score.
- Blindness lifts only when the User holds a **submitted** Scorecard on this Application **with every Criterion scored**. **[New]** In v0 an empty submission lifted it.

## 5. Agent-managed IAM (for operators using Claude or another agent)

This section is about an *operator* administering the instance with an admin PAT. Agents that do recruiting work have their own identities, scopes and Proposals (13 §3–§6). Admin tools are never available to them.

An operator can let an agent manage access without giving it database access:

1. The operator creates a PAT on an `admin` account, possibly a dedicated *Ops Agent* local user with role `admin`.
2. The agent uses the CLI (`docker exec ochre ochre users …`), the REST API, or the MCP endpoint. The MCP tool list and its permissions are in 13 §6, and only there. Admin tools there require an admin PAT.
3. Every agent action is recorded as an Event with the PAT's User as actor and `via: "pat:<prefix>"` or `"mcp:<prefix>"`.
4. The repository ships a Claude Code skill, `skills/ochre-operator/SKILL.md`, specified in 09. It walks an agent through installing Ochre, creating the Entra or Google app, and wiring each profile. It contains no secrets and tells the agent to put credentials in the host's secret store, never in the repo.

When identity is managed in the IdP (managed roles or SCIM), Ochre refuses role changes that would contradict it and says where to change them instead ("Role is managed by Microsoft Entra: change the app role assignment there").
