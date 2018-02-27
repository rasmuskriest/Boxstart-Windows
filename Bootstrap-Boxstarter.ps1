<#
    .SYNOPSIS
        This is a helper script to easily deploy different computers based on one Boxstarter script.
    .DESCRIPTION
        Bootstrap-Boxstarter.ps1 sets a variety of enviroment variables that ease the workflow with Boxstarter. Based on the arguments given in .EXAMPLE, this script will download itself and specify enviroment variables that are being used by the called Deploy-Machines.ps1 afterwards.
    .EXAMPLE
        wget -Uri 'https://raw.githubusercontent.com/rasmuskriest/Boxstart-Windows/master/Bootstrap-Boxstarter.ps1' -OutFile "$($env:temp)\bootstrap.ps1";&Invoke-Command -ScriptBlock { &"$($env:temp)\bootstrap.ps1" -InstallDesktop -SkipWindowsUpdate }
#>

param
(
    [Switch]
    $InstallSurface = $false,

    [Switch]
    $InstallDesktop = $false,

    [String]
    $DataDrive,

    [Switch]
    $SkipWindowsUpdate,
)

function Set-EnvironmentVariable {
    param
    (
        [String]
        [Parameter(Mandatory = $true)]
        $Key,

        [String]
        [Parameter(Mandatory = $true)]
        $Value
    )

    [Environment]::SetEnvironmentVariable($Key, $Value, "Machine") # for reboots
    [Environment]::SetEnvironmentVariable($Key, $Value, "Process") # for right now

}

if ($InstallSurface) {
    Set-EnvironmentVariable -Key "BoxStarter:InstallSurface" -Value "1"
}

if ($InstallDesktop) {
    Set-EnvironmentVariable -Key "BoxStarter:InstallDesktop" -Value "1"
}

if ($DataDrive) {
    Set-EnvironmentVariable -Key "BoxStarter:DataDrive" -Value $DataDrive
}

if ($SkipWindowsUpdate) {
    Set-EnvironmentVariable -Key "BoxStarter:SkipWindowsUpdate" -Value "1"
}

if ($EnableWindowsAuthFeature) {
    Set-EnvironmentVariable -Key "BoxStarter:EnableWindowsAuthFeature" -Value "1"
}

$installScript = 'https://raw.githubusercontent.com/rasmuskriest/Boxstart-Windows/master/Deploy-Machines.ps1'
$webLauncherUrl = "http://boxstarter.org/package/nr/url?$installScript"

Start-Process microsoft-edge:$webLauncherUrl
