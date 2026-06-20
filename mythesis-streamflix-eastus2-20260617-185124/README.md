# StreamFlix POC: Multi-Agent IaC Orchestration (Azure, East US 2)

This folder is the deployment package root for the StreamFlix proof-of-concept run targeting Azure `eastus2`, orchestrated using a multi-agent IaC workflow (1 orchestrator + 9 specialized agents).

## Objective
Deploy the StreamFlix static web application on an Ubuntu VM using Nginx, with strict governance controls:

- Human-in-the-loop gates
- Preflight auth and SKU checks before plan
- OIDC-only CI/CD (no client secret)
- Metrics and execution logging during the run

## Scope of This POC
- **Application**: StreamFlix static web app
- **Hosting model**: Nginx on Azure VM (port `80`)
- **Source repository**: `https://github.com/devopsinsiders/StreamFlix.git`
- **Source branch**: `build`
- **Bootstrap**: `cloud-init`
- **Cloud**: Microsoft Azure
- **Target region**: `eastus2`
- **VM image**: Ubuntu 22.04 LTS Gen2
- **Requested size**: `Standard_B2s`

## Security and Network Requirements
- New VNet and subnet with explicit address spaces
- NSG rules:
  - Allow `TCP/80` from `0.0.0.0/0`
  - Allow `TCP/22` only from `84.226.95.4/32`
- SSH authentication:
  - Key-pair authentication enabled
  - Password authentication disabled
  - SSH key resolved from `.github/agents/context.json`

## Authentication Requirements
- Terraform provider authentication must use the current Azure CLI session (`az login`).
- The `azure_client_secret` value in `context.json` is a placeholder and must **not** be used.

## Multi-Agent Orchestration Model
### Orchestrator
- `IaC Workflow Orchestrator`

### Specialized agents
1. `Requirement Normalizer`
2. `Architecture Mapper`
3. `Module Discoverer`
4. `Module Parameterizer`
5. `Terraform Assembler`
6. `CI/CD Generator`
7. `Validator & Governor`
8. `Knowledge Management Agent`
9. `POC Documentary Agent`

## Mandatory Execution Rules
The run is expected to enforce the following controls end-to-end:

1. **R01: Pre-flight auth**
   - Validate backend + `azurerm` provider authentication before `terraform plan`.
2. **R02: SKU pre-check**
   - Verify `Standard_B2s` availability and quota in `eastus2` before planning.
   - If unavailable, propose the nearest supported size and pause for approval.
3. **R03: Full pipeline required**
   - Include CI/CD generation (`deploy.yml`) with OIDC and PR-gated apply.
4. **HITL approval gates**
   - Pause for explicit approval at:
     - Architecture diagram
     - Terraform plan
5. **R05: Post-apply validation**
   - Wait/retry for cloud-init completion before HTTP checks.
   - Validate provisioning state, Nginx, local/public HTTP 200, and SSH restriction.
6. **R09: Metrics capture**
   - Write timestamps, events, validation, and `metrics.json` into `.iac/`.
7. **R10: Execution log**
   - Maintain `.iac/execution.log` with timestamped phase/command/approval/error/fix entries.
8. **Teardown ordering**
   - Teardown only after documentary and metric capture is complete.

## CI/CD Policy
- Generate `deploy.yml` with OIDC only (`azure/login` + `id-token: write`).
- Do **not** include or rely on `ARM_CLIENT_SECRET`.

## Architecture Rendering
Expected rendering command for architecture diagram:

```powershell
java -jar "C:\tools\plantuml\plantuml.jar" .\architecture.puml
```

## Instrumentation Policy
The documentary output must use only instrumented values from `.iac/` artifacts.
- If a metric is missing/null, mark it as **not instrumented**.
- Do not estimate values or copy sample numbers.

## Folder Status
At the time this README was generated, this folder contained:
- `streamflix-case-study.html` (currently empty)
- `README.md` (this file)

## Recommended Next Artifacts
For a complete, publishable POC package, include:
- `architecture.puml` and rendered architecture image
- `infra/terraform/` with generated Terraform files
- `.github/workflows/deploy.yml` (OIDC + PR-gated apply)
- `.iac/metrics.json`
- `.iac/execution.log`
- non-empty `streamflix-case-study.html`

## Notes
This README is generated from the active session backup and explicitly stated requirements. It intentionally avoids inventing runtime outputs that are not currently present in this deployment folder.
