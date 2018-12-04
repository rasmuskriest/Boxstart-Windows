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

# List of all functions that are part of every installation.
$installFunctionList = @("WindowsFeatures", "Prerequisites", "Browsers", "CommunicationTools", "DevTools", "Vagrant", "VisualStudioCode", "Atom", "Multimedia", "WorkTools", "EducationTools", "TechTools", "Gaming")

# Contents of these lists are looped as individual packages / modules.
$installWindowsFeaturesDismList = @("Microsoft-Windows-Subsystem-Linux", "LegacyComponents") # Microsoft-Hyper-V-All is currently removed
$addWindowsCapabilityList = @("OpenSSH*")
$installPowerShellToolsList = @("au", "conemu", "gow", "pstools", "vcxsrv")
$installPowerShellModulesList = @("Get-ChildItemColor", "posh-git", "Pscx", "PSReadline", "z")
$installPrerequisitesList = @("1password", "7zip", "dropbox", "flashplayerplugin", "git", "google-drive-file-stream", "google-backup-and-sync", "javaruntime", "jdk8", "lame", "notepad3", "python", "python2", "quicktime", "strawberryperl", "unchecky", "virtualbox", "VirtualBox.ExtensionPack", "vmwareworkstation")
$installBrowsersList = @("firefox -packageParameters 'l=en-US'", "GoogleChrome", "tor-browser", "vivaldi")
$installCommunicationToolsList = @("mattermost-desktop", "skype")
$installDevToolsList = @("android-sdk", "sqlitebrowser", "winscp")
$installMultimediaList = @("jdownloader -pre", "transmission", "vlc", "xmedia-recode")
$installWorkToolsList = @("adobe-creative-cloud", "elsterformular", "outlookcaldav", "onenote", "onetastic", "teamviewer", "todoist")
$installEducationToolsList = @("miktek", "R.Project", "R.Studio", "russian-grammatical-dictionary", "xmind" "zotero")
$installTechToolsList = @("docker-toolbox", "doublecmd", "fiddler", "groupy", "keepass", "keepass-plugin-favicon", "linkshellextension", "lockhunter", "mp3tag", "nirlauncher", "openvpn", "putty", "recuva", "reshack", "royalts", "rufus", "speccy", "sysinternals", "teracopy", "testdisk-photorec", "windirstat", "winmerge-jp", "wireshark")
$installGamingList = @("goggalaxy", "origin", "steam", "twitch", "uplay")

# Specific lists for different systems.
$installDesktopOnlyList = @("dopamine", "defraggler", "eac", "imgburn", "gamesavemanager", "geforce-experience", "Physx.Legacy")
$installSurfaceOnlyList = @("wifi-manager")

# $storeAppsList @("amazonmusic", "evernote", "heidisql", "Office365HomePremium", "paint.net", "slack", "spotify", "whatsapp")
# $notAvailableList = @("cisco-anyconnect", "citavi", "instagiffer", "multibootusb", "notion")

$checkpointPrefix = 'BoxStarter:Checkpoint:'

# WFunctions to handle checkpoints.

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
    choco install $args
}

function Install-WindowsUpdate {
    if (Test-Path env:\BoxStarter:SkipWindowsUpdate) {
        return
    }

    Enable-MicrosoftUpdate
    Install-WindowsUpdate -AcceptEula
    #if (Test-PendingReboot) { Invoke-Reboot }
}

# Beginning of specific functions for this install.

function Enable-ChocolateyFeatures {
    choco feature enable --name=autoUninstaller
    choco feature enable --name=allowGlobalConfirmation
}

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
    foreach ($dismFeature in $installWindowsFeaturesDismList) {
        dism /Online /Enable-Feature /FeatureName=$dismFeature /NoRestart
    }

    foreach ($windowsCapability in $addWindowsCapabilityList) {
        Add-WindowsCapability -Online -Name $windowsCapability
    }
    
    # See https://docs.microsoft.com/en-us/windows/wsl/install-manual
    # Invoke-WebRequest -Uri https://aka.ms/wsl-ubuntu -OutFile ~/Ubuntu.appx -UseBasicParsing
    # Add-AppxPackage -Path ~/Ubuntu.appx

    if (Test-PendingReboot) { Invoke-Reboot }
}

