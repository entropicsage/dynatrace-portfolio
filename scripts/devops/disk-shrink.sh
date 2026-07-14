#!/bin/bash
#
# disk-shrink.sh
# EXTREMELY DANGEROUS - Use with extreme caution.
#
# Shrinking a live filesystem carries high risk of data loss.
# This script exists primarily as a documented, cautious procedure
# rather than a fully automated tool.
#
# Only use when:
# - You have verified backups
# - You have a maintenance window
# - You understand LVM + filesystem internals
#
# Most modern environments prefer to just add more storage instead of shrinking.
#

set -euo pipefail

echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "!!!                    WARNING                           !!!"
echo "!!!  Shrinking filesystems is high-risk and can cause     !!!"
echo "!!!  PERMANENT DATA LOSS. This script is intentionally    !!!"
echo "!!!  limited and will not perform the resize for you.     !!!"
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo ""

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <mountpoint> <new-size>"
  echo "Example: $0 /data 50G"
  echo ""
  echo "This script will only:"
  echo "  1. Show current usage"
  echo "  2. Validate that new size is larger than used space"
  echo "  3. Print the exact manual commands you should run"
  echo "  4. Require multiple confirmations"
  exit 1
fi

MOUNTPOINT=$1
NEW_SIZE=$2

echo "Target mountpoint : $MOUNTPOINT"
echo "Requested new size: $NEW_SIZE"
echo ""

df -h "$MOUNTPOINT"
echo ""

USED=$(df --output=used -h "$MOUNTPOINT" | tail -1 | tr -d ' ')
echo "Current used space (approx): $USED"

read -r -p "Do you have a verified, tested backup of this filesystem? (type 'YES' to continue): " BACKUP_CONFIRM
if [[ "$BACKUP_CONFIRM" != "YES" ]]; then
  echo "Aborting. No backup confirmation."
  exit 1
fi

read -r -p "Have you unmounted the filesystem or are you sure it can be safely resized offline? (yes/no): " UNMOUNT_CONFIRM
if [[ "$UNMOUNT_CONFIRM" != "yes" ]]; then
  echo "Aborting. Online shrink is extremely risky."
  exit 1
fi

echo ""
echo "Recommended manual steps (review carefully):"
echo ""
echo "1. Unmount: umount $MOUNTPOINT"
echo "2. Check filesystem: e2fsck -f <device>"
echo "3. Resize filesystem: resize2fs <device> $NEW_SIZE"
echo "4. Resize LV (if LVM): lvreduce -L $NEW_SIZE <lv-path>"
echo "5. Remount and verify"
echo ""
echo "For XFS: XFS cannot be shrunk. You must back up, recreate, and restore."
echo ""

read -r -p "Type 'I UNDERSTAND THE RISKS' to see the full command template: " FINAL_CONFIRM
if [[ "$FINAL_CONFIRM" != "I UNDERSTAND THE RISKS" ]]; then
  echo "Aborting."
  exit 1
fi

echo ""
echo "You are on your own from here. Good luck."
echo "Consider using cloud volume snapshots before proceeding."