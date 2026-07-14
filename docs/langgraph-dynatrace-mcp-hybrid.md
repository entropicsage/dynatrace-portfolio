# LangGraph + Dynatrace MCP: Production-Grade Conversational Agents

## What is LangGraph?
LangGraph (from LangChain) is a **low-level orchestration framework** for building reliable, stateful, long-running AI agents and multi-actor applications.

It is **not** a chatbot or an LLM itself. It is the "control plane" or "workflow engine" that sits between:
- Your LLM (e.g., Claude via Anthropic SDK or LangChain)
- Tools (including Dynatrace via MCP)
- Memory, persistence, human oversight, cycles, streaming, etc.

### Simple Analogy
- **Pure Claude + Dynatrace MCP Server**: You have a very smart, conversational SRE who can instantly query your live EasyTrade data (problems, traces, logs, Davis insights) using natural language. Great for interactive troubleshooting.
- **LangGraph "too"**: You give that SRE a structured playbook (a graph of steps), a notebook for remembering context across sessions, the ability to ask you for approval before taking risky actions, and tools to execute full workflows (not just answer questions). It still feels conversational when you talk to it, but the execution is reliable and programmable.

LangGraph models agents as **graphs**:
- **Nodes**: Individual steps (LLM calls, tool calls, custom functions like "scale loadgen", "run dtctl query").
- **Edges**: How steps connect (conditional routing, cycles for retries/loops, parallel branches).
- Built-in features: Persistence (checkpointing state to a database), human-in-the-loop (interrupts), time travel (rewind/replay agent runs), streaming, fault tolerance.

## Why Add LangGraph to Dynatrace MCP?
From the 2026 research:
- Pure MCP (with Claude Code/Desktop/Rovo) is excellent for **conversational access** and low-friction use.
- LangGraph + `langchain-mcp-adapters` is the recommended hybrid for **production-grade conversational execution**.

Benefits specific to your goals:
- **More than chat**: Turn natural language requests into multi-step actions. Example: "Investigate the recent long_sell_error in easytrade, correlate with loadgen visits, pull full traces/logs via Dynatrace, then suggest and (with approval) apply the matching self-heal workflow."
- **Reliability & control**: Cycles for "retry with different DQL if first query fails", persistence so the agent remembers previous investigations, human-in-the-loop before scaling your loadgen or restarting pods in the kind cluster.
- **Multi-tool orchestration**: Combine Dynatrace MCP tools (for data) with other MCP servers (GitHub for code, Slack for notifications) + custom tools (kubectl for your EasyTrade namespace, dtctl).
- **Observability of the agent itself**: Dynatrace can trace the LangGraph agent (LangChain has native instrumentation), and the agent can query its own observability via Dynatrace MCP.
- **Stateful & long-running**: Perfect for SRE-style agents that run over minutes/hours (e.g., monitor a load burst, analyze results, remediate).

Official bridge: `langchain-mcp-adapters` (https://github.com/langchain-ai/langchain-mcp-adapters) converts any MCP server (including Dynatrace's) into native LangChain Tools that LangGraph agents can use seamlessly. Works with Claude as the LLM.

## How It Fits Your EasyTrade + Dynatrace Setup
Your current assets are a perfect foundation:
- Live data from loadgen (8 replicas @ http://YOUR_WSL_IP:8081).
- Dynakube with enrichment + log monitoring.
- A custom troubleshooting prompt (scope to `k8s.namespace.name == "easytrade"`, reference specific loadgen scenarios, prioritize correlated traces).
- Existing self-healing workflows.
- Portfolio docs on MCP + Assist best practices.

A LangGraph agent can become your "conversational SRE operator":
1. User (you, via voice/chat/CLI) gives a high-level goal.
2. Agent uses Dynatrace MCP tools (via adapter) to investigate (problems, spans, logs).
3. Applies your custom EasyTrade rules/prompt logic.
4. Executes or recommends actions (scale loadgen, rollout restart, query dtctl).
5. Streams updates back conversationally.
6. Persists the investigation for later review or time travel.

This is the "maximize the power of conversational execution" pattern highlighted in research (ARIA project does something similar with multiple MCP servers + agent framework).

## Minimal Starter Concept (Python + LangGraph + Dynatrace MCP)
(You can run this in your WSL environment with the right keys/tokens.)

```python
from langchain_mcp_adapters.client import MultiServerMCPClient
from langgraph.prebuilt import create_react_agent
from langchain_anthropic import ChatAnthropic

# 1. Connect to your Dynatrace MCP Server (configure with your tenant + token)
mcp_client = MultiServerMCPClient(
    {
        "dynatrace": {
            "url": "your-dynatrace-mcp-endpoint",  # From tenant MCP setup
            "transport": "streamable-http",  # or stdio if self-hosted
            # auth headers with your DT token
        }
    }
)

# 2. Get tools (Dynatrace MCP tools become LangChain tools)
tools = mcp_client.get_tools()

# 3. LLM (Claude works great with tool use)
llm = ChatAnthropic(model="claude-3-5-sonnet-20241022", temperature=0)

# 4. Create a LangGraph ReAct agent (or custom graph for more control)
agent = create_react_agent(llm, tools)

# 5. Run conversationally (with your EasyTrade prompt context injected)
response = agent.invoke({
    "messages": [
        ("system", "You are an EasyTrade SRE agent. ALWAYS scope to k8s.namespace.name == 'easytrade'. Use loadgen scenarios like deposit_and_long_buy_error. Reference external URL http://YOUR_WSL_IP:8081. Load dt-dql-essentials and dt-obs-problems skills if available."),
        ("human", "Investigate recent problems and long_sell_error visits in the easytrade namespace. Pull correlated traces and logs, then recommend next actions.")
    ]
})

print(response)
```

This agent can:
- Use natural language with you.
- Call real Dynatrace tools (DQL, problems, traces) via MCP.
- Follow your custom rules.
- Be extended with custom nodes for Kubernetes actions (e.g., via kubectl Python client or dtctl).

For full graphs with persistence/human-in-the-loop, use LangGraph's `StateGraph` instead of the prebuilt ReAct agent.

## Getting Started Recommendations
1. Enable Dynatrace MCP Server in your tenant first (as covered in previous docs).
2. Install: `pip install langchain langgraph langchain-mcp-adapters langchain-anthropic`
3. Get a Claude API key (or use Claude Code if it supports MCP natively).
4. Test with the Dynatrace MCP tools directly in a simple LangGraph agent.
5. Inject the custom troubleshooting prompt as system context.
6. Add custom tools for your cluster (scaling loadgen, etc.).
7. Observe the agent with Dynatrace (it will appear as its own service).

LangGraph provides the "execution" layer while preserving the conversational interface.

This document is the companion to the main research summary (`dynatrace-conversational-ai-research-2026.md`).

---
*Created for Tim's EasyTrade + Dynatrace portfolio. Loadgen active as of 2026-06-10.*
