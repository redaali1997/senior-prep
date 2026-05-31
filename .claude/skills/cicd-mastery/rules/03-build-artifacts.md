# Stage 2 — Build & Artifacts (Docker)

## Objectives
- Produce **one immutable, versioned artifact** that is promoted unchanged from dev → staging → prod.
- Understand container images: layers, caching, multi-stage builds, slim/secure images.
- Tag and store artifacts in a registry with a traceable version scheme.

## Core concepts (the why)

**Build once, promote everywhere.** The cardinal rule. If you rebuild per environment, staging and prod are *different binaries* and your testing proves nothing about what ships. Build a single artifact, then change only *configuration* (env vars, secrets) per environment. The artifact is immutable; config is injected at runtime.

**Why containers.** A Docker image bundles the app + its runtime + its OS-level deps into one portable, reproducible unit. "Works on my machine" dies because the machine ships *with* the app. The image is your artifact.

**Image layers & build cache.** A Dockerfile is a stack of layers; each instruction is a cached layer invalidated when its inputs change. Order instructions **least-changing → most-changing**:
```dockerfile
COPY composer.json composer.lock ./   # changes rarely
RUN composer install --no-dev          # cached unless lock changes
COPY . .                               # changes every commit
```
Copy the lockfile and install deps *before* copying source, so dependency installation stays cached across code-only changes.

**Multi-stage builds** keep the final image small and free of build tools. Build/compile in a fat "builder" stage, then copy only the runtime artifacts into a slim final stage:
```dockerfile
FROM composer:2 AS vendor
COPY composer.* ./
RUN composer install --no-dev --no-scripts --prefer-dist

FROM node:22 AS assets
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM php:8.4-fpm-alpine AS app
COPY --from=vendor /app/vendor ./vendor
COPY --from=assets /app/public/build ./public/build
COPY . .
```
Smaller images = faster pulls, smaller attack surface, lower cost.

**Versioning / tagging scheme.** Tags must be traceable back to a commit. Good practice: tag images with **both** an immutable identifier (the git SHA, e.g. `app:1a2b3c4`) and a moving pointer (`app:latest` or semver `app:1.4.2`). The SHA tag is what you actually deploy and roll back to — `latest` is a convenience that should never be trusted in production.

**Registry.** Images live in a container registry (GitHub Container Registry, Docker Hub, ECR, GCR). The registry is your artifact store; the deploy step *pulls by digest/tag*, it does not rebuild.

**Provenance & reproducibility.** A senior aims for builds reproducible from source: pinned base images (`php:8.4-fpm-alpine`, ideally by digest), pinned dependency versions (lockfiles committed), no `apt-get` without version pins where it matters. This is the foundation for the supply-chain work in Stage 4.

## Hands-on milestone
Write a multi-stage Dockerfile for the Laravel app that:
- installs composer deps in a cached layer keyed on `composer.lock`,
- builds frontend assets with `npm run build` in a separate stage,
- copies only `vendor/` + `public/build` + source into a slim PHP-FPM final image.

Then add a CI job that builds the image and tags it with the git SHA, and pushes to GitHub Container Registry. Confirm a code-only change reuses the dependency layer cache (build is fast); a `composer.lock` change rebuilds it.

## Senior insights
- **Don't bake secrets into images.** Anything `COPY`'d or `ENV`'d is in the image layers forever, extractable by anyone who pulls it. Secrets are injected at *runtime*, never build time. (More in Stage 4.)
- **`.dockerignore` matters** — exclude `.git`, `node_modules`, `.env`, `vendor` (if built in-image) to shrink context and avoid leaking files.
- **Pin base images, ideally by digest.** `latest` base images make builds non-reproducible and silently pull in changes.
- **One process per container** is the conventional model; use the orchestrator (or `supervisord` deliberately) for multi-process needs like queue workers.
- **The image is the contract between Dev and Ops.** Once teams ship images, "it failed in prod but not staging" almost always means a *config/data* difference, not a code one — which is exactly what you want, because config diffs are easy to find.

## Self-check (senior interview drills)
1. Why is "build once, promote the same artifact" non-negotiable, and what specifically breaks if you rebuild per environment?
2. Your Docker build reinstalls all dependencies on every single commit even when only app code changed. What's wrong with the Dockerfile and how do you fix it?
3. Why tag images with the git SHA and not just `latest`? Which tag do you roll back to and why?
4. What does a multi-stage build buy you over a single-stage build? Give two concrete benefits.
5. A teammate adds `ENV DB_PASSWORD=...` to the Dockerfile "to make it work." Explain the problem and the correct approach.
