# Hybrid MCP + dtctl Agent for Full Dynatrace Conversational Power (Including Dashboard Creation)

## Problem Statement
- Dynatrace MCP Server (the hosted/remote one) is intentionally scoped to ~17-20 read-focused tools:
  - DQL generation/explanation/execution
  - Problem/vulnerability investigation (Davis root cause)
  - K8s analysis
  - Timeseries forecasting
  - Entity resolution
  - Document lookup
- It excels at conversational intelligence and analysis **without logging into DT**.
- Limitation: No native support for write/creation actions like **creating or managing dashboards** (a very common user request). MCP is read-heavy by design for safety and focus.

This matches exactly what you observed in your production environment. Users don't want to log into Dynatrace — they want AI to do the work for them.

## The Solution: Hybrid Agent (MCP for Context + dtctl for Actions)
**dtctl** (the official Dynatrace CLI, kubectl-style) has full power for the missing pieces:
- `dtctl get dashboard <id> -o json --plain`
- Dashboard creation/update via JSON + apply (or the documented workflows)
- `dtctl query` for advanced DQL
- Workflow execution, settings management, much broader access

The **dynatrace-for-ai** repo + dtctl's own agent skill are built exactly for this hybrid:
- Load `dt-app-dashboards` skill (already in the cloned repo) — it teaches precise workflows for creating/modifying dashboards using dtctl under the hood.
- Install dtctl's dedicated skill: `npx skills add dynatrace-oss/dtctl` (or `dtctl skills install`)
- Combine with MCP (for rich, live context from your data) in a single agent.

The blog post confirms this pattern: "You can now also use dtctl ... in Claude Code alongside the Dynatrace MCP server to manage dashboards, run workflows, and execute DQL from your terminal."

### Recommended Architecture for Production Convenience
Use **LangGraph** (or Claude Code + skills) as the orchestrator:

1. **MCP tools** (via langchain-mcp-adapters or native in Claude): For conversational queries, pulling real-time traces/logs/problems from your complex prod environment.
2. **dtctl tools** (wrapped as LangGraph tools or via the dtctl skill): For actions like "create a dashboard for EasyTrade frontend errors" or "retrieve and analyze data from this dashboard".
3. **Custom EasyTrade scoping** (a custom troubleshooting prompt plus dt-app-dashboards rules).
4. **Safety layers for prod**:
   - Human-in-the-loop (LangGraph interrupts) before any write (dashboard create, etc.).
   - Scoped tokens (read-only for MCP, limited for dtctl actions).
   - Audit everything (Dynatrace will see the dtctl calls as coming from the agent user).
   - Start with read-only dtctl, graduate to writes.

This gives users a single conversational front-end (Claude, custom Slack/Teams bot, web chat, Cursor, etc.) that feels like "super Assist" without ever logging into DT.

## How to Build It (Concrete Steps & Code)

### 1. Install the Skills (in your agent environment)
```bash
# dtctl CLI itself
brew install dynatrace-oss/tap/dtctl   # or equivalent
dtctl auth login --context my-env --environment "https://YOUR_TENANT_ID.live.dynatrace.com"

# dtctl agent skill (teaches the LLM how to use dtctl safely)
npx skills add dynatrace-oss/dtctl

# The dashboards skill (from dynatrace-for-ai: skills/dt-app-dashboards)
# In Claude Code / Cursor: add the skill or point to the SKILL.md
```

Load these in your agent prompt:
- dt-app-dashboards (for exact JSON + dtctl create/update workflow)
- dt-dql-essentials
- A custom troubleshooting prompt (scope to namespace, loadgen scenarios, external URL if relevant)
- dtctl skill

### 2. LangGraph Hybrid Agent Example (Python)
This is a starter you can run/extend in your WSL lab (or prod agent host). It combines:
- MCP for DT intelligence
- Subprocess wrapper for dtctl (for dashboard creation)
- LangGraph for orchestration + memory + human approval

