# DevOps & Systems Administration Tools

This directory contains practical Linux administration and troubleshooting scripts designed to complement Dynatrace observability and Kubernetes operations.

## Purpose

A technical manager hiring for a role involving Dynatrace, Linux/Windows Server administration, and Kubernetes would want evidence that the candidate can:

- Quickly diagnose and remediate common infrastructure issues (especially those that trigger observability alerts)
- Perform safe disk and resource management in production-like environments
- Troubleshoot across the stack: host → container → Kubernetes → application
- Automate repetitive admin tasks with clear, documented, and safe tooling
- Bridge monitoring insights (from Dynatrace) with hands-on remediation

These scripts focus on real operational needs rather than toy examples. They are written for readability, safety, and extensibility.

## Scripts Overview

| Script                  | Description                                      | Ties To                          |
|-------------------------|--------------------------------------------------|----------------------------------|
| `disk-usage.sh`         | Enhanced view of disk space, inodes, and top consumers | High disk alerts in Dynatrace   |
| `disk-grow.sh`          | Safely extend filesystems (LVM / cloud volumes) | Growing volumes after alerts    |
| `disk-shrink.sh`        | Guided (and heavily warned) filesystem shrink    | Reclaiming space carefully      |
| `system-snapshot.sh`    | Collects comprehensive system state (top-like + more) for diagnostics | When Davis or custom alerts fire |
| `k8s-troubleshoot.sh`   | Kubernetes node/pod/resource checks and events   | K8s + Dynatrace integration     |
| `service-check.sh`      | Verify critical services, ports, and processes   | General Linux/Windows admin     |

## How These Fit Together with Dynatrace + K8s

- **Dynatrace** surfaces problems (high disk usage, high load, pod restarts, etc.).
- These scripts provide the **remediation and deep investigation** layer on Linux hosts and Kubernetes nodes.
- The `system-snapshot.sh` can be run manually or triggered from a Dynatrace workflow / custom alert to gather evidence.
- K8s scripts help when Dynatrace shows infrastructure or container problems.
- Disk scripts are essential because storage issues are among the most common production incidents.

## Windows Server Administration

See `windows-server-notes.md` for key PowerShell commands and patterns for disk management, services, event logs, and remote administration. The focus here is Linux-first (matching the current homelab), with notes for hybrid environments.

## Usage Philosophy

- All scripts include `--help` and safety checks.
- Destructive operations (shrink) require explicit confirmation.
- Scripts log actions where appropriate.
- Designed to be readable so others can understand and extend them.
- Many assume common tools (LVM, xfs/ext4, kubectl, etc.).

## Recommended Next Steps in a Real Environment

1. Run `disk-usage.sh` regularly or via cron.
2. Integrate `system-snapshot.sh` output into runbooks or Dynatrace problem comments.
3. Use disk grow/shrink scripts during maintenance windows with proper change control.
4. Extend the K8s script with your specific namespace and resource checks.

These tools demonstrate practical, end-to-end operational capability across observability, Linux administration, and Kubernetes.