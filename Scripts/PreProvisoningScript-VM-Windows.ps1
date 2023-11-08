<#
.SYNOPSIS
  This script does the post configuration of the VM post terraform deployment 

.DESCRIPTION
  This script does the post configuration of the VM post terraform deployment

.PARAMETER VnetName
  Specifies the Vnet name from which subnet ID needs to be extracted from its underlying subnets

.PARAMETER VnetRGName
 Specifies the resource group name of the Vnet

.PARAMETER SubnetName
  Specifies the Subnet name which resource ID needs tobe extracted

.PARAMETER SubscriptionID
  Specifies the Subscription ID

.PARAMETER GalsubID
  Specifies the Subscription ID of Azure Compute Gallery

.PARAMETER GalleryImageDefinitionName
  Specifies the image definition name

.PARAMETER GalleryResourceGroupName
  Specifies the resource group name of Gallery

.PARAMETER GalleryName
  Specifies the Gallery Name

.Notes

#>

param(
  [Parameter(Mandatory = $true)]
  [string]$VnetName,
  [Parameter(Mandatory = $true)]
  [string]$VnetRGName,
  [Parameter(Mandatory = $true)]
  [string]$SubnetName,
  [Parameter(Mandatory = $true)]
  [string]$SubscriptionID,
  [Parameter(Mandatory = $true)]
  [string]$GalsubID,
  [Parameter(Mandatory = $true)]
  [string]$GalleryImageDefinitionName,
  [Parameter(Mandatory = $true)]
  [string]$GalleryResourceGroupName,
  [Parameter(Mandatory = $true)]
  [string]$GalleryName
  # [Parameter(Mandatory = $true)]
  # [string]$KeyvaultName,
  # [Parameter(Mandatory = $true)]
  # [string]$KeyvaultSubID
)

try {

  #region Fetching Source Image Definition ID

  Write-Host "Fetching the source VM image Id definition from the gallery"
  Write-Host "Setting context to the gallery subscription"
  $null = Set-AzContext -SubscriptionID $galsubID -Scope Process -ErrorAction Stop
  $fetchGalleryImage = Get-AzGalleryImageDefinition -ResourceGroupName $galleryResourceGroupName -Name $galleryImageDefinitionName -GalleryName $galleryName
  Write-Host "Fetched the source VM image Id definition from the gallery"
  $imageDefinitionID = $fetchGalleryImage.Id
  #region: Create pipeline variables
  Write-Host "##vso[task.setvariable variable=ImageDefinitionID;isSecret=false]$imageDefinitionID";
  #endregion: Create pipeline variables

  #endRegion

  #region setting context to home subscription.

  Write-Host "Reseting the subscription context to the home subscription"
  $null = Set-AzContext -SubscriptionId $subscriptionID -Scope Process -ErrorAction Stop
  Write-Host "Subscritpion context set"
 
  #endRegion

  #region Fetch ILB Front End IP

  Write-Host "Fetching the next available IP address for ILB Front End IP"

  $subnetConfiguration = Get-AzVirtualNetwork -ExpandResource "subnets/ipConfigurations" -Name $vnetName -ResourceGroupName $vnetRGName | Select-Object -ExpandProperty Subnets | Where-Object { $_.Name -eq $subnetName }
  Write-Host "Subnet address prefix:`t`t`t$($subnetConfiguration.AddressPrefix)"
     
  $usedIpAddresses = @()
  $usedIpAddresses += $subnetConfiguration.ipConfigurations.privateIPAddress | Sort-Object 

  if ([string]::IsNullOrEmpty($usedIpAddresses)) {
    $subnetAddressPrefixes = $subnetConfiguration.AddressPrefix
    $formatIPAddress = $subnetAddressPrefixes.Split('/')
    $ipaddress = $formatIPAddress[0].Split('.')
    $lastOctet = [int]$ipaddress[-1] + 4
    $nextAvailableIPAddress = $ipaddress[0] + '.' + $ipaddress[1] + '.' + $ipaddress[2] + '.' + $lastOctet
  }
  else {
    $lastUsedIPAddress = $usedIpAddresses[-1]
    do {
   
      Write-Host "Last Used IP Address: $lastUsedIPAddress"
      $fmtIPAddress = $lastUsedIPAddress.Split('.')
      $lastOctetofLastUSedIPAddress = $fmtIPAddress[-1]
      $lastOctetofLastUSedIPAddress = [int]$lastOctetofLastUSedIPAddress
      if ($lastOctetofLastUSedIPAddress -lt 255) {
        $addIPAddress = $lastOctetofLastUSedIPAddress + 1
        $nextAvailableIPAddress = $fmtIPAddress[0] + '.' + $fmtIPAddress[1] + '.' + $fmtIPAddress[2] + '.' + $addIPAddress
        $lastUsedIPAddress = $nextAvailableIPAddress      
      }
      else {
        Write-Error "Private IP Not available in this subnet"
      }     
        
    } until ($nextAvailableIPAddress -notin $usedIpAddresses)
    Write-Host "Fetched the ILB Front End IP: $nextAvailableIPAddress"
    $iLBFrontEndIP = $nextAvailableIPAddress
    #region: Create pipeline variables
    Write-Host "##vso[task.setvariable variable=ILBFrontEndIP;isSecret=false]$iLBFrontEndIP";
    #endregion: Create pipeline variables
  }

  #endRegion

  # #region fetching required secrets

  # #region setting context to home subscription.

  # Write-Host "Reseting the subscription context to the home subscription"
  # $null = Set-AzContext -SubscriptionId $KeyvaultSubID -Scope Process -ErrorAction Stop
  # Write-Host "Subscritpion context set"
  
  # #endRegion

  # #region fetching secrets
  # Write-Host "Fetching Keyvault Secrets" 
  # $LocalUserName = Get-AzKeyVaultSecret -VaultName $keyvaultName -Name 'LocalUserName' -AsPlainText
  # $LocalPass = Get-AzKeyVaultSecret -VaultName $keyvaultName -Name 'LocalPass' -AsPlainText

  # #region: Create pipeline variables
  # Write-Host "##vso[task.setvariable variable=LocalUserName;isSecret=true]$LocalUserName";
  # Write-Host "##vso[task.setvariable variable=LocalPass;isSecret=true]$LocalPass";
  # #endregion: Create pipeline variables
  # #endRegion

  # #endRegion

}
catch {
  Write-Error "Error while fetching the subnet Id and Image Definition ID. Error Message: '$($_.Exception.Message)'"
}