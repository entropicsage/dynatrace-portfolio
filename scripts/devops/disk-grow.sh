#!/bin/bash
#
# disk-grow.sh
# Safely grow a filesystem after the underlying block device has been extended.
#
# Common scenarios:
# - Cloud volume resize (AWS EBS, Azure Disk, GCP PD)
# - LVM physical volume extension
# - Virtual machine disk expansion
#
# This script is intentionally conservative and will not auto-detect everything.
# Always verify with your cloud provider / hypervisor first.
#
# Usage:
#   ./disk-grow.sh /dev/sda1 /mnt/data   # or LV path
#

set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <device-or-lv> <mountpoint>"
  echo "Example (LVM):   $0 /dev/mapper/vg_data-lv_data /data"
  echo "Example (cloud): $0 /dev/sdb /data"
  exit 1
fi

DEVICE=$1
MOUNTPOINT=$2

echo "=== Disk Grow Operation ==="
echo "Device/LV : $DEVICE"
echo "Mountpoint: $MOUNTPOINT"
echo ""

# Basic checks
if ! mountpoint -q "$MOUNTPOINT"; then
  echo "ERROR: $MOUNTPOINT is not a mount point."
  exit 1
fi

FSTYPE=$(findmnt -n -o FSTYPE "$MOUNTPOINT")
echo "Filesystem type: $FSTYPE"

read -r -p "Have you already extended the underlying disk/volume in your hypervisor/cloud? (yes/no): " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
  echo "Aborting. Extend the volume first, then re-run."
  exit 1
fi

echo ""
echo "Rescanning device (if applicable)..."
# For SCSI devices
if [[ -b "$DEVICE" ]]; then
  echo "1" > /sys/block/$(basename "$DEVICE")/device/rescan 2>/dev/null || true
fi

echo "Growing physical volume if LVM..."
if command -v pvresize &>/dev/null && pvdisplay "$DEVICE" &>/dev/null; then
  pvresize "$DEVICE" || echo "pvresize skipped or not needed"
fi

echo "Extending logical volume if LVM..."
LV_PATH=$(findmnt -n -o SOURCE "$MOUNTPOINT")
if [[ "$LV_PATH" == /dev/mapper/* ]] && command -v lvextend &>/dev/null; then
  lvextend -l +100%FREE "$LV_PATH" || true
fi

echo "Growing filesystem..."
case "$FSTYPE" in
  xfs)
    xfs_growfs "$MOUNTPOINT"
    ;;
  ext4|ext3|ext2)
    resize2fs "$DEVICE" || resize2fs "$LV_PATH" 2>/dev/null || true
    ;;
  *)
    echo "Unsupported or unknown filesystem: $FSTYPE"
    echo "You may need to run the appropriate grow command manually."
    exit 1
    ;;
esac

echo ""
echo "=== Post-grow verification ==="
df -h "$MOUNTPOINT"
lsblk -f | grep -E "$(basename "$DEVICE")|$(basename "$LV_PATH" 2>/dev/null || true)" || true

echo ""
echo "Disk grow operation completed."
echo "Recommend running: ./disk-usage.sh to verify."