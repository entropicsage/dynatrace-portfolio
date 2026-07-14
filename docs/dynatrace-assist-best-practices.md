# Dynatrace Assist Best Practices for EasyTrade Microservices

## Why Assist Feels Limited (and How to Make It Much More Capable)

Dynatrace Assist (part of Dynatrace Intelligence) is **not** a general-purpose chatbot like Claude or ChatGPT. It is a **scoped, deterministic + agentic** interface built on Davis causal AI, Grail, and Smartscape. 

It excels at precise, production-grounded tasks (root cause, impact analysis, log explanation, recommending actions) **when**:
- Your data is rich, correlated, and fully instrumented.
- Questions use platform-native terminology and are tightly scoped.
- You work iteratively and provide context.

Vague or out-of-domain questions ("tell me about the app" or free-form chat) commonly trigger "I don't understand" or re-prompts. This is by design for reliability and guardrails.

**There is no user-level fine-tuning or custom system prompt for the built-in Assist.** Improvement comes from:
- Data quality & enrichment
- Precise, iterative prompting techniques
- Leveraging context in the right parts of the UI (Problems, Notebooks, Dashboards)
- Combining with Workflows, Notebooks, DQL, and (for truly conversational power) the MCP Server + external agents (Claude + dynatrace-for-ai skills)

Your EasyTrade setup (loadgen-driven browser sessions, metadata enrichment, logMonitoring, DynaKube v1beta6, correlated traces/logs/spans in the `easytrade` namespace) is already excellent fuel for Assist.

## Core Techniques to Make Assist More Capable

### 1. Maximize Data Quality (You Are Already Doing This Well)
- Keep sustained + bursty loadgen running (`kubectl scale deployment easytrade-loadgen -n easytrade --replicas=8-12` and the CronJob `easytrade-load-burst`).
- Ensure metadataEnrichment + logMonitoring are active on DynaKube (already configured).
- Generate real problems via the problem-operator and loadgen error/timeout paths (deposit_and_long_buy_error, long_sell_error, etc.).
- Verify correlation: Logs should carry trace IDs from OneAgent-instrumented services (Java/.NET/Node/Go).

Live evidence (as of 2026-06-10):
- Loadgen actively running visits: `long_sell_success`, `deposit_and_long_buy_timeout`, `long_sell_timeout`, etc.
- Spans flowing with full k8s attributes, trace IDs, DB calls to TradeManagement, HTTP routes, user agents, etc.
- Services: easytrade-manager, easytrade-offerservice, frontend, etc. all visible with Smartscape relationships.

### 2. Prompting Techniques That Work
Use **specific, grounded, iterative** language. Always reference:
- Namespace: `easytrade`
- Entities: `easytrade-frontend`, `easytrade-frontendreverseproxy`, `broker-service`, `credit-card-order-service`, `easytrade-manager`
- Time windows: "in the last 30 minutes", "since the last load burst"
- Scenarios: "during deposit_and_long_buy_error visits from loadgen"
- URL: the external one `http://YOUR_WSL_IP:8081`

**Good patterns**:
- "Analyze the recent performance issues on easytrade-frontend in the easytrade namespace during loadgen visits. Correlate with broker-service and database calls. Show Smartscape impact and suggest remediation."
- "Explain the root cause of the long_sell_error scenario from loadgen. Include the trace flow, any ERROR spans, and correlated logs."
- "What problems are currently active in the easytrade namespace? For the most recent one, give impact, root cause hypothesis using Davis, and recommended next actions or workflows."
- Follow-ups: "Show the exact DQL for that trace", "Drill into the frontend reverseproxy logs for the same timeframe", "Recommend a workflow to restart the affected deployment".

**Avoid**:
- Broad/vague: "Tell me what's wrong with the app"
- Out-of-scope: Questions about non-observed systems or general knowledge

Start in the **Problems app** or a specific service dashboard for built-in context.

### 3. Use the Right UI Surfaces (Context Helps a Lot)
- **Problems app** → Best for root cause and impact. Ask Assist while a problem is selected.
- **Notebooks** → For multi-step analysis. Paste DQL results and ask Assist to interpret/explain/summarize.
- **Dashboards** (your EasyTrade Microservices Portfolio) → Ask about tiles or specific services shown.
- **Logs & Traces** explorers → Scope first, then ask Assist to analyze patterns or explain errors.
- **Smartscape** → Great for topology questions.

### 4. Combine with Workflows & Automation (Agentic Power)
Assist can recommend or comment on workflows. You already have:
- `easytrade-frontend-self-heal.yaml`
- `easytrade-broker-self-heal.yaml`
- `easytrade-general-remediation.yaml`

Tip: When asking about a problem, add: "...and suggest or trigger the appropriate self-healing workflow if it matches frontend or broker issues."

You can also ask Assist to help author or improve workflow definitions.

### 5. Companion Tools (Often More Powerful Than Pure Chat)
- **DQL directly** in search bar or Notebooks (more reliable for complex queries).
- **dtctl** for scripted/declarative work (`dtctl query 'fetch spans | filter k8s.namespace.name == "easytrade" | limit 5'`).
- **Dashboards + SLOs** for at-a-glance + Assist explanations.
- **MCP Server + external agents** (recommended for truly capable conversation — see below).

### 6. The Real Path to "Awesome" Conversational Experience: MCP + Claude (or similar)
For free-form, multi-turn, highly capable conversation that still leverages all of Dynatrace's deterministic power:

- Enable the **Dynatrace MCP Server** in your tenant (under Dynatrace Intelligence).
- Connect it to Claude Desktop / Cursor / Claude Code (or Atlassian Rovo, Port, Azure SRE Agent, etc.).
- Use skills and prompts from the `dynatrace-for-ai` project, including a custom scoped troubleshooting prompt.
- Result: A much stronger conversational partner that can call Dynatrace tools (DQL, problems, traces, K8s) behind the scenes while speaking naturally.

This is the current recommended way to overcome the conversational limitations of built-in Assist.

## Quick Test Prompts Tailored to Your EasyTrade Lab

1. "List active or recent problems in the easytrade namespace. For the most recent loadgen-related one, provide root cause using Davis, affected entities, and correlated log excerpts."

2. "During the last 15 minutes of loadgen activity (scenarios like long_sell_error and deposit_and_long_buy_timeout), what was the error rate and trace characteristics on easytrade-frontend and reverseproxy? Show key spans and suggest fixes."

3. "Give a health summary of the easytrade microservices. Highlight any services with elevated response times or errors in the current load burst. Reference Smartscape dependencies."

4. "Explain the trace for a deposit_and_long_buy_success visit from loadgen. Include frontend to manager to database flow and any notable timings."

Iterate with follow-ups like "Show the DQL behind that analysis" or "What workflow would remediate this?"

## Ongoing Improvements
- Continue running the loadgen CronJob for fresh, realistic data.
- Monitor Dynatrace release notes (v1.340+) for Assist/Intelligence enhancements.
- Provide feedback inside the platform or via Dynatrace support — this is still maturing in mid-2026.
- For maximum capability right now, pair built-in Assist (for quick in-UI work) with MCP + Claude (for deep conversational SRE work).

This guide lives in your portfolio so you can reference and expand it as you test more scenarios.

---
*Generated with live EasyTrade data from kind-dt-homelab on 2026-06-10. Loadgen actively producing browser sessions and spans.*
