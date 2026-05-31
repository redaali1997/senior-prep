# Stage 0 — Foundations & Mental Models

## Objectives
- Define CI, Continuous Delivery, and Continuous Deployment precisely and stop confusing them.
- Understand *why* automation exists: shrinking the feedback loop and the batch size.
- Speak the vocabulary: pipeline, stage, job, step, runner, artifact, trigger, gate.

## Core concepts (the why)

**The feedback loop is the whole game.** Every CI/CD practice exists to shorten the time between "I changed something" and "I have trusted evidence it's safe." Slow feedback = large batches = big, scary, hard-to-debug releases. Fast feedback = small batches = boring, safe, frequent releases. Internalize: *boring releases are the goal.*

**CI vs CD vs CD — the precise definitions:**
- **Continuous Integration (CI):** every developer merges small changes to a shared mainline frequently (at least daily), and each merge is automatically built and tested. The point is integration pain → zero, caught early. CI is a *team habit* enabled by automation, not just "we have a test pipeline."
- **Continuous Delivery (CD):** every change that passes CI is *automatically proven releasable* and kept in a deployable state. A human clicks "go" to ship.
- **Continuous Deployment (CD):** same, but there is no human click — passing the pipeline *is* the deploy to production.

The hierarchy: you cannot do Delivery without Integration, nor Deployment without Delivery. Most teams should *master CI and Continuous Delivery* before attempting Continuous Deployment.

**Anatomy of a pipeline:**
- **Trigger / event** — push, PR opened, tag, schedule, manual dispatch.
- **Stage** — a logical phase (build → test → scan → deploy). Stages run in order; gates sit between them.
- **Job** — a unit of work that runs on a **runner** (an ephemeral VM/container). Jobs in a stage can run in parallel.
- **Step** — a command inside a job.
- **Artifact** — a build output passed *between* jobs/stages (a jar, a Docker image, a compiled asset bundle). Artifacts are how you "build once, use many."
- **Gate** — a condition that must pass to proceed (tests green, approval given, scan clean).

**Branching strategy underpins everything.** Two camps:
- **Trunk-based development** — short-lived branches (hours/days), merge to `main` constantly, feature flags hide unfinished work. *This is what high-performing teams do* and what CI was designed for.
- **GitFlow / long-lived release branches** — heavier, more ceremony, slower feedback, painful merges. Appropriate for versioned shipped software (e.g. desktop apps with multiple supported versions), rarely for web apps.

A senior knows trunk-based + small PRs + flags beats GitFlow for continuous web delivery, and can articulate *why* (merge debt, blast radius, bisectability).

## Hands-on milestone
On paper (or a whiteboard/markdown doc), diagram the current delivery process of a real project end-to-end: from "dev writes code" to "users see it." Mark every **manual** step and every **wait**. Circle the slowest feedback point. That circle is your Stage 1 target.

## Senior insights
- The metric that matters is **lead time for change** (commit → in production) and **how often you can do it safely**. Automation is a means, not the goal.
- "We have a CI server" ≠ "we do CI." If branches live for two weeks, you have automated builds, not Continuous Integration.
- Every manual step is a place for human error and a bottleneck on a person. Automate the repeatable; keep humans for judgment (approvals, incident calls).

## Self-check (senior interview drills)
1. A teammate says "we do CI/CD" but features sit on branches for 10 days before merging. What's wrong, and what would you change first?
2. Explain the difference between Continuous Delivery and Continuous Deployment to a non-engineer manager in two sentences.
3. Why are small, frequent deploys *safer* than one big weekly release? Give two concrete mechanisms.
4. What is an "artifact" and why does "build once, deploy many" matter?
