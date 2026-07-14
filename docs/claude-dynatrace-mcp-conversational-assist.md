# Conversational Observability: Connecting Claude to Dynatrace via MCP

## Overview

Dynatrace's built-in Assist (Davis Copilot) provides scoped agentic analysis within the platform. However, it does not natively support external LLM integration. By using the **Dynatrace MCP Server**, Claude can act as a conversational front-end to Dynatrace, enabling natural-language investigation of problems, traces, logs, and Kubernetes state — grounded in live observability data.

This is the pattern Dynatrace promotes in 2026 for integrating with external AI agents (Claude, Atlassian Rovo, Azure SRE Agent, etc.).

## Architecture

```
User (voice/text)
      ↓
Claude (Desktop / Cursor / Claude Code)
      ↓  (MCP tools)
Dynatrace MCP Server
      ↓
Dynatrace Intelligence (Davis, Grail, Smartscape, Problems, Traces, Logs, K8s)
      ↑
EasyTrade cluster (loadgen, spans, errors, enriched pods in easytrade ns)
```

Claude handles conversational reasoning. MCP gives Claude structured access to live Dynatrace data — effectively wrapping Assist's capabilities in a more flexible LLM interface.

## Setup

### 1. Enable Dynatrace MCP Server

1. In your Dynatrace tenant, navigate to **Dynatrace Intelligence → MCP server**
2. Enable the server and generate connection details / scoped token
3. Required token scopes: DQL, problems, traces, entities, logs

### 2. Connect Claude to Dynatrace MCP

For Claude Desktop / Claude Code / Cursor:

```bash
# Using the official plugin
claude plugin marketplace add dynatrace/dynatrace-for-ai
claude plugin install dynatrace@dynatrace-for-ai
```

Or manually configure the MCP server endpoint in your Claude settings with the token from step 1.

Load the relevant skills from `dynatrace-for-ai`:
- `dt-dql-essentials`, `dt-obs-problems`, `dt-obs-tracing`
- `dt-obs-kubernetes`, `dt-obs-logs`, `dt-obs-services`

### 3. Example Queries

Once connected, Claude can answer questions grounded in your live EasyTrade data:

- "Investigate the recent broker-service errors in the easytrade namespace. Show the trace flow and correlated logs."
- "Give me a health report on the frontend and reverseproxy after the last load burst."
- "List current open problems in easytrade, drill into the most critical one with full trace details."
- "What would a good self-healing workflow look like for this issue?"

## Bidirectional Integration (Assist → Claude)

Built-in Assist cannot natively call external LLMs. Workarounds:

- **Dynatrace Workflows**: On problem detection, use an HTTP action to call the Claude API with problem context. Post the response back as a problem comment or custom event.
- **External bridge service**: Listen for Dynatrace webhooks, route to Claude, write results back to Dynatrace.
- **Notebooks / custom apps**: Mix Dynatrace queries with external API calls.

The MCP approach (Claude → Dynatrace) is the recommended and production-ready path for most use cases.

## Integration with This Portfolio

- Loadgen generates continuous realistic data (browser sessions, errors, timeouts)
- DynaKube with `metadataEnrichment` and `logMonitoring` ensures rich K8s context on all telemetry
- Self-healing workflows in `automation/` can be investigated and refined conversationally
- DQL queries from `dql-examples/` and `dashboards/` provide starting points for MCP-based analysis

## References

- [Dynatrace MCP documentation](https://docs.dynatrace.com/docs/platform/davis-ai/davis-copilot/mcp)
- [dynatrace-for-ai GitHub](https://github.com/Dynatrace/dynatrace-for-ai)
- [dynatrace-mcp GitHub](https://github.com/dynatrace-oss/dynatrace-mcp)
- `mcp-examples/mcp-integration-guide.md` in this repo
