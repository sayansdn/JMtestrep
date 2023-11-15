
terraform {
  /*backend "azurerm" {
    resource_group_name = "TestRG"
    storage_account_name = "teststgxyxx"
    container_name       = "testcnt"
    key                  = "terrav.tfstate"
    #use_oidc = true
    #access_key            = var.access_key
    #access_key = "q3kRLfKlcbOF6Y+bMCzkEHR1BNK2cbDrFdLsb73H06ceUqdcutdBG1l4Tkh6z39e61ess3+a+7wK+AStAUJilw=="

  }*/
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.27.0"
    }
  }
}

provider "azurerm" {
  features {}
  use_msi = true
  skip_provider_registration = true
  #environment     = "production"
  #subscription_id = "79170484-10cc-48f5-99a2-f4bfe2ad50e1"
  #client_id       = "dc156045-af12-4b19-ac45-9535124c50ac"
  #client_secret   = var.spnPass
  #tenant_id       = "baaae90c-2f56-4229-bdc1-7a0a8192b487"
  #msi_endpoint = true
  
}

#Data Modules

data "azurerm_virtual_network" "target_vnet" {
  name                = var.vnetName
  resource_group_name = var.vnetRGName
}


data "azurerm_subnet" "target_subnet" {
  name                 = var.SubnetName
  virtual_network_name = data.azurerm_virtual_network.target_vnet.name
  resource_group_name  = data.azurerm_virtual_network.target_vnet.resource_group_name
}

#Create a resource group

resource "azurerm_resource_group" "rgname" {
  name     = var.RGname
  location = var.location
}

#Create NSG

resource "azurerm_network_security_group" "rdp-nsg" {
  name     = var.NSGName
  location = var.location
  resource_group_name = azurerm_resource_group.rgname.name
/*
  security_rule {
    name                       = "AllowRDPInbound"
    description                = "Allow RDP"
    priority                   = 500
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  tags = {}
  */
}

#Create network interface
resource "azurerm_network_interface" "app_vm_nic" {
  name                = "${var.vmName}-nic01"
  location            = var.location
  resource_group_name            = azurerm_resource_group.rgname.name
  
  ip_configuration {
    name                          = "${var.vmName}-ipconfig01"
    subnet_id                     = data.azurerm_subnet.target_subnet.id
    private_ip_address_allocation = "Dynamic"
    #public_ip_address_id          = azurerm_public_ip.my_terraform_public_ip.id
  }
 tags = {}
}


#Create LB

resource "azurerm_lb" "app_lb" {
  name                = var.ILBName
  location            = var.location
  resource_group_name = azurerm_resource_group.rgname.name
  sku = "Standard"
  frontend_ip_configuration {
    name                          = "${var.ILBName}-frontend-ip"
    subnet_id                     = data.azurerm_subnet.target_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address_version    = "IPv4"
    private_ip_address            = var.ILBFrontEndIP
  }

  tags = {}
}

#Create LB Backend Pool
resource "azurerm_lb_backend_address_pool" "app_lb_backend_address_pool" {
  name            = "${var.ILBName}-backend-pool"
  loadbalancer_id = azurerm_lb.app_lb.id
  
}

#Create LB Probe
resource "azurerm_lb_probe" "app_lb_probe" {
  name                = "${var.ILBName}-health-probe"
  protocol            = "Tcp"
  port                = 443
  loadbalancer_id     = azurerm_lb.app_lb.id
  #resource_group_name = var.RGname
}

#Create LB Rule
resource "azurerm_lb_rule" "app_lb_rule_app1" {
  name                           = "${var.ILBName}-lbrule"
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = azurerm_lb.app_lb.frontend_ip_configuration[0].name
#  backend_address_pool_id        = azurerm_lb_backend_address_pool.app_lb_backend_address_pool.id
  probe_id                       = azurerm_lb_probe.app_lb_probe.id
  loadbalancer_id                = azurerm_lb.app_lb.id
 # resource_group_name = var.RGname
}

# Connect the Loadbalancer to the network interface
resource "azurerm_network_interface_backend_address_pool_association" "ilb_nic_connect" {
  network_interface_id    = azurerm_network_interface.app_vm_nic.id
  ip_configuration_name   = "${var.vmName}-ipconfig01"
  backend_address_pool_id = azurerm_lb_backend_address_pool.app_lb_backend_address_pool.id
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "nsg_nic_connect" {
  network_interface_id      = azurerm_network_interface.app_vm_nic.id
  network_security_group_id = azurerm_network_security_group.rdp-nsg.id
}

#create VM

resource "azurerm_virtual_machine" "azureVM" {

  name                             = var.vmName
  location                         = var.location
  resource_group_name              = azurerm_resource_group.rgname.name
  network_interface_ids            = ["${azurerm_network_interface.app_vm_nic.id}"]
  vm_size                          = var.vmSize
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true

  storage_image_reference {
    id =  var.ImageDefinitionID
    #publisher =  var.publisher
    #offer =  var.offer
    #sku =  var.sku
  }

  storage_os_disk {
    name              = "${var.vmName}-OSdisk01"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = var.DiskSku
  }

   os_profile {
     computer_name  = var.vmName
     admin_username = var.AdminUser
     admin_password = var.AdminPass
   }
  # boot_diagnostics {
  #   storage_account_uri = azurerm_storage_account.bootdiag_storage_account.primary_blob_endpoint
    
  # }

  os_profile_windows_config {
    enable_automatic_upgrades = false
  }
}


/*
resource "azurerm_backup_protected_vm" "vm1" {
  resource_group_name = data.azurerm_recovery_services_vault.target_rsv.resource_group_name
  recovery_vault_name = data.azurerm_recovery_services_vault.target_rsv.name
  source_vm_id        = azurerm_virtual_machine.azureVM.id
  backup_policy_id    = data.azurerm_backup_policy_vm.target_bkp_pol.id
}
*/