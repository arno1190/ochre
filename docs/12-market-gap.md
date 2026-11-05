# 12 — Market gap: Ochre v1 against commercial ATSs (November 2026)

This page compares Ochre with the commercial ATSs a small or mid-sized team would otherwise buy: Greenhouse, Ashby, Lever, Workable, Teamtailor and Welcome to the Jungle. It also covers the AI layer forming around them. It is **analysis, not spec**. What we decided to build is in [13 Agent platform](13-agent-platform.md) and the [roadmap](11-roadmap.md).

## 1. Where the market is in late 2026

- **AI-native ATSs ship assistants, agents and MCP servers.**
  - Ashby announced agents, an assistant and MCP support in May 2026. Its MCP server is in open beta on all plans, and it sells a native AI notetaker and advanced scheduling as add-ons.
  - Greenhouse launched a governed MCP connector (open beta for Core, Plus and Pro), an Analytics Chart Agent, a Notetaker, and a "Job Kickoff Agent" that builds a structured job from kickoff notes. It is positioned as AI that "strengthens structured hiring, not shortcuts it". It holds ISO/IEC 42001 certification.
  - Workable includes an MCP server in every plan and markets an "AI Recruiting Agent".
  - Lever has no official MCP server; third-party connectors fill the gap.
- **Sourcing agents live outside the ATS.** LinkedIn's Hiring Assistant runs background searches and outreach as a paid add-on, and reviewers note that deep outbound sourcing needs a dedicated layer even on AI-native ATSs.
- **Regulation is catching up.**
  - EU AI Act, Annex III: AI used for recruitment screening and ranking is **high-risk**.
  - The Digital Omnibus reportedly moves the Annex III obligations from 2 Aug 2026 to **2 Dec 2027**. Check publication in the Official Journal before relying on it.
  - The Article 50 transparency duties apply from **2 Aug 2026**.
  - Responsibility sits with the deployer, meaning the company using the tool, which is why tools that make compliance easy matter.
  - GDPR Article 22 already restricts decisions about people made by solely automated means.

## 2. Feature gap

Legend: **v1** = in the Ochre v1 spec · **v1.0+** = added to the v1.0 scope by doc 13 · **v1.x** = planned after 1.0 · **no** = deliberate non-goal.

| Capability | Typical in commercial ATSs | Ochre | Notes |
|---|---|---|---|
| Careers site, apply form, branded pages | all | **v1** | Themeable, multilingual, JSON-LD, works without JS |
| Email intake from a shared mailbox | rare (most force a form) | **v1** | An Ochre strength |
| Pipelines, kanban, bulk actions | all | **v1** | |
| Scorecards, structured interviews | Greenhouse, Ashby, Lever | **v1** | With enforced blind scoring |
| Candidate email: templates, threads | all | **v1** | |
| Talent pool / CV Library, tags | all | **v1** | |
| AI CV parsing | all | **v1** | Grounded, provider-agnostic |
| **Custom application questions, knockouts** | all | **v1.0+** | Was missing: the form had fixed fields only |
| **Outbound webhooks** | Greenhouse, Ashby, Lever, Workable | **v1.0+** | Was missing: the backbone for any outside automation |
| **MCP server with governed writes** | Greenhouse, Ashby, Workable (2026) | **v1.0+** | v1 had read-mostly MCP tools; doc 13 adds agent identities, proposals and autopilot |
| **Human-in-the-loop approvals for agent actions** | emerging (Greenhouse "governed" framing) | **v1.0+** | The Proposals inbox |
| **Import from another ATS / CSV** | migration services | **v1.0+** | Adoption blocker without it |
| **AI transparency and a register** (AI Act Art. 50 + deployer logs) | Greenhouse (ISO 42001), others partial | **v1.0+** | AI register page, candidate notice, per-candidate AI log |
| Interview scheduling: free/busy, panels, candidate self-scheduling | Ashby (paid), Greenhouse, Workable | **v1.x** | v1 uses personal booking links. Doc 13 §8 specifies Ochre-generated slot links over Graph/Google free/busy |
| Interview notetaker → scorecard draft | Ashby, Greenhouse (2026), Metaview | **v1.x** | Ochre ingests transcripts (Teams, Meet, Zoom or uploaded VTT) rather than running a recording bot |
| Job kickoff agent: notes → position, requirements, scorecard | Greenhouse (Q3 2026) | **v1.x** | |
| CV Library rediscovery (semantic search, "people like this") | Ashby, Workable, LinkedIn | **v1.x** | pgvector. Suggestions with grounded reasons, never a hidden score |
| Analytics: reports, time-to-hire, source ROI, chart Q&A | all; Greenhouse Chart Agent | **v1.x** | Standard reports plus read-only reporting views; Q&A through MCP from the user's own assistant |
| Offers: templates, approvals, e-signature | Workable, Teamtailor, Greenhouse | **v1.x** | Signature adapter (Docuseal self-hosted, Yousign, DocuSign) |
| Job requisitions and approvals, hiring plan | Greenhouse, Ashby | **v1.x** | Light: approval chain before publish |
| Job board multiposting | Workable (200+ boards), Teamtailor | **v1.x** | Standard XML feeds (Indeed, LinkedIn Limited Listings) plus Google for Jobs (already v1) |
| Candidate status page, NPS survey | Teamtailor, Greenhouse | **v1.x** | Magic-link status page; 1-question NPS after the outcome |
| Slack / Teams notifications | all | **v1.x** | Through webhooks, plus two first-party adapters |
| HRIS handoff on hire | all (Personio, HiBob, BambooHR…) | **v1.x** | Hire webhook first; adapters later |
| Referrals portal | Greenhouse, Teamtailor | **v1.x** | Employee submits a referral, tracked as a source |
| Two-way personal mailbox sync | Greenhouse, Lever | v1.x (maybe) | Ochre threads through the shared mailbox; personal sync is costly and privacy-heavy |
| Assessments and background checks | via marketplaces | v1.x (webhooks) | Integrate by webhook, no marketplace |
| SMS / WhatsApp to candidates | Teamtailor, Paradox | v1.x (maybe) | |
| Outbound sourcing from LinkedIn and the web | LinkedIn, hireEZ, Gem | **no** | LinkedIn's terms; a separate product category |
| AI voice / avatar interviewer | Ashby (waitlist), Paradox, HeyMilo | **no** | High-risk, low trust; conflicts with principle 3 |
| AI auto-reject or auto-rank as a decision | some vendors | **no** | GDPR Art. 22, AI Act human oversight; conflicts with principle 3 |
| EEO/OFCCP (US) reporting | US vendors | **no** (v1) | Revisit if US users ask |
| Multi-tenant SaaS / agency mode | Recruitee, Manatal | **no** | One instance, one organisation |

