<#
  .SYNOPSIS
  Renames the VM hostname from the source VM of the golden image to the provided VM name
  .DESCRIPTION
   Renames the VM hostname from the source VM of the golden image to the provided VM name
  .PARAMETER LocalUserName
  Specifies the local user hostname
  .PARAMETER LocalPass
  Specifies the local user password

  .EXAMPLE
  & .\Rename_Hostname.ps1 -NewHostName '<< VM Name >>'
#>

[CmdLetBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string] $NewHostName,
    [Parameter(Mandatory = $true)]
    [string] $LocalUserName,
    [Parameter(Mandatory = $true)]
    [string] $LocalPass

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
    Add-Content -path $logFileFullPath -value "$date : Inititating hostname change"
    $secureString = ConvertTo-SecureString -String $LocalPass -AsPlainText -Force
    $localCredential = New-Object System.Management.Automation.PSCredential -ArgumentList $localUserName, $secureString
    Rename-Computer -ComputerName $hostName -NewName $newHostName -LocalCredential $localCredential -PassThru -Force
    Add-Content -path $logFileFullPath -value "$date : Renamed the VM hostname from $hostname to $newHostName for '$newHostName'. Restarting the VM..."
    Write-Output "Hostname change successful"
    #endRegion 


}
catch {
    Write-Output "Error while renaming the hostname. Error Message '$($_.Exception.Message)'" 
}