<#
.SYNOPSIS
  This script does the post configuration of the VM post terraform deployment 

.DESCRIPTION
  This script does the post configuration of the VM post terraform deployment

.PARAMETER ResourceGroupName
  Specifies the resource group name of the virtual machine


.PARAMETER VMName
  Specifies the VM name

.PARAMETER SubscriptionId
 Specifies the SubscriptionId of the VM


.PARAMETER Location
  Specifies the Location of the VM

.PARAMETER KeyVaultName
  Specifies the keyvault name where the SAS URI of the static data of domain join information and the SAS URI of the
  MMA  agent is stored along with the credentials 


.PARAMETER LAWorksSpaceName
  Specifies the log analytics worksspace name for monitoring purposes

.PARAMETER SAName
  Specifies the Storage Account Name for boot diagnistics

.PARAMETER LawSubID
  Specifies the log analytics worksspace subscription ID for monitoring purposes


.PARAMETER DataDiskSize
  Specifies the data disk size of the VM

.PARAMETER DataDiskSku
  Specifies the data disk SKU of the VM within Premium_LRS,Premium_ZRS,Standard_LRS,StandardSSD_LRS,StandardSSD_ZRS

.PARAMETER ILBName
  Specifies the load balancer name in front of the VMSS

.PARAMETER SAName
  Specifies the storage account name for storing the boot diagnostics logs

.PARAMETER SARGName
  Specifies the RG storage account name for storing the boot diagnostics logs

.PARAMETER VnetName
  Specifies the Vnet Name where the VM resides

.PARAMETER VnetRGName
   Specifies the RG Vnet Name where the VM resides

.PARAMETER AdditionalDiskRequired
   A flag to determine whether additional data disk is required or not

.PARAMETER NSGName
  Specifies of the NSG Name

.PARAMETER CountOfDataDisk
   Specifies the count of data disk 

.PARAMETER NSGRGName
   Specifies of the NSG RG Name


.PARAMETER CreatedBy
    Specifies the Created By  for tagging purpose

.PARAMETER ManagedBy
   Specifies the Managed By for tagging purpose

 
.Notes

#>

param(
  [Parameter(Mandatory = $true)]
  [string]$ResourceGroupName,
  [Parameter(Mandatory = $true)]
  [string]$VMName,
  [Parameter(Mandatory = $true)]
  [string]$Location,
  [Parameter(Mandatory = $true)]
  [string]$SubscriptionId,
  [Parameter(Mandatory = $true)]
  [string]$LAWorksSpaceName,
  [Parameter(Mandatory = $true)]
  [string]$SAName,
  [Parameter(Mandatory = $false)]
  [string]$LAWorksSpaceRGName,
  [Parameter(Mandatory = $true)]
  [string]$LawSubID,
  [Parameter(Mandatory = $true)]
  [string]$SARGName,   
  [Parameter(Mandatory = $true)]
  [ValidateSet("true", "false")]
  [string]$AdditionalDiskRequired,   
  [Parameter(Mandatory = $true)]
  [string]$DataDiskSku,   
  [Parameter(Mandatory = $true)]
  [string]$DiskSizeGB,   
  [Parameter(Mandatory = $true)]
  [string]$CountOfDataDisk,
  [Parameter(Mandatory = $true)]
  [string]$VnetName,
  [Parameter(Mandatory = $true)]
  [string]$VnetRGName,
  [Parameter(Mandatory = $true)]
  [string]$NSGName,
  [Parameter(Mandatory = $true)]
  [string]$NSGRGName,
  [Parameter(Mandatory = $true)]
  [string]$KeyvaultName,  
  [Parameter(Mandatory = $false)]
  [string]$CreatedBy,
  [Parameter(Mandatory = $false)]
  [string]$ManagedBy  
)

