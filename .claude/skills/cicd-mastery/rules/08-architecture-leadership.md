# Stage 7 — Architecture, Platform & Leadership

## Objectives
- Design CI/CD for *teams and organizations*, not just one repo.
- Reason about cost, scale, reliability, and governance trade-offs.
- Operate as the person who sets standards, mentors, and is trusted in incidents.

This stage is less about new tools and more about **judgment, communication, and systems thinking** — which is what actually separates senior/staff from mid-level.

## Core concepts (the why)

**Reusability & standards across many repos.** One pipeline is mid-level. A senior builds **reusable building blocks** so 50 repos don't reinvent (and misconfigure) CI:
- Reusable workflows / composite actions (GitHub), shared CI templates (GitLab `include`), shared Docker base images.
- A "golden path": the paved, well-lit default pipeline that's easy to adopt and hard to do insecurely. Make the secure, observable choice the *default*, not an opt-in.

**Platform engineering / Internal Developer Platform (IDP).** At scale, a platform team provides self-service paved roads so product teams ship without becoming infra experts. The senior question shifts from "how do I deploy my app" to "how do I let *every* team deploy safely with minimal cognitive load." Backstage, self-service templates, golden paths.

**Cost & efficiency as a first-class concern.** CI minutes, runner sizing, registry storage, parallelism, and cloud spend all cost real money. Seniors:
- Right-size runners; use caching and path filters so unaffected jobs don't run.
- Use self-hosted runners when CI volume makes managed runners expensive — weighing the maintenance/security trade-off.
- Cancel superseded runs (concurrency groups) instead of burning compute on stale commits.
- Treat pipeline duration and cost as tracked metrics with budgets.

**Reliability & scale of the delivery system itself.** The pipeline is production infrastructure. What happens when the registry is down, a runner pool is exhausted, or a deploy is mid-flight during an outage? Seniors design for: deploy queuing, concurrency limits (don't deploy two things to one env at once), idempotent retries, and a documented "break glass" manual path for when automation is down.

**Governance, compliance & change management.** In regulated or larger orgs: who can deploy to prod, segregation of duties, audit trails (which the pipeline + GitOps provide for free), required approvals, and compliance evidence (the SBOM/attestations from Stage 4). The art is making governance *automated and low-friction* rather than a ticket-driven bottleneck — compliance as code, not compliance as committee.

**Migration & adoption strategy.** Real seniority is taking a legacy "deploy by SSH and pray" team to modern CI/CD *without halting delivery*. Strangler-fig the pipeline: add CI checks first (non-blocking → blocking), then automate one environment, then production, then progressive delivery. Bring people along — the social change is harder than the technical change.

## The leadership layer (the actual senior differentiator)
- **Trade-off articulation.** You will be judged on explaining *why*, with the costs named, not on knowing tool names. "We chose rolling over blue-green because our infra budget doesn't justify 2× capacity and our rollback SLA of 5 minutes is acceptable for this service."
- **Incident leadership.** Calm, structured response; blameless postmortems that produce systemic fixes (often a pipeline/automation improvement), not scapegoats.
- **Mentoring & multiplying.** Documenting the golden path, reviewing others' pipeline changes, growing the team's capability. Your impact is measured by the team's output, not your own commits.
- **Saying no to complexity.** The most senior move is often *removing* a tool, not adding one. Match architecture to real scale. Kubernetes for a 3-person team shipping a CRUD app is a red flag, not a credential.
- **Influence without authority.** Driving adoption of standards across teams you don't manage, through demonstrated value and good docs.

## Hands-on milestone
1. Extract your Stage 1–6 pipeline into a **reusable workflow** and consume it from a second repo. Prove a fix in one place propagates everywhere.
2. Write a one-page **Architecture Decision Record (ADR)** for one real choice (e.g. "blue-green vs rolling for service X"), naming the trade-offs, the decision, and the conditions under which you'd revisit it.
3. Add **concurrency control** so two deploys to the same environment can't race, and cancel superseded CI runs.
4. Write a short **runbook**: how to deploy, how to roll back, how to deploy manually when CI is down, and who to call.

## Senior insights
- **The pipeline is a product with users (your developers).** Apply product thinking: reduce their friction, measure their satisfaction, iterate. A pipeline people route around has failed regardless of its technical merits.
- **Conway's Law applies to delivery.** Your pipeline structure will mirror your org structure; designing one is partly an org-design act.
- **Document the *why*, not just the *how*.** ADRs and runbooks outlive the people who wrote them and are how knowledge scales past you.
- **Resilience over perfection.** Assume things break; optimize for fast, calm recovery and continuous improvement.

## Self-check (staff-level interview drills)
1. You're handed 40 repos with 40 slightly-different, half-insecure pipelines. What's your strategy to standardize without halting any team's delivery?
2. When is adopting Kubernetes/GitOps the *wrong* call? Argue both sides.
3. Walk through how you'd take a team from manual SSH deploys to Continuous Delivery over a quarter, keeping shipping the whole time.
4. Your CI bill tripled. Name five levers to cut cost and the trade-off of each.
5. Write the trade-off statement for choosing canary deployment for a payments service — name what it costs and what it buys, and the prerequisite you'd insist on first.
6. How do you make compliance/governance automated rather than a bottleneck? Give a concrete example.
