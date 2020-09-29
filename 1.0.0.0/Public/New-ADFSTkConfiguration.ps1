#Requires -Version 5.1

function New-ADFSTkConfiguration {




[cmdletbinding()]
    Param (
        [parameter(ValueFromPipeline=$True)]
        [string[]]$MigrationConfig
    )

    Begin {

        $myModule = Get-Module ADFSToolkit-IDEM
        $configPath = Join-Path $myModule.ModuleBase "config"
        if (Test-Path $configPath)
        {
            $configDefaultPath = Join-Path $configPath "default"
            if (Test-Path $configDefaultPath)
            {
                $dirs = Get-ChildItem -Path $configDefaultPath -Directory
                $configFoundLanguages = (Compare-ADFSTkObject -FirstSet $dirs.Name -SecondSet ([System.Globalization.CultureInfo]::GetCultures("SpecificCultures").Name) -CompareType Intersection).CompareSet
    
                $configFoundLanguages | % {
                    $choices = @()
                    $caption = "Select language"
                    $message = "Please select which language you want help text in."
                    $defaultChoice = 0
                    $i = 0
                }{
                    $choices += New-Object System.Management.Automation.Host.ChoiceDescription "&$([System.Globalization.CultureInfo]::GetCultureInfo($_).DisplayName)","" #if we want more than one language with the same starting letter we need to redo this (number the languages)
                    if ($_ -eq "en-US") {
                        $defaultChoice = $i
                    }
                    $i++
                }{
            
                    $result = $Host.UI.PromptForChoice($caption,$message,[System.Management.Automation.Host.ChoiceDescription[]]$choices,$defaultChoice) 
                }
        
                $configChosenLanguagePath = Join-Path $configDefaultPath ([string[]]$configFoundLanguages)[$result]

                if (Test-Path $configChosenLanguagePath)
                {
                    $defaultConfigFile = Get-ChildItem -Path $configChosenLanguagePath -File -Filter "config.ADFSTk.default*.xml" | Select -First 1 #Just to be sure
                }
                else
                {
                    #This should'nt happen
                }
            }
            else
            {
                #no default configs :(
            }
        }
        else
        {
            #Yeh what to do?
        }

}

# for each configuration we want to handle, we do these steps
# if given a configuration, we use it to load and set them as defaults and continue with the questions
# allowing them to hit enter to accept the default to save time and previous responses.
#
# if an empty configuration file is entered, we will ask the questions, with no defaults set.

process 
{

 # Detect and prep previousConfig to source values for defaults from it
        [xml]$previousConfig=""
        $previousMsg=""

             if ([string]::IsNullOrEmpty($MigrationConfig))
                {
                    Write-Verbose "No Previous Configuration detected"
                }else
                {
                 if (Test-Path -Path $MigrationConfig )
                        {
                        $previousConfig=Get-Content $MigrationConfig
                        $previousMsg="Using previous configuration for defaults (file: $MigrationConfig)`nPLEASE NOTE: Previous hand edits to config must be manually applied again`n"
                    }
                    else 
                    {
                        Throw "Error:Migration file $MigrationConfig does not exist, exiting"
                     }

                }

 
        # Use our template from the Module to start with

        [xml]$config = Get-Content $defaultConfigFile.FullName


            Write-Host "--------------------------------------------------------------------------------------------------------------" -ForegroundColor Cyan
        if (([string[]]$configFoundLanguages)[$result] -eq "en-US")
        {
            Write-Host "You are about to create a new configuration file for ADFSToolkit-IDEM." -ForegroundColor Cyan
            Write-Host " "
            Write-Host "$previousMsg" -ForegroundColor Red
            Write-Host " "
            Write-Host "You will be prompted with questions about metadata, signature fingerprint" -ForegroundColor Cyan
            Write-Host "and other question about your institution." -ForegroundColor Cyan
            Write-Host " "
            Write-Host "Hit enter to accept the defaults in round brackets" -ForegroundColor Cyan
            Write-Host " "
            Write-Host "If you make a mistake or want to change a value after this cmdlet is run" -ForegroundColor Cyan
            Write-Host "you can manually open the config file or re-run this command." -ForegroundColor Cyan
        }
        elseif (([string[]]$configFoundLanguages)[$result] -eq "sv-SE")
        {
            Write-Host "You are about to create a new configuration file for ADFSToolkit-IDEM." -ForegroundColor Cyan
            Write-Host " "
            Write-Host "$previousMsg" -ForegroundColor Red
            Write-Host " "
            Write-Host "You will be prompted with questions about metadata, signature fingerprint" -ForegroundColor Cyan
            Write-Host "and other question about your institution." -ForegroundColor Cyan
            Write-Host " "
            Write-Host "Hit enter to accept the defaults in round brackets" -ForegroundColor Cyan
            Write-Host " "
            Write-Host "If you make a mistake or want to change a value after this cmdlet is run" -ForegroundColor Cyan
            Write-Host "you can manually open the config file or re-run this command." -ForegroundColor Cyan

     }
            Write-Host "--------------------------------------------------------------------------------------------------------------" -ForegroundColor Cyan


       
        Set-ADFSTkConfigItem -XPath "configuration/metadataURL" `
                       -ExampleValue 'https://metadata.federationOperator.org/path/to/metadata.xml'
                       
        Set-ADFSTkConfigItem -XPath "configuration/signCertFingerprint" `
                       -ExampleValue '0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF'

        Set-ADFSTkConfigItem -XPath "configuration/MetadataPrefix" `
                       -ExampleValue 'ADFSTk/SWAMID/CANARIE/INCOMMON' `
                  
        Set-ADFSTkConfigItem -XPath "configuration/staticValues/o" `
                       -ExampleValue 'ABC University'

        Set-ADFSTkConfigItem -XPath "configuration/staticValues/co" `
                       -ExampleValue 'Canada, Sweden'

        Set-ADFSTkConfigItem -XPath "configuration/staticValues/c" `
                       -ExampleValue 'CA, SE'

        Set-ADFSTkConfigItem -XPath "configuration/staticValues/schacHomeOrganization" `
                       -ExampleValue 'institution.edu'

        Set-ADFSTkConfigItem -XPath "configuration/staticValues/norEduOrgAcronym" `
                       -ExampleValue 'CA'

        Set-ADFSTkConfigItem -XPath "configuration/staticValues/ADFSExternalDNS" `
                       -ExampleValue 'adfs.institution.edu'


        $epsa = $config.configuration.storeConfig.attributes.attribute | ? type -eq "urn:mace:dir:attribute-def:eduPersonScopedAffiliation"
        $epa = $config.configuration.storeConfig.attributes.attribute | ? type -eq "urn:mace:dir:attribute-def:eduPersonAffiliation" 

        $epa.ChildNodes | % {
            $node = $_.Clone()    
            $node.'#text' += "@$($config.configuration.staticValues.schacHomeOrganization)"

            $epsa.AppendChild($node) | Out-Null

        }

        # Post processing to apply some business logic to enhance things

        # Module specific info
            $myWorkingPath= (Get-Module -Name ADFSToolkit-IDEM).ModuleBase
            $myVersion= (Get-Module -Name ADFSToolkit-IDEM).Version.ToString()


        # set workingpath for base:
            $myInstallDir= "c:\ADFSToolkit-IDEM"
            $myADFSTkInstallDir= Join-path $myInstallDir $myVersion



        # various useful items for minting our configuration 


        # user entered
            $myPrefix=     (Select-Xml -Xml $config -XPath "configuration/MetadataPrefix").Node.'#text'
        # sourced from config template
            $myCacheDir =  (Select-Xml -Xml $config -XPath "configuration/CacheDir").Node.'#text'
            $myConfigDir = (Select-Xml -Xml $config -XPath "configuration/ConfigDir").Node.'#text'
    
        # derived paths 
            $myTargetInstallCacheDir = Join-path $myADFSTkInstallDir $myCacheDir
            $myTargetInstallConfigDir = Join-path $myADFSTkInstallDir $myConfigDir

            # this one is a really a text string with variables in it for a script to use. ie. it has 'thing\$VarName' as the literal value
            # Variable name as string used in sync-ADFSTkAggregates to construct a dynamic path to indicate current version
            $myADFSTkCurrVerVarName="CurrentLiveVersion"
            $myTargetInstallDirDynamicPathString= Join-Path $myADFSTkInstallDir "`$$($myADFSTkCurrVerVarName)"

   

        #verify directories for cache and config exist or create if they do not

        # we need an install directory

        If(!(test-path $myADFSTkInstallDir))
        {
              New-Item -ItemType Directory -Force -Path $myADFSTkInstallDir
              Write-Host "ADFSToolkit-IDEM directory did not exist, creating it here: $myADFSTkInstallDir"
        }else
        {
            Write-Host "Cache directory exists at $myADFSTkInstallDir"
        }

            If(!(test-path $myTargetInstallCacheDir))
        {
              New-Item -ItemType Directory -Force -Path $myTargetInstallCacheDir
              Write-Host "Cache directory did not exist, creating it here: $myTargetInstallCacheDir"
        }else
        {
            Write-Host "Cache directory exists at $myTargetInstallCacheDir"
        }

            If(!(test-path $myTargetInstallConfigDir))
        {
              New-Item -ItemType Directory -Force -Path $myTargetInstallConfigDir
              Write-Host "Config directory did not exist, creating it here: $myTargetInstallConfigDir"
        }else
        {
            Write-Host "Config directory exists at $myTargetInstallConfigDir"
        }




        # For the ADFSTk functionality, we desire to associate certain cache files to certain things and bake a certain default location
 
             (Select-Xml -Xml $config -XPath "configuration/WorkingPath").Node.'#text' = "$myADFSTkInstallDir"
             (Select-Xml -Xml $config -XPath "configuration/SPHashFile").Node.'#text' = "$myPrefix-SPHashfile.xml"
             (Select-Xml -Xml $config -XPath "configuration/MetadataCacheFile").Node.'#text' = "$myPrefix-metadata.cached.xml"



        $configFile = Join-Path $myTargetInstallConfigDir "config.$myPrefix.xml"
        $configJobName="sync-ADFSTkAggregates.ps1"
        $configJob = Join-Path $myADFSTkInstallDir $configJobName

        #
        # Prepare our template for ADFSTkManualSPSettings to be copied into place, safely of course, after directories are confirmed to be there.

            $myADFSTkManualSpSettingsFileNamePrefix="get-ADFSTkLocalManualSpSettings"
            $myADFSTkManualSpSettingsFileNameDistroPostfix="-dist.ps1"
            $myADFSTkManualSpSettingsFileNameInstallDistroName="$($myADFSTkManualSpSettingsFileNamePrefix)$($myADFSTkManualSpSettingsFileNameDistroPostfix)"
            $myADFSTkManualSpSettingsFileNameInstallPostfix=".ps1"
            $myADFSTkManualSpSettingsFileNameInstallInstallName="$($myADFSTkManualSpSettingsFileNamePrefix)$($myADFSTkManualSpSettingsFileNameInstallPostfix)"

            $myADFSTkManualSpSettingsDistroTemplateFile= Join-Path $myWorkingPath -ChildPath "config" |Join-Path -ChildPath "default" | Join-Path -ChildPath "en-US" |Join-Path -ChildPath "$($myADFSTkManualSpSettingsFileNameInstallDistroName)"
    
            $myADFSTkManualSpSettingsInstallTemplateFile= Join-Path $myADFSTkInstallDir -ChildPath "config" |Join-Path -ChildPath "$($myADFSTkManualSpSettingsFileNameInstallInstallName)"
    
    

            # create a new file using timestamp removing illegal file characters 
            $myConfigFileBkpExt=get-date -Format o | foreach {$_ -replace ":", "."}

        if (Test-path $configFile) 
        {
                $message  = "ADFSToolkit:Configuration Exists."
                $question = "Overwrite $configFile with this new configuration?`n(Backup will be created)"

                $choices = New-Object Collections.ObjectModel.Collection[Management.Automation.Host.ChoiceDescription]
                $choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&Yes'))
                $choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&No'))

                $decision = $Host.UI.PromptForChoice($message, $question, $choices, 1)
                if ($decision -eq 0) {

            
                    $myConfigFileBkpName="$configFile.$myConfigFileBkpExt"

                    Write-Host "Creating new config in: $configFile"
                    Write-Host "Old configuration: $myConfigFileBkpName"

                    Move-Item -Path $configFile -Destination $myConfigFileBkpName

                    $config.Save($configFile)


                } else {
         
          
                    throw "Safe exit: User decided to not overwrite file, stopping"
        
                }


        }else
        {
                Write-Host "No existing file, saving new ADFSTk configuration to: $configFile"
                $config.Save($configFile)
         
        }

        if (Test-path $myADFSTkManualSpSettingsInstallTemplateFile ) 
        {

                $message  = "Local Relying Party Settings Exist"
                $question = "Overwrite $myADFSTkManualSpSettingsInstallTemplateFile with new blank configuration?`n(Backup will be created)"

                $choices = New-Object Collections.ObjectModel.Collection[Management.Automation.Host.ChoiceDescription]
                $choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&Yes'))
                $choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&No'))

                $decision = $Host.UI.PromptForChoice($message, $question, $choices, 1)
                if ($decision -eq 0) {
                    Write-Host "Confirmed, saving new Relying Part/Service Provider customizations to: $myADFSTkManualSpSettingsInstallTemplateFile"


                    $mySPFileBkpName="$myADFSTkManualSpSettingsInstallTemplateFile.$myConfigFileBkpExt"

                    Write-Host "Creating new config in: $myADFSTkManualSpSettingsDistroTemplateFile"
                    Write-Host "Old configuration: $mySPFileBkpName"
                    # Make backup
                    Move-Item -Path $myADFSTkManualSpSettingsInstallTemplateFile -Destination $mySPFileBkpName

                    # Detect and strip signature from file we ship

                    $myFileContent=get-content $($myADFSTkManualSpSettingsDistroTemplateFile)
                    $mySigLine=($myFileContent|select-string "SIG # Begin signature block").LineNumber
                    $sigOffset=2
                    $mySigLocation=$mySigLine-$sigOffset

                    # detection is anything greater than zero with offset as the signature block will be big.
                    if ($mySigLocation -gt 0 )
                     {
                        $myFileContent =$myFileContent[0..$mySigLocation]
                        Write-Host "File signed, stripping signature and putting in place for you to customize"
                    }
                    else
                    {
                        Write-Host "File was not signed, simple copy being made"
                    }
                        $myFileContent | set-content $myADFSTkManualSpSettingsInstallTemplateFile
     

                } else {
          
                    Write-Host "User decided to not overwrite existing SP settings file, proceeding to next steps" 
                }

        }else
        {
                Write-Host "No existing file, saving new configuration to: $($myADFSTkManualSpSettingsInstallTemplateFile)"
               Copy-item -Path $($myADFSTkManualSpSettingsDistroTemplateFile) -Destination $myADFSTkManualSpSettingsInstallTemplateFile

                }

        # Builing sync-ADFSTkAggregates.ps1
        #
        # We build our strings to create or augment the sync-ADFSTkAggregates.ps1
        # and then pivot on logic regarding the existence of the file
        # Logic:
        #       Create file if it doesn't exist
        #       If exists, augment with the next configuration
        #

        # Build the necessary strings to use in building our script

        $myDateFileUpdated                = Get-Date
        $myADFSTkCurrentVersion           = (Get-Module -ListAvailable ADFSToolkit-IDEM).Version.ToString()
        $ADFSTkSyncJobSetVersionCommand   = "`$$($myADFSTkCurrVerVarName) = $myADFSTkCurrentVersion"

        $ADFSTkSyncJobFingerPrint  = "#ADFSToolkit:$myADSTkCurrentVersion : $myDateFileUpdated"
        $ADFSTkImportCommand       ="`$md=get-module -ListAvailable adfstoolkit-idem; Import-module `$md" 

        $ADFSTkRunCommand          = "Import-ADFSTkMetadata -ProcessWholeMetadata -ForceUpdate -ConfigFile '$configFile'"
        #$ADFSTKManualSPCommand     =". $($myADFSTkManualSpSettingsInstallTemplateFile)`r`n`$ADFSTkSiteSPSettings=$myADFSTkManualSpSettingsFileNamePrefix"

        $ADFSTkModuleBase=(Get-Module -ListAvailable ADFSToolkit-IDEM).ModuleBase




        if (Test-path $configJob) 
        {
                $message  = 'ADFSToolkit-IDEM Script for Loading Exists.'
                $question = "Append this: $configJob in $configJobName ?`n(Recommended approach is yes)"

                $choices = New-Object Collections.ObjectModel.Collection[Management.Automation.Host.ChoiceDescription]
                $choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&Yes'))
                $choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList '&No'))

                $decision = $Host.UI.PromptForChoice($message, $question, $choices, 1)
                if ($decision -eq 0) {
                    Write-Host "Confirmed, appending command to: $configJob"
                    # We want to write only the job to schedule on a newline to be run
                    # Other steps for the first time the file is written is in a nother section of the testing for existence of this file
                    Add-Content $configJob "`n$ADFSTkRunCommand"
                    Add-Content $configJob "`n#Updated by: $ADFSTkSyncJobFingerPrint"
     
                } else {
                   Write-host "User selected to NOT add this configuration to $configJob"      
                }


        }else
        {
                # This is the first time the file is written so we need a few more items that other lines depend on in subsequent invocations
                Write-Host "$configJob PowerShell job does not exist. Creating it now"
                    
            
                     Add-Content $configJob "`n$ADFSTkSyncJobFingerPrint"
                     Add-Content $configJob "`n$ADFSTkSyncJobSetVersionCommand"
                     Add-Content $configJob "`n$ADFSTkImportCommand"
                    # Add-Content $configJob "`n$ADFSTKManualSPCommand"
                     Add-Content $configJob "`n$ADFSTkRunCommand"        
                     Add-Content $configJob "`n#Updated by: $ADFSTkSyncJobFingerPrint"        
        }



        Write-Host "--------------------------------------------------------------------------------------------------------------" -ForegroundColor Cyan

        if (([string[]]$configFoundLanguages)[$result] -eq "en-US")
        {
            Write-Host "The configuration file has been saved here:" -ForegroundColor Cyan
            Write-Host $configFile -ForegroundColor Yellow
            Write-Host "To run the metadata import use the following command:" -ForegroundColor Cyan
            Write-Host $ADFSTkRunCommand -ForegroundColor Yellow
            Write-Host "Do you want to create a scheduled task that executes this command every hour?" -ForegroundColor Cyan
            Write-Host "The scheduled task will be disabled when created and you can change triggers as you like." -ForegroundColor Cyan
            $scheduledTaskQuestion = "Create ADFSToolkit scheduled task?"
            $scheduledTaskName = "Import Federated Metadata with ADFSToolkit-IDEM"
            $scheduledTaskDescription = "This scheduled task imports the Federated Metadata with ADFSToolkit-IDEM"
        }
        elseif (([string[]]$configFoundLanguages)[$result] -eq "sv-SE")
        {
            Write-Host "This is actually in Swedish! ;)" -ForegroundColor Cyan
            Write-Host "The configuration file has been saved here:" -ForegroundColor Cyan
            Write-Host $configFile -ForegroundColor Yellow
            Write-Host "To run the metadata import use the following command:" -ForegroundColor Cyan
            Write-Host $ADFSTkRunCommand -ForegroundColor Yellow
            Write-Host "Do you want to create a scheduled task that executes this command every hour?" -ForegroundColor Cyan
            Write-Host "The scheduled task will be disabled when created and you can change triggers as you like." -ForegroundColor Cyan
            $scheduledTaskQuestion = "Create ADFSToolkit scheduled task?"
            $scheduledTaskName = "Import Federated Metadata with ADFSToolkit-IDEM"
            $scheduledTaskDescription = "This scheduled task imports the Federated Metadata with ADFSToolkit-IDEM"
        }

        if (Get-ADFSTkAnswer $scheduledTaskQuestion)
        {
            $stAction = New-ScheduledTaskAction -Execute 'Powershell.exe' `
                                              -Argument "-NoProfile -WindowStyle Hidden -command '& $configJob'"

            $stTrigger =  New-ScheduledTaskTrigger -Daily -DaysInterval 1 -At (Get-Date)
            $stSettings = New-ScheduledTaskSettingsSet -Disable -MultipleInstances IgnoreNew -ExecutionTimeLimit ([timespan]::FromHours(12))

            Register-ScheduledTask -Action $stAction -Trigger $stTrigger -TaskName $scheduledTaskName -Description $scheduledTaskDescription -RunLevel Highest -Settings $stSettings -TaskPath "\ADFSToolkit-IDEM\"
    
        }

        Write-Host "--------------------------------------------------------------------------------------------------------------" -ForegroundColor Cyan

        if (([string[]]$configFoundLanguages)[$result] -eq "en-US")
        {
            Write-Host "All done!" -ForegroundColor Green
        }
        elseif (([string[]]$configFoundLanguages)[$result] -eq "sv-SE")
        {
            Write-Host "This is actually in Swedish! ;)" -ForegroundColor Cyan
            Write-Host "All done!" -ForegroundColor Green
        }

        }


<#
.SYNOPSIS
Create or migrats an ADFSToolkit configuration file per aggregate.

.DESCRIPTION

This command creates a new or migrates an older configuration to a newer one when invoked.

How this Powershell Cmdlet works:
 
When loaded we:
   -  seek out a template configuration in $Module-home/config/default/en/config.ADFSTk.default*.xml 
   -- where * is the language designation, usually 'en'
   -  if invoked with -MigrateConfig, the configuration attempts to detect the previous answers as defaults to the new ones where possible

   
.INPUTS

zero or more inputs of an array of string to command

.OUTPUTS

configuration file(s) for use with current ADFSToolkit that this command is associated with

.EXAMPLE
new-ADFSTkConfiguration

.EXAMPLE

"C:\ADFSToolkit\0.0.0.0\config\config.file.xml" | new-ADFSTkConfiguration

.EXAMPLE

"C:\ADFSToolkit\0.0.0.0\config\config.file.xml","C:\ADFSToolkit\0.0.0.0\config\config.file2.xml" | new-ADFSTkConfiguration

#>

}
# SIG # Begin signature block
# MIIYUAYJKoZIhvcNAQcCoIIYQTCCGD0CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUWW7gDOOVo27+fP2p/iIpvYy5
# M2KgghKwMIIEFDCCAvygAwIBAgILBAAAAAABL07hUtcwDQYJKoZIhvcNAQEFBQAw
# VzELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExEDAOBgNV
# BAsTB1Jvb3QgQ0ExGzAZBgNVBAMTEkdsb2JhbFNpZ24gUm9vdCBDQTAeFw0xMTA0
# MTMxMDAwMDBaFw0yODAxMjgxMjAwMDBaMFIxCzAJBgNVBAYTAkJFMRkwFwYDVQQK
# ExBHbG9iYWxTaWduIG52LXNhMSgwJgYDVQQDEx9HbG9iYWxTaWduIFRpbWVzdGFt
# cGluZyBDQSAtIEcyMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAlO9l
# +LVXn6BTDTQG6wkft0cYasvwW+T/J6U00feJGr+esc0SQW5m1IGghYtkWkYvmaCN
# d7HivFzdItdqZ9C76Mp03otPDbBS5ZBb60cO8eefnAuQZT4XljBFcm05oRc2yrmg
# jBtPCBn2gTGtYRakYua0QJ7D/PuV9vu1LpWBmODvxevYAll4d/eq41JrUJEpxfz3
# zZNl0mBhIvIG+zLdFlH6Dv2KMPAXCae78wSuq5DnbN96qfTvxGInX2+ZbTh0qhGL
# 2t/HFEzphbLswn1KJo/nVrqm4M+SU4B09APsaLJgvIQgAIMboe60dAXBKY5i0Eex
# +vBTzBj5Ljv5cH60JQIDAQABo4HlMIHiMA4GA1UdDwEB/wQEAwIBBjASBgNVHRMB
# Af8ECDAGAQH/AgEAMB0GA1UdDgQWBBRG2D7/3OO+/4Pm9IWbsN1q1hSpwTBHBgNV
# HSAEQDA+MDwGBFUdIAAwNDAyBggrBgEFBQcCARYmaHR0cHM6Ly93d3cuZ2xvYmFs
# c2lnbi5jb20vcmVwb3NpdG9yeS8wMwYDVR0fBCwwKjAooCagJIYiaHR0cDovL2Ny
# bC5nbG9iYWxzaWduLm5ldC9yb290LmNybDAfBgNVHSMEGDAWgBRge2YaRQ2XyolQ
# L30EzTSo//z9SzANBgkqhkiG9w0BAQUFAAOCAQEATl5WkB5GtNlJMfO7FzkoG8IW
# 3f1B3AkFBJtvsqKa1pkuQJkAVbXqP6UgdtOGNNQXzFU6x4Lu76i6vNgGnxVQ380W
# e1I6AtcZGv2v8Hhc4EvFGN86JB7arLipWAQCBzDbsBJe/jG+8ARI9PBw+DpeVoPP
# PfsNvPTF7ZedudTbpSeE4zibi6c1hkQgpDttpGoLoYP9KOva7yj2zIhd+wo7AKvg
# IeviLzVsD440RZfroveZMzV+y5qKu0VN5z+fwtmK+mWybsd+Zf/okuEsMaL3sCc2
# SI8mbzvuTXYfecPlf5Y1vC0OzAGwjn//UYCAp5LUs0RGZIyHTxZjBzFLY7Df8zCC
# BJ8wggOHoAMCAQICEhEh1pmnZJc+8fhCfukZzFNBFDANBgkqhkiG9w0BAQUFADBS
# MQswCQYDVQQGEwJCRTEZMBcGA1UEChMQR2xvYmFsU2lnbiBudi1zYTEoMCYGA1UE
# AxMfR2xvYmFsU2lnbiBUaW1lc3RhbXBpbmcgQ0EgLSBHMjAeFw0xNjA1MjQwMDAw
# MDBaFw0yNzA2MjQwMDAwMDBaMGAxCzAJBgNVBAYTAlNHMR8wHQYDVQQKExZHTU8g
# R2xvYmFsU2lnbiBQdGUgTHRkMTAwLgYDVQQDEydHbG9iYWxTaWduIFRTQSBmb3Ig
# TVMgQXV0aGVudGljb2RlIC0gRzIwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEK
# AoIBAQCwF66i07YEMFYeWA+x7VWk1lTL2PZzOuxdXqsl/Tal+oTDYUDFRrVZUjtC
# oi5fE2IQqVvmc9aSJbF9I+MGs4c6DkPw1wCJU6IRMVIobl1AcjzyCXenSZKX1GyQ
# oHan/bjcs53yB2AsT1iYAGvTFVTg+t3/gCxfGKaY/9Sr7KFFWbIub2Jd4NkZrItX
# nKgmK9kXpRDSRwgacCwzi39ogCq1oV1r3Y0CAikDqnw3u7spTj1Tk7Om+o/SWJMV
# TLktq4CjoyX7r/cIZLB6RA9cENdfYTeqTmvT0lMlnYJz+iz5crCpGTkqUPqp0Dw6
# yuhb7/VfUfT5CtmXNd5qheYjBEKvAgMBAAGjggFfMIIBWzAOBgNVHQ8BAf8EBAMC
# B4AwTAYDVR0gBEUwQzBBBgkrBgEEAaAyAR4wNDAyBggrBgEFBQcCARYmaHR0cHM6
# Ly93d3cuZ2xvYmFsc2lnbi5jb20vcmVwb3NpdG9yeS8wCQYDVR0TBAIwADAWBgNV
# HSUBAf8EDDAKBggrBgEFBQcDCDBCBgNVHR8EOzA5MDegNaAzhjFodHRwOi8vY3Js
# Lmdsb2JhbHNpZ24uY29tL2dzL2dzdGltZXN0YW1waW5nZzIuY3JsMFQGCCsGAQUF
# BwEBBEgwRjBEBggrBgEFBQcwAoY4aHR0cDovL3NlY3VyZS5nbG9iYWxzaWduLmNv
# bS9jYWNlcnQvZ3N0aW1lc3RhbXBpbmdnMi5jcnQwHQYDVR0OBBYEFNSihEo4Whh/
# uk8wUL2d1XqH1gn3MB8GA1UdIwQYMBaAFEbYPv/c477/g+b0hZuw3WrWFKnBMA0G
# CSqGSIb3DQEBBQUAA4IBAQCPqRqRbQSmNyAOg5beI9Nrbh9u3WQ9aCEitfhHNmmO
# 4aVFxySiIrcpCcxUWq7GvM1jjrM9UEjltMyuzZKNniiLE0oRqr2j79OyNvy0oXK/
# bZdjeYxEvHAvfvO83YJTqxr26/ocl7y2N5ykHDC8q7wtRzbfkiAD6HHGWPZ1BZo0
# 8AtZWoJENKqA5C+E9kddlsm2ysqdt6a65FDT1De4uiAO0NOSKlvEWbuhbds8zkSd
# wTgqreONvc0JdxoQvmcKAjZkiLmzGybu555gxEaovGEzbM9OuZy5avCfN/61PU+a
# 003/3iCOTpem/Z8JvE3KGHbJsE2FUPKA0h0G9VgEB7EYMIIE0DCCA7igAwIBAgIB
# BzANBgkqhkiG9w0BAQsFADCBgzELMAkGA1UEBhMCVVMxEDAOBgNVBAgTB0FyaXpv
# bmExEzARBgNVBAcTClNjb3R0c2RhbGUxGjAYBgNVBAoTEUdvRGFkZHkuY29tLCBJ
# bmMuMTEwLwYDVQQDEyhHbyBEYWRkeSBSb290IENlcnRpZmljYXRlIEF1dGhvcml0
# eSAtIEcyMB4XDTExMDUwMzA3MDAwMFoXDTMxMDUwMzA3MDAwMFowgbQxCzAJBgNV
# BAYTAlVTMRAwDgYDVQQIEwdBcml6b25hMRMwEQYDVQQHEwpTY290dHNkYWxlMRow
# GAYDVQQKExFHb0RhZGR5LmNvbSwgSW5jLjEtMCsGA1UECxMkaHR0cDovL2NlcnRz
# LmdvZGFkZHkuY29tL3JlcG9zaXRvcnkvMTMwMQYDVQQDEypHbyBEYWRkeSBTZWN1
# cmUgQ2VydGlmaWNhdGUgQXV0aG9yaXR5IC0gRzIwggEiMA0GCSqGSIb3DQEBAQUA
# A4IBDwAwggEKAoIBAQC54MsQ1K92vdSTYuswZLiBCGzDBNliF44v/z5lz4/OYuY8
# UhzaFkVLVat4a2ODYpDOD2lsmcgaFItMzEUz6ojcnqOvK/6AYZ15V8TPLvQ/MDxd
# R/yaFrzDN5ZBUY4RS1T4KL7QjL7wMDge87Am+GZHY23ecSZHjzhHU9FGHbTj3ADq
# Ray9vHHZqm8A29vNMDp5T19MR/gd71vCxJ1gO7GyQ5HYpDNO6rPWJ0+tJYqlxvTV
# 0KaudAVkV4i1RFXULSo6Pvi4vekyCgKUZMQWOlDxSq7neTOvDCAHf+jfBDnCaQJs
# Y1L6d8EbyHSHyLmTGFBUNUtpTrw700kuH9zB0lL7AgMBAAGjggEaMIIBFjAPBgNV
# HRMBAf8EBTADAQH/MA4GA1UdDwEB/wQEAwIBBjAdBgNVHQ4EFgQUQMK9J47MNIMw
# ojPX+2yz8LQsgM4wHwYDVR0jBBgwFoAUOpqFBxBnKLbv9r0FQW4gwZTaD94wNAYI
# KwYBBQUHAQEEKDAmMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5nb2RhZGR5LmNv
# bS8wNQYDVR0fBC4wLDAqoCigJoYkaHR0cDovL2NybC5nb2RhZGR5LmNvbS9nZHJv
# b3QtZzIuY3JsMEYGA1UdIAQ/MD0wOwYEVR0gADAzMDEGCCsGAQUFBwIBFiVodHRw
# czovL2NlcnRzLmdvZGFkZHkuY29tL3JlcG9zaXRvcnkvMA0GCSqGSIb3DQEBCwUA
# A4IBAQAIfmyTEMg4uJapkEv/oV9PBO9sPpyIBslQj6Zz91cxG7685C/b+LrTW+C0
# 5+Z5Yg4MotdqY3MxtfWoSKQ7CC2iXZDXtHwlTxFWMMS2RJ17LJ3lXubvDGGqv+Qq
# G+6EnriDfcFDzkSnE3ANkR/0yBOtg2DZ2HKocyQetawiDsoXiWJYRBuriSUBAA/N
# xBti21G00w9RKpv0vHP8ds42pM3Z2Czqrpv1KrKQ0U11GIo/ikGQI31bS/6kA1ib
# RrLDYGCD+H1QQc7CoZDDu+8CL9IVVO5EFdkKrqeKM+2xLXY2JtwE65/3YR8V3Idv
# 7kaWKK2hJn0KCacuBKONvPi8BDABMIIFHTCCBAWgAwIBAgIJAKDBywSoyJDtMA0G
# CSqGSIb3DQEBCwUAMIG0MQswCQYDVQQGEwJVUzEQMA4GA1UECBMHQXJpem9uYTET
# MBEGA1UEBxMKU2NvdHRzZGFsZTEaMBgGA1UEChMRR29EYWRkeS5jb20sIEluYy4x
# LTArBgNVBAsTJGh0dHA6Ly9jZXJ0cy5nb2RhZGR5LmNvbS9yZXBvc2l0b3J5LzEz
# MDEGA1UEAxMqR28gRGFkZHkgU2VjdXJlIENlcnRpZmljYXRlIEF1dGhvcml0eSAt
# IEcyMB4XDTE4MDMwODE4NTgwMFoXDTE5MDMwODE4NTgwMFowXjELMAkGA1UEBhMC
# Q0ExEDAOBgNVBAgTB09udGFyaW8xDzANBgNVBAcTBk90dGF3YTEVMBMGA1UEChMM
# Q0FOQVJJRSBJbmMuMRUwEwYDVQQDEwxDQU5BUklFIEluYy4wggEiMA0GCSqGSIb3
# DQEBAQUAA4IBDwAwggEKAoIBAQDZhfCjFqiTmN1uLoySixnwaOjf/ZAL9P6SvjlC
# aBA2mutoorEgnzUP8HnOIcvMRgEMPmpaZ8egM93Bmx9d41xoarsQpCN3DhYOo+b3
# fWnPucVtpxbul2OFePv63mw/uvr+dqkv4b/f3Tg+ilQbpsNonbvh9MKEFv8Pn9ko
# j0ySV+qxz34PxTVAe6g//pel3/3i9fqilCnIEcx4zg/+NKBeOWROSs4oXo3IvBjV
# runmz+YuieSr78TqIE6hD8JF2q1wKwfMB3+x7dEXZAus9WtIU/qITATtEfO9QAgr
# rYL4F1MLN+osSp8my5eCOjnLTQc47q574V3zQhsIHW7yBXLdAgMBAAGjggGFMIIB
# gTAMBgNVHRMBAf8EAjAAMBMGA1UdJQQMMAoGCCsGAQUFBwMDMA4GA1UdDwEB/wQE
# AwIHgDA1BgNVHR8ELjAsMCqgKKAmhiRodHRwOi8vY3JsLmdvZGFkZHkuY29tL2dk
# aWcyczUtMy5jcmwwXQYDVR0gBFYwVDBIBgtghkgBhv1tAQcXAjA5MDcGCCsGAQUF
# BwIBFitodHRwOi8vY2VydGlmaWNhdGVzLmdvZGFkZHkuY29tL3JlcG9zaXRvcnkv
# MAgGBmeBDAEEATB2BggrBgEFBQcBAQRqMGgwJAYIKwYBBQUHMAGGGGh0dHA6Ly9v
# Y3NwLmdvZGFkZHkuY29tLzBABggrBgEFBQcwAoY0aHR0cDovL2NlcnRpZmljYXRl
# cy5nb2RhZGR5LmNvbS9yZXBvc2l0b3J5L2dkaWcyLmNydDAfBgNVHSMEGDAWgBRA
# wr0njsw0gzCiM9f7bLPwtCyAzjAdBgNVHQ4EFgQUUPnMg2nmYS8l7rmax3weVkrg
# z5AwDQYJKoZIhvcNAQELBQADggEBAC6a/aY8FBEZHuMG91JyZLxC+XeK2oxf6xkl
# JGjGZeKxSkQkT7XQBVmKirthDKXpMYlCpv7IwW/aFhWwZVHhXCN9v+TwgQWl3wX3
# 1Ao6T78GuTn18sm0iojqgtSZtJT/gUlkgctigluKVazC/QRT/AvwnBA9AyjNFZot
# yyofIT6be3Hjan6l+kmEcuQENNUQballqWKc1cI8Lig26QoT6Ht0+7x6kgRLeRey
# Idu0eSCKkGiO9H2R4KZSWB9MTg5WoYPzVRlV/WpV5XA9QhiHxn+nuQGFXO+l82qw
# ZhFCAnZGQzqQTWtmXjIFKW7RoeSYK9YdomGixR54prjFrQGq1T0xggUKMIIFBgIB
# ATCBwjCBtDELMAkGA1UEBhMCVVMxEDAOBgNVBAgTB0FyaXpvbmExEzARBgNVBAcT
# ClNjb3R0c2RhbGUxGjAYBgNVBAoTEUdvRGFkZHkuY29tLCBJbmMuMS0wKwYDVQQL
# EyRodHRwOi8vY2VydHMuZ29kYWRkeS5jb20vcmVwb3NpdG9yeS8xMzAxBgNVBAMT
# KkdvIERhZGR5IFNlY3VyZSBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkgLSBHMgIJAKDB
# ywSoyJDtMAkGBSsOAwIaBQCgeDAYBgorBgEEAYI3AgEMMQowCKACgAChAoAAMBkG
# CSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEE
# AYI3AgEVMCMGCSqGSIb3DQEJBDEWBBTaUE75V88pho2Nbo4H7uchQZ5Z3DANBgkq
# hkiG9w0BAQEFAASCAQDUuguspjOuwvdlqLI91+aBahYZeN+DeLLwhHLZTt944fPa
# T1B+1IjJKKcLOvMgb3RVmr50pEZJoKbcV7nqmzfmiQnzax+XSZI7ZZF75aagr4nQ
# 6iupbJn/N8khb3HvYddK83QTVXnJVWyseAp2tDnLHZZUvDmeWFPBN236UoTYLtPK
# /b36R8kgZphfBezxSisrYc+3nUw8nhnJ58+y9filXDXKpuMPXpeZzFLM56FQlxJE
# xg5aZNb9jXLHdG1a4okIgly8xbRXK8P7ayB8KaHZ3snYdyEwbvhv7yld6rlRNzmv
# IDM10j/XssZDwg0Xb3VR44PV+w7g+NHZr2be7xO1oYICojCCAp4GCSqGSIb3DQEJ
# BjGCAo8wggKLAgEBMGgwUjELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNp
# Z24gbnYtc2ExKDAmBgNVBAMTH0dsb2JhbFNpZ24gVGltZXN0YW1waW5nIENBIC0g
# RzICEhEh1pmnZJc+8fhCfukZzFNBFDAJBgUrDgMCGgUAoIH9MBgGCSqGSIb3DQEJ
# AzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTE4MDQxODE2NDkxM1owIwYJ
# KoZIhvcNAQkEMRYEFG53IktkZHc0uje9BJOVRmZR4nZoMIGdBgsqhkiG9w0BCRAC
# DDGBjTCBijCBhzCBhAQUY7gvq2H1g5CWlQULACScUCkz7HkwbDBWpFQwUjELMAkG
# A1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExKDAmBgNVBAMTH0ds
# b2JhbFNpZ24gVGltZXN0YW1waW5nIENBIC0gRzICEhEh1pmnZJc+8fhCfukZzFNB
# FDANBgkqhkiG9w0BAQEFAASCAQColvTgeIEfz0kVlX0y2SyAj/AdMLlmrldmOGaA
# 7X77qTUNX3FBrJo8jVxLWYMtrcCHp4lGRCrcmVvaTybEduRB4zWy9rFxOorHQfUH
# jxUHrwibsw8ScwVj91Uv+LCcPvUJkEPnSZurzgIdf4mF7DHmkHxSlpNWntF4MYq0
# yRlvXK2to/cB16+avRxiRkfPGdjEwOcOM5usxssNn2yoSZ1BboaH8xCCNWX2vPav
# 78Lyqu/r7DCJc8g7XDBIDjLQwN4wUbdHDd6s6NeVjzBN/jeO42V4dwD1rQbyzyQs
# 5W4obGlhGYYhhQJaIGvd5hGXE8StGZgKJ57IVtjPiAqre9IE
# SIG # End signature block
