<#
  .SYNOPSIS
  Initializes data disks of the specified VM
  .DESCRIPTION
   Initializes data disks of the specified VM
  .PARAMETER VMName
  Specifies the name f the VM where data disks initialization is required
 
  .EXAMPLE
  & .\Initialize-DataDisk.ps1 -VMName '<< VM Name >>'
#>

[CmdLetBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string] $VMName
)



$disks = Get-Disk | Where-Object { $_.partitionstyle -eq 'raw' } | Sort-Object number
$letters = 69..89 | ForEach-Object { [char]$_ }
$count = 0


ForEach ($disk in $disks) {
    $driveLetter = $letters[$count].ToString()
    Initialize-Disk $disks.Number 
    New-Partition -UseMaximumSize -DiskNumber $disks.Number  -DriveLetter $driveLetter 
    Format-Volume -DriveLetter $driveLetter -FileSystem "NTFS" -Force
    $count = $count + 1
}

return 'DatadiskInitializationOfTheVMSuccessful'
