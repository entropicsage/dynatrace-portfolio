#!/usr/bin/env python3
"""
Dynatrace API & dtctl Examples for Portfolio
Demonstrates skills for Senior Dynatrace Engineer, Observability Architect, and SRE roles.

Covers:
- dtctl wrappers (preferred for this env, validated via doctor)
- Direct Dynatrace Environment/Configuration API examples (curl + Python requests)
- EasyTrade-specific queries (k8s.namespace.name == "easytrade")
- Problems, DQL, dashboards, entities, spans
- Ties directly to job requirements: scripting (Python/Bash), API automation, DQL, Davis/problems, K8s observability, automation

Run: python3 api-examples/dynatrace-dtctl-api-examples.py
Requires: dtctl configured with 'my-env' context (or set DTCTL_CONTEXT)
Optional: pip install requests (for raw API examples; dtctl path works without)

Sources: Dynatrace API docs (Environment API for problems/metrics/DQL, Configuration for dashboards), dynatrace-for-ai skills, live EasyTrade homelab.
"""

import os
import subprocess
import json
import sys
from pathlib import Path
from typing import Dict, Any, List, Optional

# Config
DTCTL = os.getenv("DTCTL_PATH", "dtctl")
DEFAULT_CONTEXT = os.getenv("DTCTL_CONTEXT", "my-env")
DT_API_URL = os.getenv("DT_API_URL", "https://YOUR_TENANT_ID.apps.dynatrace.com")  # Update per tenant
DT_API_TOKEN = os.getenv("DT_API_TOKEN", "")  # For raw API examples; use dtctl for most

def run_dtctl(args: List[str], timeout: int = 60) -> Dict[str, Any]:
    """Internal dtctl runner. Matches validated patterns from portfolio agent code."""
    cmd = [DTCTL] + args + ["--context", DEFAULT_CONTEXT]
    if "--plain" not in " ".join(args):
        cmd.append("--plain")
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=timeout,
            check=False
        )
        output = result.stdout.strip()
        error = result.stderr.strip()
        success = result.returncode == 0
        parsed = None
        if output and (output.startswith("{") or output.startswith("[")):
            try:
                parsed = json.loads(output)
            except:
                pass
        return {
            "success": success,
            "command": " ".join(cmd),
            "output": output[:8000],
            "parsed": parsed,
            "error": error if error else None,
            "returncode": result.returncode
        }
    except subprocess.TimeoutExpired:
        return {"success": False, "error": "Timeout", "command": " ".join(cmd)}
    except Exception as e:
        return {"success": False, "error": str(e), "command": " ".join(cmd)}

# === High-Value Functions for Portfolio / Job Demos ===

def doctor_and_whoami() -> Dict[str, Any]:
    """Verify setup - critical first step in any agent/script (from skills)."""
    print("=== dtctl Doctor & Whoami (Setup Verification) ===")
    doc = run_dtctl(["doctor"])
    who = run_dtctl(["auth", "whoami"])
    print(json.dumps({"doctor": doc, "whoami": who}, indent=2))
    return {"doctor": doc, "whoami": who}

def list_easytrade_problems() -> Dict[str, Any]:
    """List open problems filtered to EasyTrade. Direct match to Davis AI / root cause requirements."""
    print("\n=== EasyTrade Problems (Davis AI / Root Cause) ===")
    dql = 'fetch dt.davis.problems | filter status == "open" and (contains(dt.entity.service, "easytrade") or k8s.namespace.name == "easytrade") | sort timestamp desc | limit 10'
    res = run_dtctl(["query", dql])
    print(res["output"][:2000] if res["output"] else json.dumps(res, indent=2))
    return res

def easytrade_red_metrics() -> Dict[str, Any]:
    """RED metrics for EasyTrade services (Response time, Errors, Throughput). Core observability skill."""
    print("\n=== EasyTrade RED Metrics (Services) ===")
    dql = '''timeseries avg(dt.service.request.response_time), by:{dt.service.name}
| filter dt.service.name contains "easytrade" or dt.service.name contains "broker" or dt.service.name contains "frontend"
| limit 20'''
    res = run_dtctl(["query", dql])
    print(res["output"][:1500] if res["output"] else json.dumps(res, indent=2))
    return res

def easytrade_k8s_pods() -> Dict[str, Any]:
    """Kubernetes pods and resources for EasyTrade ns. Matches K8s + Dynatrace requirements."""
    print("\n=== EasyTrade K8s / Pods ===")
    dql = 'fetch dt.entity.kubernetes_pod | filter k8s.namespace.name == "easytrade" | fields dt.entity.kubernetes_pod, k8s.pod.name, k8s.namespace.name, cpu_usage, memory_working_set | limit 10'
    res = run_dtctl(["query", dql])
    print(res["output"][:1500] if res["output"] else json.dumps(res, indent=2))
    return res

