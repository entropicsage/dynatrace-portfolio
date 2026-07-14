#!/bin/bash
# Dynatrace Direct API curl Examples
# For Senior Dynatrace / Observability roles requiring API automation skills.
# Update DT_API_TOKEN and DT_BASE_URL. Use read scopes for safety.
# Run: ./api-examples/dynatrace-api-curls.sh

set -e
DT_BASE_URL="${DT_BASE_URL:-https://YOUR_TENANT_ID.apps.dynatrace.com}"
DT_API_TOKEN="${DT_API_TOKEN:-YOUR_DT_API_TOKEN_HERE_WITH_READ_SCOPES}"

echo "=== Dynatrace Environment & Configuration API Examples ==="
echo "Base: $DT_BASE_URL"
echo "Token (masked): ${DT_API_TOKEN:0:10}..."

# Problems (Davis AI / root cause) - High priority for SRE roles
echo -e "\n1. List Open Problems (filtered or all):"
curl -s -H "Authorization: Api-Token $DT_API_TOKEN" \
  "$DT_BASE_URL/api/v2/problems?status=open&limit=5" | jq '.' | head -30 || echo "Install jq or check token"

# DQL / Grail queries - Core for modern Dynatrace (Grail lakehouse)
echo -e "\n2. DQL Query - EasyTrade Spans (k8s filter):"
curl -s -X POST -H "Authorization: Api-Token $DT_API_TOKEN" \
  -H "Content-Type: application/json" \
  "$DT_BASE_URL/api/v2/dql" \
  -d '{
    "query": "fetch spans | filter k8s.namespace.name == \"easytrade\" | summarize count() by {dt.service.name} | limit 10",
    "requestTimeoutSeconds": 30
  }' | jq '.result | .[] | .' | head -20 || true

# Entities / Services (Smartscape topology)
echo -e "\n3. Entities - EasyTrade Services:"
curl -s -H "Authorization: Api-Token $DT_API_TOKEN" \
  "$DT_BASE_URL/api/v2/entities?entitySelector=type(%22SERVICE%22),k8s.namespace.name(%22easytrade%22)&fields=properties&limit=10" | jq '.entities[0:3]' || true

# Metrics / Timeseries (RED metrics)
echo -e "\n4. Metrics Query (response time example):"
curl -s -H "Authorization: Api-Token $DT_API_TOKEN" \
  "$DT_BASE_URL/api/v2/metrics/query?metricSelector=builtin:service.response.time:avg&entitySelector=type(SERVICE)&limit=5" | jq '.' || true

# Dashboards (Configuration API) - list or get specific
echo -e "\n5. List Dashboards (Configuration):"
curl -s -H "Authorization: Api-Token $DT_API_TOKEN" \
  "$DT_BASE_URL/api/v2/dashboards" | jq '.dashboards[0:3] | .[] | {id, name}' || true

echo -e "\n=== Notes for Portfolio / Interviews ==="
echo "- Replace filters with k8s.namespace.name == \"easytrade\" for homelab demos."
echo "- Combine with loadgen/problem-operator for real problems/traces."
echo "- Use with dtctl for mutations (dashboards, workflows) - see dtctl_tools.py and setup-homelab.sh."
echo "- Scopes needed: Read entities, metrics, logs, problems; Write for config."
echo "- Full docs: https://docs.dynatrace.com/docs/dynatrace-api"

# Make executable: chmod +x this file
