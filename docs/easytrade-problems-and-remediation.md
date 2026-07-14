# EasyTrade Problems, DQL, and Self-Healing Remediation

This document catalogs common/reproducible problems in the EasyTrade microservices deployment, along with DQL queries, traces, and how Dynatrace workflows (in `automation/easytrade-self-healing/`) remediate them.

This environment uses the official problem-operator and load generator to produce authentic, investigable problem data.

## Triggering Problems
- Use the load generator: Access EasyTrade UI or run loadgen bursts.
- Problem operator in namespace injects realistic issues (high CPU, latency, errors).
- From k8s/ and scripts: Restart pods or scale to simulate.

Common services: broker-service, frontend, calculationservice, loadgen, problem-operator, etc.

## Key Problems & Evidence

### 1. High CPU / Spike in calculationservice
**Trigger**: Load bursts or problem-operator.
**Symptoms**: Davis AI problem, high CPU, slow response times.
**DQL to investigate**:
```
timeseries avg(dt.service.cpu.time), by: {k8s.pod.name, dt.entity.service}
| filter k8s.namespace.name == "easytrade"
| filter dt.entity.service == "calculationservice"
| sort timestamp desc
```

**Remediation Workflow**: `automation/easytrade-self-healing/` scales replicas or restarts pod via DT action.
Evidence: Traces show hot path in calculation logic; Smartscape shows dependency on DB.

### 2. Slow Database Queries / Latency in deposit flow
**Symptoms**: High response time, error rate on broker-service or frontend.
**DQL**:
```
fetch logs, from: now()-1h
| filter k8s.namespace.name == "easytrade"
| filter contains(content, "slow query") or contains(content, "timeout")
| summarize count(), by: {service.name}
```

**Remediation**: Workflow triggers DB connection pool increase or failover (via Ansible or k8s patch).
Traces: Distributed trace from frontend -> broker -> DB shows latency bottleneck.

### 3. Broker Errors / Message Queue Issues
**Symptoms**: Error rate spike, failed transactions.
**DQL for problems**:
```
timeseries count(dt.service.errors.server.rate), by:{dt.entity.service}
| filter contains(toString(dt.entity.service), "broker")
| limit 10
```

**Remediation**: Self-healing restarts the broker pod or scales the queue consumer. Ties to DT problem event.

### 4. Memory Leak Simulation / Pod OOM
**Trigger**: Specific loadgen scenario.
**DQL**:
```
timeseries avg(dt.process.memory.resident_set_size), by: {k8s.pod.name}
| filter k8s.namespace.name == "easytrade"
| filter dt.process.memory.resident_set_size > 524288000
```

**Remediation**: Workflow kills/restarts leaking pod; alerts via SLO.

### 5. Flaky / Timeout Endpoints (frontend, loadgen)
**DQL for traces**:
```
fetch spans, from: now()-30m
| filter k8s.namespace.name == "easytrade"
| filter contains(span.name, "timeout") or contains(span.name, "flaky")
| summarize count(), avg(duration), by: {span.name, service.name}
```

## Full Investigation Flow (for AI/MCP or Manual SRE)
1. Start with DT Problems in easytrade namespace.
2. Drill into traces for root cause (e.g., calculation -> DB).
3. Use DQL above.
4. Trigger workflow for auto-remediation.
5. Verify with SLO dashboards.

See `automation/easytrade-self-healing/` for the actual workflow definitions (problem-triggered actions).

## Metrics & Evidence Collection
- Use dtctl or MCP to pull: `dtctl problems list --namespace easytrade`
- Dashboards: `dashboards/easytrade-microservices.yaml` and SLOs.
This setup generates real, investigable data rather than synthetic canned examples.

## References
- Main README: Reproducible setup and access.
- mcp-examples/: Use AI agents with these DQL/problems.
- Additional research and comparisons to other observability labs.
