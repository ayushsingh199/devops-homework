# Session 21: Final DevOps Project & Troubleshooting

An end-to-end DevOps project assembled from the real, independently-proven pieces built
across this entire homework repo — not re-simulated, the actual working artifacts —
plus a live troubleshooting challenge run against a real cluster.

```
Application → Git → GitHub → CI Pipeline → Build & Test → Security Scanning →
Docker Image → Container Registry → Kubernetes → Helm → Monitoring → GitOps
```

## Project Structure

```text
21-final-devops-project/
├── application/        # Flask app + tests (reused from 16-devsecops-pipeline)
├── helm/final-app-chart/  # NEW: Helm chart wrapping the application
├── kubernetes/          # (the Helm chart generates these -- see helm/)
├── security/            # this README section + links to the real scan results
├── troubleshooting/      # the final challenge, run for real
├── .github/workflows/    # reference copy of the proven CI/CD+DevSecOps workflow
└── README.md
```

## Application

[`application/`](application) — the same Flask "DevSecOps Dashboard" app from
[Session 17](../16-devsecops-pipeline), reused deliberately rather than rebuilt: it
already has 8 real passing tests, a working `Dockerfile`, and (most importantly) an
already-**proven** full CI/CD+DevSecOps pipeline running successfully on GitHub's actual
infrastructure. Rebuilding a second, different app for this capstone would not
demonstrate anything new about the pipeline — reusing the proven one and focusing this
session's *new* work on Helm packaging and live troubleshooting is the more honest use of
the remaining time and this Mac's increasingly scarce disk (documented throughout
[Session 18](../18-terraform-iac)–[20](../20-monitoring-observability-gitops)).

## CI/CD + DevSecOps

The real, already-passing pipeline lives at
[`../.github/workflows/session17-devsecops.yml`](../.github/workflows/session17-devsecops.yml)
and its proof-of-execution is in
[`../16-devsecops-pipeline/task3-ci-pipeline-run.txt`](../16-devsecops-pipeline/task3-ci-pipeline-run.txt)
— unit tests → CodeQL (SAST) → pip-audit (SCA) → gitleaks (secret scanning) → Docker build
→ Trivy (container image scan) → push to GHCR → deploy to an ephemeral Kind cluster, with
a live `curl` verifying the deployed app. A reference copy sits at
[`.github/workflows/ci-reference.yml.txt`](.github/workflows/ci-reference.yml.txt) —
deliberately saved as `.txt`, not `.yml`, so it doesn't register as a *second* active
GitHub Actions workflow duplicating the same real pipeline run (and real GitHub Actions
minutes) for no additional evidence.

## Kubernetes + Helm

[`helm/final-app-chart/`](helm/final-app-chart) — a real Helm chart (new work for this
session) wrapping the application: Deployment (2 replicas, readiness/liveness probes
against `/health`) + ClusterIP Service. Deployed for real to the k3s cluster used
throughout this repo (`helm install final-app helm/final-app-chart`), verified with live
`curl`s against `/health` and `/api/status`, then used as the actual target of the
troubleshooting challenge below.

## Terraform (Infrastructure as Code)

Already built and run for real in [Session 18](../18-terraform-iac) (S3) and
[Session 19](../19-cloud-terraform-in-action) (full VPC → Subnet → Internet Gateway →
Route Table → Security Group → EC2 → S3, 8 resources, full init/plan/apply/destroy cycle)
against LocalStack. Not re-run here to avoid re-pulling LocalStack's ~2GB image a third
time on a Mac that has spent much of this session within a few hundred MB of running out
of disk entirely — see those sessions' READMEs for the full real transcripts and the
actual licensing snag (LocalStack `:latest` requiring a paid account) hit and fixed along
the way.

## Monitoring & GitOps

Already demonstrated for real in [Session 20](../20-monitoring-observability-gitops):
live metrics via the cluster's `metrics-server` and the raw `metrics.k8s.io` API, real
logs via `kubectl logs`/`exec`, and a genuinely functional GitOps reconciler proving the
full Git → reconcile → Kubernetes loop including automatic self-healing after manual
drift (with a real `kubectl apply` ordering bug hit and fixed along the way).

