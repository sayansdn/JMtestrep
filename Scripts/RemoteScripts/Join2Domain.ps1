<#
  .SYNOPSIS
  Renames the VM hostname from the source VM of the golden image to the provided VM name
  .DESCRIPTION
   Renames the VM hostname from the source VM of the golden image to the provided VM name
  .PARAMETER DomainName
  Specifies the Domain name
  .PARAMETER Credential
  Specifies the credential of the domain admin 

  .EXAMPLE
  & .\Rename_Hostname.ps1 -NewHostName '<< VM Name >>'
#>

[CmdLetBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string] $DomainName,
    [Parameter(Mandatory = $true)]
    [System.Management.Automation.PSCredential] $Credential
)
try {

    #region Create a log file path to log custom script data

    $date = (Get-Date -Format "MM-dd-yyyy_HH:mm:ss").ToString()
    $systemDriveLocation = (Get-CimInstance -class Win32_OperatingSystem).SystemDrive + "\"
 
    $logFileFullPath = $systemDriveLocation + "Logs\" + "Rename_HostName.txt"
    $logFileLocation = $systemDriveLocation + "Logs"
    $logFileName = "Rename_HostName.txt"

    $hostName = hostname
   
    if (!(Test-Path $logFileFullPath)) {
        Set-Location $systemDriveLocation
        New-Item "Logs" -ItemType Directory
        New-Item -path $logFileLocation -name $logFileName -type "file" -value "$date : Rename the VM hostname from $hostname to $newHostName for '$newHostName'"
    }
    else {
        Add-Content -path $logFileFullPath -value "$date : Rename the VM hostname from $hostname to $newHostName for '$newHostName'"
    }

    #endRegion

    #region Change the Hostname 
    Add-Content -path $logFileFullPath -value "$date : Domain joining Initiation of the server:  $hostName"

    #$OSType = (Get-WmiObject -Class Win32_OperatingSystem).Caption
    #$DomainName = "barry-callebaut.com"

    #$Credential = New-Object System.Management.Automation.PSCredential ($DomainUsername, (ConvertTo-SecureString $DomainPassword -AsPlainText -Force))
    Add-Content -path $logFileFullPath -value "$date :  Domain joining Initiation of the server:  $hostName. Restarting the VM....."
    $hostname = hostname
    Add-Computer -DomainName $domainName -ComputerName $hostName  -Credential $credential -Force
    Write-Output "Domain joining is successful"
  
    #endRegion 


}
catch {
    Write-Output "Error while renaming the hostname. Error Message '$($_.Exception.Message)'" 
}

