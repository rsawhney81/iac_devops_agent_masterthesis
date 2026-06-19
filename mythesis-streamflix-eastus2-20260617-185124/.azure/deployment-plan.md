# Deployment Plan

- Workload: StreamFlix
- Region: eastus2
- VM: Standard_E2s_v7 (zone 1)
- Network: public HTTP 80, SSH only 84.226.95.4/32
- Bootstrap: cloud-init clones https://github.com/devopsinsiders/StreamFlix.git (branch build) and publishes to /var/www/html
- Backend: azurerm remote state with use_azuread_auth=true
- Validation: terraform fmt/init/validate/plan/apply + VM cloud-init logs + HTTP content verification
