# Session 13: Kubernetes Storage, HPA & Probes

Everything here ran for real against the same k3s cluster (Colima) used in the earlier
Kubernetes topics.

## Task 1: Volumes

See [`01-kubernetes-volumes/README.md`](01-kubernetes-volumes/README.md) — emptyDir,
hostPath, static PV/PVC binding (including a real StorageClass gotcha hit and fixed),
and StorageClass dynamic provisioning. Transcript: [`task1-volumes.txt`](task1-volumes.txt).

## Task 2: Probes

Startup, Readiness, and Liveness probes — including a **deliberately broken** readiness
probe to show the real, often-misunderstood effect: `kubectl get endpoints` came back
completely empty while the Pod stayed `Running` the whole time (readiness failure pulls
a Pod out of Service traffic; it does **not** restart the container — only a failing
*liveness* probe does that). Transcript: [`task2-probes.txt`](task2-probes.txt).

| Probe | Question it answers | What happens on failure |
|---|---|---|
| Startup | Has the app finished initializing? | Container restarted; blocks liveness/readiness from running until it passes |
| Readiness | Can this Pod take traffic right now? | Pod pulled from Service Endpoints — not restarted |
| Liveness | Is the container still working? | kubelet restarts the container |

## Task 3: HPA hands-on

[`04-hpa/`](04-hpa) — Deployment + Service + HorizontalPodAutoscaler
(`minReplicas: 1`, `maxReplicas: 5`, target 50% average CPU). Transcript:
[`task3-hpa.txt`](task3-hpa.txt).

**A deliberate substitution, documented rather than hidden**: the reference curriculum's
HPA demo uses plain `nginx`. Nginx serving a static page uses almost no CPU per request,
so it would take an unrealistic amount of traffic to ever cross a 50% CPU target. Swapped
in Kubernetes' own official teaching image for this exact exercise —
[`registry.k8s.io/hpa-example`](https://github.com/kubernetes/website) — which does real
CPU work (a `sqrt()` loop) per request, so load actually shows up as CPU load. Same
resource requests/limits, same `HorizontalPodAutoscaler` spec either way.

Real scale-out captured live, polling every 20s after starting an in-cluster load
generator (`busybox` in a tight `wget` loop against the Service):

```text
t+0s    cpu: <unknown>/50%   replicas: 1    (no CPU sample yet — metrics-server needs ~1 scrape interval)
t+60s   cpu: 200%/50%        replicas: 4    (HPA reacted: 200% is 4x the 50% target -> scaled toward 4x pods)
```

Then the load generator was killed and the HPA was watched scale back down once CPU
utilization dropped below target (with Kubernetes' default 5-minute scale-down
stabilization window, so this took longer than the scale-up did — also captured in the
transcript).

## Mini Project: Production-Ready Kubernetes Web App

[`mini-project/`](mini-project) combines all three pillars from this session into one
app, in its own namespace:

- **State persistence**: a PVC mounted at `/data`, proved to survive a Pod being deleted
  and rescheduled.
- **Elastic scaling**: an HPA (2–5 replicas, 50% CPU target).
- **Health diagnostics**: Startup + Readiness + Liveness probes on every replica.

Full walkthrough and output: [`mini-project/README.md`](mini-project/README.md).

Screenshots: [`../screenshots/12-volumes-probes.png`](../screenshots/12-volumes-probes.png),
[`../screenshots/12-hpa.png`](../screenshots/12-hpa.png),
[`../screenshots/12-mini-project.png`](../screenshots/12-mini-project.png)
