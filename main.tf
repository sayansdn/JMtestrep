
terraform {
  backend "azurerm" {
    storage_account_name = "teststg"
    container_name       = "testcnt"
    #key                  = "varvmName"
    #access_key            = var.access_key
    #access_key = "q3kRLfKlcbOF6Y+bMCzkEHR1BNK2cbDrFdLsb73H06ceUqdcutdBG1l4Tkh6z39e61ess3+a+7wK+AStAUJilw=="

  }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.65"
    }
  }
  required_version = ">= 0.14.9"
}

provider "azurerm" {
  features {}
  environment     = "public"
  subscription_id = "79170484-10cc-48f5-99a2-f4bfe2ad50e1"
  # client_id       = var.spnID
  # client_secret   = var.spnPass
  # tenant_id       = var.tenantID
}

# # Bootstrapping Script
# data "template_file" "tf-script" {
#   template = file("setup.ps1")
# }

#Data Modules


#Create a resource group

resource "azurerm_resource_group" "rgname" {
  name     = "testRG"
  location = "West us"
}