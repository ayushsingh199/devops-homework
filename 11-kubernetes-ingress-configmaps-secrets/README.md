# Kubernetes Ingress, ConfigMaps & Secrets

A full app — frontend + backend + config + credentials + one entry point — built and run
for real on the k3s cluster from [Topic 08](../08-kubernetes-fundamentals). Full
transcript: [`task-ingress-configmaps-secrets.txt`](task-ingress-configmaps-secrets.txt).

## 1. ConfigMap ([`configmap.yaml`](configmap.yaml)) — plain-text config

```bash
kubectl apply -f configmap.yaml
kubectl get configmap yatri-app-config -o jsonpath='{.data.ENVIRONMENT}'
# production
```
5 key-value pairs (`ENVIRONMENT`, `LOG_LEVEL`, `APP_PORT`, `DEFAULT_CURRENCY`,
`MAX_BOOKING_DAYS`) — no secrets, just configuration.

## 2. Secret ([`secret.yaml`](secret.yaml)) — credentials, and the `echo -n` gotcha

```bash
echo "mypassword" | base64      # bXlwYXNzd29yZAo=   <- WRONG, trailing \n baked in
echo -n "mypassword" | base64   # bXlwYXNzd29yZA==   <- CORRECT
```
Reproduced this for real: decoding the "wrong" encoding gives `mypassword\n` (15
characters), which most databases reject outright as a wrong password — an easy,
genuinely common bug.

```bash
kubectl apply -f secret.yaml
kubectl describe secret yatri-db-secret   # values shown only as byte counts, e.g. "14 bytes"
kubectl get secret yatri-db-secret -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 --decode
# secretpassword
```
**Base64 is encoding, not encryption.** Anyone with `get secret` RBAC permission can
decode it in one command, as just shown. Real production secrets need something like
Sealed Secrets, an External Secrets Operator, or a KMS-backed vault — a plain Kubernetes
`Secret` only protects against *casual* exposure (it's not stored as cleartext in `etcd`
if encryption-at-rest is configured, and `describe`/`get -o yaml` mask it by default).

## 3. Backend ([`backend.yaml`](backend.yaml)) — consuming both

```yaml
envFrom:
  - configMapRef: { name: yatri-app-config }   # all 5 ConfigMap keys at once
env:
  - name: POSTGRES_PASSWORD
    valueFrom: { secretKeyRef: { name: yatri-db-secret, key: POSTGRES_PASSWORD } }
```
```bash
kubectl apply -f backend.yaml
kubectl exec deployment/yatri-backend -- env | grep -E "ENVIRONMENT|POSTGRES"
# ENVIRONMENT=production
# POSTGRES_USER=yatri_admin
# POSTGRES_PASSWORD=secretpassword
# POSTGRES_DB=yatri_production_db
```
Both the ConfigMap and the Secret land inside the container as ordinary environment
variables — the app code never knows or cares which object they came from.

## 4. Frontend ([`frontend.yaml`](frontend.yaml))

Plain `nginx:1.25-alpine`, also reading the ConfigMap. Both services are `ClusterIP` —
internal-only, which is exactly why the next step exists.

## 5. Ingress ([`ingress.yaml`](ingress.yaml)) — one entry point, two backends

```bash
kubectl apply -f ingress.yaml
colima ssh -- curl -H "Host: yatri.local" http://192.168.5.1/
# <title>Welcome to nginx!</title>          <- routed to the frontend

colima ssh -- curl -H "Host: yatri.local" http://192.168.5.1/api/
# Yatri Backend API
# ENVIRONMENT     : production
# POSTGRES_USER   : yatri_admin
# POSTGRES_DB     : yatri_production_db     <- routed to the backend
```
One host (`yatri.local`), one IP, two paths, two completely different backend Deployments
— proving genuine Layer-7 path-based routing, not just a second `LoadBalancer`.

**Two real environment adaptations, documented rather than hidden:**
- k3s via Colima **disables its default Traefik ingress controller**. The
  [`ingress-nginx`](https://github.com/kubernetes/ingress-nginx) controller (the same one
  the original lab targets) was installed separately for this topic and removed after.
- The original lab's `ingress.yaml` uses a regex `rewrite-target` annotation to strip
  `/api` before forwarding. This backend's Python handler ignores the request path
  entirely (it always returns the same config dump), so that rewrite has no observable
  effect here — simplified to plain `pathType: Prefix` rules instead. The concept being
  tested (one Ingress, host + path rules, routing to two different Services) is identical.

## 6. The ConfigMap live-update trap

```bash
kubectl patch configmap yatri-app-config --type merge -p '{"data":{"ENVIRONMENT":"staging"}}'
kubectl exec deployment/yatri-backend -- env | grep ENVIRONMENT
# ENVIRONMENT=production     <- UNCHANGED, even though the ConfigMap says "staging" now

kubectl rollout restart deployment/yatri-backend
kubectl exec deployment/yatri-backend -- env | grep ENVIRONMENT
# ENVIRONMENT=staging        <- NOW it's picked up
```
Environment variables are injected once, at container start. Editing a ConfigMap does
**not** live-reload already-running pods — you need a rolling restart (or a mounted
volume + an app that watches the file, which does update live). This is a very common
real-world "why didn't my config change take effect" bug, reproduced and fixed here
exactly as it would happen in production.

Screenshot: [`../screenshots/11-ingress-configmaps-secrets.png`](../screenshots/11-ingress-configmaps-secrets.png)
