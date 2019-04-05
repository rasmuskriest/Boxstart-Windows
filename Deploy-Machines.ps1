<#
    .NOTES
        If not working, Chocolatey can be installed manually by following https://chocolatey.org/install and running each line manually. Some functions might be exclusive to Boxstarter and therefore not work.
    .SYNOPSIS
        This is a Boxstarter script created to work based on previously set enviroment variables.
    .DESCRIPTION
        Boxstarter script for my different systems. It sets different settings and installs almost all necessary programs / packages. Many things are done automatically based on the enviroment variables that Bootstrap-Boxstarter.ps1 set previously.
    .EXAMPLE
        START http://boxstarter.org/package/nr/url?http://boxstarter.org/package/nr/url?https://raw.githubusercontent.com/rasmuskriest/Boxstart-Windows/master/Deploy-Machines.ps1
#>

$Boxstarter.RebootOk = $false
$Boxstarter.NoPassword = $false
$Boxstarter.AutoLogin = $true

$baseUri = "https://raw.githubusercontent.com/rasmuskriest/Boxstart-Windows/master"
$checkpointPrefix = 'Boxstarter:Checkpoint:'

# List of all functions that are part of every installation.
$installFunctionList = @("WindowsFeatures", "PowerShell", "Dependencies", "Programs")
$runScriptList = @("Chocolatey", "Git", "Vagrant", "VSCode")

# Functions to handle checkpoints.
function Get-CheckpointName {
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $CheckpointName
    )
    return "$checkpointPrefix$CheckpointName"
}

function Set-Checkpoint {
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $CheckpointName,

        [Parameter(Mandatory = $true)]
        [string]
        $CheckpointValue
    )

    $key = Get-CheckpointName $CheckpointName
    [Environment]::SetEnvironmentVariable($key, $CheckpointValue, "Machine") # for reboots
    [Environment]::SetEnvironmentVariable($key, $CheckpointValue, "Process") # for right now
}

function Get-Checkpoint {
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $CheckpointName
    )

    $key = Get-CheckpointName $CheckpointName
    [Environment]::GetEnvironmentVariable($key, "Process")
}

function Clear-Checkpoints {
    $checkpointMarkers = Get-ChildItem Env: | Where-Object { $_.name -like "$checkpointPrefix*" } | Select-Object -ExpandProperty name
    foreach ($checkpointMarker in $checkpointMarkers) {
        [Environment]::SetEnvironmentVariable($checkpointMarker, '', "Machine")
        [Environment]::SetEnvironmentVariable($checkpointMarker, '', "Process")
    }
}

function Use-Checkpoint {
    param(
        [string]
        $CheckpointName,

        [string]
        $SkipMessage,

        [scriptblock]
        $Function
    )

    $checkpoint = Get-Checkpoint -CheckpointName $CheckpointName

    if (-not $checkpoint) {
        $Function.Invoke($Args)

        Set-Checkpoint -CheckpointName $CheckpointName -CheckpointValue 1
    }
    else {
        Write-BoxstarterMessage $SkipMessage
    }
}

# Functions to handle drives.
function Get-SystemDrive {
    return $env:SystemDrive[0]
}

function Get-DataDrive {
    $driveLetter = Get-SystemDrive

    if ((Test-Path env:\BoxStarter:DataDrive) -and (Test-Path $env:BoxStarter:DataDrive)) {
        $driveLetter = $env:BoxStarter:DataDrive
    }

    return $driveLetter
}

# Necessary functions to run script.
function Convert-StringToScriptBlock {
    param(
        [parameter(ValueFromPipeline = $true, Position = 0)]
        [string]
        $string
    )
    $sb = [scriptblock]::Create($string)
    return $sb
}

function Update-Path {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}

function Install-ChocoPackage {
    choco install $args --yes --limitoutput
}

function Execute-Script {
    Param ([string]$script)
    Write-Host "Executing $script ..."
    Invoke-Expression ((New-Object net.webclient).DownloadString("$baseUri/RunScripts/$script.ps1"))
}

function Install-WindowsUpdate {
    if (Test-Path env:\BoxStarter:SkipWindowsUpdate) {
        return
    }

    Enable-MicrosoftUpdate
    Install-WindowsUpdate -AcceptEula
    if (Test-PendingReboot) { Invoke-Reboot }
}

# Beginning of specific functions for this install.
function Set-BaseSettings {
    Enable-RemoteDesktop
    Set-CornerNavigationOptions -EnableUsePowerShellOnWinX
    Set-WindowsExplorerOptions -EnableShowHiddenFilesFoldersDrives -EnableShowProtectedOSFiles -EnableShowFileExtensions
}

function Update-WindowsLibraries {
    $dataDriveLetter = Get-DataDrive
    $dataDrive = "$dataDriveLetter`:"

    if (Get-SystemDrive -eq $dataDriveLetter) {
        return
    }

    Move-WindowsLibrary -libraryName "Personal" -newPath (Join-Path $dataDrive "Documents")
    Move-WindowsLibrary -libraryName "Downloads" -newPath (Join-Path $dataDrive "Downloads")
    Move-WindowsLibrary -libraryName "My Music" -newPath (Join-Path $dataDrive "Music")
    Move-WindowsLibrary -libraryName "My Pictures" -newPath (Join-Path $dataDrive "Pictures")
    Move-WindowsLibrary -libraryName "My Video" -newPath (Join-Path $dataDrive "Videos")
}