try {

  #region setting context to subscription where VM resides.

  Write-Host "Seting context to the subscription"
  $null = Set-AzContext -SubscriptionId $subscriptionID -Scope Process -ErrorAction Stop
  Write-Host "Subscritpion context set"
  
  #endRegion

  #region Configuration of Tagging data

  Write-Host "Configuration of tagging data"
  $createdBy = $createdBy.Replace("_", " ")
  $managedBy = $managedBy.Replace("_", " ")
  # $businessUnit = $businessUnit.Replace("_", " ")
  # $sub_BU = $sub_BU.Replace("_", " ")
  # $role = $role.Replace("_", " ")

  $taggingData = @{
    # Costcentre   = $costcentre
    # Application  = $applicationName
    # BusinessUnit = $businessUnit
    CreatedBy = $createdBy
    # Role         = $Role
    # Sub_BU       = $sub_BU
    # SR           = $sr
    ManagedBy = $managedBy
  }
              
  #endRegion

  #region checking the existence of the specified VM

  $fetchVM = Get-AzVM -ResourceGroupName $resourceGroupName -Name $vmName -ErrorAction SilentlyContinue
  if (![string]::IsNullOrEmpty($fetchVM)) {

    #region Attaching a data disk to the VM with AV zone 
    
    $countOfDataDisk = [int]$countOfDataDisk
    if ($additionalDiskRequired -eq "true") {
      Write-Host "Attaching additional disk with the availability zone. Additional Disk count $countOfDataDisk"
      for ($i = 1; $i -le $countOfDataDisk; $i = $i + 1) {
        $storageType = $dataDiskSku
        $dataDiskName = $vmName + '-datadisk-0' + $i
        $dataDiskName
           
        Write-Host "Updating disk configuration"
        if ($DataDiskSku -match "ZRS") {
          $diskConfig = New-AzDiskConfig -SkuName $storageType -Location $location -CreateOption Empty -DiskSizeGB $diskSizeGB -Tag $taggingData
          $dataDisk = New-AzDisk -DiskName $dataDiskName -Disk $diskConfig -ResourceGroupName $resourceGroupName
          $vm = Add-AzVMDataDisk -VM $fetchVM -Name $dataDiskName -CreateOption Attach -ManagedDiskId $dataDisk.Id -Lun $i -Caching ReadWrite
        }
        else {
          $diskConfig = New-AzDiskConfig -SkuName $storageType -Location $location -CreateOption Empty -DiskSizeGB $dataDiskSize -Zone $zone -Tag $taggingData
          $dataDisk = New-AzDisk -DiskName $dataDiskName -Disk $diskConfig -ResourceGroupName $resourceGroupName
          $vm = Add-AzVMDataDisk -VM $fetchVM -Name $dataDiskName -CreateOption Attach -ManagedDiskId $dataDisk.Id -Lun $i -Caching ReadWrite
        }
        Update-AzVM -VM $vm -ResourceGroupName $resourceGroupName
      }
      Write-Host "Attached additional disk with the availability zone. Additional Disk count $countOfDataDisk"
    }
    #endRegion

    #region NSG Association to the Subnet

    Write-Host "Fetch the Network Security Group of the VM $vmName"
    $fetchNSG = Get-AzNetworkSecurityGroup -ResourceGroupName $nsgRGName -Name $nsgName
    Write-Host "Fetch the Vnet Details of the VM $vmName"
    $fetchVnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $vnetRGName
    Write-Host "Fetch the NIC Details of the VM $vmName"
    $fetchVMNiC = Get-AzNetworkInterface -ResourceId  $fetchVM.NetworkProfile.NetworkInterfaces.id
    Write-Host "Fetch the subnet Configuration of the VM $vmName"
    $subnetConfig =  Get-AzVirtualNetworkSubnetConfig -ResourceId $fetchVMNiC.IpConfigurations.Subnet.Id
    Write-Host "Associating NSG of Name $nsgName to the subnet $($fetchVMNiC.IpConfigurations.Subnet.Id)"
    $subnetConfig.NetworkSecurityGroup = $fetchNSG
    Set-AzVirtualNetwork -VirtualNetwork $fetchVnet
    Write-Host "Associated NSG of Name $nsgName to the subnet $($fetchVMNiC.IpConfigurations.Subnet.Id)"

    #endRegion

    #region IIS installation to the target VM via custom script extension

    Write-Host "Initiating IIS installation to the target VM via custom script extension"

    Set-AzVMExtension `
      -ResourceGroupName $resourceGroupName `
      -ExtensionName IIS `
      -VMName $vmName `
      -Publisher Microsoft.Compute `
      -ExtensionType CustomScriptExtension `
      -TypeHandlerVersion 1.4 `
      -SettingString '{"commandToExecute":"powershell Add-WindowsFeature Web-Server; powershell Add-Content -Path \"C:\\inetpub\\wwwroot\\Default.htm\" -Value $($env:computername)"}' `
      -Location $location -ErrorAction SilentlyContinue

    Write-Host "Completed IIS installation to the target VM via custom script extension"

    #endRegion

    #region enable monitoring

    Write-Host "Switching to LAW subscription"
    $null = Set-AzContext -SubscriptionId $lawSubID -Scope Process -ErrorAction Stop
    $checkLAWorkspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $laWorksSpaceRGName -Name $laWorksSpaceName -ErrorAction SilentlyContinue
    if (![string]::IsNullOrEmpty($checkLAWorkspace)) {
      #region fetching Log anaytics workspace details

      $workSpaceID = $checkLAWorkspace.CustomerId.guid
      $workSpaceKey = (Get-AzOperationalInsightsWorkspaceSharedKey -ResourceGroupName $laWorksSpaceRGName -Name $laWorksSpaceName).PrimarySharedKey
      Write-Host "Switching back to VM subscription"
      $null = Set-AzContext -SubscriptionId $subscriptionID -Scope Process -ErrorAction Stop

      #endRegion
  
      #region MMA installation
  
      Write-Output "Formulating the MMA installation Script Path"
      $mmaInstallationScriptPath = Join-Path -Path $PSScriptRoot -ChildPath 'RemoteScripts\MMAInstallationScript.ps1'
      Write-Host "Invoking Script to install MMA agent"
     
      $initializeMMAInstallation = Invoke-AzVMRunCommand -ResourceGroupName $resourceGroupName -Name $vmName -CommandId 'RunPowerShellScript' -ScriptPath $mmaInstallationScriptPath -Parameter @{<#"SasURISetUp" = $sasURISetUp; #>"WorkSpaceID" = $workSpaceID; "WorkSpaceKey" = $workSpaceKey }
      $mmaInstallationMessage = $initializeMMAInstallation.Value[0].Message
      if ($mmaInstallationMessage -match "Error" -or $mmaInstallationMessage -match "blocked") {
        Write-Host "Error while installing MMA agent. Message $mmaInstallationMessage" 
      }
      else {
        Write-Host "Message from $vmName : $mmaInstallationMessage"
      }
      #endRegion

    }
    else {
      Write-Host "The specified log anaytics work space does not exists."
    }

    #endRegion

    #region Enable Boot Diagnostics

    Write-Host "Checking the exstence of the storage account provided of name $saName"
    $checkSAExistence = Get-AzStorageAccount -ResourceGroupName $saRGName -Name $saName -ErrorAction SilentlyContinue
    if ($checkSAExistence) {
      Write-Host "Enabling boot diagnostics settings for VM: $vmName"
      Set-AzVMBootDiagnostic -VM $fetchVM -Enable -ResourceGroupName $saRGName -StorageAccountName $saName -ErrorAction SilentlyContinue
      Update-AzVM -VM $fetchVM -ResourceGroupName $resourceGroupName
      Write-Host "Enabled boot diagnostics settings for VM: $vmName"
    }
    else {
      Write-Host "The specified Storage account $saName for boot diagnostics does not exists. "
    }    

    #endRegion

    #region  change the hostname of the Virtual machine
    Write-Host "Renaming the host name of the VM from the source VM Golden Image hostname to the provided VM name: $vmName"
    Write-Output "Formulating the Hostname change Script Path"
    $hostnameChangeScriptPath = Join-Path -Path $PSScriptRoot -ChildPath 'RemoteScripts\Rename_Hostname.ps1'
    Write-Host "Invoking Script to change the hostname"
    $LocalUserName = Get-AzKeyVaultSecret -VaultName $keyvaultName -Name 'LocalUserName' -AsPlainText
    $LocalPass = Get-AzKeyVaultSecret -VaultName $keyvaultName -Name 'LocalPass' -AsPlainText
     
    $initializeHostNameChange = Invoke-AzVMRunCommand -ResourceGroupName $resourceGroupName -Name $vmName -CommandId 'RunPowerShellScript' -ScriptPath $hostnameChangeScriptPath -Parameter @{"NewHostName" = $vmName; "LocalUserName" = $LocalUserName; "LocalPass" = $LocalPass }
    $hostnameChangeMsg = $initializeHostNameChange.Value[0].Message
    if ($hostnameChangeMsg -match "Error" -or $hostnameChangeMsg -match "blocked") {
      Write-Host "Error while chaning the hostname. Message $hostnameChangeMsg" -ErrorAction SilentlyContinue
    }
    else {
      Write-Host "Message from $vmName : $hostnameChangeMsg"
      Write-Host "Hostname change from the golden image hostname to $vmName has been done successfully. Restarting the VM..."
      #Start-Sleep -Seconds 60
      Restart-AzVM -ResourceGroupName $resourceGroupName -Name $vmName
      Write-Host "VM:  $vmName restarted successfully..."
    }
  
    #endRegion

    #Region Starting MMA services 

    Write-Host "Starting the MMA service which might could stop after the restart and if found stopped starting those services"
    $startMMAService = Invoke-AzVMRunCommand -ResourceGroupName $ResourceGroupName -Name $vmName -CommandId 'RunPowerShellScript' -ScriptPath $mmaInstallationScriptPath -Parameter @{"WorkSpaceID" = $workSpaceID; "WorkSpaceKey" = $workSpaceKey }
    $startServiceMSG = $startMMAService.Value[0].Message
    if ($startServiceMSG -match "Error" -or $startServiceMSG -match "blocked") {
      Write-Host "Message from $vmName : $startServiceMSG" 
    }
    else {
      Write-Host "Message from $vmName : $startServiceMSG"
    }
  
  
    #EndRegion

    #region data disk initialization of target VM
    if ($additionalDiskRequired -eq "true") {
      Write-Host "Formulating the Data Disk Initialization Script Path"
      $dataDiskInitScriptPath = Join-Path -Path $PSScriptRoot -ChildPath 'RemoteScripts\Initialize-DataDisk.ps1'
      Write-Host "Invoking Script for Data Disk Initialization"
  
      $initializeDataDisk = Invoke-AzVMRunCommand -ResourceGroupName $resourceGroupName -Name $vmName -CommandId 'RunPowerShellScript' -ScriptPath $dataDiskInitScriptPath -Parameter @{"VMName" = $vmName; }
      $dataDiskInstallationMessage = $initializeDataDisk.Value[0].Message
      if ($dataDiskInstallationMessage -match "Successful") {
        Write-Host "Message from $vmName : $dataDiskInstallationMessage"
      }
      else {
        Write-Host "Error while initializing Data Disk. Message $dataDiskInstallationMessage. Data disks has to be initialized manually" 
      }
    }
    # Write-Host "High availability from source server $sourceVMName to target server $targetVMName has been achieved successfully"
    #endRegion

    #region domain join of a VM

    Write-Host "Fetching the domain information and the domain credentials from the Keyvault"
    $domainName = Get-AzKeyVaultSecret -VaultName $keyvaultName -Name 'DomainInfo' -AsPlainText
    $domainUserName = Get-AzKeyVaultSecret -VaultName $keyvaultName -Name 'DomainUserName' -AsPlainText
    $domainPassword = (Get-AzKeyVaultSecret -VaultName $keyvaultName -Name 'DomainPassword').SecretValue
    $credential = New-Object System.Management.Automation.PSCredential -ArgumentList $domainUserName, $domainPassword
    $credential
    Write-Host "Fetched the domain information and the domain credentials from the Keyvault. Initiating domain join to $domainName"
    $domainJoinName = $vmName + '-domainjoin'
    $domainJoinName
    #$domainJoinMsg = Set-AzVMADDomainExtension -DomainName $domainName -VMName $vMName -Credential $credential -ResourceGroupName $resourceGroupName -Name  $domainJoinName  -Restart -Verbose -JoinOption 0x00000001 -ErrorAction SilentlyContinue
    if (![string]::IsNullOrEmpty($domainJoinMsg)) {
      Write-Host "The VM $vmName got domain joined to the domain $domainName. Restarting the VM...."
  
      #region Restart post all the configuration

      Write-Host "VM configuration has now been complete restarting the VM: $vmName to make the changes in effect"
      Restart-AzVM -ResourceGroupName $resourceGroupName -Name $vmName
      Write-Host "The VM: $vmName has been restarted successfully.."

      #endRegion
    }
    else {
      Write-Host "Domain join cannot be done automatically as it is entering into long running seesion. The same needs to be completed manually. "
    }
    #endRegion

  }
  else {
    Write-Error "The specified VM does not exists. Error Message: '$($_.Exception.message)'" -ErrorAction Stop
  }


  #endRegion 

 
}
catch {
  Write-Error -Message "Error while performing post provisioning configuration of VM. Error message: '$($_.Exception.Message)'"
}


