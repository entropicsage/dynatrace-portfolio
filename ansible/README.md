# Ansible Automation for Dynatrace

This directory contains Ansible playbooks **and roles** for automating Dynatrace agent and infrastructure deployment. These complement the existing Dynatrace observability portfolio, Linux/Windows admin scripts, and Kubernetes setup.

**Reference**: Role structure aligned with the official `Dynatrace/Dynatrace-OneAgent-Ansible` collection.

## Structure

- `playbooks/` — High-level playbooks (install-oneagent-linux.yml, install-activegate-linux.yml, prepare-host.yml, deploy-dynatrace-stack.yml, and remediation/)
- `roles/` — Reusable Ansible roles (modeled after official Dynatrace patterns)
  - `roles/oneagent/` — OneAgent deployment role (tasks, defaults, meta)
  - `roles/activegate/` — (skeleton for ActiveGate)
- `inventory/` and `group_vars/` — Examples

## Why This Matters for Top Contender Status

Official Dynatrace-OneAgent-Ansible uses proper roles, meta, tests, and CI. This portfolio demonstrates the same professional practices while tailoring to EasyTrade + homelab + self-healing use cases.

Combined with native Dynatrace Workflows, this shows hybrid automation (DT-native for K8s + Ansible for hosts).

## Usage

See individual playbooks for examples. Roles can be included in your own playbooks:

```yaml
- hosts: linux_hosts
  roles:
    - oneagent
```

For full details on variables and integration with the EasyTrade portfolio, refer to the playbooks and the main project README.