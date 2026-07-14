# Dynatrace MCP + AI Agent Integrations (for Portfolio)

This demonstrates MCP (Model Context Protocol) and external AI agent integrations — key differentiators for modern Dynatrace SRE / Observability Architect / Consultant roles ($120k–$200k+).

## Why MCP for Dynatrace Roles?
- Dynatrace Intelligence / Assist is powerful but scoped/agentic (not fully conversational).
- **Dynatrace MCP Server** (included with SaaS): Exposes problems, DQL, traces, logs, topology, Davis as discoverable tools to Claude, Cursor, Azure SRE Agent, Atlassian Rovo, custom agents.
- Enables natural language SRE work: "Investigate the EasyTrade broker errors" → root cause + traces + actions.
- From research: Preferred over pure custom API for conversational power (see dynatrace-for-ai and hybrid patterns).

## Setup (Tenant Admin)
1. In Dynatrace UI: Dynatrace Intelligence → Apps & Settings → MCP Server → Enable.
2. Generate token with appropriate scopes (Read entities/metrics/logs/problems + actions as needed).
3. URL typically: https://mcp.<env-id>.live.dynatrace.com or similar.
4. Governance: Tools selection, user permissions, logging.

## Integration Examples
- **dynatrace-for-ai** (https://github.com/Dynatrace/dynatrace-for-ai): Skills (dt-dql-essentials, dt-obs-problems, dt-obs-tracing, dt-obs-kubernetes...) + prompts (dt-troubleshoot-problem: start with problems, scope to timeframe, extract traces).
  - Install in Claude/Cursor: npx skills add dynatrace/dynatrace-for-ai
  - .claude-plugin / .cursor-plugin configs in the repo.

- **Hybrid MCP + dtctl + skills** (see sibling dynatrace-azure-sre-agent):
  - skills_loader.py loads 15+ skills for "speak Dynatrace".
  - mcp_adapter.py uses streamablehttp_client for remote MCP tools.
  - dtctl_tools.py for actions MCP doesn't cover (rich dashboards, apply, delete).
  - EasyTrade context: k8s.namespace.name == "easytrade", loadgen scenarios.

- **MCP**: Config in your MCP client under mcp_servers.

## EasyTrade Demo Usage
Provide agent context:
- Namespace filter for all queries.
- Service list (broker-service, frontend, calculationservice, loadgen, problem-operator...).
- Current ingress URL for loadgen.
- "Always start with problems / root cause agent."

Example prompt (from dynatrace-for-ai):
" You are a Senior SRE. Use MCP tools or dtctl for all queries. Start with open problems in easytrade namespace. Reconstruct flows using traces. Output: hypothesis, evidence (DQL shown), actionable steps."

## Verification
- Run loadgen bursts (see easytrade-load-generation.md reference) to generate real problems/traces/spans.
- Test: "What is the current status of EasyTrade deposit flow?"
- Cross-verify with dtctl query and tenant UI.

## Job Alignment
This shows you can:
- Connect rich Dynatrace data (from EasyTrade microservices + problem-operator) to external agents.
- Overcome Assist limitations with MCP.
- Build production SRE agents (Azure OpenAI, Claude, etc.).
- Combine with dtctl for full control (dashboards, workflows).

References:
- dynatrace skill references (dynatrace-intelligence-mcp-and-for-ai.md, hybrid-mcp-dtctl-for-external-llms.md)
- Official: Dynatrace MCP docs + dynatrace-for-ai GitHub (108+ stars, active MCP plugin work)
- Live in this homelab with 19+ services.

Clone dynatrace-for-ai and the azure-sre-agent for full code.
