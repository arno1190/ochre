# 07 — Screens

Every route, who reaches it, what is on it and every state. The interactions are in 02 and the visual rules in 08. "Reach" uses the permission shorthand of 03.

## Global frame (app)

- **Sidebar** (collapsible to icons, `⌘\` toggles it), top to bottom:
  - org logo;
  - **Home**;
  - **Positions**;
  - **CV Library** (Rc), with a vermilion dot carrying the Needs Triage count;
  - **My interviews**;
  - a divider;
  - **Settings** (A; members see Profile only);
  - the user menu: profile, theme, sign out.
  The active item matches by path **prefix**. **[New: v0 used exact match]**
- **Top bar**: page title and breadcrumbs, the ⌘K button ("Search ⌘K"), and a "Mail redirected" banner when `MAIL_REDIRECT_TO` is set.
- **Mobile** (below 768 px): the sidebar becomes a bottom tab bar (Home, Positions, Library, Interviews, Me). The board scrolls horizontally with one column per viewport and snap scrolling. The candidate page stacks profile → documents → tabs.
- **Keyboard**:
  - `⌘K` search;
  - `g h` / `g p` / `g l` / `g i` go to Home, Positions, Library, Interviews;
  - `?` shows the shortcut sheet;
  - `Esc` closes overlays.
  - Shortcuts are disabled inside inputs.
- **Errors**:
  - a route error boundary shows "Something went wrong" with *Retry* and the request id;
  - a 404 or no reach shows "This page doesn't exist or isn't shared with you";
  - offline shows a toast "You're offline. Changes will fail until you reconnect". There is no offline mode.

## Routes

| Route | Reach | Content and states |
|---|---|---|
| `/login` | public | `wash-dawn` background, the brush mark and org name, one button per OIDC provider (icon and label from settings), the email and password form if local is on, and "Forgot password". The error banner maps `?error=` codes: `not_invited`, `domain_not_allowed`, `wrong_tenant`, `deactivated`, `provider_error` |
| `/setup` | setup token | the 6-step wizard of 02 W0, with a step indicator. Each step has *Test* with an inline result (green tick, or red with the provider's message) |
| `/` Home | Any | Greeting. **My interviews** (next 5 and "to score" with a count). **Needs attention**, compact, only if the user has reach. Recent activity. Empty: "Nothing on your plate. When someone adds you to a position, it shows up here" |
| `/positions` | Any (filtered) | Header: *New position* (Rc). Tabs **Positions** and **Dashboard**. Positions shows a search, a status filter (default: draft, open, paused) and a "Show closed (n)" toggle; rows show title, department, status pill, active count, newest application age and my role. The row menu has Open, Edit, Publish/Pause/Close (M). Empty: Rc sees "No positions yet" with *Create the first one*; members see "No positions shared with you yet" |
| `/positions?tab=dashboard` | Any | 02 W15 sections. Each "needs attention" item links to its Application |
| `/positions/new` | Rc | Position form (below) |
| `/positions/:id` | R | Redirects to `/positions/:id/board` |
| `/positions/:id/board` | R | Header: title, status pill, automation pill ("Automation on" / "off"), department · location · type, default Screener avatar. Actions (M): *Add candidate*, *Select*, a menu (*Edit*, *Pipeline*, *Publish/Pause/Close*, *Reopen* (A), *Send screening/interview invitations* when automation is off). Below: the filter bar (collapsed into a "Filters (2)" button). The board: columns plus the collapsed Hired, Rejected and Withdrawn lanes. Loading: column skeletons. Empty: "No candidates yet. Add one, or share the careers link" with a copy-link button. Read-only: no drag affordances |
| `/positions/:id/team` | R (edit: A, owner) | 02 W12 |
| `/positions/:id/pipeline` | R (edit: M) | 02 W2. Unsaved changes are guarded |
| `/positions/:id/settings` | M | Position form, translations, publication (status, screener, automation), danger zone (close, delete for A) |
| `/applications/:id` | R | Candidate page, 02 W7. The URL keeps `?tab=` and `?from=board`. The layout is two columns on screens wider than 1200 px (left 7/12, right 5/12, each scrolling on its own) and stacked otherwise. **[New: v0 used a fixed `calc(100vh-200px)`]** |
| `/candidates/:id` | R via any Application, or Rc | Same layout without the Application context. The tabs are Overview, Notes, Emails and Timeline, plus an **Applications** list. Used for CV Library people and from search |
| `/library` | Rc | Tabs **Candidates** and **Needs Triage** (with a count). 02 W11. The candidate drawer is `?candidate=<id>`. Empty: "Your CV Library is empty. Spontaneous applications and people you set aside land here" |
| `/library?tab=triage` | Rc | Triage table. Empty: `wash-meadow` with "Nothing to triage" |
| `/interviews` | Any | **My interviews**. Tabs Upcoming, To score, Past. Rows show the time (in the user's timezone), candidate, position, stage, meeting link, a Notes pill and the scorecard status. Empty states per tab |
| `/settings/profile` | Self | Name, title, avatar, locale, timezone, theme, Scheduling Links (with *Send me a test invitation*), notification preferences, sessions, personal access tokens |
| `/settings/organisation` | A | Name, logo, website, address, timezone, default locale, careers locales |
| `/settings/careers` | A | Theme (08 §1.6) with live preview, hero text per locale, response-time text, privacy notice editor per locale (Markdown, saving bumps the consent version and shows it), captcha provider |
| `/settings/sign-in` | A | Provider cards (enable, configure, test, role mapping), allowed domains, JIT switch, SCIM tokens |
| `/settings/users` | A | Users table (name, email, role, managed-by badge, state, last login) with invite, change role, deactivate and history |
| `/settings/mail` | A | Outbound transport, sender name, Intake Mailbox (transport, mailbox, folder, after-import action), with tests. A last-poll summary links to Background work |
| `/settings/ai` | A | Providers (keys show fingerprint and status: ok, cooling, disabled), Task Routes (drag to order), budgets, *Test all*, usage chart, and Digest settings (recipients, preview last week, send test) |
| `/settings/rubric` | A | Rubric form (05 §3.4) with a YAML toggle and *Try on a CV from the Library* (dry run, nothing stored) |
| `/settings/templates/email` | A | 02 W13 |
| `/settings/templates/scorecards` | A | 02 W13 |
| `/settings/pipeline` | A | Default Pipeline editor (same component as the position pipeline) |
| `/settings/retention` | A | Months, hired action, mode, last report |
| `/settings/work` | A | Schedules: name, cron, enabled, last run (outcome, counters, duration), next run, *Run now*. Recent failures with the error |
| `/settings/audit` | A | Events with no candidate (settings, secrets, users, roles), filterable |
| `/settings/outbox` | A | Messages by status, with resend and cancel |

## Position form
- Left column: title, department, location, remote policy, employment type, salary (min, max, currency, period, "show publicly"), aliases (chips).
- Right column: description and requirements in a Markdown editor with *Write* and *Preview* tabs and a toolbar (headings, bold, lists, link).
- Translations: one tab per extra careers locale, each field showing the default-locale value as its placeholder.
- Validation is inline, and the *Save* button names the action ("Create draft", "Save changes").

## Board card (detail)
```
┌───────────────────────────────────────┐
│ (AL)  Ada Lovelace            ★★★★☆   │
│       Analyst · Babbage & Co          │
│ ▣ ✉ ☎ in      [Notes 2]     ⏱ 9d  ›  │
└───────────────────────────────────────┘
```
- In select mode a checkbox replaces the avatar.
- A card in an outcome lane shows a pill instead of `›`.
- **Focus** gets the `ultramarine` ring.
- **Keyboard on a focused card**:
  - Enter opens it;
  - `]` / `[` move it to the next or previous Stage;
  - `x` toggles selection in select mode;
  - `r` rejects it (M).

## Candidate page (detail)
```
┌ Back · Ada Lovelace ───────────────── 3/12 in Screening  ‹ › ┐
│ [Move ▾] [Reject] [Hire] [⋯ Transfer · Withdraw · Delete]    │
├──────────────────────────────┬────────────────────────────────┤
│ Profile card                 │ [CV] [Cover.pdf] [Portfolio]   │
│ Notes callout (if any)       │                                │
│ Overview|Notes|Interviews|   │     PDF viewer (pdf.js)        │
│ Scorecards|Emails|Timeline   │                                │
│ …tab content…                │ [Replace] [Remove] [Open ↗]    │
└──────────────────────────────┴────────────────────────────────┘
```
- The PDF viewer is **pdf.js** (`react-pdf`), so rendering is the same in every browser, text is selectable and search works. **[New: v0 used an iframe]**
- Images render inline. Anything else offers *Download*.

## Careers site (server-rendered, 09 §Frontend)

| Route | Content |
|---|---|
| `/careers` | 302 to `/careers/{locale}` (Accept-Language, then the org default) |
| `/careers/{locale}` | Hero: wash or image, the org logo, a serif headline (settings), a tagline and an "Open positions" anchor. List: the spontaneous row first ("Don't see your role? Apply spontaneously"), then positions as rows (title in serif, then department · location · remote · type). Footer: org links, privacy, a language switcher. No positions: "No open positions right now", with the spontaneous row kept |
| `/careers/{locale}/{slug}` | Hero (title, facts, *Apply*). A two-column body: description and requirements (Markdown), salary when public, then the sticky form. Includes `JobPosting` JSON-LD (title, description, datePosted = `published_at`, employmentType, jobLocation or `jobLocationType: TELECOMMUTE`, baseSalary when public, hiringOrganization). A closed or unknown slug returns HTTP **410** with alternatives |
| `/careers/{locale}/apply` | The spontaneous form |
| `/careers/{locale}/privacy` | The notice with version and date |
| `/careers/{locale}/thanks` | The success page (the form posts with JS; without JS it falls back to a full-page POST then redirects here) |

The careers pages must:
- score **100 on Lighthouse accessibility** and at least 95 on performance on mobile;
- work **without JavaScript**: the form posts multipart, and the captcha degrades to a `noscript` notice;
- weigh less than 60 kB of JS (the form script and captcha only).
`<html lang>` is the locale and `hreflang` alternates are listed. Sitemap: `/careers/sitemap.xml`.

## Emails (rendered)
- The layout is single column, 600 px:
  - org logo top-left on `paper`;
  - body in `ink` on `surface` with a 1 px `line` border;
  - the CTA button as an `ultramarine` fill with white text;
  - a footer with the org name and address.
- Dark-mode clients get `color-scheme: light dark` with explicit colours.
- A plain-text part is always included.
