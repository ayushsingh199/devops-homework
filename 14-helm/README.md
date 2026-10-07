# Session 15: Helm

A full install → upgrade → bad-upgrade → rollback → uninstall lifecycle, run for real
against the k3s cluster from the earlier Kubernetes sessions. Transcript:
[`task1-helm-workflow.txt`](task1-helm-workflow.txt).

## The chart: [`notes-chart/`](notes-chart)

A small Notes app chart — ConfigMap + Deployment + NodePort Service — parameterized by
[`values.yaml`](notes-chart/values.yaml) (development: 1 replica, `nginx:1.24`) and
[`values-prod.yaml`](notes-chart/values-prod.yaml) (production: 3 replicas, `nginx:1.25`).

## Every command, run for real

| Command | What happened |
|---|---|
| `helm lint notes-chart` | `1 chart(s) linted, 0 chart(s) failed` |
| `helm template notes-dev notes-chart` | Rendered real Kubernetes YAML locally, no cluster contact — every `{{ }}` replaced |
| `helm install notes-dev notes-chart` | `REVISION: 1`, 1 pod running (dev values) |
| `helm list` | Showed `notes-dev`, revision 1, `deployed` |
| `helm status notes-dev` | Full resource breakdown — ConfigMap, Service, Deployment, Pod |
| `helm upgrade notes-dev notes-chart -f values-prod.yaml` | `REVISION: 2` — scaled 1→3 pods, image `1.24`→`1.25` |
| `helm get values notes-dev` | Confirmed the live release is running the prod values |
| `helm history notes-dev` | Listed every revision with its status |
| `helm upgrade ... --set image.tag=broken-tag-does-not-exist` | `REVISION: 3` — real `ErrImagePull` pod appeared |
| `helm rollback notes-dev 2` | `Rollback was a success!` — `REVISION: 4` (a rollback is its own new revision, not a time-machine back to 2), pods healthy again |
| `helm get manifest notes-dev` | Printed the exact live Kubernetes YAML Helm is managing |
| `helm repo add bitnami ...` + `helm repo update` | Added a real public chart repository |
| `helm search repo nginx` | Found 3 real published charts (`bitnami/nginx`, `bitnami/nginx-ingress-controller`, `bitnami/nginx-intel`) |
| `helm uninstall notes-dev` | All 3 resources (Pod, Service, ConfigMap) gone, `helm list` empty |

## The rollback workflow, in detail

```
install (rev 1, dev)
   │
   ▼
upgrade -f values-prod.yaml (rev 2, prod: 3 replicas)
   │
   ▼
upgrade --set image.tag=broken-tag-does-not-exist (rev 3, BROKEN — real ErrImagePull)
   │
   ▼
rollback 2 (rev 4 — a new revision whose content matches rev 2, NOT a revert of history)
   │
   ▼
verify: 3 healthy pods, nginx:1.25 again
```

**Worth calling out explicitly**: `helm rollback notes-dev 2` did not make history "go
back to 2" — it created **revision 4**, whose *content* matches revision 2. `helm history`
after the rollback shows all 4 revisions, not 2. This is a common point of confusion:
rollback is implemented as "deploy this old revision's values again," recorded as a brand
new entry, not a destructive undo.

## Why a Helm chart beats raw `kubectl apply -f`

- **One release, one name** — `helm list` tracks "notes-dev" as a single unit instead of
  five separate YAML files you'd have to remember to apply/delete together.
- **Real rollback** — `kubectl apply` has no memory of what you applied five minutes ago.
  Helm's revision history is what made `helm rollback notes-dev 2` possible at all.
- **One chart, many environments** — the same chart produced a 1-replica dev deployment
  and a 3-replica prod deployment, differing only by which values file was passed in.

Screenshot: [`../screenshots/14-helm.png`](../screenshots/14-helm.png)
