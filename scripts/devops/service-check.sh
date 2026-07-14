#!/bin/bash
#
# service-check.sh
# Check status of critical system services and listening ports.
# Run when Dynatrace shows service availability or connectivity problems.
#

set -euo pipefail

echo "=== Service & Port Health Check - $(date) ==="
echo ""

CRITICAL_SERVICES=("sshd" "systemd-journald" "kubelet" "containerd" "docker" "chronyd" "ntpd")

echo "--- Critical Services ---"
for svc in "${CRITICAL_SERVICES[@]}"; do
  if systemctl is-active --quiet "$svc" 2>/dev/null; then
    echo "[OK]  $svc"
  else
    echo "[!!]  $svc - $(systemctl is-active "$svc" 2>/dev/null || echo 'not found')"
  fi
done

echo ""
echo "--- Listening Ports (ss -tuln) ---"
ss -tuln | grep -E 'LISTEN|State' | head -20

echo ""
echo "--- Established Connections (top 10) ---"
ss -tan | grep ESTAB | sort | uniq -c | sort -nr | head -10

echo ""
echo "Run with 'journalctl -u <service>' for detailed logs on failures."