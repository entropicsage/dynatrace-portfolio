# GitOps with ArgoCD for EasyTrade + Dynatrace

This directory provides ArgoCD Application examples for GitOps deployment of the EasyTrade observability stack. It demonstrates modern IaC + GitOps practices for observability platforms.

## Why GitOps + ArgoCD?
- Declarative, auditable deployments synced from Git.
- Automatic drift detection and remediation.
- Easy rollbacks and multi-env promotion.
- Complements DT-native workflows and Ansible (hybrid automation).
- Common in enterprise Dynatrace + Kubernetes environments (EKS/AKS).

## Structure
- `applications/` — ArgoCD Application CRs for key components.
- `kustomize/` or plain manifests (if needed for overrides).
- Ties into existing `k8s/`, `helm/`, and main setup.

## Prerequisites
- ArgoCD installed in cluster (or use `argocd` CLI).
- Git repo with this content (public or private with ArgoCD access).
- Dynatrace tokens/secrets managed via SealedSecrets, External Secrets, or ArgoCD secrets.
- kind or target cluster with ingress.

## Example Applications

### 1. Dynatrace Operator (GitOps)
See `applications/dynatrace-operator.yaml`

Deploys the operator via Helm chart, then applies DynaKube.

### 2. EasyTrade Application
See `applications/easytrade.yaml`

Uses official Helm chart, with values overrides for namespace, monitoring, etc.

### 3. Supporting Resources
- Ingress, DynaKube, etc. can be included in the same or separate apps for ordering.

## Usage (ArgoCD CLI or UI)
```bash
# Login to ArgoCD
argocd login <argocd-server>

# Create the app from this repo (example for main branch)
argocd app create easytrade-gitops \
  --repo https://github.com/entropicsage/dynatrace-portfolio.git \
  --path gitops \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace argocd \
  --sync-policy automated \
  --auto-prune

argocd app sync easytrade-gitops
```

Or apply the Application manifests directly:
```bash
kubectl apply -f gitops/applications/
```

Monitor in ArgoCD UI. Changes to this repo (e.g., new DynaKube) will sync automatically.

## Integration with Portfolio
- Combine with `scripts/setup-homelab.sh` for initial bootstrap.
- DT self-healing workflows (in `automation/`) can react to problems post-deploy.
- Ansible roles for host-level agents outside K8s.
- For full AIOps loop (like CaptainBarki62): Add ServiceNow or other integrations via DT workflows triggered after ArgoCD sync.

## Next Enhancements
- Add Kustomize overlays for dev/staging/prod.
- Integrate with dtctl or monaco post-sync hooks.
- Add health checks and sync waves for dependencies (Operator before EasyTrade).

See the main README for full context.