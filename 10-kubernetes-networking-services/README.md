# Kubernetes Networking & Services

All 5 Kubernetes Service types, applied to the same 3-replica `nginx` Deployment
([`deployment.yml`](deployment.yml)), on the real k3s cluster from
[Topic 08](../08-kubernetes-fundamentals). Full transcript:
[`task-networking-services.txt`](task-networking-services.txt).

Pods are disposable and get a new IP every time they restart. A Service gives them one
stable name/IP that never changes, and load-balances across whichever pods are currently
healthy.

## 1. ClusterIP ([`01-clusterip.yml`](01-clusterip.yml)) — the default, internal only

```bash
kubectl apply -f 01-clusterip.yml
kubectl run tester --rm -i --restart=Never --image=busybox:1.36 -- wget -qO- web-clusterip
# <title>Welcome to nginx!</title>
```
Only reachable from inside the cluster, by DNS name or its virtual IP.

## 2. NodePort ([`02-nodeport.yml`](02-nodeport.yml)) — a fixed port on every node

```bash
kubectl apply -f 02-nodeport.yml
curl http://localhost:30080   # <title>Welcome to nginx!</title>
```
Opens port `30080` (range `30000–32767`) on every node. Colima forwards the VM's node
port range to the Mac's `localhost`, which is why this curl works directly from the host.

## 3. LoadBalancer ([`03-loadbalancer.yml`](03-loadbalancer.yml)) — real external IP, locally

```bash
kubectl apply -f 03-loadbalancer.yml
kubectl get svc web-loadbalancer
# EXTERNAL-IP: 192.168.5.1   (not <pending>!)
colima ssh -- curl http://192.168.5.1:8888   # <title>Welcome to nginx!</title>
```
On a bare/local cluster, `type: LoadBalancer` normally sits `<pending>` forever — there's
no cloud provider to provision one. k3s ships its own lightweight `servicelb`
(a per-service DaemonSet pod using `hostPort`) that actually assigns the node's own IP,
which is why this got a real `EXTERNAL-IP` instead of staying `<pending>`. On AWS/GCP/Azure
the exact same YAML would instead provision a real cloud load balancer with a public IP —
the app never has to know the difference.

**A real conflict hit and fixed along the way:** this service originally used `port: 80`,
which collided with the `ingress-nginx-controller`'s own `LoadBalancer` service (installed
for Topic 11) — both wanted the *same* node's port 80, and `servicelb` can only bind one.
The fix was changing this demo's port to `8888` — a real illustration of why a single-node
cluster can't run two `LoadBalancer` services competing for the same port, and why in
production you'd put everything behind **one** Ingress Controller's LoadBalancer instead
of giving every service its own.

**Also real:** `192.168.5.1` is the address on the Colima VM's own private network —
reachable from *inside* the VM (`colima ssh -- curl ...`) but not from the Mac's
`localhost` directly, unlike Docker's `-p` port publishing which colima does forward.

## 4. ExternalName ([`04-externalname.yml`](04-externalname.yml)) — pure DNS alias

```bash
kubectl apply -f 04-externalname.yml
kubectl run dnstest --rm -i --restart=Never --image=busybox:1.36 -- nslookup external-google
# external-google.default.svc.cluster.local  canonical name = www.google.com
# Name: www.google.com   Address: 142.251.xxx.xxx
```
No selector, no pod, no ClusterIP, no `kube-proxy` involvement at all — CoreDNS just
returns a `CNAME` to the real external hostname. Genuinely resolved to Google's real IPs.

## 5. Headless Service ([`05-headless.yml`](05-headless.yml)) — direct pod IPs, no VIP

```bash
kubectl apply -f 05-headless.yml
kubectl run dnstest2 --rm -i --restart=Never --image=busybox:1.36 -- nslookup web-headless
```
The proof that matters — same command against the two service types, side by side:
```text
nslookup web-headless    -> 3 Address lines (10.42.0.28, 10.42.0.27, 10.42.0.26) -- one per pod
nslookup web-clusterip   -> 1 Address line  (10.43.137.39) -- the single virtual service IP
```
`clusterIP: None` tells Kubernetes: don't allocate a load-balanced VIP, just hand back
every backing pod's real IP directly. This is what StatefulSets (Kafka, Cassandra,
MongoDB replica sets) rely on — each replica needs to be individually addressable, not
hidden behind one anonymous load-balanced IP.

## Quick comparison

| Type | Gets an IP? | External access? | Mechanism |
|---|---|---|---|
| ClusterIP | Yes (virtual) | No | `kube-proxy` iptables/IPVS |
| NodePort | Yes (+ opens a node port) | Yes, via `<node-ip>:<port>` | Same, + port on every node |
| LoadBalancer | Yes (+ external IP) | Yes, via the external IP | Cloud LB API, or k3s's `servicelb` locally |
| ExternalName | No | N/A (redirects outward) | CoreDNS `CNAME` only |
| Headless | No (`None`) | No | DNS returns every pod IP directly |

Screenshot: [`../screenshots/10-networking-services.png`](../screenshots/10-networking-services.png)