# While many functions might seem similiar, they are handeled individually to allow for additional commands, i.e. set policies.
function Install-WindowsFeatures {
    $installWindowsFeaturesDismList = Invoke-WebRequest -Uri $baseUri/ProgramLists/WindowsFeaturesDism.list | Select-Object -ExpandProperty Content
    $installWindowsFeaturesDismList -split "`n" | ForEach-Object {
        dism /Online /Enable-Feature /FeatureName=$_ /NoRestart
    }

    $installWindowsFeaturesDismList = Invoke-WebRequest -Uri $baseUri/ProgramLists/WindowsCapability.list | Select-Object -ExpandProperty Content
    $addWindowsCapabilityList -split "`n" | ForEach-Object {
        Add-WindowsCapability -Online -Name $_
    }
    
    # See https://docs.microsoft.com/en-us/windows/wsl/install-manual
    # Invoke-WebRequest -Uri https://aka.ms/wsl-ubuntu -OutFile ~/Ubuntu.appx -UseBasicParsing
    # Add-AppxPackage -Path ~/Ubuntu.appx

    if (Test-PendingReboot) { Invoke-Reboot }
}

function Install-PowerShell {
    $installPowerShellToolsList = Invoke-WebRequest -Uri $baseUri/ProgramLists/PowerShellTools.list | Select-Object -ExpandProperty Content
    $installPowerShellToolsList -split "`n" | ForEach-Object {
        Install-ChocoPackage $_
    }
    Set-PSRepository -Name 'PSGallery' -InstallationPolicy 'Trusted'

    $installPowerShellModulesList = Invoke-WebRequest -Uri $baseUri/ProgramLists/PowerShellModules.list | Select-Object -ExpandProperty Content
    $installPowerShellModulesList -split "`n" | ForEach-Object {
        Install-Module $_ -Scope CurrentUser -AllowClobber
    }

    Set-PSRepository -Name 'PSGallery' -InstallationPolicy 'Untrusted'
}

function Install-Dependencies {
    $installDependenciesList = Invoke-WebRequest -Uri $baseUri/ProgramLists/Dependencies.list | Select-Object -ExpandProperty Content
    $installDependenciesList -split "`n" | ForEach-Object {
        Install-ChocoPackage $_
    }
}

function Install-Programs {
    $installProgramsList = Invoke-WebRequest -Uri $baseUri/ProgramLists/Programs.list | Select-Object -ExpandProperty Content
    $installProgramsList -split "`n" | ForEach-Object {
        Install-ChocoPackage $_
    }
}

function Install-DesktopOnly {
    $installDesktopOnlyList = Invoke-WebRequest -Uri $baseUri/ProgramLists/DesktopOnly.list | Select-Object -ExpandProperty Content
    $installDesktopOnlyList -split "`n" | ForEach-Object {
        Install-ChocoPackage $_
    }
}

function Install-SurfaceOnly {
    $installSurfaceOnlyList = Invoke-WebRequest -Uri $baseUri/ProgramLists/SurfaceOnly.list | Select-Object -ExpandProperty Content
    $installSurfaceOnlyList -split "`n" | ForEach-Object {
        Install-ChocoPackage $_
    }
}

# Configuration functions.
$dataDriveLetter = Get-DataDrive
$dataDrive = "$dataDriveLetter`:"

# This is where the actual script starts.
Use-Checkpoint -Function ${Function:Set-BaseSettings} -CheckpointName 'BaseSettings' -SkipMessage 'BaseSettings already configured'
Use-Checkpoint -Function ${Function:Update-WindowsLibraries} -CheckpointName 'WindowsLibraries' -SkipMessage 'WindowsLibraries already moved'
Use-Checkpoint -Function ${Function:Install-PowerShell} -CheckpointName 'PowerShell' -SkipMessage 'PowerShellTools already installed'

foreach ($installFunction in $installFunctionList) {
    Write-BoxstarterMessage "Installing $installFunction"
    $forwardFunction = Convert-StringToScriptBlock "Install-$installFunction"
    Use-Checkpoint -Function $forwardFunction -CheckpointName $installFunction -SkipMessage '$installFunction already installed'
}

if (Test-Path env:\BoxStarter:InstallDesktop) {
    Write-BoxstarterMessage "Installing desktop-only software"

    Use-Checkpoint -Function ${Function:Install-DesktopOnly} -CheckpointName 'InstallDesktopOnly' -SkipMessage 'Desktop-only software already installed'
    if (Test-PendingReboot) { Invoke-Reboot }
}

if (Test-Path env:\BoxStarter:InstallSurface) {
    Write-BoxstarterMessage "Installing Surface-only software"
    Use-Checkpoint -Function ${Function:Install-SurfaceOnly} -CheckpointName 'InstallSurfaceOnly' -SkipMessage 'InstallSurfaceOnly already installed'
    if (Test-PendingReboot) { Invoke-Reboot }
}

# Install Chocolatey as very last package
Install-ChocoPackage chocolatey
if (Test-PendingReboot) { Invoke-Reboot }

# Reload path
Update-Path
Set-Volume -DriveLetter $sytemDrive -NewFileSystemLabel "Windows"

# Configure Software
foreach ($script in $runScriptList) {
    Execute-Script $script
}

# Run Windows Update one last time
Write-BoxstarterMessage "Updating Windows"
Install-WindowsUpdate

Clear-Checkpoints
