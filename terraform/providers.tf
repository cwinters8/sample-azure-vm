terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.33"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.4"
    }
  }

  backend "azurerm" {
    resource_group_name  = "orion"
    storage_account_name = "orions"
    container_name       = "terraform"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  subscription_id = "8e52f007-5720-4265-a54a-5587e2195284"
  features {}
}

provider "azuread" {}

data "azurerm_client_config" "current" {}
