terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.80.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "uat-infra"
    storage_account_name = "uatinfrastorage042026"
    container_name       = "uatcontainer"
    key                  = "terraformuat.tfstate"
  }
}

provider "azurerm" {
  features {}
  # Authenticate through Azure CLI or the Azure DevOps service connection.
}
