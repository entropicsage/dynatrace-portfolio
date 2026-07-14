# Terraform Provider for Dynatrace - Portfolio Examples
# Provider: dynatrace-oss/dynatrace (official community)
# Demonstrates IaC for observability using Terraform and GitOps patterns.
#
# Install: terraform init (after provider config)
# Docs: https://registry.terraform.io/providers/dynatrace-oss/dynatrace/latest/docs
#
# Note: Requires Dynatrace API token with appropriate scopes.
# Set via environment variables DT_API_TOKEN and DT_API_URL, or in a .tfvars file (gitignored).

terraform {
  required_providers {
    dynatrace = {
      source  = "dynatrace-oss/dynatrace"
      version = "~> 1.67"
    }
  }
}

provider "dynatrace" {
  # Set via env vars: DT_API_TOKEN, DT_API_URL
  # For homelab: export DT_API_URL=https://YOUR_TENANT_ID.live.dynatrace.com
  # Or use a terraform.tfvars file (add to .gitignore)
}

# SLO for EasyTrade availability - ties to self-healing workflows and dashboards
resource "dynatrace_slo_v2" "easytrade_availability" {
  name               = "EasyTrade Availability"
  enabled            = true
  metric_expression  = "(100)*(builtin:service.errors.server.successCount:splitBy())/(builtin:service.requestCount.server:splitBy())"
  evaluation_type    = "AGGREGATE"
  filter             = "type(SERVICE),entityName.startsWith(\"easytrade\")"
  target             = 99.5
  warning            = 99.8
  evaluation_window  = "-1w"
}

# Management zone scoping EasyTrade services for dashboard/alerting isolation
resource "dynatrace_management_zone_v2" "easytrade" {
  name = "EasyTrade Portfolio"
  rules {
    rule {
      type    = "ME"
      enabled = true
      attribute_rule {
        entity_type = "SERVICE"
        attribute_conditions {
          condition {
            case_sensitive = false
            key            = "KUBERNETES_NAMESPACE"
            operator       = "EQUALS"
            string_value   = "easytrade"
          }
        }
      }
    }
  }
}

# Alerting profile for EasyTrade problems from loadgen/problem-operator
resource "dynatrace_alerting" "easytrade_critical" {
  name = "EasyTrade Critical"
  management_zone = dynatrace_management_zone_v2.easytrade.id
  rules {
    rule {
      delay_in_minutes = 0
      include_mode     = "INCLUDE_ALL"
      severity_level   = "AVAILABILITY"
    }
    rule {
      delay_in_minutes = 0
      include_mode     = "INCLUDE_ALL"
      severity_level   = "ERRORS"
    }
  }
}

output "slo_id" {
  value = dynatrace_slo_v2.easytrade_availability.id
}

output "management_zone_id" {
  value = dynatrace_management_zone_v2.easytrade.id
}
