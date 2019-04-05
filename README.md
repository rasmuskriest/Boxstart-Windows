# Boxstart-Windows

A script for setting up PCs using Boxstarter (a layer to automate the use of Boxstarter).

This script is heavily based (not to say that it's a fork) on [the one by JonCubed](https://github.com/JonCubed/boxstarter) which itself is based on a [gist](https://gist.github.com/JonCubed/e5f6c273b6e836a8cfba0a92fe2f4f1a)
and [neutmute script's](https://github.com/neutmute/nm-boxstarter).

## How To Use

There are a few options for launching a Boxstarter script check out the [offical documentation](http://boxstarter.org/InstallingPackages) for
all the various methods.

### Bootstrapper

The Bootstrapper method is the recommended way to run this script. Simply open a elevated powershell console and run the following command:

```powershell
> wget -Uri 'https://raw.githubusercontent.com/rasmuskriest/Boxstart-Windows/master/Bootstrap-Boxstarter.ps1' -OutFile "$($env:temp)\Bootstrap-Boxstarter.ps1";&Invoke-Command -ScriptBlock { &"$($env:temp)\Bootstrap-Boxstarter.ps1" <arguments> }
```

You may remove *&lt;arguments&gt;* or replace it with one or more argument lists below

| Argument | Type | Value Description |
| -------- | ---- | ----------------- |
| InstallSurface | Switch | Configures machine to be a portable computer (aka my Surface). |
| InstallDesktop | Switch | Configures machine to be a workhorse for home and work use (aka my Desktop). |
| SkipWindowsUpdate | Switch | Skips Windows Update. |
| DataDrive | Char | Drive to move libraries and other data to. Defaults to system drive. |

#### Examples

1. Set up Surface:

```powershell
> wget -Uri 'https://raw.githubusercontent.com/rasmuskriest/Boxstart-Windows/master/Bootstrap-Boxstarter.ps1' -OutFile "$($env:temp)\Bootstrap-Boxstarter.ps1";&Invoke-Command -ScriptBlock { &"$($env:temp)\Bootstrap-Boxstarter.ps1" -InstallSurface -SkipWindowsUpdate }
```

2. Set up Desktop with data drive specified:

```powershell
> wget -Uri 'https://raw.githubusercontent.com/rasmuskriest/Boxstart-Windows/master/Bootstrap-Boxstarter.ps1' -OutFile "$($env:temp)\Bootstrap-Boxstarter.ps1";&Invoke-Command -ScriptBlock { &"$($env:temp)\Bootstrap-Boxstarter.ps1" -InstallDesktop -DataDrive 'D' }
```


### Manual

If you want more control over what is happening you can manually run the script.

1. You must first setup environment keys for the features you would like to install.

    | Argument | Value | Value Description |
    | -------- | ---- | ----------------- |
    | BoxStarter:InstallSurface | 1 | Configures machine to be a portable computer (aka my Surface). |
    | BoxStarter:InstallDesktop | 1 | Configures machine to be a workhorse for home and work use (aka my Desktop). |
    | BoxStarter:SkipWindowsUpdate | 1 | Skips Windows Update. |
    | BoxStarter:DataDrive | Char | Drive to move libraries and other data to. Defaults to system drive. |

    **Environment variables must be added to *Machine* and *Process* scopes.**

2. Run the following command

    * In Command Prompt:

    ```powershell
    > START http://boxstarter.org/package/nr/url?http://boxstarter.org/package/nr/url?https://raw.githubusercontent.com/rasmuskriest/Boxstart-Windows/master/Deploy-Machines.ps1
    ```

  * In Edge Or Internet Explorer, go to:

    ```http
    http://boxstarter.org/package/nr/url?http://boxstarter.org/package/nr/url?https://raw.githubusercontent.com/rasmuskriest/Boxstart-Windows/master/Deploy-Machines.ps1
    ```
