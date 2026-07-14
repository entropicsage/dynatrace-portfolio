#!/bin/bash
#
# k8s-troubleshoot.sh
# Quick Kubernetes diagnostics focused on common issues that Dynatrace would surface
# (node pressure, pod restarts, resource limits, events).
#
# Assumes kubectl is configured for the target cluster.
#
# Usage:
#   ./k8s-troubleshoot.sh [namespace]
#   Default namespace: all (or current context default)
#

set -euo pipefail

NAMESPACE=${1:-""}

echo "=== Kubernetes Troubleshooting Snapshot ==="
echo "Date: $(date)"
echo "Context: $(kubectl config current-context 2>/dev/null || echo 'unknown')"
echo ""

echo "=== Nodes ==="
kubectl get nodes -o wide
echo ""
kubectl top nodes 2>/dev/null || echo "Metrics server not available for top nodes"

echo ""
echo "=== Node Pressure / Conditions ==="
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.conditions[?(@.type=="MemoryPressure")].status}{"\t"}{.status.conditions[?(@.type=="DiskPressure")].status}{"\t"}{.status.conditions[?(@.type=="PIDPressure")].status}{"\n"}{end}' 2>/dev/null || echo "Could not retrieve conditions"

echo ""
echo "=== Pods with Issues (CrashLoop, Pending, etc.) ==="
kubectl get pods --all-namespaces --field-selector=status.phase!=Running 2>/dev/null | head -30 || \
kubectl get pods -A | grep -E 'CrashLoop|Pending|Error|Evicted' | head -20 || true

if [[ -n "$NAMESPACE" ]]; then
  NS_FLAG=(-n "$NAMESPACE")
else
  NS_FLAG=(--all-namespaces)
fi

echo ""
echo "=== Recent Events (last 20) ==="
kubectl get events "${NS_FLAG[@]}" --sort-by=.lastTimestamp 2>/dev/null | tail -20 || true

echo ""
echo "=== Top Resource Consumers (if metrics available) ==="
kubectl top pods "${NS_FLAG[@]}" --sort-by=cpu 2>/dev/null | head -15 || echo "kubectl top not available"
echo ""
kubectl top pods "${NS_FLAG[@]}" --sort-by=memory 2>/dev/null | head -15 || true

echo ""
echo "=== Dynatrace Integration Note ==="
echo "When Dynatrace shows problems for pods/nodes in this cluster, run this script"
echo "and attach the output. Cross-reference with DynaKube and OneAgent logs."
echo ""
echo "=== End of K8s Troubleshooting Snapshot ==="