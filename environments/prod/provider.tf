terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.80.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "prod-infra"
    storage_account_name = "prodinfrastorage042026"
    container_name       = "prodcontainer"
    key                  = "terraformprod.tfstate"
  }
}

provider "azurerm" {
  features {}
  # Authenticate through Azure CLI or the Azure DevOps service connection.
}
