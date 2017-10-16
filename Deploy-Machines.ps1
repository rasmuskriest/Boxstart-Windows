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

$Boxstarter.RebootOk = $true
$Boxstarter.NoPassword = $false
$Boxstarter.AutoLogin = $true

$checkpointPrefix = 'BoxStarter:Checkpoint:'

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
    $checkpointMarkers = Get-ChildItem Env: | where { $_.name -like "$checkpointPrefix*" } | Select -ExpandProperty name
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

function Install-WindowsUpdate {
    if (Test-Path env:\BoxStarter:SkipWindowsUpdate) {
        return
    }

    Enable-MicrosoftUpdate
    Install-WindowsUpdate -AcceptEula
    #if (Test-PendingReboot) { Invoke-Reboot }
}

function Enable-ChocolateyFeatures {
    choco feature enable --name=autoUninstaller
    choco feature enable --name=allowGlobalConfirmation
}

function Set-BaseSettings {
    Update-ExecutionPolicy -Policy Unrestricted

    Enable-RemoteDesktop
    Set-CornerNavigationOptions -EnableUsePowerShellOnWinX
    Set-WindowsExplorerOptions -EnableShowHiddenFilesFoldersDrives -EnableShowProtectedOSFiles -EnableShowFileExtensions -EnableShowFullPathInTitleBar
}

function Update-WindowsLibraries {
    $dataDriveLetter = Get-DataDrive
    $dataDrive = "$dataDriveLetter`:"

    if (Get-SystemDrive -eq $dataDriveLetter) {
        return
    }

    Move-WindowsLibrary -libraryName "Personal" -newPath (Join-Path $dataDrive "Documents")
    Move-WindowsLibrary -libraryName "Downloads" -newPath (Join-Path $dataDrive "Downloads")
    Move-WindowsLibrary -libraryName "My Music"     -newPath (Join-Path $dataDrive "Music")
    Move-WindowsLibrary -libraryName "My Pictures"    -newPath (Join-Path $dataDrive "Pictures")
    Move-WindowsLibrary -libraryName "My Video"    -newPath (Join-Path $dataDrive "Videos")
}

function Install-WindowsFeatures {
    $features = choco list --source windowsfeatures
    if ($features | Where-Object {$_ -like "*Linux*"}) {
        dism /Online /Enable-Feature /FeatureName=Microsoft-Windows-Subsystem-Linux
    }
    dism /Online /Enable-Feature /FeatureName=LegacyComponents
    dism /Online /Enable-Feature /FeatureName=NetFx3

    if (Test-PendingReboot) { Invoke-Reboot }
}

function Install-HyperV {
    dism /Online /Enable-Feature /FeatureName=Microsoft-Hyper-V-All
}

function Install-PowerShellTools {
    choco install conemu
    choco install gow
    choco install pscx
    choco install pstools
    choco install openssh
}

function Install-PowerShellModules {
    Set-PSRepository -Name 'PSGallery' -InstallationPolicy 'Trusted'
    Install-Module PSReadline -Scope CurrentUser -AllowClobber
    Install-Module posh-git -Scope CurrentUser -AllowClobber
    Install-Module oh-my-posh -Scope CurrentUser -AllowClobber
    Set-PSRepository -Name 'PSGallery' -InstallationPolicy 'Untrusted'
}

function Install-Prerequisites {
    choco install 7zip
    choco install dropbox
    choco install flashplayerplugin
    choco install git
    choco install google-drive-file-stream
    choco install google-backup-and-sync
    choco install javaruntime
    choco install jdk8
    choco install notepad2
    # choco install OneDriveForBusiness
    choco install paint.net
    choco install python
    choco install python2
    choco install quicktime
    choco install unchecky
    choco install VirtualBox
    choco install VirtualBox.ExtensionPack
}

function Install-Browsers {
    choco install firefox -packageParameters "l=en-US"
    choco install firefox-dev --pre
    choco install GoogleChrome
    choco install GoogleChrome.Canary
    choco install tor-browser
    choco install vivaldi
}

function Install-CommunicationTools {
    choco install mattermost-desktop
    # choco install slack # Is in store
    choco install skype
    choco install whatsapp
}

function Install-DevTools {
    choco install android-sdk
    choco install gitkraken
    choco install heidisql
    choco install sqlitebrowser
    choco install vmwareworkstation
    choco install winscp
}

function Install-Vagrant {
    choco install vagrant
    Update-Path

    vagrant plugin install vagrant-hostsupdater
    vagrant plugin install vagrant-triggers
}

function Install-VisualStudioCode {
    choco install visualstudiocode
    Update-Path

    Start-Process code
    Start-Sleep -s 10

    code --install-extension donjayamanne.githistory
    code --install-extension donjayamanne.python
    code --install-extension marcostazi.vs-code-vagrantfile
    code --install-extension mdob2k.stata-language
    code --install-extension ms-vscode.powershell
    code --install-extension ms-vscode.theme-tomorrowkit
    code --install-extension robertohuertasm.vscode-icons
}

function Install-Multimedia {
    # choco install amazonmusic
    choco install jdownloader -pre
    # choco install spotify # Is in store
    choco install transmission
    choco install vlc
    choco install xmedia-recode
}

function Install-WorkTools {
    choco install adobe-creative-cloud # ps,ai,id,lr,acrobat
    # choco install cisco-anyconnect
    # choco install citavi
    # choco install elsterformular
    # choco install evernote # Is in store
    # choco install instagiffer
    choco install Office365HomePremium
    # choco install driveforoffice
    choco install outlookcaldav
    # choco install onetastic
    # choco install russian-grammatical-dictionary
    choco install teamviewer
    choco install xmind
}

