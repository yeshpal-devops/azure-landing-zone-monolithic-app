terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.80.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "dev-infra"
    storage_account_name = "devinfrastorage042026"
    container_name       = "devcontainer"
    key                  = "terraformdev.tfstate"
  }
}

provider "azurerm" {
  features {}
  # Authenticate through Azure CLI or the Azure DevOps service connection.
  # subscription_id is intentionally not hard-coded here.
}
