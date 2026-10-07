# Session 20: Monitoring, Observability & GitOps

## Task 1: Monitoring

"Is the system healthy?" — answered with real numbers from the cluster's own
`metrics-server` (installed since [Session 13](../12-kubernetes-storage-hpa-probes)).
Transcript: [`task1-monitoring-observability.txt`](task1-monitoring-observability.txt).

```bash
kubectl top nodes
# colima   785m   39%   1382Mi   47%
kubectl top pod mon-demo
# mon-demo   0m   2Mi
```

Monitoring is built from exactly this kind of number: CPU%, memory%, request count,
error rate — each one checked against a threshold (`IF error_rate > 5% THEN alert`).
It answers *whether* something is wrong, not *why*.

## Task 2: Observability

The three signals, demonstrated against a real pod:

| Signal | What it is | Demonstrated with |
|---|---|---|
| **Metrics** | Numbers over time | The real Kubernetes metrics API: `kubectl get --raw /apis/metrics.k8s.io/v1beta1/namespaces/default/pods/mon-demo2` — real JSON, real `cpu`/`memory` usage values |
| **Logs** | Discrete, timestamped events | `kubectl logs` — nginx's own startup/access log stream, plus a manual `kubectl exec` writing app-style log lines |
| **Traces** | One request's journey across multiple services, as linked spans | Not installed here — see below |

**Why no tracing backend (Jaeger/Tempo/Zipkin) was installed**: this Mac's disk ran
critically low during this session (documented across [Session 18](../18-terraform-iac)
and [Session 19](../19-cloud-terraform-in-action) — LocalStack alone pushed free space
under 1GB more than once). A tracing backend is multi-container and multi-hundred-MB; with
under 1.5GB free at this point, pulling another stack wasn't a responsible call. What a
trace actually is, conceptually: a single `trace_id` shared across every service a request
touches, with one `span` per hop (its own start/end timestamp, its own duration) — so a
slow request can be broken down into "which specific hop took 1.8 of the 2 total seconds,"
rather than monitoring's flat "latency = 2 seconds."

### Monitoring vs Observability

Monitoring asks "is it healthy?" and answers with dashboards and threshold alerts —
excellent for problems you already know to look for. Observability asks "why is it
behaving this way?" for problems you *didn't* predict — it requires being able to ask new
questions of the system after the fact, which needs metrics **and** logs **and** traces
together, not just a dashboard. A system can be heavily monitored (50 dashboards) and
still not be observable (none of those dashboards can answer "why did this one specific
request from this one specific user fail").

## Task 3: GitOps

A genuinely functional reconciler — not a mock — proving the real GitOps loop:
**Git = desired state → reconciler = sync engine → Kubernetes = actual state**, with
automatic self-healing. Transcript: [`task2-gitops-demo.txt`](task2-gitops-demo.txt),
reconciler: [`gitops-demo/reconciler.sh`](gitops-demo/reconciler.sh).

```bash
bash reconciler.sh 5 &     # polls gitops-demo/app/ every 5s, kubectl apply's it
```

1. First poll creates the Deployment + Service from the manifests — `2/2` replicas.
2. `app/deployment.yaml` edited `replicas: 2` → `replicas: 3` (standing in for a real
   `git commit && git push` — a repo-watching reconciler reacts identically either way).
3. Reconciler's next poll picks it up automatically → `3/3`.
4. **Manual drift**, bypassing Git entirely: `kubectl scale --replicas=1` → `READY 3/1`.
5. Reconciler's next poll sees live state (1) ≠ desired state in the file (3) →
   re-applies → back to `3/3`, with **zero human intervention**. That's self-healing.

### Why a hand-rolled reconciler instead of real ArgoCD

The reference curriculum's Session 20 mini-project installs ArgoCD (`argocd-server`,
`repo-server`, `application-controller`, `dex`, `redis` — 5+ images, typically 800MB–1.5GB
combined) into a fresh `kind` cluster. Given the disk situation at this point in the
session, pulling that whole stack risked pushing this Mac's disk to zero — a real
machine-stability risk, not just a homework risk. The reconciler script above is a
genuinely smaller version of the *exact same mechanism* ArgoCD automates: watch a source
of truth, continuously diff it against live state, re-apply on drift. ArgoCD adds a web
UI, RBAC, multi-cluster/multi-app management, and SSO on top of that same core loop — none
of which changes what the loop itself *does*, which is what this demo proves hands-on.

### A real bug, hit and fixed mid-demo

The reconciler died silently after its first iteration — `kubectl apply -f app/` submits
every file in the directory as one batch, and on a truly fresh cluster the Deployment
(inside the `gitops-demo` namespace) got submitted before the Namespace object had
actually finished being created in that same batch, failing. The script had `set -e`,
so that single failure killed the whole loop instantly. Fixed by applying
`namespace.yaml` explicitly first (idempotent on every later iteration), then the rest —
a genuine `kubectl apply` ordering gotcha, not anything GitOps-specific. See
[`task2-gitops-demo.txt`](task2-gitops-demo.txt) for the full before/after.

### Viva answers

1. **Monitoring vs Observability** — monitoring answers "is it healthy" with known
   thresholds; observability answers "why" for problems you didn't predict in advance.
2. **Metrics vs Logs vs Traces** — numbers over time, discrete timestamped events, and a
   request's cross-service journey as linked spans, respectively.
3. **What is Prometheus?** — a metrics-focused time-series database that *pulls*
   (scrapes) metrics from configured HTTP endpoints on an interval and stores them for
   querying (PromQL) and alerting.
4. **What is Grafana?** — a dashboarding/visualization layer that queries data sources
   like Prometheus and renders them as graphs, typically paired with Prometheus rather
   than replacing it.
5. **What is GitOps?** — an operational model where Git is the single source of truth for
   a system's desired state, and an automated agent continuously reconciles live
   infrastructure to match it.
6. **Why is Git the source of truth?** — every change is a commit: reviewable (PRs),
   auditable (`git log`/`git blame`), and revertible (`git revert`) — properties a
   `kubectl apply` run from someone's laptop has none of.
7. **What does Argo CD do?** — watches a Git repo, diffs it against the live cluster, and
   syncs (applies) any difference — the production-grade version of this session's
   `reconciler.sh`.
8. **Desired state** — what the manifests in Git say *should* exist.
9. **Actual state** — what's *actually* running in the cluster right now.
10. **Reconciliation** — the act of comparing desired vs actual and taking action to
    close any gap.
11. **Self-healing (in this context)** — if actual state drifts from desired state for
    *any* reason, including manual intervention, the reconciler corrects it automatically
    on its next pass — demonstrated concretely in step 4–5 above.
12. **What happens when replicas changes from 2 to 3 in Git?** — nothing immediately; the
    reconciler's *next poll* notices the diff and applies it — there's an inherent (small,
    configurable) delay between "Git says X" and "cluster is X," which is the real
    trade-off GitOps makes for safety and auditability over instant manual changes.

Screenshot: [`../screenshots/19-monitoring-gitops.png`](../screenshots/19-monitoring-gitops.png)
