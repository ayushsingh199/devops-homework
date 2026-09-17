# Kubernetes Pods, ReplicaSets & Deployments

Three objects, each adding one capability on top of the last. All three were actually
applied to a real k3s cluster (see [Topic 08](../08-kubernetes-fundamentals)) — full
transcript: [`task1-pods-replicasets.txt`](task1-pods-replicasets.txt).

## 1. Pod ([`pod.yml`](pod.yml)) — no self-healing

A Pod is the smallest deployable unit — one or more containers sharing network/storage.
On its own, a Pod has **no controller watching it**:

```bash
kubectl apply -f pod.yml
kubectl delete pod nginx-pod --wait=false
kubectl get pod nginx-pod   # Terminating, then gone -- nothing recreates it
```

## 2. ReplicaSet ([`replicaset.yml`](replicaset.yml)) — self-healing, fixed count

A ReplicaSet wraps a Pod template with a `replicas` count and continuously reconciles
toward it. Proved this for real by deleting a live pod out from under it:

```bash
kubectl apply -f replicaset.yml            # 3 pods: nginx-rs-7r4rt, -jjzzt, -wvbtg
kubectl delete pod nginx-rs-7r4rt
kubectl get pods -l app=nginx              # still exactly 3 -- a NEW pod replaced it
```

What a ReplicaSet **cannot** do cleanly: change the Pod template's image and have it
roll out gradually — editing a ReplicaSet's template doesn't touch existing pods at all.
That gap is exactly what a Deployment fixes.

## 3. Deployment ([`deployment.yml`](deployment.yml)) — rolling updates + rollback

A Deployment manages ReplicaSets the way a ReplicaSet manages Pods. Verified all of its
extra capabilities for real:

**Rolling update** — change the image, watch old pods drain as new ones come up:
```bash
kubectl set image deployment/nginx-deployment nginx=nginx:1.26
kubectl get rs -l app=nginx
# nginx-deployment-569f95f5cb   0   0   0   <- OLD ReplicaSet scaled to 0, kept around
# nginx-deployment-8574879789   3   3   3   <- NEW ReplicaSet scaled to 3
```

**Rollback** — undo it, and the old image really comes back:
```bash
kubectl rollout undo deployment/nginx-deployment
kubectl describe deployment nginx-deployment | grep Image
# Image: nginx:1.25   <- back to the original, not 1.26
```

**Scaling**:
```bash
kubectl scale deployment/nginx-deployment --replicas=5
kubectl get pods -l app=nginx   # 5 pods running
```

## Why this matters

- **Pod** = one running instance, disposable, no guarantees.
- **ReplicaSet** = "always keep N of these running" — the self-healing primitive.
- **Deployment** = ReplicaSet + safe, gradual, reversible change management. In practice
  you almost never create a bare Pod or ReplicaSet directly in production — you write a
  Deployment, and Kubernetes creates the ReplicaSet (and the ReplicaSet creates the Pods)
  underneath it for you.

Screenshot: [`../screenshots/09-pods-replicasets-deployments.png`](../screenshots/09-pods-replicasets-deployments.png)
