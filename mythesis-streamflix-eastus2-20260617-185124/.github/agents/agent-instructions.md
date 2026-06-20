**IaC Orchestrator: Preflight & Context Usage**

The orchestrator agent must run a preflight step before attempting any write operations (e.g., `terraform apply`). This preflight performs these actions:

- Parse `.github/agents/context.json` to obtain Azure subscription and tenant details (subscription ID, tenant ID, client ID). Note: `azure_client_secret` is intentionally a placeholder (`USE_OIDC_OR_AZ_CLI_AUTH`) and must NOT be used as a credential.
- Authenticate using the existing Azure CLI login session (`az login` already performed by the operator). Do NOT run `az login --service-principal` and do NOT read a client secret from `context.json`.
- Set the active subscription with `az account set --subscription` using the subscription ID from the file.
- Check subscription state and fail fast if subscription is disabled/read-only.
- Verify required local tools: `terraform`, `java`, and optionally `plantuml`.
- Export `ARM_SUBSCRIPTION_ID`, `ARM_TENANT_ID`, and `ARM_CLIENT_ID` into the environment for Terraform's AzureRM provider. Do NOT export `ARM_CLIENT_SECRET`; instead set `ARM_USE_CLI=true` so the AzureRM provider authenticates through the Azure CLI session.

Preflight is performed inline by the orchestrator agent as described above (there is no separate script file). The agent executes these steps directly using the operator's Azure CLI session before any Terraform write operation.

Security notes:
- Storing secrets in repository files is not recommended. Prefer GitHub Secrets or Azure Key Vault and load them at runtime. For local runs, Azure CLI authentication (`ARM_USE_CLI=true`) avoids storing any secret at all.
- If the orchestrator is run in CI, replace reading `context.json` with secure secret injection or OIDC federated credentials (no stored secret).

Behavioral change for the agent:
- Always run the preflight script as the first step. If preflight fails, stop and report a clear actionable error (disabled subscription, missing tools, or missing credentials).
- For provider authentication, rely on the operator's existing Azure CLI session (`ARM_USE_CLI=true`). Never attempt service-principal secret authentication using the placeholder value in `context.json`.
