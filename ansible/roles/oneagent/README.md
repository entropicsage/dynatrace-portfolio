# OneAgent Ansible Role

This role provides a structured way to deploy Dynatrace OneAgent, modeled after the official Dynatrace/Dynatrace-OneAgent-Ansible but tailored for homelab and EasyTrade environments.

## Usage

```yaml
- hosts: linux_hosts
  roles:
    - oneagent
  vars:
    dynatrace_tenant_url: "https://YOUR_TENANT.live.dynatrace.com"
    dynatrace_paas_token: "{{ vault_token }}"
    oneagent_host_group: "easytrade-homelab"
```

See parent `ansible/README.md` for full playbooks that can include this role.

## Role Structure
- `tasks/main.yml`: Core installation logic
- `defaults/main.yml`: Sensible defaults
- `meta/main.yml`: Dependencies and metadata
- `handlers/`: Service management

This demonstrates production-grade Ansible practices for observability agent deployment.