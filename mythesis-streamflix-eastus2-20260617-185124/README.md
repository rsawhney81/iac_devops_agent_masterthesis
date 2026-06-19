# StreamFlix IaC

This folder provisions an Azure Linux VM in eastus2 and bootstraps StreamFlix from GitHub branch `build` via cloud-init.

## Determinism
- Terraform version pinned to `= 1.15.5`
- azurerm provider pinned to `= 4.14.0`
- Ubuntu image version pinned to `22.04.202606110`

## Bootstrap
cloud-init clones repository and publishes app files into `/var/www/html`, then performs on-VM content verification.
