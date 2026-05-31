# Stage 5 — Observability & DORA Metrics

## Objectives
- Measure delivery performance with the four DORA metrics.
- Instrument the pipeline and the running app: logs, metrics, traces, health checks.
- Close the loop: deploys emit signals, and bad signals trigger automated response.

## Core concepts (the why)

**You can't improve what you don't measure.** A senior doesn't *assert* the pipeline is good — they show the numbers and the trend.

**The four DORA metrics** (the research-backed measures of software delivery performance):
1. **Deployment Frequency** — how often you deploy to production. Elite teams deploy on demand, multiple times a day.
2. **Lead Time for Changes** — commit → running in production. Elite: under an hour.
3. **Change Failure Rate** — % of deploys that cause a failure needing remediation. Elite: 0–15%.
4. **Mean Time to Restore (MTTR)** — how long to recover from a failure. Elite: under an hour.

The genius of DORA: the first two measure **speed**, the last two measure **stability**, and the research shows they are *not* a trade-off — elite teams are better at *both*. Going faster *safely* (small batches, automation, good rollback) improves all four. If someone claims "we must slow down to be stable," DORA is your evidence-based rebuttal. (A fifth, **reliability**, was added later.)

**The three pillars of observability** (for the running app, which CI/CD must support):
- **Logs** — discrete events ("user 5 checkout failed"). Structured (JSON) and centralized, not `dd()` on a server.
- **Metrics** — aggregated numbers over time (request rate, error rate, p95 latency, queue depth). Cheap to store, great for dashboards and alerts.
- **Traces** — the path of one request across services. Essential once you have more than one service.

**Health checks are the pipeline's eyes.** A `/health` (liveness) and `/ready` (readiness) endpoint let the deploy system decide whether to route traffic and whether the deploy succeeded. Readiness should check real dependencies (DB, cache) reachable.

**Closing the loop — deploys as observable events:**
- **Mark deploys on your dashboards** (a deploy annotation). When error rate spikes, the first question is always "what changed?" — the deploy marker answers it instantly. This is the fastest MTTR win available.
- **Automated rollback on bad signals.** Canary analysis: after shifting traffic, watch error rate / latency for N minutes; if it breaches a threshold, auto-abort and roll back. This is how Change Failure Rate stays low *and* you keep deploying fast.
- **Alert on symptoms, not causes.** Alert on "checkout error rate > 2%" (user impact), not "CPU > 80%" (a cause that may not matter).

## Hands-on milestone
1. Add a `/health` and `/ready` endpoint to the app; have the deploy gate on `/ready` returning 200.
2. Emit a **deploy event** (timestamp + git SHA) to wherever you can see app metrics (even a logged structured event to start).
3. Start tracking the four DORA metrics — even a manual spreadsheet for a month builds the instinct. Capture: deploys/week, commit→prod time, % of deploys that needed a hotfix/rollback, time-to-recover.
4. Add a post-deploy smoke check that, on failure, automatically triggers the rollback from Stage 3.

## Senior insights
- **Vanity vs actionable metrics.** "95% test coverage" is vanity if the tests are weak. DORA metrics are actionable because they measure *outcomes* the business feels.
- **MTTR > prevention, past a point.** You cannot prevent all failures. Investing in *fast detection and recovery* (good rollback, observability, deploy markers) often beats chasing the last 1% of prevention. Designing for recoverability is a senior mindset.
- **Observability is a feature you build, not buy and forget.** Instrumentation that nobody looks at is dead weight; wire metrics to dashboards people actually watch and alerts people actually get paged on.
- **Correlate deploy → metric.** The single highest-ROI observability practice is the deploy annotation overlaid on error/latency graphs.

## Self-check (senior interview drills)
1. Name the four DORA metrics and which two measure speed vs stability. Why is "we must trade speed for stability" wrong according to the research?
2. Differentiate logs, metrics, and traces — which would you reach for to debug "checkout is slow for 5% of users"?
3. What's the difference between a liveness and a readiness probe, and why does the deploy system care about readiness specifically?
4. Describe automated canary analysis: what signals do you watch and what do you do when they breach?
5. Your error rate spiked at 14:03. What's the first dashboard question, and what instrumentation makes it answerable in seconds?
