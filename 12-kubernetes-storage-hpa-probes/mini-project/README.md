# Mini Project: Production-Ready Kubernetes Web App

Combines the three pillars from this session into one app in its own namespace
(`production-webapp`): persistent storage, elastic scaling, and health diagnostics.
Real transcript: [`../task4-mini-project.txt`](../task4-mini-project.txt).

## Deploy

```bash
kubectl apply -f namespace.yaml     # namespace/production-webapp created
kubectl apply -f pvc.yaml           # persistentvolumeclaim/web-data created
kubectl apply -f deployment.yaml    # 2 replicas, probes, volume mount, resource limits
kubectl apply -f service.yaml       # ClusterIP on port 80
kubectl apply -f hpa.yaml           # 2-5 replicas, 50% CPU target
```

```text
$ kubectl get pvc -n production-webapp
NAME       STATUS   VOLUME                        CAPACITY   ACCESS MODES   STORAGECLASS
web-data   Bound    pvc-b37650c3-...               500Mi      RWO            local-path

$ kubectl get pods -n production-webapp
NAME                      READY   STATUS    RESTARTS   AGE
web-app-bc8dfb4db-9ddl9   1/1     Running   0          14s
web-app-bc8dfb4db-kplbw   1/1     Running   0          14s
```

## Verification 1: storage survives Pod rescheduling

```bash
kubectl exec -n production-webapp web-app-bc8dfb4db-9ddl9 -- sh -c 'echo "Student: Ayush Singh" > /data/student.txt'
kubectl delete pod -n production-webapp web-app-bc8dfb4db-9ddl9
# ... a NEW pod, web-app-bc8dfb4db-kxlv4, gets scheduled to replace it ...
kubectl exec -n production-webapp web-app-bc8dfb4db-kxlv4 -- cat /data/student.txt
# Student: Ayush Singh
```

The file written by the pod that got deleted is still there on the pod that replaced it
— the PVC (and its underlying volume) outlives any individual Pod.

**Caveat worth being honest about**: `ReadWriteOnce` restricts a volume to one *node*,
not one *pod*. Both replicas here run on this single-node cluster, so they could mount
the same volume concurrently regardless of deletion — this single-node setup doesn't
fully exercise the "only one node can attach it at a time" guarantee. On a real
multi-node cluster the same YAML would behave identically but that guarantee would
actually matter.

## Verification 2: Service

```bash
kubectl run curltest -n production-webapp --rm -i --restart=Never --image=busybox:1.36 -- wget -qO- http://web-service
# <title>Welcome to nginx!</title>
```

## Verification 3: HPA

The `HorizontalPodAutoscaler` here is live and reading real CPU metrics
(`kubectl get hpa -n production-webapp` → `cpu: 1%/50%`, `REPLICAS: 2`). The actual
scale-out-under-load proof is done once, properly, in
[Task 3](../README.md#task-3-hpa-hands-on) against `registry.k8s.io/hpa-example` —
repeating it here against plain `nginx` would hit the exact same "too little real CPU
work per request to ever cross 50%" problem explained there, so this project reuses that
proof rather than staging a second load test that wouldn't actually move the needle.

## Probe diagnostics reference

| Probe | Target question | Action on failure |
|---|---|---|
| Startup | Has the process initialized? | Restarts container; blocks the other two probes until it passes |
| Readiness | Can the Pod receive user traffic right now? | Drops the Pod from Service Endpoints — no restart |
| Liveness | Is the container alive and responsive? | kubelet restarts the container |

(Startup/Readiness/Liveness failure behavior demonstrated hands-on, with a deliberately
broken readiness probe, in [Task 2](../task2-probes.txt).)
