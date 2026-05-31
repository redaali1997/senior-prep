# Stage 3 — Continuous Delivery & Deployment

## Objectives
- Promote one artifact through environments (dev → staging → prod) with config-only differences.
- Master deployment strategies: recreate, rolling, blue-green, canary — and when each fits.
- Achieve **zero-downtime** deploys and a **tested, fast rollback**.

## Core concepts (the why)

**Environments are config, not rebuilds.** Promote the *same image/artifact* from Stage 2 through each environment, changing only injected config. Staging must mirror production closely (same image, similar infra) or it tests nothing meaningful.

**Promotion gates.** Between stages sit gates: automated (smoke tests pass, health check green) and manual (a human approval for prod in Continuous *Delivery*). Continuous *Deployment* removes the manual gate and relies entirely on automated confidence.

**Deployment strategies — the core senior decision:**

| Strategy | How | Downtime | Rollback | Cost | Use when |
|---------|-----|----------|----------|------|----------|
| **Recreate** | Stop old, start new | Yes | Redeploy old | Low | Dev only, or when downtime is acceptable |
| **Rolling** | Replace instances batch by batch | No | Roll back batch by batch (slow) | Low | Default for stateless services; mixed versions run briefly |
| **Blue-Green** | Two full envs; flip traffic blue→green | No | Flip back instantly | High (2× infra) | Fast rollback critical; can afford double infra |
| **Canary** | Send 1%→10%→100% to new version, watch metrics | No | Stop rollout, drain canary | Medium | Large blast radius; you have good observability |

The senior judgment: **blue-green buys instant rollback at the cost of double infra; canary buys risk reduction at the cost of needing real observability to make the gradual decision.** Don't pick canary if you can't measure error rate per cohort — you'd just be deploying slowly and blindly.

**Zero-downtime requires more than a strategy.** You also need:
- **Health checks / readiness probes** — don't route traffic to an instance until it reports ready.
- **Graceful shutdown** — drain in-flight requests before killing the old instance.
- **Backward-compatible database migrations** (the hard part — see below).

**Database migrations are where zero-downtime deploys go to die.** During a rolling/canary deploy, old and new code run *simultaneously* against *one* database. So migrations must be **backward compatible**:
- Use the **expand/contract (parallel change)** pattern: (1) *expand* — add the new column/table, deploy code that writes both old and new; (2) *migrate* data; (3) *contract* — remove the old column in a later deploy once no code reads it.
- Never rename or drop a column in the same deploy that stops using it. Never make a migration that the currently-running old code can't tolerate.
- Keep migrations fast and non-locking on large tables (watch for full-table locks).

**Rollback is a feature you must test.** "We'll just redeploy the old version" is not a rollback plan until you've *practiced* it. Know your rollback time. Blue-green: seconds. Rolling: minutes. Forward-fix vs roll-back is a real-time incident decision — seniors pre-decide the criteria.

## Hands-on milestone
Take the image from Stage 2 and build a delivery pipeline that, on merge to `main`:
1. deploys to **staging** automatically,
2. runs smoke tests / health check against staging,
3. waits for a **manual approval** gate,
4. deploys to **production** with zero downtime (rolling or blue-green on your platform),
5. runs migrations using the expand/contract approach,
6. and has a documented, *tested* rollback (actually trigger it once).

For Laravel/Forge/Cloud specifics, see `09-laravel-pipeline.md`.

## Senior insights
- **Decouple deploy from release.** *Deploying* code (putting the artifact on servers) and *releasing* a feature (making it visible to users) are different events. Feature flags let you deploy dark and release later — this is the bridge to Stage 6 and the key to safe trunk-based development.
- **Idempotent deploys.** Running the deploy twice must be safe. Migrations guarded so they don't double-apply; config converging to a desired state, not mutating blindly.
- **Smoke test after deploy, every time.** A trivial "is the homepage 200, is `/health` green" check catches the catastrophic deploy in 10 seconds.
- **Maintenance mode is a last resort, not a strategy.** `php artisan down` is honest for true breaking changes, but the goal is to design changes that never need it.

## Self-check (senior interview drills)
1. Compare blue-green vs canary: what does each cost you and what does each buy you? When would you *refuse* canary?
2. During a rolling deploy you need to rename `users.name` to `users.full_name`. Walk through the exact migration sequence that keeps both old and new code working.
3. What's the difference between deploying and releasing, and why does decoupling them make trunk-based development safe?
4. Your rollback "plan" is "redeploy the previous tag." Why is that not yet a plan, and what would make it one?
5. Why must staging use the same artifact as production rather than its own build?
