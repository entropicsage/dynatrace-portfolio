# Conversational AI Approaches for Dynatrace (June 2026)

**Scope**: This document compares two approaches for making Dynatrace "more conversational":
- **A**: Custom AI chatbot armed with skills + API access, connected to Dynatrace control.
- **B**: AI chatbot directly connected to Dynatrace MCP Server.
Research real guides, implementations, community examples, and what maximizes power for conversational execution (SRE-like troubleshooting, root cause, analysis) on top of Dynatrace data (problems, traces, logs, DQL, Smartscape, Davis AI, K8s).

**Research Sources** (executed via live web/X/GitHub/docs):
- Official Dynatrace MCP docs (https://docs.dynatrace.com/docs/dynatrace-intelligence/dynatrace-mcp and shortlink).
- Dynatrace blog: "Bring real-time production insights into Claude Code with the Dynatrace MCP Server" (March 30, 2026).
- GitHub: Dynatrace/dynatrace-for-ai (skills, prompts, dtctl integration).
- X/Twitter discussions (agentic AI, MCP, Rovo, Claude Code, LangChain).
- Community examples: Pavan Belagatti (dev.to "Agentic Observability"), ARIA project (GitHub), Riley Brown/Avthar MCP tutorials, LangChain announcements.
- Cross-referenced with hands-on lab work (dynatrace-for-ai skills, a custom scoped troubleshooting prompt, EasyTrade load-generator data).

## Executive Recommendation
**B (MCP-connected chatbot) is currently the best and most recommended path for maximizing conversational power with Dynatrace.**

- It is the official, production-focused direction from Dynatrace in 2026.
- MCP (Model Context Protocol, Anthropic-originated) acts like a "universal USB port for AI agents" — standardized, dynamic tool discovery, streaming, stateful/multi-turn support, far less boilerplate than custom APIs.
- Delivers true conversational experiences: natural language questions grounded in live production data (traces, problems, logs, root cause via Davis, topology) without leaving the chat/IDE/Jira.
- Pairs perfectly with skills/prompts from dynatrace-for-ai and custom domain prompts (like your EasyTrade one).
- Community momentum: Claude Code, Atlassian Rovo (Jira-native), multi-MCP agents (with GitHub, Slack, Arize, Port), LangGraph hybrids.

**A (Custom API + skills chatbot)** is viable for full control or non-MCP clients but involves significantly more maintenance and is generally inferior for fluid, conversational agentic workflows. It is complementary at best (e.g., use MCP tools inside a custom LangGraph agent).

**Hybrid winner for power users**: LangGraph (LangChain) orchestration + Dynatrace MCP Server (via official adapters) + skills + custom prompts. This gives framework power + standardized, maintained Dynatrace tools.

Your EasyTrade setup (loadgen-driven realistic browser sessions, DynaKube with metadataEnrichment + logMonitoring, correlated traces/logs in `easytrade` namespace, external access at http://YOUR_WSL_IP:8081) is an **excellent** testbed for either, but shines with MCP.

## Detailed Comparison: Approach A vs B

### Approach B: AI Chatbot Connected to Dynatrace MCP Server
**Description**: The chatbot (Claude, Cursor, custom agent, Rovo, etc.) connects via the standardized MCP protocol. Dynatrace exposes tools/resources for DQL (generate/explain/run), problems/vulnerabilities (Davis root cause + impact), traces/logs/metrics, K8s events, timeseries forecasting, entity resolution, docs. The LLM discovers tools dynamically and calls them conversationally.

**Key Strengths (from official docs + blog + X)**:
- **Conversational by design**: Ask in plain English ("Why is checkout slow after the last deploy?", "Investigate this Jira error using production data", "Show correlated logs and traces for deposit_and_long_buy_error in easytrade"). Gets live data + analysis without switching apps.
- Low integration effort: One connector setup works across clients.
- Dynamic + advanced protocol features: Tool discovery at runtime, streaming results, "LLM-in-the-tool" for sub-reasoning, better state/memory handling than raw function calling.
- Official use cases: DQL help, problem investigation, K8s analysis, forecasting, product Q&A.
- Real production grounding: Pulls actual Smartscape topology, Davis causal AI insights, OneAgent-enriched data.
- Integrations highlighted: Claude Code (in-IDE troubleshooting), Atlassian Rovo (Jira/JSM "what's broken in prod?"), Port as context lake.
- Companion: dtctl CLI for actions (dashboards, workflows, DQL) inside the same agent session.

**Setup (from Dynatrace blog March 2026)**:
1. In Claude (Code/Desktop/Chat): Go to Connectors → search "Dynatrace" → install "Dynatrace MCP Server" connector.
2. Follow prompts for tenant URL + scoped API token.
3. (Optional but recommended) Load dynatrace-for-ai skills plus a custom scoped troubleshooting prompt.
4. Query naturally. Example from blog: Receive Jira ticket → ask Claude → it pulls root cause, logs, traces, profiling data via MCP.

**Community Guides & Real Implementations**:
- **Official Blog**: https://www.dynatrace.com/news/blog/bring-real-time-production-insights-into-claude-code-with-the-dynatrace-mcp-server/ — Details Claude Code integration, troubleshooting without leaving the IDE, combining with dtctl.
- **Pavan Belagatti dev.to**: "Agentic Observability: How I wired a real app with Dynatrace MCP in minutes" — Practical e-commerce example + layering AI agents. Follow-ups add Port for richer context.
- **ARIA (open source)**: https://github.com/Nidhicodes/aria — Gemini + Google Agent Development Kit + Dynatrace MCP + Arize Phoenix MCP. Single reasoning pass correlating infra (Dynatrace: pods, latency, memory) with LLM issues (hallucinations). Streams reasoning, confidence scores, proposes fixes, human-in-the-loop. FastAPI + Next.js dashboard. Excellent advanced multi-MCP example.
- **Atlassian Rovo GA**: https://www.dynatrace.com/news/blog/dynatrace-mcp-server-for-atlassian-rovo-investigate-production-problems-without-leaving-jira-or-jsm/ — Native Jira conversations.
- **General MCP + Claude tutorials**: Riley Brown, Avthar, Anthropic docs (adaptable; focus on config for Dynatrace server).
- **LangChain angle**: Official langchain-mcp-adapters let you drop Dynatrace MCP tools into LangGraph agents with minimal code. Dynatrace also auto-instruments/traces LangChain apps.
- **dynatrace-for-ai GitHub**: https://github.com/Dynatrace/dynatrace-for-ai — Skills (DQL essentials, obs-problems/tracing/k8s/logs/services/frontends, dashboards/notebooks, predictive, cloud-specific) + prompts (troubleshoot-problem, health-check, incident-response, daily-standup, performance-regression, investigate-error). Explicitly recommends MCP for native agents; skills teach agents the domain. Claude Code plugin install command included. dtctl skill as alternative for CLI-focused agents.

**X/Community Sentiment**: MCP is the "emerging consensus for agentic observability." Reduces N×M glue code. Better for conversational/stateful agents than raw APIs. Teams combine multiple MCP servers (Dynatrace for obs + code + ticketing) for unified agents. Early 2026 momentum around Claude Code + Rovo.

**Limitations**: Requires MCP-compatible client. Ecosystem growing (more servers/adapters in 2026). Token scoping important for security.

### Approach A: Custom AI Chatbot with Skills + Direct API Access
**Description**: Build or use a framework-based chatbot (LangChain/LangGraph, LlamaIndex, custom Python/JS agent, etc.). Manually define tools that call Dynatrace REST APIs (Grail for DQL/logs/traces, Problems API, Smartscape, entity APIs, etc.), or wrap dtctl. Inject skills/prompts from dynatrace-for-ai as system knowledge or RAG. Connect to "DT control" via API keys/tokens.

**Key Strengths**:
- Full control and flexibility: Any LLM, custom memory/reasoning loops, multi-agent orchestration, non-standard workflows, deep customization (e.g., your own self-healing logic tied to specific EasyTrade services).
- Works everywhere: No dependency on MCP support.
- Skills integration: dynatrace-for-ai skills provide ready-made instructions/references (DQL pitfalls, correlation rules, entity mapping, etc.) that you can load progressively or embed.
- dtctl as a bridge: The repo provides a dedicated skill for agents to use the kubectl-like CLI for queries and actions.

**Key Weaknesses (why less ideal for pure "conversational" power)**:
- High boilerplate: You must implement auth, tool schemas (JSON descriptions for every DQL/problems endpoint), response parsing, error handling, retries, streaming. Tools are static (LLM doesn't discover new ones dynamically as easily).
- Harder for fluid conversation: Agents built on raw function calling struggle more with long multi-turn, stateful sessions compared to MCP's protocol features.
- Maintenance burden: Keep tools in sync with Dynatrace API changes, handle pagination, rate limits, entity resolution quirks yourself.
- Less "grounded" out of the box: More risk of hallucination on DQL or topology unless you heavily engineer the skills/prompts.
- From research: Discussions position this as the "old way" or for prototypes/simple scripts. Even LangChain advocates MCP adapters for Dynatrace to avoid custom tool writing.

**Examples/Guides Found**:
- Limited prominent "wow" public implementations compared to MCP stories. More internal/custom SRE bots or one-off LangChain experiments.
- dynatrace-for-ai repo itself supports this path via skills + dtctl (for agents without native MCP).
- General observability + LLM patterns: People use LangChain for agents that query multiple data sources (including custom Dynatrace wrappers). Dynatrace's own auto-instrumentation helps observe your custom agent.
- No strong "this beats MCP" success stories in 2026 X/docs; instead, advice is "use MCP where possible, supplement with custom."

**When to Choose A**:
- You need features outside MCP tools (e.g., triggering specific workflows, bulk changes, integration with non-MCP systems in a very custom loop).
- Using an LLM/framework without good MCP support.
- Prototyping, or when owning the entire agent stack matters (e.g., a custom "EasyTrade SRE Agent" with full sub-agents).

## What Maximizes Conversational Execution Power in Dynatrace?
From all sources, the winning patterns (2026 state of the art):

1. **MCP as the foundation for observability tools** — Standardized, maintained by Dynatrace, works across clients.
2. **Layer Agent Skills + custom prompts** — dynatrace-for-ai provides battle-tested knowledge (DQL rules, obs best practices, problem investigation flows). Always scope prompts (e.g., k8s.namespace.name == "easytrade", reference loadgen scenarios, prioritize correlated traces).
3. **Client choice for conversation quality**:
   - Claude (Code/Desktop) for developer/SRE workflows — excellent at tool use + natural dialogue.
   - Atlassian Rovo for team/ticket-integrated conversations.
   - LangGraph for complex orchestration (with MCP adapters).
4. **Data quality first** (you already excel here): Sustained + burst load (your CronJob + scaling), full-stack instrumentation, metadata enrichment, log correlation with traces. This makes every conversational query more accurate and useful.
5. **Multi-source agents**: Combine Dynatrace MCP with GitHub (code), Linear/Slack (tickets), Arize (LLM evals), Port (context), etc.
6. **Hybrid for ultimate power**: LangGraph agent that uses MCP tools for Dynatrace + custom tools for actions. Stream reasoning, add confidence/human-in-loop (as in ARIA).
7. **Built-in Assist as complement**: Use native Dynatrace Intelligence/Assist for quick in-UI scoped queries (Problems app, dashboards). Use external MCP chat for deep, free-form, multi-turn conversational SRE work.
8. **Practical tips from community**:
   - Start simple: Enable MCP → connect to Claude → test with your loadgen data.
   - Scope aggressively in prompts (namespace, services like easytrade-frontend/reverseproxy/broker-service, time windows, specific scenarios).
   - Iterate: "Show the DQL", "Correlate with logs", "Recommend workflow".
   - Security: Use least-privilege tokens; review what tools expose.
   - Observe your agent: Dynatrace traces LangChain/Claude sessions too.

**Real-World Power Examples**:
- Developer: In Claude Code, paste error or review PR → Claude pulls exact production traces/logs/problems for that service/path.
- SRE in Jira: Rovo answers "investigate high error rate on offerservice" with Davis root cause + remediation suggestions.
- Advanced agent: ARIA-style system that reasons across infra + AI model health in one pass.
- Your EasyTrade: Conversational troubleshooting of loadgen-induced problems (long_sell_error, deposit_and_long_buy_timeout) with full context, then auto-suggest or trigger self-heal workflows.

## Gaps & Future Outlook
- MCP ecosystem still maturing (more adapters, more servers expected).
- No evidence of Dynatrace exposing "call external LLM" from built-in Assist (one-way: external agents call DT).
- Custom API work is still needed for full autonomy (e.g., Workflow + Claude API bridge for DT-initiated calls).
- Best practice evolution: Watch Dynatrace blogs, KubeCon/observability events, LangChain releases. MCP appears to be winning for "conversational execution."

## Recommended Next Steps
1. **Prioritize B (MCP)**: Enable Dynatrace MCP Server in your tenant (Dynatrace Intelligence section). Connect to Claude (use the plugin or Connectors UI). Load skills plus a custom scoped troubleshooting prompt.
2. **Enhance with hybrid if desired**: Add langchain-mcp-adapters if building a custom orchestrator.
3. **Keep data fresh**: Run the load generator continuously (multiple replicas plus CronJob bursts) to keep problems and traces flowing.
4. **Document & demo**: Combine this research with the companion docs (dynatrace-assist-best-practices.md, claude-dynatrace-mcp-conversational-assist.md) and a custom prompt for an end-to-end "Agentic Observability with Dynatrace + Claude" demo.
5. **Test prompts** (tailored to EasyTrade):
   - "Using easytrade namespace data and recent loadgen visits (long_sell_error, deposit_and_long_buy_timeout), perform root cause analysis with Davis, show correlated traces/logs, and suggest a remediation workflow."
   - "Health check on easytrade-frontend and reverseproxy. Pull live metrics, any problems, and frontend RUM data."

**Files Updated/Created**:
- This research summary.
- Prior: claude-dynatrace-mcp-conversational-assist.md and dynatrace-assist-best-practices.md (already reference MCP + skills).

**Sources for Further Reading** (key ones):
- Dynatrace MCP docs + blog (linked above).
- https://github.com/Dynatrace/dynatrace-for-ai
- Pavan Belagatti dev.to article on agentic observability.
- ARIA GitHub for advanced multi-MCP.
- Atlassian Rovo integration blog.

This is the current (mid-2026) state of the art based on official + community sources. MCP + skills is the clear path to the most powerful, low-friction conversational experience on Dynatrace data.

---
*Research performed live 2026-06-10. Tailored to EasyTrade microservices portfolio on kind-dt-homelab. Loadgen active at 8 replicas.*