function Install-TechTools {
    choco install ccleaner
    choco install doublecmd
    choco install fiddler
    choco install keepass
    choco install keepass-plugin-favicon
    choco install lockhunter
    choco install mp3tag
    # choco install multibootusb
    choco install nirlauncher
    choco install openvpn
    choco install putty
    choco install qttabbar
    choco install recuva
    choco install reshack
    choco install royalts
    choco install rufus
    choco install speccy
    choco install sysinternals
    choco install windirstat
    choco install winmerge
    choco install wireshark
}

function Install-Gaming {
    choco install goggalaxy
    choco install origin
    choco install steam
    choco install uplay
}

function Install-DesktopOnly {
    # choco install zune
    choco install todoist
    choco install defraggler
    choco install imgburn
    # choco install pstart
    choco install gamesavemanager
    choco install geforce-experience
    choco install Physx.Legacy
}

function Install-SurfaceOnly {
    # choco install OfficeRemote
    choco install wifi-manager
}

function ConfigureSoftware {
    git config --global core.editor "nano"
    git config --global user.name "rasmuskriest"
    git config --global user.email "rasmusk@outlook.com"
}

function Update-Path {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}

$dataDriveLetter = Get-DataDrive
$dataDrive = "$dataDriveLetter`:"
$tempInstallFolder = New-InstallCache -InstallDrive $dataDrive

# Change default Chocolatey behaviour
Use-Checkpoint -Function ${Function:Enable-ChocolateyFeatures} -CheckpointName 'IntialiseChocolatey' -SkipMessage 'Chocolatey already configured'

Use-Checkpoint -Function ${Function:Set-BaseSettings} -CheckpointName 'BaseSettings' -SkipMessage 'Base settings already configured'
Use-Checkpoint -Function ${Function:Update-WindowsLibraries} -CheckpointName 'WindowsLibraries' -SkipMessage 'Libraries already moved'

Write-BoxstarterMessage "Installing Windows Features"
Use-Checkpoint -Function ${Function:Install-WindowsFeatures} -CheckpointName 'UserSettings' -SkipMessage 'User settings are already configured'


Write-BoxstarterMessage "Starting software installation"

Use-Checkpoint -Function ${Function:Install-Prerequisites} -CheckpointName 'Install-Prerequisites' -SkipMessage 'Prerequisites already installed'

Use-Checkpoint -Function ${Function:Install-Browsers} -CheckpointName 'Install-Browsers' -SkipMessage 'Browsers already installed'

Use-Checkpoint -Function ${Function:Install-CommunicationTools} -CheckpointName 'Install-CommunicationTools' -SkipMessage 'Communication tools already installed'

Use-Checkpoint -Function ${Function:Install-DevTools} -CheckpointName 'Install-DevTools' -SkipMessage 'Development tools already installed'

Use-Checkpoint -Function ${Function:Install-Vagrant} -CheckpointName 'Install-Vagrant' -SkipMessage 'Vagrant already installed'

Use-Checkpoint -Function ${Function:Install-VisualStudioCode} -CheckpointName 'Install-VisualStudioCode' -SkipMessage 'Visual Studio Code already installed'

Use-Checkpoint -Function ${Function:Install-Multimedia} -CheckpointName 'Install-Multimedia' -SkipMessage 'Multimedia software already installed'

Use-Checkpoint -Function ${Function:Install-WorkTools} -CheckpointName 'Install-WorkTools' -SkipMessage 'Work tools software already installed'

Use-Checkpoint -Function ${Function:Install-TechTools} -CheckpointName 'Install-TechTools' -SkipMessage 'Tech tools software already installed'

Use-Checkpoint -Function ${Function:Install-Gaming} -CheckpointName 'Install-Gaming' -SkipMessage 'Gaming software software already installed'

if (Test-Path env:\BoxStarter:InstallDesktop) {
    Write-BoxstarterMessage "Installing desktop-only software"

    Use-Checkpoint -Function ${Function:Install-HyperV} -CheckpointName 'Install-HyperV' -SkipMessage 'Hyper-V already installed'
    if (Test-PendingReboot) { Invoke-Reboot }

    Use-Checkpoint -Function ${Function:Install-DesktopOnly} -CheckpointName 'InstallDesktopOnly' -SkipMessage 'Desktop-only software already installed'
    if (Test-PendingReboot) { Invoke-Reboot }
}

if (Test-Path env:\BoxStarter:InstallSurface) {
    Write-BoxstarterMessage "Installing Surface-only software"

    Use-Checkpoint -Function ${Function:Install-SurfaceOnly} -CheckpointName 'InstallSurfaceOnly' -SkipMessage 'Surface-only software already installed'
    if (Test-PendingReboot) { Invoke-Reboot }
}

# Install Chocolatey as very last package
choco install chocolatey

if (Test-PendingReboot) { Invoke-Reboot }

# Reload path
Update-Path

Use-Checkpoint -Function ${Function:Install-PowerShellModules} -CheckpointName 'PowerShellModules' -SkipMessage 'PowerShell modules already installed'

Use-Checkpoint -Function ${Function:ConfigureSoftware} -CheckpointName 'ConfigureSoftware' -SkipMessage 'Software already configured'

# Run Windows Update one last time
Write-BoxstarterMessage "Updating Windows"
Install-WindowsUpdate

Clear-Checkpoints
