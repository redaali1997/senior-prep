# Laravel/PHP Reference Pipeline (GitHub Actions)

Concrete, copy-adaptable examples for this stack (Laravel 13, PHP 8.4, Pest 4, Pint). Teach the universal principle from the other modules *first*, then ground it here. Pin action SHAs in real use (tags shown for readability).

## Stage 1 — CI: lint + static analysis + tests

`.github/workflows/ci.yml`:
```yaml
name: CI
on:
  push: { branches: [main] }
  pull_request:

concurrency:                       # cancel superseded runs on the same ref (cost + speed)
  group: ci-${{ github.ref }}
  cancel-in-progress: true

jobs:
  quality:
    runs-on: ubuntu-latest
    services:
      mysql:                       # real DB, not mocked — ephemeral per run
        image: mysql:8
        env: { MYSQL_DATABASE: testing, MYSQL_ROOT_PASSWORD: password }
        ports: ['3306:3306']
        options: >-
          --health-cmd="mysqladmin ping" --health-interval=10s
          --health-timeout=5s --health-retries=5
    steps:
      - uses: actions/checkout@v4

      - uses: shivammathur/setup-php@v2
        with:
          php-version: '8.4'
          coverage: pcov
          tools: composer:v2

      - name: Cache composer deps        # highest-leverage speed win, keyed on the lockfile
        uses: actions/cache@v4
        with:
          path: vendor
          key: composer-${{ hashFiles('composer.lock') }}
          restore-keys: composer-

      - run: composer install --no-interaction --prefer-dist --no-progress

      - name: Lint / style (cheap, first)
        run: vendor/bin/pint --test

      - name: Static analysis            # add Larastan/PHPStan when present
        run: vendor/bin/phpstan analyse --no-progress
        continue-on-error: true          # set false once your baseline is clean

      - name: Tests (expensive, last)
        env:
          DB_CONNECTION: mysql
          DB_HOST: 127.0.0.1
          DB_DATABASE: testing
          DB_USERNAME: root
          DB_PASSWORD: password
        run: php artisan test --parallel --compact

      - name: Security audit             # free, built-in SCA — Stage 4
        run: composer audit
```
Then in **branch protection** for `main`: require the `quality` check + require PRs. Red now blocks merge — that's the contract from `02-continuous-integration.md`.

> **Frontend note:** if assets matter to a test (browser/smoke tests), add a Node step: `actions/setup-node@v4` + cache on `package-lock.json` + `npm ci && npm run build` before the test step.

## Stage 2 — Build image, tag by SHA, push to GHCR

`Dockerfile` (multi-stage, see `03-build-artifacts.md` for the why):
```dockerfile
# --- composer deps (cached on lockfile) ---
FROM composer:2 AS vendor
WORKDIR /app
COPY composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --no-interaction --prefer-dist

# --- frontend assets ---
FROM node:22-alpine AS assets
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# --- slim runtime ---
FROM php:8.4-fpm-alpine AS app
WORKDIR /var/www
RUN docker-php-ext-install pdo_mysql bcmath
COPY --from=vendor /app/vendor ./vendor
COPY --from=assets /app/public/build ./public/build
COPY . .
RUN php artisan config:cache && php artisan route:cache && php artisan view:cache
```
`.github/workflows/build.yml` (runs after CI passes on `main`):
```yaml
name: Build
on:
  push: { branches: [main] }
permissions:
  contents: read
  packages: write                  # least privilege
jobs:
  image:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}     # short-lived, scoped token
      - uses: docker/build-push-action@v6
        with:
          push: true
          tags: |
            ghcr.io/${{ github.repository }}:${{ github.sha }}
            ghcr.io/${{ github.repository }}:latest
          cache-from: type=gha
          cache-to: type=gha,mode=max
```
The **immutable** tag is `:${{ github.sha }}` — that's what you deploy and roll back to. `:latest` is convenience only.

## Stage 3 — Deploy with zero downtime

**Option A — Laravel Cloud / Forge (recommended for this stack).** These platforms handle zero-downtime atomic deploys (symlink swap) for you. Trigger via a deploy hook after build:
```yaml
  deploy-staging:
    needs: image
    runs-on: ubuntu-latest
    environment: staging            # GitHub Environments = approval gates + scoped secrets
    steps:
      - run: curl -fsS "${{ secrets.FORGE_STAGING_DEPLOY_HOOK }}"

  deploy-production:
    needs: deploy-staging
    runs-on: ubuntu-latest
    environment: production         # add required reviewers here = manual gate (Cont. Delivery)
    steps:
      - run: curl -fsS "${{ secrets.FORGE_PROD_DEPLOY_HOOK }}"
```
The Forge/Cloud deploy script runs migrations and rebuilds caches. The atomic symlink swap is the zero-downtime mechanism.

**Migrations — backward compatible (expand/contract).** During the swap, old and new code briefly coexist. Follow `04-delivery-deployment.md`: add columns in one deploy, backfill, switch reads/writes, drop in a *later* deploy. Run `php artisan migrate --force` in the deploy script; never rename/drop a column the running code still needs.

**Smoke test + rollback:**
```yaml
      - name: Smoke test
        run: curl -fsS https://app.example.com/health || exit 1
      # On failure: re-trigger the previous SHA's deploy hook, or use the
      # platform's one-click "redeploy previous" — and have practiced it.
```

## Stage 4 hooks (security)
- `composer audit` (already above) + `npm audit --omit=dev`.
- Image scan: add a `aquasecurity/trivy-action` step on the built image, fail on `CRITICAL,HIGH`.
- Secret scan: `gitleaks/gitleaks-action`.
- SBOM: `anchore/sbom-action` (syft) → upload as artifact.

## Stage 6 hooks (progressive delivery)
- Feature flags: **Laravel Pennant** (`Feature::active('new-checkout')`). Deploy dark, enable per-cohort, kill instantly — no redeploy.

## Laravel-specific gotchas
- **`config:cache` + env:** once cached, `env()` returns null outside config files. Only call `env()` inside `config/*.php`; everywhere else use `config()`. Cache config in the image/deploy, never read `env()` at runtime in app code.
- **Queue workers** must be **restarted on deploy** (`php artisan queue:restart`) or they run stale code from the previous release.
- **Storage symlink** (`php artisan storage:link`) and writable `storage/`, `bootstrap/cache` permissions in the image.
- **Migrations in CI** run against the ephemeral service DB; in deploy run with `--force` (non-interactive).
- **Octane/long-running**: if using Octane, a deploy must reload workers to pick up new code.

## The portfolio outcome
One repo wiring CI (this file) → image build → staging → gated prod → smoke test → flagged feature → tracked DORA metrics. That single end-to-end repo is the strongest senior-interview artifact you can bring — it demonstrates every stage concretely.
