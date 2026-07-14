# EasyTrade SRE Prompts for AI Agents (MCP + dtctl)

These prompts are optimized for use with Dynatrace MCP Server + external agents (Claude, Cursor, and other agents). They leverage the rich data from EasyTrade (19+ services, problem-operator, traces, logs).

## Core Context to Provide Agent
- Namespace: easytrade
- Key services: broker-service, frontend, calculationservice, loadgen, problem-operator, contentcreator
- Always start with open problems.
- Use DQL for evidence; cross with dtctl for actions.
- Reference: docs/easytrade-problems-and-remediation.md and dql-examples/

## Prompt 1: Investigate Current Problems
```
You are a Senior SRE specializing in Dynatrace and Kubernetes microservices.

Use available MCP tools or dtctl.

1. List all open problems in the easytrade namespace right now.
2. For the top problem: 
   - Get root cause analysis from Davis.
   - Pull relevant traces and spans.
   - Run DQL to show metrics/logs around the incident.
3. Output:
   - Hypothesis
   - Evidence (include exact DQL)
   - Recommended remediation (reference workflow if applicable)
   - Next steps
```

## Prompt 2: Analyze Deposit Flow Performance
```
Focus on the deposit / broker flow in EasyTrade.

- Find the slowest services and spans in the last hour.
- Use DQL for response time and error rate by service.
- Correlate with any problems or loadgen activity.
- Suggest optimizations or confirm if self-healing workflow would trigger.
Provide visualizations in text and actionable DQL.
```

## Prompt 3: Full RCA + Remediation for Specific Issue
```
Investigate high CPU or memory issues in calculationservice or broker.

Steps:
1. Query problems and entities.
2. Get distributed traces.
3. Analyze k8s metrics (pod CPU/memory).
4. Check if Ansible or DT workflow remediation is suitable.
5. Propose a fix and how to apply via dtctl or k8s.
```

## Prompt 4: SLO and Dashboard Health Check
```
Check current SLOs for EasyTrade services.

- Query SLO status for key services.
- Identify any breaching.
- Pull related dashboards.
- Recommend updates to monaco configs or workflows.
```

## Usage Tips
- Load the mcp-integration-guide.md context first.
- For custom agents: Inject the namespace filter and service list.
- Generate real data: Run loadgen or problem scenarios before querying.
- Combine with additional research for advanced patterns.

These demonstrate production SRE agent capabilities on real observability data — a key differentiator.