## 3. What actually closes the gap in the AI age

Copying features one by one is a losing race against funded vendors. The leverage is different: **make Ochre the best ATS for agents to work in**, safely. Five primitives do that (specified in [13](13-agent-platform.md)):

1. **Agent identities**: an agent is a first-class actor with a name, an owner, scopes, a budget and a kill switch. It is not a borrowed human token, and every action it takes is attributed to it.
2. **Proposals**: when an agent wants to do something consequential (reject, advance, send a non-template email, hire), it files a *proposal* with its reasons and evidence. A human approves or edits each one in one click, singly or in bulk. Most of the work is automated while the decision stays human, which is also how the AI Act and GDPR expect it.
3. **Autopilot policies per position**: the hiring team chooses what may run without approval. Examples: invite to screening when a candidate passes every knockout question; send scheduling reminders; chase overdue scorecards. Rejection and hiring always need a human, and that is a property of the product, not a setting.
4. **Complete MCP plus webhooks**: everything a human can read, an agent can read through MCP (with blind scoring still enforced). Every Event is also pushed as a signed webhook. Any assistant (Claude, ChatGPT, Copilot, a local model) or any workflow tool (n8n, Zapier) can then drive Ochre end to end.
5. **Compliance by construction**: an AI register, a candidate-facing AI notice, a per-candidate log of AI involvement, and exports. A small company can then meet its deployer duties without a consultant.

With these, "fully automated" becomes concrete. A daily agent run (doc 13 §7) can:
- triage the mailbox;
- check knockouts;
- invite qualified candidates to screening;
- chase scorecards;
- draft rejections and summaries.

Each morning the recruiter only reviews a short Proposals inbox.

## Sources

- Ashby, agents, assistant and MCP (May 2026): [press release](https://digital-release.wowktv.com/business/press-releases/cision/20260507SF53835/ashby-expands-its-ai-native-ats-with-agents-assistant-and-mcp-support) · [MCP product update](https://www.ashbyhq.com/product-updates/mcp) · [2026 keynote](https://www.ashbyhq.com/ashby-one/2026/london/product-keynote)
- Greenhouse: [new AI capabilities](https://www.greenhouse.com/newsroom/greenhouse-launches-new-ai-capabilities-built-to-strengthen-structured-hiring-not-shortcut-it) · [Greenhouse MCP](https://www.greenhouse.com/newsroom/greenhouse-launches-mcp-giving-hiring-teams-a-governed-way-to-connect-ai-tools-to-greenhouse) · [July 2026 release notes](https://support.greenhouse.io/hc/en-us/articles/53681385010331-Release-Notes-July-2026)
- Ecosystem comparisons (vendor-biased): [Agentic ATS 2026: Greenhouse vs Ashby vs Workday](https://www.herohunt.ai/blog/agentic-ats-2026-greenhouse-vs-ashby-vs-workday/) · [Best MCPs for recruiting 2026](https://www.herohunt.ai/blog/best-mcps-for-recruiting-in-2026/) · [Geekflare ATS guide](https://geekflare.com/guides/best-applicant-tracking-system/)
- LinkedIn Hiring Assistant: [ERE](https://newsletter.ere.net/p/inside-linkedin-s-hiring-assistant-rollout) · [SHRM](https://shrm.org/topics-tools/news/talent-acquisition/linkedin-debuts-ai-agent-to-streamline-recruiting-tasks)
- Offers and e-signature: [Teamtailor e-signing](https://support.teamtailor.com/en/articles/11290403-enable-e-signing-for-documents-in-teamtailor) · [Workable offer letters](https://help.workable.com/hc/en-us/articles/360037551153)
- EU AI Act and recruitment: [deadline extension](https://minthcm.org/ai-act-deadline-extension-confirmed-new-timeline-for-hr-recruitment-systems/) · [obligations before 2 Aug 2026](https://minthcm.org/ai-act-for-hr-what-you-need-to-do-before-2-august-2026/) · [AI Act and staffing](https://artificialintelligenceact.eu/?p=6039)

Most sources are vendor announcements or vendor-biased blogs. Feature availability changes fast, so re-check before quoting any claim publicly.