def easytrade_spans() -> Dict[str, Any]:
    """Traces/spans for EasyTrade flows. Critical for tracing, loadgen validation, MCP tools."""
    print("\n=== EasyTrade Spans/Traces ===")
    dql = 'fetch spans | filter k8s.namespace.name == "easytrade" | summarize count() by {dt.service.name} | limit 10'
    res = run_dtctl(["query", dql])
    print(res["output"][:1500] if res["output"] else json.dumps(res, indent=2))
    return res

def list_dashboards() -> Dict[str, Any]:
    """List dashboards - demonstrates Configuration API / dashboard management."""
    print("\n=== Dashboards (Configuration) ===")
    res = run_dtctl(["get", "dashboards", "-o", "json"])
    print(res["output"][:2000] if res["output"] else json.dumps(res, indent=2))
    return res

def sample_dql_queries():
    """Library of validated DQL for EasyTrade (from dt-dql-essentials + obs skills)."""
    print("\n=== Sample DQL Library (EasyTrade Focused) ===")
    queries = [
        ("Services Overview", 'fetch dt.entity.service | filter k8s.namespace.name == "easytrade" | limit 20'),
        ("Problems Root Cause", 'fetch dt.davis.problems | filter status == "open" | fields problem.title, root_cause, impact'),
        ("Loadgen Activity", 'fetch logs | filter k8s.namespace.name == "easytrade" and contains(content, "loadgen") | limit 5'),
        ("Response Time Percentiles", 'timeseries percentile(dt.service.request.response_time, 95), by:{dt.service.name} | filter dt.service.name contains "easytrade"'),
    ]
    for name, q in queries:
        print(f"\n--- {name} ---")
        print(q)
        res = run_dtctl(["query", q])
        print("Sample output (truncated):", res["output"][:500] if res["output"] else "N/A")

# === Raw Dynatrace API Examples (curl + requests) ===

def api_curl_examples():
    """Direct API examples using curl (works without dtctl). Update token/URL."""
    print("\n=== Raw Dynatrace API Examples (curl) ===")
    token = DT_API_TOKEN or "YOUR_DT_API_TOKEN_WITH_READ_SCOPES"
    base = DT_API_URL.rstrip("/")
    examples = [
        ("List Problems (Environment API)", f'curl -s -H "Authorization: Api-Token {token}" "{base}/api/v2/problems?status=open&limit=5" | jq .'),
        ("DQL Query (Grail)", f'''curl -s -X POST -H "Authorization: Api-Token {token}" -H "Content-Type: application/json" "{base}/api/v2/dql" -d '{{"query": "fetch spans | filter k8s.namespace.name == \\"easytrade\\" | limit 3", "requestTimeoutSeconds": 60}}' | jq .'''),
        ("Services / Entities", f'curl -s -H "Authorization: Api-Token {token}" "{base}/api/v2/entities?entitySelector=type(%22SERVICE%22),k8s.namespace.name(%22easytrade%22)" | jq .'),
    ]
    for name, cmd in examples:
        print(f"\n{name}:")
        print(cmd)

def api_python_requests_example():
    """Python requests example for API (install: pip install requests)."""
    print("\n=== Python requests API Example ===")
    code = '''
import requests
import os
token = os.getenv("DT_API_TOKEN", "YOUR_TOKEN")
base = "https://YOUR_TENANT_ID.apps.dynatrace.com"
headers = {"Authorization": f"Api-Token {token}"}
# Example: Problems
resp = requests.get(f"{base}/api/v2/problems?status=open&limit=5", headers=headers)
print(resp.json() if resp.ok else resp.text)
# DQL example similar with POST
'''
    print(code)

if __name__ == "__main__":
    print("=== Dynatrace API + dtctl Portfolio Examples ===")
    print("Targeting roles: Dynatrace Observability Engineer, SRE (K8s+Dynatrace), APM Consultant, Senior Engineer\n")
    doctor_and_whoami()
    list_easytrade_problems()
    easytrade_red_metrics()
    easytrade_k8s_pods()
    easytrade_spans()
    list_dashboards()
    sample_dql_queries()
    api_curl_examples()
    api_python_requests_example()
    print("\n=== Done. These demonstrate real scripting, DQL, problems, K8s, API, and dashboard skills for Dynatrace roles. ===")
    print("Extend with MCP tools or loadgen bursts for richer data (see easytrade-load-generation reference).")
