﻿#############################################################################################################################
## Input Parameters
##########################################################################################################################
param($VarientSubFolder, $EnableDebugMode)
##########################################################################################################################
#############################################################################################################################

#############################################################################################################################
## Set Policy
##########################################################################################################################
Set-ExecutionPolicy Unrestricted -force
#set-executionpolicy remotesigned
##########################################################################################################################
#############################################################################################################################


#############################################################################################################################
## Init
##########################################################################################################################
    $scriptPath = $MyInvocation.MyCommand.Path #Get script location and name. Used later on to know if this was executed on a flash disk or not. 
    $Scriptdir = Split-Path $scriptPath
    $scriptName = Split-Path $scriptPath -leaf
    . $($PSScriptRoot + '\PowerShellHelperFunctions\HelperFunctions.ps1') #Load another script file
    $Logfile = $($Scriptdir + "\proc_$env:computername.log") 
##########################################################################################################################
## End Init
#############################################################################################################################

#############################################################################################################################
## Settings  :: Users are to EDIT THESE Varibles!!!!
##########################################################################################################################
#$EnableDebugMode = 1 #Use 0 for false, 1 for true
$EnableUninstallTwinCATFirst = 1
$EnableInstallTwinCAT = $true
$EnableInstallTwinCATHMI = $true
$EnableInstallChrome = $true

$CopyFilesToLocalDirectory= 0 # set to 1 if you wish to move the entire script and install files to the local hard drive. Can be nice if you wish to pull the USB stick out while installation is ongoing.
$SubFolderProgramsToBeInstalled="ProgramsToBeInstalled" #Directory where TwinCAT install files are located. Can be a sub directory or a directory with a root name.
$LocalDirectoryProgramsToBeInstalled = "C:\ProgramsToBeInstalled" #directory on local PC where log files, progress file to be located. If CopyFileToLocalDir true, then this folder gets script as well.
$StartupFolderLocation = "C:\Users\Administrator\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup" #Directory where batch file that executes script on bootup. This shouldn't be changed.
if($VarientSubFolder -eq $null -or $VarientSubFolder.Length -eq 0){
    $VarientSubFolder = "MachineDefaultVarient" #Can be edited to change what folder boot and HMI projects are stored. Easier to edit this variable then edit script to change script for differnet varients.
}
$RootInstallFolderExist = Test-Path -Path $LocalDirectoryProgramsToBeInstalled
##########################################################################################################################
## End Settings
#############################################################################################################################

