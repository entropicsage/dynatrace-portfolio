#!/usr/bin/env bash
# Apply EasyTrade Self-Healing Workflows to Dynatrace
# Usage: ./scripts/apply-easytrade-automation.sh
# Requires dtctl authenticated (as in this portfolio setup).
# Part of the Dynatrace/EasyTrade portfolio for automated self-healing.

set -e

PORTFOLIO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
AUTOMATION_DIR="$PORTFOLIO_DIR/automation/easytrade-self-healing"

echo "=== Applying EasyTrade Self-Healing Automation to Dynatrace ==="
echo "Portfolio dir: $PORTFOLIO_DIR"
echo "Automation dir: $AUTOMATION_DIR"

cd "$AUTOMATION_DIR"

for wf in *.yaml; do
  if [ -f "$wf" ]; then
    echo "Applying workflow: $wf"
    # Use explicit 'create workflow' subcommand (dtctl auto-detect sometimes fails on workflows).
    # For updates after creation, you may need to use the UI or delete+recreate, or dtctl apply if it detects.
    dtctl create workflow -f "$wf" || echo "  (Already exists or error — check tenant or use UI to update)"
    echo "  ✓ Processed $wf"
  fi
done

echo ""
echo "=== Done. Workflows are now in your Dynatrace tenant (or already were). ==="
echo "To test a workflow manually:"
echo "  dtctl exec workflow <workflow-id-or-name> --input '{\"test\":true}'"
echo ""
echo "EasyTrade problems (from problem-operator) should now trigger self-healing."
echo "View in Dynatrace UI under Automation > Workflows or Problems."
echo ""
echo "Next: Update your local files and re-apply with this script after changes."
