#!/bin/bash
#
# system-snapshot.sh
# Collects a comprehensive system state snapshot.
# Run this when Dynatrace shows high CPU, memory pressure, or mysterious host issues.
# Output can be attached to tickets or fed into runbooks.
#
# Usage:
#   ./system-snapshot.sh [output-file]
#   If no file given, outputs to stdout + /tmp/system-snapshot-<date>.log
#

set -euo pipefail

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
OUTPUT=${1:-/tmp/system-snapshot-$TIMESTAMP.log}

exec > >(tee -a "$OUTPUT") 2>&1

echo "=== System Snapshot - $TIMESTAMP ==="
echo "Hostname: $(hostname)"
echo "Uptime:   $(uptime)"
echo ""

echo "=== CPU ==="
lscpu | head -20
echo ""
echo "Top processes by CPU:"
ps aux --sort=-%cpu | head -15

echo ""
echo "=== Memory ==="
free -h
echo ""
echo "Top processes by memory:"
ps aux --sort=-%mem | head -15

echo ""
echo "=== Disk ==="
df -h
echo ""
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE

echo ""
echo "=== Network ==="
ss -tuln | head -20
echo ""
ip -brief addr

echo ""
echo "=== Load & VM Stats ==="
vmstat 1 5
echo ""

if command -v iostat &>/dev/null; then
  echo "=== I/O Stats ==="
  iostat -x 1 3 || true
fi

echo ""
echo "=== Recent Kernel Messages (last 50 lines) ==="
dmesg -T | tail -50 || journalctl -k -n 50 --no-pager || true

echo ""
echo "=== Systemd Services (failed or not running) ==="
systemctl --failed || true
echo ""
systemctl list-units --type=service --state=running | head -20

echo ""
echo "Snapshot written to: $OUTPUT"
echo "=== End of Snapshot ==="