```python
import subprocess
from langchain_mcp_adapters.client import MultiServerMCPClient
from langgraph.prebuilt import create_react_agent
from langchain_anthropic import ChatAnthropic
from langchain_core.tools import tool

# 1. MCP client for Dynatrace (your remote tenant)
mcp_client = MultiServerMCPClient({
    "dynatrace": {
        "url": "https://your-tenant.live.dynatrace.com/mcp",  # or the MCP endpoint from tenant config
        "transport": "streamable-http",
        # Add your MCP token / auth here
    }
})
mcp_tools = mcp_client.get_tools()

# 2. dtctl tool wrapper (execute safely)
@tool
def run_dtctl(command: str, context: str = "my-env") -> str:
    """Run a dtctl command. Use for dashboard creation, queries, workflows.
    Examples: 'get dashboard <id> -o json --plain', 'query "fetch logs..." --plain'
    For dashboard create: follow dt-app-dashboards workflow — download first, modify JSON, then apply.
    """
    full_cmd = f"dtctl --context {context} {command}"
    result = subprocess.run(full_cmd, shell=True, capture_output=True, text=True)
    if result.returncode != 0:
        return f"Error: {result.stderr}"
    return result.stdout

# 3. LLM (Claude recommended for strong tool use + MCP)
llm = ChatAnthropic(model="claude-3-5-sonnet-20241022", temperature=0)

# 4. All tools: MCP (context) + dtctl (actions)
all_tools = mcp_tools + [run_dtctl]

# 5. LangGraph agent with system prompt (inject your EasyTrade rules + dashboard skill)
system_prompt = """
You are a production Dynatrace SRE agent for a complex environment.
- ALWAYS use MCP tools first for live data, problems, traces, DQL.
- For actions like creating dashboards, use run_dtctl + follow the dt-app-dashboards skill rules exactly:
  1. Load dt-dql-essentials and dt-app-dashboards.
  2. Validate queries with dtctl query.
  3. For updates: ALWAYS `dtctl get dashboard <id> ...` first.
  4. Scope to relevant services/namespace if applicable (e.g. easytrade patterns).
- Never perform writes without user confirmation (use human-in-the-loop).
- Retrieve/hold data from dashboards using dtctl get + analysis.
- User never needs to log into Dynatrace — do everything conversationally.
"""

agent = create_react_agent(llm, all_tools, prompt=system_prompt)

# Example usage
response = agent.invoke({
    "messages": [
        ("human", "Create a new dashboard for EasyTrade frontend errors and long_sell issues. Include recent traces, RUM data, and loadgen visits. Use the dt-app-dashboards workflow.")
    ]
})
print(response)
```

### 3. For Pure Claude Code / Cursor (No Custom Code)
- Add the Dynatrace MCP connector.
- Add dtctl skill + dt-app-dashboards skill.
- Instruct Claude: "Use dtctl for dashboard creation following the skill. Combine with MCP for context."
- It will call dtctl in the terminal for you (as shown in the official blog).

### 4. Production Hardening Ideas
- Wrap dtctl calls in a controlled service (API gateway) instead of raw subprocess for audit/logging.
- Use LangGraph's `interrupt` for approval before `dtctl apply` or dashboard deploy.
- Separate tokens: MCP read token + limited dtctl token (only dashboard + query scopes).
- Observe the agent itself with Dynatrace (it will appear as a service calling dtctl/MCP).
- For your complex prod: Start with read-only hybrid (MCP + dtctl query), add write actions per service/team with approvals.

## Next Steps I Can Execute for You
- Customize the LangGraph example above with your exact tenant, EasyTrade services, and a sample dashboard JSON (using the dt-app-dashboards references).
- Create a full reusable "hybrid-dtctl-mcp" skill in your dynatrace-for-ai fork.
- Prototype running the agent against your lab EasyTrade data (or remote tenant) and actually create a test dashboard.
- Add human-in-the-loop and persistence.
- Document a Slack/Teams bot wrapper so end users just chat there.

This hybrid is currently the most powerful and practical way to deliver "Dynatrace without logging in" for complex environments.

The lab (EasyTrade + loadgen + a custom prompt + DynaKube) is well suited to validating the pattern before rolling to production.

Let me know the next concrete thing to build or test (e.g., "create the dashboard skill file" or "run a test agent that creates a sample EasyTrade dashboard via dtctl"). 

Current loadgen status: 8 replicas active on http://YOUR_WSL_IP:8081 generating realistic data for testing.