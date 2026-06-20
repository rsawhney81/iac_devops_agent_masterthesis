# Application Deployment Requirement Template

Use this template when a user provides short or partial deployment requirements. Ask only unresolved fields after context merge.

## 1) Application and Goal
- Application/workload name:
- Deployment objective (new deploy / redeploy / update / migrate):
- Runtime type (static site / API / full stack / worker):
- Success criteria (for example: public URL works, health endpoint 200, SSH access):

## 2) Cloud and Scope
- Cloud/subscription ID:
- Tenant ID:
- Target region:
- Environment name (dev / test / prod):
- Resource naming prefix:
- Required tags:

## 3) Compute
- Compute model (single VM / VMSS / App Service / Container Apps / AKS):
- VM or service name:
- VM size/SKU (mandatory for VM):
- OS image + version (mandatory for VM):
- Admin username (if VM):

## 4) Network and Security
- Exposure model (public / private):
- Public IP required (yes/no):
- Inbound ports and protocols:
- SSH/RDP source allowlist CIDR (default is user public IP /32 unless overridden):
- TLS/HTTPS requirement (yes/no):

## 5) Application Bootstrap and Source
- Deployment method (cloud-init / script / container image / package):
- Source repository + branch/tag:
- App build artifact location:
- Web root or startup command:
- Services to start/enable (for example `nginx`):

## 6) Terraform and State
- Terraform backend resource group:
- Terraform backend storage account:
- Terraform backend container:
- State key naming convention:
- Provider auth method (Azure CLI / service principal / OIDC):

## 7) Operations and Governance
- Plan-first approval required (yes/no):
- Architecture diagram required (PUML + PNG) (yes/no):
- Case-study HTML required (yes/no):
- Destroy after validation (yes/no):
- Cost guardrails or budget limits:

## 8) Output Contract (what to return before generation)
- `requirements_completeness`: `complete` or `incomplete`
- `missing_fields`: list all unresolved mandatory fields
- `assumptions`: only user-approved assumptions
- `normalized_spec`: final structured deployment input

## Mandatory Minimum Set Before Planning
- Application name
- Region
- Compute model
- VM size (if VM)
- OS image/version (if VM)
- Exposure model + ports
- SSH allowlist CIDR (if VM)
- Bootstrap/source method
- Destroy preference

If any mandatory field is missing, stop and ask clarifying questions. Do not proceed to architecture mapping or Terraform assembly.
