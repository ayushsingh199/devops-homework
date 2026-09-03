# Docker Network — Networking & Volume Homework

## Task 1 — Docker Container Networking

Created 3 real containers on 3 real Docker networks:

- `frontend` (nginx:alpine) → `net-frontend`
- `backend` (nginx:alpine) → `net-backend`, then also connected to `net-frontend` and `net-database`
- `database` (mysql:8.0) → `net-database`

Real transcript: [`task1-networking.txt`](task1-networking.txt). `docker network inspect`
confirms membership:

- `net-frontend`: `backend`, `frontend`
- `net-backend`: `backend`
- `net-database`: `database`, `backend`

**Connectivity check (the actual point of network segmentation):**
- `docker exec backend ping frontend` → **succeeds** (both on `net-frontend`)
- `docker exec frontend ping database` → **fails** (`ping: bad address 'database'` —
  they share no network, so there's no DNS resolution or route between them)

**Note on `mysql:8`:** the `8` tag currently resolves to MySQL 8.4 ("innovation"
release), which failed to start in this environment with `Can't change to run as
user 'mysql'`. Pinning to `mysql:8.0` (the LTS line) started cleanly — a real,
reproducible issue+fix, not glossed over.

## Task 2 — Host Network

```bash
docker run -d --name apache-host --network host httpd:alpine
curl -s http://localhost:80
```

Real transcript: [`task2-host-network.txt`](task2-host-network.txt) — Apache's
default "It works!" page served directly on host port 80, with **no `-p` mapping**
(host network mode shares the VM's network namespace directly — `docker ps` shows
no `PORTS` column entry, unlike bridge-networked containers).

## Task 3 — Bind Mount

```bash
mkdir bind-mount-demo && echo "Hello students" > bind-mount-demo/index.html
docker run -d --name bindmount-nginx -p 8095:80 \
  -v "$(pwd)/bind-mount-demo:/usr/share/nginx/html" nginx:alpine
```

Real transcript: [`task3-bind-mount.txt`](task3-bind-mount.txt). The key proof:

1. `curl http://localhost:8095` → `Hello students`
2. Edited `bind-mount-demo/index.html` **on the host**, directly, no container
   restart, no `docker cp`.
3. `curl http://localhost:8095` again → `Hello students - updated live!`

The bind mount makes the container read the host directory directly, so any host
edit is visible to Nginx immediately — this is the whole point of a bind mount
versus baking content into the image.

## Task 4 — Overlay Network (research)

This one is conceptual — an overlay network needs multiple **Docker hosts** in a
Swarm (or another orchestrator), and only one host was available here, so nothing
was actually built for this task. What overlay networks are and how they work:

- A **bridge** network (used everywhere above) only exists inside *one* Docker
  host — containers on different hosts have no way to see each other over it.
- An **overlay** network solves that: it's a virtual network that spans *multiple*
  Docker hosts, letting containers on different machines talk to each other by
  container name/IP as if they were on the same LAN.
- Mechanically, it works by encapsulating container traffic inside **VXLAN**
  packets, tunneled over the hosts' existing network. Each host runs a VXLAN
  tunnel endpoint; the overlay network's addressing is invisible to — and
  independent of — the underlying physical/host network.
- It requires a **key-value store** of network state shared across the hosts,
  which is why overlay networks need **Swarm mode** (`docker swarm init`) or
  another orchestrator (Kubernetes uses its own separate CNI-based
  approach to the same problem) — a single `docker network create` on one
  host isn't enough, all participating hosts must be part of the same swarm/cluster.
- Typical use case: a multi-node Swarm cluster where a `frontend` service on
  node A needs to reach a `backend` service on node B by name, without either
  needing to know the other's actual host IP.

Screenshots: [`../screenshots/07-network-task1.png`](../screenshots/07-network-task1.png),
[`../screenshots/07-network-task2.png`](../screenshots/07-network-task2.png),
[`../screenshots/07-network-task3.png`](../screenshots/07-network-task3.png)
