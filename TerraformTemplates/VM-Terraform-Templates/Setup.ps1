<#
  .SYNOPSIS
  This is a bootstrap file called setup.ps1 to configure each Windows Server in the scale set.
  .DESCRIPTION
   This is a bootstrap file called setup.ps1 to configure each Windows Server in the scale set.

  .EXAMPLE
  & .\Setup.ps1
#>

[CmdletBinding()]
param ()
try {
    Write-Host "Starting Transcript....."
    Start-Transcript Join-Path -Path $PSScriptRoot -ChildPath 'terraform-log.txt' -append;
    $VerbosePreference = 'Continue';
    $InformationPreference = 'Continue';
    Install-WindowsFeature -name Web-Server -IncludeManagementTools;
    Write-Host "Installed Web server and Stopping Transcript....."
    Stop-Transcript;

}
catch {
    Write-Error "Error while confguring windows server in scale set. Error Message: '$($_.Exception.Message)'" 
}