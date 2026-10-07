# Kubernetes Volumes

All of this was run for real against a k3s cluster (Colima) — transcript:
[`../task1-volumes.txt`](../task1-volumes.txt).

## emptyDir ([`emptydir-pod.yaml`](emptydir-pod.yaml))

A directory created fresh when the Pod is scheduled, and **deleted permanently the
moment the Pod is removed** — not on container restart, only on Pod deletion.

```bash
kubectl exec emptydir-demo -- sh -c "echo hello > /data/test.txt && cat /data/test.txt"
# hello
kubectl delete pod emptydir-demo
# nothing to recover -- the storage was deleted with the pod
```

Use case: scratch space shared between containers in the same Pod (e.g. a sidecar that
processes files a main container writes), or caching that's fine to lose.

## hostPath ([`hostpath-pod.yaml`](hostpath-pod.yaml))

Mounts a path from the **node's own filesystem** directly into the container.

```bash
kubectl exec hostpath-demo -- sh -c "echo from-hostpath > /data/test.txt"
colima ssh -- cat /tmp/hostpath-data/test.txt
# from-hostpath   <- really sitting on the node's disk, outside any container
kubectl delete pod hostpath-demo
# file is still there -- hostPath survives Pod deletion
```

The real limitation: this only works if whatever Pod needs the data next gets
scheduled on **the same node**. In a multi-node cluster that's not guaranteed, which is
exactly why hostPath is rarely used for real application data — mainly for node-level
agents (log collectors, monitoring daemons) that are *supposed* to see that specific
node's files.

## PersistentVolume + PersistentVolumeClaim ([`../02-persistent-storage`](../02-persistent-storage))

A PV is a piece of real storage an admin provisions; a PVC is an application's request
for storage that gets matched (bound) to a PV. This decouples "what storage exists" from
"what a Pod asks for."

Proved persistence survives Pod deletion — wrote a file, deleted the Pod, recreated it,
same PVC, file still there:
```bash
kubectl exec storage-demo -- cat /data/test.txt
# persisted-data   <- survived a full pod delete + recreate
```

**A real gotcha hit and documented**: on a cluster that has a **default StorageClass**
(this one does — k3s ships `local-path`), a PVC with no `storageClassName` does **not**
bind to your manually created PV — it gets handed to the default StorageClass's dynamic
provisioner instead, which silently creates its *own* new PV. The manually created
`student-pv` sat there `Available`, completely unused, while the PVC bound to a brand
new dynamically-provisioned volume. The fix: set `storageClassName: ""` explicitly on the
PVC ([`../02-persistent-storage/pvc-static-fixed.yaml`](../02-persistent-storage/pvc-static-fixed.yaml))
to opt out of dynamic provisioning and force static-only matching — confirmed with
`kubectl get pv student-pv` showing it actually `Bound` to the claim afterward.

## StorageClass + dynamic provisioning ([`../03-storageclass`](../03-storageclass))

```bash
kubectl get storageclass
# local-path (default)   rancher.io/local-path   ... WaitForFirstConsumer ...
```
No PV to write by hand at all — the PVC just names a StorageClass, and a **provisioner**
creates a matching PV automatically, the moment a Pod actually needs it
(`VOLUMEBINDINGMODE: WaitForFirstConsumer` — the PVC sits `Pending` until a Pod using it
is scheduled, confirmed in the transcript: `Pending` before a pod attached, `Bound` with
a real dynamically-created PV name right after).

This is what almost every real cluster uses in practice — AWS EBS, GCP PD, Azure Disk all
plug in as StorageClass provisioners, so `kubectl apply -f pvc.yaml` is enough; nobody
hand-writes PV objects for cloud disks.

## Quick comparison

| | emptyDir | hostPath | Static PV/PVC | Dynamic (StorageClass) |
|---|---|---|---|---|
| Survives Pod deletion | No | Yes (same node only) | Yes | Yes |
| Survives node loss | No | No | Depends on backing storage | Depends on backing storage |
| Who creates the volume | kubelet, automatically | N/A (already exists) | Admin, by hand | Provisioner, on demand |
| Real-world use | scratch/cache | node-local agents | rare now | the normal path |
