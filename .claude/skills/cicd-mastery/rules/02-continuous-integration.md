# Stage 1 — Continuous Integration

## Objectives
- Make every push automatically build, lint, statically analyze, and test.
- Make a red pipeline *block merge* — a green main is non-negotiable.
- Make CI fast: cache dependencies, parallelize, fail fast, order checks cheap→expensive.

## Core concepts (the why)

**The CI pipeline is a contract: nothing reaches `main` unless it's proven.** The mechanism is **branch protection** + **required status checks**. Without enforcement, CI is a suggestion.

**The standard CI job order (cheap → expensive, fail fast):**
1. **Checkout** the code.
2. **Restore caches** (dependency cache keyed on the lockfile hash).
3. **Install dependencies** (only on cache miss).
4. **Lint / format check** — fast, catches style early (Pint for PHP, ESLint/Prettier for JS).
5. **Static analysis** — type/bug checks without running code (PHPStan/Larastan, Psalm).
6. **Tests** — unit → feature/integration → browser/e2e (slowest last).
7. **Coverage / quality gate** (optional) — fail if coverage drops below threshold.

Order matters: a 2-second lint failure should not wait behind a 4-minute test run. Put the cheapest, most-likely-to-fail checks first.

**Caching is the highest-leverage speed win.** Key the cache on the hash of your lockfile (`composer.lock`, `package-lock.json`). Cache hit = skip a fresh install. This often cuts pipeline time by half or more.

**Matrix builds** run the same job across combinations (PHP 8.3 + 8.4, MySQL + Postgres) in parallel. This is how you prove compatibility without serial cost.

**Parallelization & sharding.** Independent jobs run concurrently. Large test suites can be *sharded* across N runners (split the suite, run pieces simultaneously, aggregate). Pest supports parallel execution (`--parallel`).

**Ephemeral, reproducible environments.** Each job runs on a clean runner. If it passes only because of leftover state, it's a flaky lie. Spin up service containers (a real MySQL/Redis) per run rather than mocking the world.

**Flaky tests are a senior-level emergency, not an annoyance.** A test that fails 1% of the time trains the team to ignore red — which destroys the entire value of CI. Quarantine, fix, or delete flakes. A trusted suite is the asset; an untrusted one is worse than none.

## Hands-on milestone
Add a GitHub Actions workflow that, on every push and PR:
- restores a composer cache keyed on `composer.lock`,
- runs `vendor/bin/pint --test` (style),
- runs your static analysis,
- runs `php artisan test --parallel`,
- and is set as a **required status check** in branch protection so red blocks merge.

See `09-laravel-pipeline.md` for the concrete YAML. Verify it by opening a PR that intentionally breaks a test and confirming merge is blocked.

## Senior insights
- **Fail fast, but report fully.** Stop the pipeline on the first stage failure to save minutes — but within a stage, let all tests run so you see every failure, not just the first.
- **Pin your versions.** `actions/checkout@v4`, not `@main`. Unpinned actions are a supply-chain risk and a reproducibility hole.
- **Pre-commit hooks ≠ CI.** Local hooks (Husky, lint-staged) give instant feedback but can be skipped; CI is the enforced backstop. Use both — hooks for speed, CI for trust.
- **Budget your pipeline time.** Under ~10 min for the PR loop is a good target; beyond that people batch changes and CI loses its purpose. Treat pipeline duration as a first-class metric.

## Self-check (senior interview drills)
1. Your CI takes 25 minutes and devs have started batching changes to avoid the wait. Name three concrete levers to cut it and order them by leverage.
2. Why run lint before tests instead of after?
3. A test passes locally and on reruns but fails ~5% of the time in CI. Walk through how you'd diagnose and what you'd do *today* to protect the team's trust in the suite.
4. What is a required status check and why is CI without one merely "decorative"?
5. How does keying a cache on `composer.lock` work, and what breaks if you key it on the branch name instead?