## Final Troubleshooting Challenge

Two bugs, injected on purpose into the **live, already-working** `final-app` Helm
release, found and fixed using the same `observe → investigate → root cause → fix →
verify` discipline from [Session 14](../13-kubernetes-troubleshooting) and
[Session 20](../20-monitoring-observability-gitops). Full transcripts:
[`task2-troubleshooting.txt`](task2-troubleshooting.txt),
[`task3-troubleshooting-2.txt`](task3-troubleshooting-2.txt).

### Bug 1 — bad image tag via `helm upgrade`

```bash
helm upgrade final-app helm/final-app-chart --set image.tag=v2-broken
```
- **Observed**: `kubectl get pods` → one pod `ErrImagePull` → `ImagePullBackOff`.
- **Investigated**: `kubectl describe pod` → *"pull access denied for
  final-devops-app, repository does not exist"*.
- **Root cause**: `v2-broken` was never built — only `local` exists.
- **A real, important detail observed along the way**: the Deployment's default
  `RollingUpdate` strategy meant the 2 *old, healthy* pods were **never killed** —
  the app kept serving real traffic through the entire incident. This is Kubernetes'
  built-in deploy safety working exactly as designed, not something this project had to
  build.
- **Fix**: `helm rollback final-app 1`.
- **Verified**: `kubectl get pods` → healthy again; a live `curl` against `/health`
  through the Service confirmed the app was actually serving requests again, not just
  that the Pod objects looked fine.

### Bug 2 — Service selector mismatch, introduced into the chart itself

```yaml
# helm/final-app-chart/templates/service.yaml, broken on purpose:
selector:
  app: {{ .Release.Name }}-WRONG
```
- **Observed**: a `curl` through the Service got `Connection refused` — immediately, not
  a timeout (no endpoint means no DNAT target at all).
- **Investigated**: `kubectl get endpoints final-app-svc` → `<none>`;
  `kubectl describe svc` → `Selector: app=final-app-WRONG`;
  `kubectl get pods --show-labels` → real label is `app=final-app`.
- **Root cause**: a typo in the Service selector — doesn't match any Pod, so the Service
  silently has zero endpoints. Kubernetes never validates this at creation time; it only
  surfaces once something actually tries to connect.
- **Fix**: corrected the selector in the chart template, `helm upgrade`.
- **Verified**: `kubectl get endpoints` → real Pod IPs again;
  `curl http://final-app-svc/health` → healthy response.

### The full incident record

```bash
$ helm history final-app
REVISION  STATUS      DESCRIPTION
1         superseded  Install complete
2         superseded  Upgrade complete      <- Bug 1 introduced
3         superseded  Rollback to 1         <- Bug 1 fixed
4         superseded  Upgrade complete      <- Bug 2 introduced
5         deployed    Upgrade complete      <- Bug 2 fixed
```

Every single step of this incident — break, investigate, fix, verify — is permanently
recorded in Helm's own revision history. Nothing about this troubleshooting session
required guessing; every root cause was found through the actual Kubernetes/Helm tooling,
exactly as Session 14's "don't guess" mindset describes.

## Lessons Learned

- **Reuse over rebuild**: the most valuable "new" work in a capstone isn't re-doing
  what's already proven — it's the integration (Helm packaging here) and the parts that
  genuinely need a live system to demonstrate (the troubleshooting challenge).
- **Deployment safety is real, not theoretical**: Bug 1 was a direct, hands-on
  demonstration that a bad rollout doesn't take down a running service — RollingUpdate's
  "old pods stay until new ones are healthy" behavior isn't just documentation, it's what
  actually happened when `v2-broken` was pushed.
- **Silent failures need the right tool, not more guessing**: both bugs *looked* like
  "the app is broken" from the outside. `kubectl describe` and `kubectl get endpoints`
  — not re-reading YAML by eye — are what actually located each root cause.
- **Disk is infrastructure too**: a meaningful fraction of this session's real engineering
  effort went into working around a genuinely scarce resource (this Mac's disk, repeatedly
  down to a few hundred MB free) — documented honestly across Sessions 18-21 rather than
  pretending every tool choice was made freely.
