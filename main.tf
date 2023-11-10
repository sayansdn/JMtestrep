
terraform {
  backend "azurerm" {
    resource_group_name = "TestRG"
    storage_account_name = "teststgxyxx"
    container_name       = "testcnt"
    key                  = "terra.tfstate"
    #use_oidc = true
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
  #use_msi = true
  #environment     = "production"
  #subscription_id = "79170484-10cc-48f5-99a2-f4bfe2ad50e1"
  #client_id       = "dc156045-af12-4b19-ac45-9535124c50ac"
  # client_secret   = var.spnPass
  #tenant_id       = "baaae90c-2f56-4229-bdc1-7a0a8192b487"
  msi_endpoint = false
  
}


#Create a resource group

resource "azurerm_resource_group" "rgname" {
  name     = "NewTestRG"
  location = "East US"
}