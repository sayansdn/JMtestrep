variable "Terraform_BackEnd_Storage_Account" {
  type    = string
  default = ""
}

variable "Resource_Group_Name" {
  type    = string
  default = ""
}

variable "Terraform_BackEnd_Storage_Container" {
  type    = string
  default = ""
}

variable "Terraform_BackEnd_Storage_State_Key" {
  type    = string
  default = ""
}

variable "SubscriptionId" {
  type    = string
  default = "#(|SubscriptionId|)#"
}

variable "VMRGName" {
  type    = string
  default = "#(|VMRGName|)#"

}

variable "vmName" {
  type    = string
  default = "#(|vmName|)#"
}

variable "location" {
  type    = string
  default = "#(|location|)#"
}

variable "AdminUser" {
  type    = string
  default = "#(|AdminUser|)#"
}

variable "AdminPass" {
  type    = string
  default = "#(|AdminPass|)#"
}

variable "vmSize" {
  type    = string
  default = "#(|vmSize|)#"
}

variable "NSGName" {
  type    = string
  default = "#(|NSGName|)#"
}


variable "ImageDefinitionID" {
  type    = string
  default = "#(|ImageDefinitionID|)#"
}

variable "vnetName" {
  type    = string
  default = "#(|vnetName|)#"
}

variable "vnetRGName" {
  type    = string
  default = "#(|vnetRGName|)#"
}

variable "SubnetName" {
  type    = string
  default = "#(|SubnetName|)#"
}


variable "CreatedBy" {
  type    = string
  default = "#(|CreatedBy|)#"
}

variable "ManagedBy" {
  type    = string
  default = "#(|ManagedBy|)#"
}

variable "storageAccountName" {
  type    = string
  default = "#(|storageAccountName|)#"
}

# variable "publisher" {
#   type    = string
#   default = "#(|publisher|)#"
# }

variable "offer" {
  type    = string
  default = "#(|offer|)#"
}

variable "sku" {
  type    = string
  default = "#(|sku|)#"
}

variable "DiskSku" {
  type    = string
  default = "#(|DiskSku|)#"
}



variable "ILBName" {
  type    = string
  default = "#(|ILBName|)#"
}

variable "ILBFrontEndIP" {
  type    = string
  default = "#(|ILBFrontEndIP|)#"
}

variable "RSVName" {
  type    = string
  default = "#(|RSVName|)#"
}

variable "RSVRGName" {
  type    = string
  default = "#(|RSVRGName|)#"
}

variable "BackupPolicyName" {
  type    = string
  default = "#(|BackupPolicyName|)#"
}




