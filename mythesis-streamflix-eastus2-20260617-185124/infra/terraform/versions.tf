terraform {
  required_version = "= 1.15.5"

  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "tfs959443weu"
    container_name       = "tfstate"
    key                  = "streamflix-eastus2-20260617-185124.tfstate"
    use_azuread_auth     = true
  }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 4.14.0"
    }
  }
}
