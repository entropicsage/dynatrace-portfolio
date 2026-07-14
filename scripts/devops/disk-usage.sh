#!/bin/bash
#
# disk-usage.sh
# Enhanced disk usage reporting for Linux systems.
# Useful when Dynatrace alerts on high disk usage, inode exhaustion, or slow I/O.
#
# Features:
# - Human-readable df output
# - Top disk consumers (files/directories)
# - Inode usage (common hidden problem)
# - Optional threshold alerting
#
# Usage:
#   ./disk-usage.sh [--threshold 80] [--top 15]
#

set -euo pipefail

THRESHOLD=80
TOP_COUNT=15

print_usage() {
  echo "Usage: $0 [--threshold PERCENT] [--top N]"
  echo "  --threshold  Alert if usage >= this percent (default: 80)"
  echo "  --top        Number of largest consumers to show (default: 15)"
}

while [[ $# -gt 0 ]]; do
  case $1 in
    --threshold)
      THRESHOLD="$2"
      shift 2
      ;;
    --top)
      TOP_COUNT="$2"
      shift 2
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      print_usage
      exit 1
      ;;
  esac
done

echo "=== Disk Usage Report - $(date) ==="
echo ""

echo "--- Filesystem Usage (df -h) ---"
df -h | awk 'NR==1 || $5+0 >= '"$THRESHOLD"' {print}'

echo ""
echo "--- Inode Usage (df -i) ---"
df -i | awk 'NR==1 || $5+0 >= '"$THRESHOLD"' {print}'

echo ""
echo "--- Top $TOP_COUNT Largest Directories (may take time on large filesystems) ---"
# Limit to / and common mount points to keep it reasonable
du -x -h --max-depth=1 / 2>/dev/null | sort -hr | head -n "$TOP_COUNT"

echo ""
echo "--- Top $TOP_COUNT Largest Files (last 30 days, top level) ---"
find / -xdev -type f -mtime -30 -exec ls -lh {} + 2>/dev/null | sort -k5 -hr | head -n "$TOP_COUNT" || echo "Note: find may be slow or restricted."

echo ""
echo "Report complete. Use this data when investigating Dynatrace disk-related problems."