function Install-PowerShellTools {
    foreach ($package in $installPowerShellToolsList) {
        Install-ChocoPackage $package
    }
}

function Install-PowerShellModules {
    Set-PSRepository -Name 'PSGallery' -InstallationPolicy 'Trusted'

    foreach ($module in $installPowerShellModulesList) {
        Install-Module $module -Scope CurrentUser -AllowClobber
    }

    Set-PSRepository -Name 'PSGallery' -InstallationPolicy 'Untrusted'
}

function Install-Prerequisites {
    foreach ($package in $installPrerequisitesList) {
        Install-ChocoPackage $package
    }
}

function Install-Browsers {
    foreach ($package in $installBrowsersList) {
        Install-ChocoPackage $package
    }
}

function Install-CommunicationTools {
    foreach ($package in $installCommunicationToolsList) {
        Install-ChocoPackage $package
    }
}

function Install-DevTools {
    foreach ($package in $installDevToolsList) {
        Install-ChocoPackage $package
    }
}

function Install-Vagrant {
    choco install vagrant
    Update-Path
    # [Environment]::SetEnvironmentVariable("VAGRANT_DEFAULT_PROVIDER", "hyperv", "Machine")

    vagrant plugin install sahara # needed for chocolatey-test-environment
    vagrant plugin install vagrant-hostsupdater # needed for most boxes that are to be reached from the host
}

function Install-VisualStudioCode {
    choco install vscode

    Start-Process code
    Start-Sleep -s 10

    code --install-extension Shan.code-settings-sync
    Update-Path
}

function Install-Atom {
    choco install atom
    apm install sync-settings
}

function Install-Multimedia {
    foreach ($package in $installMultimediaList) {
        Install-ChocoPackage $package
    }
}

function Install-WorkTools {
    foreach ($package in $installWorkToolsList) {
        Install-ChocoPackage $package
    }
}

function Install-TechTools {
    foreach ($package in $installTechToolsList) {
        Install-ChocoPackage $package
    }
}

function Install-Gaming {
    foreach ($package in $installGamingList) {
        Install-ChocoPackage $package
    }
}

function Install-DesktopOnly {
    foreach ($package in $installDesktopOnlyList) {
        Install-ChocoPackage $package
    }
}

function Install-SurfaceOnly {
    foreach ($package in $installSurfaceOnlyList) {
        Install-ChocoPackage $package
    }
}

# Configuration functions.

function ConfigureSoftware {
    git config --global core.editor "nano"
    git config --global user.name "rasmuskriest"
    git config --global user.email "rasmusk@outlook.com"
}

$dataDriveLetter = Get-DataDrive
$dataDrive = "$dataDriveLetter`:"

# This is where the actual script starts.

Use-Checkpoint -Function ${Function:Set-BaseSettings} -CheckpointName 'BaseSettings' -SkipMessage 'BaseSettings already configured'
Use-Checkpoint -Function ${Function:Update-WindowsLibraries} -CheckpointName 'WindowsLibraries' -SkipMessage 'WindowsLibraries already moved'
Use-Checkpoint -Function ${Function:Install-PowerShellTools} -CheckpointName 'PowerShellTools' -SkipMessage 'PowerShellTools already installed'

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
choco install chocolatey
# Change default Chocolatey behaviour
Use-Checkpoint -Function ${Function:Enable-ChocolateyFeatures} -CheckpointName 'IntialiseChocolatey' -SkipMessage 'Chocolatey already configured'

if (Test-PendingReboot) { Invoke-Reboot }

# Reload path
Update-Path
Set-Volume -DriveLetter $sytemDrive -NewFileSystemLabel "Windows"

Use-Checkpoint -Function ${Function:Install-PowerShellModules} -CheckpointName 'PowerShellModules' -SkipMessage 'PowerShell modules already installed'

Use-Checkpoint -Function ${Function:ConfigureSoftware} -CheckpointName 'ConfigureSoftware' -SkipMessage 'Software already configured'

# Run Windows Update one last time
Write-BoxstarterMessage "Updating Windows"
Install-WindowsUpdate

Clear-Checkpoints
