[Environment]::SetEnvironmentVariable("VAGRANT_DEFAULT_PROVIDER", "hyperv", "Machine")

vagrant plugin install sahara # needed for chocolatey-test-environment
vagrant plugin install vagrant-hostsupdater # needed for most boxes that are to be reached from the host
