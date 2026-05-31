# Stage 6 — Progressive Delivery, Feature Flags & GitOps

## Objectives
- Decouple deploy from release with feature flags and roll out by cohort.
- Understand Infrastructure as Code (IaC) and GitOps: Git as the single source of truth.
- Combine flags + progressive rollout + observability into safe, gradual change.

## Core concepts (the why)

**Feature flags — release control in the app, not the pipeline.** A flag wraps new behavior in a runtime switch. You **deploy** the code dark (flag off) and **release** by flipping the flag — for everyone, or a cohort (internal users → 5% → 50% → 100%). Benefits:
- **Trunk-based development becomes safe**: unfinished features merge to main behind an off flag, so there are no long-lived branches.
- **Instant kill switch**: a bad feature is disabled by flipping a flag — no redeploy, no rollback, seconds not minutes.
- **Experimentation**: A/B tests, gradual exposure, targeting by user attribute.

Cost: flags are debt. Each is a branch in your code and your testing matrix. **Remove stale flags** — a graveyard of dead flags is a senior-level mess.

**Progressive delivery = canary + flags + automated analysis.** It's the generalization of Stage 3's canary: expose change to a growing cohort, *automatically analyze* metrics at each step (Stage 5), and promote or abort. Tools: Argo Rollouts, Flagger, LaunchDarkly. The pipeline doesn't just deploy — it *conducts a gradual, measured rollout*.

**Infrastructure as Code (IaC).** Servers, networks, databases, DNS — defined in version-controlled code (Terraform, OpenTofu, Pulumi, CloudFormation), not clicked into a console. Benefits: reproducible environments, peer-reviewed infra changes, disaster recovery by re-apply, no "snowflake" servers nobody dares touch. **Declarative** (describe the desired state, the tool reconciles) beats **imperative** (list the steps).

**GitOps — Git as the source of truth for *operations*.** The desired state of your *system* (which image version, how many replicas, what config) lives in a Git repo. An agent in the cluster (Argo CD, Flux) continuously **reconciles** reality to match Git:
- **Deploy = a Git commit/PR** to the manifests repo. Full audit trail, review, and revert via standard Git.
- **Drift correction**: if someone manually changes prod, the agent reverts it to match Git. No more undocumented hotfixes.
- **Rollback = `git revert`**. The deploy history *is* the Git history.
- **Pull-based**: the cluster pulls its desired state, so CI never needs standing credentials into prod — a big security win over push-based deploys.

The mental shift: **CI builds and tests the artifact; CD (GitOps) reconciles the declared desired state.** They're separated. CI's job ends at "produce a verified image + update the manifest"; the GitOps agent's job is making the cluster match.

## Hands-on milestone
1. Introduce a feature flag library (Laravel Pennant for this stack) and ship one feature dark: merge it to main with the flag off, then enable it for yourself, then a cohort, then everyone — all without a redeploy.
2. Write the app's infrastructure (or one piece of it) as Terraform/OpenTofu and apply it; make a change *only* by editing code and re-applying — never the console.
3. (Stretch) Stand up Argo CD or Flux against a manifests repo; deploy by committing an image-tag bump and watch the agent reconcile; roll back with `git revert`.

## Senior insights
- **Deploy ≠ release is the unlock.** Once internalized, the whole "scary Friday deploy" culture dissolves: you deploy constantly and release deliberately.
- **Flags need lifecycle governance.** Owner, expiry, and a cleanup task per flag. Treat flag debt like tech debt with a paydown schedule.
- **GitOps's superpower is the audit trail and drift detection**, not just automation. "Who changed prod and why" is answered by `git log`.
- **IaC state is precious and sensitive.** Terraform state can contain secrets and is the source of truth for what exists — store it remotely, locked, encrypted, access-controlled.
- **Don't cargo-cult Kubernetes/GitOps.** For a small Laravel app on Forge/Cloud, full GitOps is overkill. Senior judgment is matching tooling to actual scale and team size, not resume-driven architecture.

## Self-check (senior interview drills)
1. Explain how feature flags make trunk-based development with frequent merges safe even for half-finished features.
2. A feature is causing errors for 10% of users. Compare your response time with a feature flag vs with a code rollback. Why the difference?
3. What is GitOps and what does "reconciliation" mean? How does `git revert` become a rollback?
4. Declarative vs imperative IaC — what does declarative buy you for drift and disaster recovery?
5. When is full GitOps/Kubernetes the *wrong* choice, and what would you do instead for a small team?
6. What is "feature flag debt" and how do you govern it?
