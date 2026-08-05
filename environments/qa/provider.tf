terraform {
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
  subscription_id = "d45d303f-5dbd-4fbf-9adb-39c652a0547d"
}