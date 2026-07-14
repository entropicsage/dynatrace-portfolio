# EasyTrade DQL Library (Validated for Portfolio)

These DQL queries are battle-tested against the EasyTrade microservices (19+ services in "easytrade" ns on kind + Dynatrace Operator applicationMonitoring).

Load first `dt-dql-essentials` patterns from dynatrace-for-ai skills.

## Core Filters (Always Use)
- `k8s.namespace.name == "easytrade"`
- Service filters: `dt.service.name contains "broker-service" or "frontend" or "calculationservice" ...`

## Problems / Davis AI (Start Here for Troubleshooting)
```dql
fetch dt.davis.problems
| filter status == "open"
| filter contains(dt.entity.service, "easytrade") or k8s.namespace.name == "easytrade"
| sort timestamp desc
| limit 20
| fields timestamp, problem.title, root_cause, impact, status
```

## RED Metrics (Response, Errors, Throughput)
```dql
timeseries 
  avg(dt.service.request.response_time), 
  sum(dt.service.request.error.count), 
  sum(dt.service.request.total)
  by:{dt.service.name}
| filter dt.service.name contains "easytrade" or dt.service.name contains "broker"
| limit 30
```

## Kubernetes / Pods
```dql
fetch dt.entity.kubernetes_pod
| filter k8s.namespace.name == "easytrade"
| fields dt.entity.kubernetes_pod, k8s.pod.name, k8s.namespace.name, cpu_usage, memory_working_set
| limit 15
```

## Spans / Traces (from loadgen visits)
```dql
fetch spans
| filter k8s.namespace.name == "easytrade"
| summarize count() by {dt.service.name, dt.span.kind}
| limit 20
```

## Logs (loadgen + problem-operator)
```dql
fetch logs
| filter k8s.namespace.name == "easytrade"
| filter contains(content, "loadgen") or contains(content, "visit:")
| limit 10
```

## Services Inventory
```dql
fetch dt.entity.service
| filter k8s.namespace.name == "easytrade"
| fields dt.entity.service, dt.service.name, dt.service.type
| limit 25
```

## Usage
- In dtctl: `dtctl query '...' --context my-env --plain`
- In API: POST /api/v2/dql
- In MCP / agents: use these as starting points (scope to problem timeframe!)
- Validate with `dtctl query` before committing to dashboards/automation.

See also: dashboards/easytrade-microservices.json for tiles using these.
Generate data first with loadgen (CronJob or manual scale) + problem-operator.

Sources: dynatrace skill (dt-dql-essentials + dt-obs-*), live homelab verification.
