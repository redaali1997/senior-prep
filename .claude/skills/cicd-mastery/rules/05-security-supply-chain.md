# Stage 4 — Secrets, Security & Supply Chain (DevSecOps)

## Objectives
- Manage secrets so they never touch source, logs, or image layers.
- Shift security *left*: scan dependencies, code, and images inside the pipeline.
- Understand supply-chain integrity: SBOMs, provenance, signing, least-privilege pipelines.

## Core concepts (the why)

**Secrets management — the rules:**
- **Never** commit secrets to git (a committed secret is compromised forever — rotate it, don't just delete it).
- **Never** bake secrets into image layers (extractable by anyone who pulls the image).
- Inject secrets at **runtime** via the platform's secret store (GitHub Actions encrypted secrets/OIDC, Vault, AWS/GCP Secrets Manager, Doppler, platform env vars).
- **Least privilege + short-lived.** Prefer **OIDC federation** over long-lived cloud keys: the pipeline exchanges a short-lived token scoped to exactly what it needs, so there's no static credential to leak.
- **Rotate** regularly and on any suspicion. Scope each secret to the narrowest environment.

**Shift-left security — the four scanners every pipeline should run:**
- **SCA (Software Composition Analysis)** — scans your *dependencies* for known CVEs (Dependabot, `composer audit`, `npm audit`, Trivy, Snyk). Most vulnerabilities live in third-party deps, not your code.
- **SAST (Static Application Security Testing)** — scans *your source* for vulnerable patterns (SQL injection, XSS) without running it (Semgrep, CodeQL).
- **Secret scanning** — detects committed credentials (Gitleaks, TruffleHog, GitHub secret scanning). Run on every push *and* on history.
- **Container/image scanning** — scans the built image's OS packages and layers for CVEs (Trivy, Grype). Also **DAST** (dynamic) tests the *running* app for vulnerabilities — slower, run on a deployed environment.

Order them by cost: secret + SCA + SAST on every PR (fast, cheap); image scan on build; DAST against staging (slow).

**Supply-chain integrity — the senior frontier:**
- **SBOM (Software Bill of Materials)** — a machine-readable inventory of every component in your artifact (SPDX/CycloneDX format). When the next Log4Shell drops, an SBOM lets you answer "are we affected?" in minutes instead of days. Generate it in CI (`syft`, `cdxgen`).
- **Provenance / attestation** — cryptographically signed evidence of *how and from what* an artifact was built (SLSA framework, GitHub artifact attestations). Lets a consumer verify the image really came from your pipeline and wasn't tampered with.
- **Image signing** — sign images (`cosign`) so deployers can verify authenticity before running.
- **Pin and verify third-party actions/dependencies** — an unpinned `uses: some/action@main` runs whatever that repo pushes; pin to a SHA. This is the exact vector behind real-world CI supply-chain attacks.

**Pipeline as attack surface.** The CI system has access to your code, your secrets, and your production. Treat it as production-critical: least-privilege tokens, no untrusted PR code running with secrets (beware `pull_request_target`), review changes to workflow files like you'd review prod IAM.

## Hands-on milestone
Harden the pipeline:
1. Add `composer audit` and `npm audit` (or Trivy) as an SCA gate.
2. Add a secret scanner (Gitleaks) on every push.
3. Add Semgrep or CodeQL SAST on PRs.
4. Scan the built Docker image with Trivy and fail on HIGH/CRITICAL.
5. Generate an SBOM (`syft`) and attach it as a build artifact.
6. Replace any long-lived cloud key with OIDC, or at minimum move all secrets into the platform's encrypted secret store and confirm none appear in logs or image layers.
7. Pin every third-party action to a commit SHA.

## Senior insights
- **A failed scan must be actionable, not noise.** Tune severity gates (fail on HIGH/CRITICAL, report the rest) and triage. A pipeline that cries wolf on every transitive low-severity CVE gets ignored — same failure mode as flaky tests.
- **Secrets in CI logs are a classic leak.** Ensure the platform masks them and never `echo` a secret for "debugging."
- **`composer audit` is free and built-in** — there's no excuse for a Laravel pipeline not to run it.
- **The pipeline's own permissions are the prize.** Compromising CI is more valuable than compromising one server, because CI can deploy to *all* servers. Minimize its standing access.

## Self-check (senior interview drills)
1. Distinguish SCA, SAST, DAST, and secret scanning — what does each catch that the others miss?
2. A secret was committed to git, then removed in the next commit. Is it safe now? What must you actually do?
3. What is an SBOM and what concrete incident does it make survivable? Give the day-it-matters scenario.
4. Why is OIDC federation safer than storing a long-lived cloud access key in CI secrets?
5. Why pin a GitHub Action to a commit SHA instead of a tag or branch? What attack does this prevent?
