#!/bin/bash
# A minimal, real GitOps reconciler: Git is the only source of truth for
# desired state; this loop continuously re-applies it to the cluster,
# undoing any manual drift -- exactly what ArgoCD automates, just without
# its web UI, SSO, or multi-cluster management.
set -uo pipefail
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INTERVAL="${1:-5}"

echo "Reconciler watching $REPO_DIR/app every ${INTERVAL}s. Ctrl+C to stop."
while true; do
  TS=$(date '+%H:%M:%S')
  # Namespace must exist before anything inside it -- apply it on its own
  # first (idempotent either way), THEN the rest of the manifests.
  kubectl apply -f "$REPO_DIR/app/namespace.yaml" > /dev/null 2>&1
  OUT=$(kubectl apply -f "$REPO_DIR/app/" 2>&1)
  CHANGED=$(echo "$OUT" | grep -v unchanged || true)
  if [ -n "$CHANGED" ]; then
    echo "[$TS] reconciled:"
    echo "$CHANGED" | sed 's/^/    /'
  else
    echo "[$TS] in sync, nothing to do"
  fi
  sleep "$INTERVAL"
done