#############################################################################################################################
## Load file which indicates installation progress. This is important if installation requires Reboots
##########################################################################################################################
    ##Load progress variable from progress file. The tracks how many times the PC has been rebooted
    if(Test-Path -Path $($LocalDirectoryProgramsToBeInstalled + '\' + "SavedProgress.txt")){
        Get-Content ($LocalDirectoryProgramsToBeInstalled + '\' + "SavedProgress.txt") | foreach-object -begin {$h2=@{}} -process { $k2 = $_ -split '=',2; if(($k2[0].CompareTo("") -ne 0) -and ($k2[0].StartsWith("[") -ne $True -And $k2[0].StartsWith("#") -ne $True)) { $h2.Add($k2[0], $k2[1]) } }       
         $InstallProgress=$h2.'Progress'}
         else{
         $InstallProgress=[int]0 

        }

##########################################################################################################################
## End Load file
#############################################################################################################################


#############################################################################################################################
#Copy Script from USB or temperatery directory to a suitable directory for working.
##########################################################################################################################
    $StartupFilePath = -join($StartupFolderLocation, "\AutoSetupPc.cmd")
    if($RootInstallFolderExist -eq 0){
        New-Item -ItemType Directory -Force -Path $LocalDirectoryProgramsToBeInstalled
        }
    if($CopyFilesToLocalDirectory -eq 1 -And  $LocalDirectoryProgramsToBeInstalled -ne $Scriptdir.ToString()){  #If directory in settings file does not match current directory then we copy the files.
        Write-Output "Copying Files to install folder on Root"

        #Copy Folder and all Content
        $CopyToDirectory = -join($Scriptdir, "\*")
        Copy-Item $CopyToDirectory  -Destination $LocalDirectoryProgramsToBeInstalled -recurse -Force
        
        Write-Output "Re-executing script on local PC"
        Start-Sleep -Seconds 5
        $ExternalScriptPath = $($LocalDirectoryProgramsToBeInstalled + '\' + $scriptName)
        Invoke-Expression -Command $ExternalScriptPath
        Exit
    }
##########################################################################################################################
#End #Copy Files from USB or temperatery directory to a suitable directory for working.
#############################################################################################################################


#############################################################################################################################
#Display Settings to user
##########################################################################################################################
    WriteLog $("Auto Setup PC Script Started. Install Progress "+  $InstallProgress)
    Write-Output $("####################################################################")
    Write-Output $("######################### Settings #################################")
    Write-Output $("Install Progress "+  $InstallProgress) #Not actual %, just counts number of installatoin programs is completed.  
    Write-Output $("Current Script Name " + $scriptName)  
    Write-Output $("Local Directory " + $LocalDirectoryProgramsToBeInstalled)
    Write-Output $("Script Directory " + $Scriptdir.ToString()) 
    Write-Output $("Folder Varient " + $VarientSubFolder.ToString())  
    Write-Output $("Settings")
    Write-Output $("EnableDebugMode                     = " + $EnableDebugMode)
    Write-Output $("SubFolderProgramsToBeInstalled      = " + $SubFolderProgramsToBeInstalled)
    Write-Output $("LocalDirectoryProgramsToBeInstalled = " + $LocalDirectoryProgramsToBeInstalled)    
    Write-Output $("StartupFolderLocation               = " + $StartupFolderLocation)
    Write-Output $("CopyFilesToLocalDirectory           = " + $CopyFilesToLocalDirectory)
    Write-Output $("####################################################################")
    Write-Output $("####################################################################")
    Write-Output $("")

##########################################################################################################################
#End Display Settings to user
#############################################################################################################################


#############################################################################################################################
#Auto Download TwinCAT installers ---- Experimental  ----- Not working yet.
##########################################################################################################################
$destination = $($Scriptdir + '\' + $SubFolderProgramsToBeInstalled +'\' + 'TwinCAT3.1.exe')
$InstallFileExist = Test-Path -Path $destination
if($InstallFileExist -eq 0 -AND 0){
### THIS does not work. Need to find a location that has download available without a login otherwise this is overly complicated. 

    Write-Output $("Downloading TwinCAT 3.1 Installer")
    #$credential = Get-Credential
    # Source file location
    $source = 'https://www.beckhoff.com/forms/twincat3/downloadFile.aspx?logID=d133d80b-32d1-4c69-a878-f803c88b733b&filename=TC31-Full-Setup.3.1.4024.35.zip&version=3.1.4024.35&pimID=530163029&email=k.robbens@beckhoff.com'
    #Download the file
    #Start-BitsTransfer -Source  $source -Destination  $destination # -Credential $credential

        # Create the new WebClient
    $webClient = [System.Net.WebClient]::new()
    # Download the file
    $webClient.DownloadFile($source, $destination)
}
##########################################################################################################################
#END Auto Download TwinCAT installers ---- Experimental
#############################################################################################################################

#############################################################################################################################
#Start Install
##########################################################################################################################
  Write-Output $("####################################################################")
  Write-Output $("##################### Install Starting #############################")
  Write-Output $("####################################################################")
  Write-Output $("")

$Done = 0
While ($Done -eq 0){
switch([int]$InstallProgress) {
   0 #Inital setup 
   {
        #Create a startup file to auto execute this script. This makes the install progress 100% automatic if reboots are needed
        WriteLog $("Creating Startup File to rerun script after reboot " + $InstallerFilePath)
        New-Item -Path $StartupFilePath -ItemType File -Force
        -join("powershell.exe -Command Start-Process PowerShell -ArgumentList '-File ", $Scriptdir, '\', $scriptName, ' ' , $VarientSubFolder, "' -Verb RunAs") | out-file -filepath $StartupFilePath -Append -Encoding Ascii    

        WriteLog $("Turn off TwinCAT security wizard. It's the web page that shows up on bootup")
        Remove-ItemProperty -Path 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run' -Name 'StartSecurityWizard'
    }
    1 #Uninstall Software. - Optional. Can improve robustness of script. If you are trying to install an older version of TwinCAT this is required. 
    {       
        if($EnableUninstallTwinCATFirst -eq 1 -and $EnableDebugMode -ne 1)
        {
            WriteLog $("Uninstalling Software")
            #Get Beckhoff installed software list
            #$ListBeckhoffInstalledSoftware= @()       
            $TwinCATInstalledInfo = Get-WmiObject -Class Win32_Product | where Name -eq 'Beckhoff TwinCAT 3.1 (Build 4024)' | select Name,Version
            
            if($TwinCATInstalledInfo.Version.length -ge 2){ #Dumb check to make sure its alrady installed. One could check the version against the version you wish to install.
                WriteLog $("Uninstalling TwinCAT build " + $TwinCATInstalledInfo.Version) #Version example '3.1.4024.35'
                Get-Package $TwinCATInstalledInfo.Name | Uninstall-Package -Force;
                Reboot
            }
        }
   }
   2 #Execute first installers. Basicly put all installers you need here. 
   {

        ## Start Installers
        if($EnableInstallTwinCAT){
            $InstallerFilePath = GetFilePathFromFolder $($Scriptdir + '\' + $SubFolderProgramsToBeInstalled +'\' + 'TwinCAT3.1')
            WriteLog $("Starting installation TwinCAT 3 at Path: " + $InstallerFilePath)
            if($EnableDebugMode -ne 1){           
                Start-Process $InstallerFilePath -argumentlist '/s /v"/qr ALLUSERS=1 REBOOT=ReallySuppress"' -Wait
            }
            WriteLog $("Copying License File") #You shouldn't need this if you use a EL6070. This is here for Testing with trial license!!!
            CopyFolderToFolder "C:\TwinCAT\3.1\Target\License" "License" 0

            WriteLog $("Copying Boot folder into TwinCAT 3")
            CopyFolderToFolder "C:\TwinCAT\3.1\Boot" "*\TwinCATBootFolder" 0
        }

        if($EnableInstallTwinCATHMI){
            $InstallerFilePath = GetFilePathFromFolder $($Scriptdir + '\' + $SubFolderProgramsToBeInstalled +'\' + 'TF2000_HMI')
            WriteLog $("Starting installation TwinCAT HMI at Path: " + $InstallerFilePath)
            if($EnableDebugMode -ne 1){           
                Start-Process $InstallerFilePath -argumentlist '/s /v"/qr ALLUSERS=1 REBOOT=ReallySuppress"' -Wait
            }
        }



        if($EnableInstallChrome){
            WriteLog $("Copying Chrome")
            CopyFolderToFolder "C:\Chrome" "ProgramsToBeInstalled\chrome-win" 0

            WriteLog $("Copying Chrome shortcut link to desktop")
            CopyFileToFolder "C:\Users\Administrator\Desktop" "ProgramsToBeInstalled\Batch_Shortcuts\HMIShortcut.lnk"

            WriteLog $("Copying Chrome shortcut link to startup")
            CopyFileToFolder "C:\TwinCAT\3.1\Target\StartUp" "ProgramsToBeInstalled\Batch_Shortcuts\HMIShortcut.lnk"
        }



        Reboot
   } 

   3 #After first installers reboot
   { # Anything you need to do after installers run and a reboot. IE: put things into run mode and maybe copy some files.
        if($EnableInstallTwinCAT){
            WriteLog $("Set Registery key for TwinCAT to run mode on bootup")
            Set-Itemproperty -Path 'HKLM:\SOFTWARE\WOW6432Node\Beckhoff\TwinCAT3\System' -Name 'SysStartupState' -value 5
        }

        if($EnableInstallTwinCATHMI){
            WriteLog $("Stopping HMI service, Copying HMI Project files, then restarting HMI service")
            Stop-Service -Name 'TcHmiSrv' -PassThru        
            CopyFolderToFolder "C:\ProgramData\Beckhoff\TF2000 TwinCAT 3 HMI Server\service\TcHmiProject" "*\TcHmiProject" 1
            Start-Service -Name 'TcHmiSrv' -PassThru
        }

        WriteLog $("Setting IP address to: N/A")
        #Get-NetIPAddress -AddressFamily IPv4
        #New-NetIPAddress -InterfaceIndex 12 -IPAddress 192.168.0.1

        WriteLog $("Delete auto start script command from: " + $StartupFilePath)
        Remove-Item -Path $StartupFilePath
        $InstallProgress = [int]100
        SaveSettingToFile $InstallProgress

        Write-Output $("####################################################################")
        Write-Output $("##################### Finishing Installation #######################")
        Write-Output $("####################################################################")
        Write-Output $("")
        Write-Output  $("Final Reboot started")

        #while we don't need to reboot, but lets test to make sure everthing loaded good
        Reboot
   } 

   4  #Another reboot if needed
   {
        ##If extra reboots needed.

   } 

   ## Reset install progress if debug mode is on. Just a little trick when testing to make life easy.
    Default {
        $Done = 1
        if($EnableDebugMode -eq 1)
        {
            $InstallProgress=0
            SaveSettingToFile $InstallProgress
        }      
    }
}
$InstallProgress = [int]$InstallProgress + [int]1
SaveSettingToFile $InstallProgress
}

if($EnableDebugMode -eq 1)
{
    Read-Host -Prompt "Press Enter to exit"
}