<#
  .SYNOPSIS
  Installs the MMA agent and configures with the log analytics workspace
  .DESCRIPTION
   Installs the MMA agent and configures with the log analytics workspace
  .PARAMETER SasURISetUp
  Specifies the SAS URI to download the MMA setup file

  .PARAMETER WorkSpaceID
  Specifies the workspace ID of the log analytics workspace

  .PARAMETER WorkSpaceKey
  Specifies the workspace key of the log analytics workspace

  .EXAMPLE
  & .\MMAInstallationScript.ps1 -SasURISetUp '<< SAS URI >>' -WorkSpaceID '<< LA WorkSpace ID >>' -WorkSpaceKey '<< LA WorkSpace Key >>'
#>

[CmdLetBinding()]
param (
    # [Parameter(Mandatory = $true)]
    #[string] $SasURISetUp,

    [Parameter(Mandatory = $true)]
    [string] $WorkSpaceID,

    [Parameter(Mandatory = $true)]
    [string] $WorkSpaceKey
)
try {

    #region Create a log file path to log custom script data

    $date = (Get-Date -Format "MM-dd-yyyy_HH:mm:ss").ToString()
    $systemDriveLocation = (Get-CimInstance -class Win32_OperatingSystem).SystemDrive + "\"
 
    $logFileFullPath = $systemDriveLocation + "Logs\" + "MMA_SetUp_Logs.txt"
    $logFileLocation = $systemDriveLocation + "Logs"
    $logFileName = "MMA_SetUp_Logs.txt"

    $hostName = hostname
    $sasURISetUp = "https://azweubcmgtstaticdatsa01.blob.core.windows.net/mmaagentsetupfile/MMASetup-AMD64.exe?sp=r&st=2023-10-27T13:24:28Z&se=2029-10-27T21:24:28Z&spr=https&sv=2022-11-02&sr=b&sig=WwVm66X0i2h3oZxzIQEeeM5CwGYWFAfq5DaR1PxtuPo%3D"
    if (!(Test-Path $logFileFullPath)) {
        Set-Location $systemDriveLocation
        New-Item "Logs" -ItemType Directory
        New-Item -path $logFileLocation -name $logFileName -type "file" -value "$date : MMA Installation log for '$hostName'"
    }
    else {
        Add-Content -path $logFileFullPath -value "$date : MMA Installation log for '$hostName'"
    }

    #endRegion


    #Region Check whether MMA is installed or not

    $retrieveMMAService = Get-Service -Name "HealthService" -ErrorAction SilentlyContinue;
    $retrieveMMAReportService = Get-Service -Name "MMAExtensionHeartbeatService" -ErrorAction SilentlyContinue;

    #endRegion

    if ([string]::IsNullOrEmpty($retrieveMMAService) -or [string]::IsNullOrEmpty($retrieveMMAReportService)) {

        #region download the MMA into the local VM


        ####Setting up download location of MMA agent set up file

        $hostname = hostname
        $installationPath = $systemDriveLocation + 'Binaries'
        if (!(Test-Path $installationPath)) {
            New-Item -path $systemDriveLocation -name 'Binaries' -type "directory"
            Add-Content -path $logFileFullPath -value "$date : A folder has been created for the download of MMA set up file for '$hostName'"
        }
       # $setupPath = $installationPath + '\MMAInstaller.msi'
       # Add-Content -path $logFileFullPath -value "$date : Downloading the latest version of MMA in .msi format for installation in VM: '$hostName'"
    
        $setupPathExe = $installationPath + '\MMAInstaller.exe'

    
        ####Downloading the file into the target location 

        Add-Content -path $logFileFullPath -value "$date : Downloading the latest version of MMA in .exe format for future purpose such as repair or uninstallation in VM: '$hostName'"
        Invoke-WebRequest $SasURISetUp -OutFile  $setupPathExe
        ###Verifying successful download of the file

        if (Test-Path $setupPathExe) {
            Add-Content -path $logFileFullPath -value "$date : MMA has been downloaded successfully in .exe format for VM: '$hostName'"
        }
        else {
            Add-Content -path $logFileFullPath -value "$date : Error while downloading MMA in .exe format for VM: '$hostName'. Check the downloader URL"
     
        }


        #endRegion 

        #region Installing the MMA Agent


        ###Initializing installation
        Add-Content -path $logFileFullPath -value "$date : Initiating MMA installation for VM: '$hostName'"
    

        $ArgumentList = '/C:"setup.exe /qn ADD_OPINSIGHTS_WORKSPACE=0 AcceptEndUserLicenseAgreement=1"'
        Start-Process $setupPathExe -ArgumentList $ArgumentList -ErrorAction Stop -Wait | Out-Null
  
        #Start-Process -FilePath "$env:systemroot\system32\msiexec.exe" -ArgumentList "/i", $setupPath , "/qn", "/l*v", "C:\windows\temp\mmasetup\MMAAgentInstall.log", "NOAPM=1", "AcceptEndUserLicenseAgreement=1" -Wait -NoNewWindow
        Add-Content -path $logFileFullPath -value "$date : MMA has been installed successfully for VM: '$hostName'"
    
        # Start-Process -Wait -FilePath $setupPathexe -ArgumentList "/q " -passthru -NonewWindow 
        # Start-Process -FilePath $setupPathexe -ArgumentList '/C','C:\Binaries\' -Wait -NoNewWindow
        # Start-Process -Wait -FilePath "c:\Binaries\MMAInstaller.msi" -ArgumentList "c:\Binaries\MMAInstaller.exe", "/Q" -passthru -NonewWindow
        Start-Sleep -Seconds 5

        #region Starting MMA service
        Set-Service -Name "HealthService" -StartupType Automatic -PassThru
        Set-Service -Name "MMAExtensionHeartbeatService" -StartupType Automatic -PassThru
        Start-Sleep -Seconds 2
        Add-Content -path $logFileFullPath -value "$date : Starting Microsoft Monitoring Agent Heart Beat Service for VM: '$hostName'"
        Start-Service -Name "MMAExtensionHeartbeatService";
        Add-Content -path $logFileFullPath -value "$date : Started Microsoft Monitoring Agent Heart Beat Service for VM: '$hostName'"
        Start-Service -Name 'HealthService' -ErrorAction SilentlyContinue
        Add-Content -path $logFileFullPath -value "$date : Started Microsoft Health Service for VM: '$hostName'"
        
        Set-Service -Name 'System Center Management APM' -StartupType Automatic -PassThru
        Start-Service -Name 'System Center Management APM' -ErrorAction SilentlyContinue
         Set-Service -Name 'AdtAgent' -StartupType Automatic -PassThru
        Start-Service -Name 'AdtAgent' -ErrorAction SilentlyContinue
        # Add-Content -path $logFileFullPath -value "$date : Started Microsoft Monitoring Agent Heart Beat Service for VM: '$hostName'"

        #endRegion
   
        #region configuration of MMA agent
        if (![string]::IsNullOrEmpty($workspaceid) -and ![string]::IsNullOrEmpty($workspacekey)) {
            Add-Content -path $logFileFullPath -value "$date : Initiating MMA configuration with the log analytics workspace for VM: '$hostName'"
            Enable-MMAgent -ApplicationLaunchPrefetching
            $AgentCfg = New-Object -ComObject AgentConfigManager.MgmtSvcCfg
            $OMSWorkspaces = $AgentCfg.GetCloudWorkspaces()
            Add-Content -path $logFileFullPath -value "$date : Workspace associated to the  VM: '$hostName' are: $OMSWorkspaces "
            $AgentCfg.addcloudworkspace($workspaceid, $workspacekey)
            $AgentCfg.reloadconfiguration()
            Restart-Service -Name "HealthService"
            Add-Content -path $logFileFullPath -value "$date : MMA has been configured successfully with the log analytics workspace for VM: '$hostName'"
        }
        return "MMAInstallationSuccessful"
        #EndRegion

        #endRegion
    }
    elseif ($retrieveMMAService.Status -eq "Running" -and $retrieveMMAReportService.Status -eq "Running") {

        #MMA is present and the services associated to it are running
        Add-Content -path $logFileFullPath -value "$date : MMA has been installed and running for VM: '$hostName'"
        Set-Service -Name "HealthService" -StartupType Automatic -PassThru
        Set-Service -Name "MMAExtensionHeartbeatService" -StartupType Automatic -PassThru
        Set-Service -Name 'System Center Management APM' -StartupType Automatic -PassThru
        Set-Service -Name 'AdtAgent' -StartupType Automatic -PassThru

     
        return "MMA was installed previously and running"

    }
    else {

        #MMA is present and the services associated to it are stopped. starting those services
        Add-Content -path $logFileFullPath -value "$date : MMA already installed in this VM but the service is stopped. Starting the agent for VM and set the startup type to automatic: '$hostName'"
        Set-Service -Name "HealthService" -StartupType Automatic -PassThru
        Set-Service -Name "MMAExtensionHeartbeatService" -StartupType Automatic -PassThru
        Start-Sleep -Seconds 2
        Start-Service -Name "HealthService";
        Start-Service -Name "MMAExtensionHeartbeatService";
        Set-Service -Name 'System Center Management APM' -StartupType Automatic -PassThru
        Start-Service -Name 'System Center Management APM' -ErrorAction SilentlyContinue
        Set-Service -Name 'AdtAgent' -StartupType Automatic -PassThru
        Start-Service -Name 'AdtAgent' -ErrorAction SilentlyContinue

            
        #EndRegion

        Add-Content -path $logFileFullPath -value "$date : All the MMA service successfully started for VM and set the startup type to automatic: '$hostName'"
        return "MMA already installed in this VM but the service is stopped due to restart. Started those services set the startup type to automatic."
    }  
    
}
catch {
    Write-Output "Error while installing MMA agent to the target servers. Error Message '$($_.Exception.Message)'" 
}