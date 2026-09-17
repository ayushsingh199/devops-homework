# Kubernetes Fundamentals

## Environment

This Mac has no built-in Kubernetes, so a real single-node cluster was provisioned with
[Colima](https://github.com/abiosoft/colima)'s bundled **k3s** distribution:

```bash
colima start --cpu 2 --memory 3 --disk 12 --kubernetes
kubectl config use-context colima
```

```bash
$ kubectl get nodes
NAME     STATUS   ROLES           AGE   VERSION
colima   Ready    control-plane   7s    v1.35.0+k3s1
```

Real transcript: [`fundamentals.txt`](fundamentals.txt).

## What a Kubernetes cluster actually is

A cluster is a set of machines (**nodes**) that run containers, managed by a shared
**control plane**. Normally these are separate pieces (etcd, `kube-apiserver`,
`kube-scheduler`, `kube-controller-manager` on one or more control-plane nodes; `kubelet`
+ `kube-proxy` + a container runtime on every worker node) — k3s bundles nearly all of
this into a single `k3s server` binary/process for a lightweight single-node setup, which
is exactly why `kubectl get pods -A` here shows only `coredns`, `local-path-provisioner`,
and `metrics-server` as pods — the API server/scheduler/controller-manager/etcd are
running as part of that one `k3s` process, not as separate pods (unlike a `kubeadm`
cluster where you'd see `kube-apiserver-*` etc. as static pods in `kube-system`).

- **`kubectl`**: the CLI client — sends REST requests to the API server. Never talks to
  nodes or containers directly.
- **API server**: the front door. Every single read/write to cluster state goes through
  it and gets persisted to **etcd** (the cluster's database).
- **Scheduler**: watches for Pods with no node assigned, picks a node for them based on
  resource requests/constraints.
- **Controller manager**: runs the reconciliation loops (Deployment controller, ReplicaSet
  controller, etc.) that continuously push actual state toward desired state.
- **kubelet**: runs on every node, actually starts/stops containers via the container
  runtime, reports node/pod status back to the API server.
- **kube-proxy**: programs each node's networking rules so Services route to the right
  Pods (see [`../10-kubernetes-networking-services`](../10-kubernetes-networking-services)).

## Hands-on: the smallest possible workload

```bash
kubectl run hello --image=nginx:alpine --port=80
kubectl expose pod hello --port=80 --name=hello-svc
kubectl run curler --rm -i --restart=Never --image=busybox:1.36 -- wget -qO- hello-svc
kubectl delete svc hello-svc && kubectl delete pod hello
```

This ran a real Pod, gave it a stable in-cluster name via a Service, and proved another
Pod could reach it by that name and get back Nginx's real HTML response — the whole
service-discovery mechanism explored in depth in Topic 10.

## `kubectl api-resources`

Every object "kind" the API server exposes (Pods, Deployments, Services, ConfigMaps,
Secrets, Ingress, ...) is discoverable at runtime — this is what makes `kubectl` and
every Kubernetes client generic instead of hardcoded per resource type. Full list
captured in the transcript.

Screenshot: [`../screenshots/08-fundamentals.png`](../screenshots/08-fundamentals.png)
