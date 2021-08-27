#Requires -Version 5.1
#Requires -RunAsAdministrator

function Import-ADFSTkMetadata 
{

    [CmdletBinding(DefaultParameterSetName='AllSPs',
                    SupportsShouldProcess=$true)]
    param (
        [Parameter(ParameterSetName='SingleSP',
            Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            Position=0)]
        $EntityId,
        [Parameter(ParameterSetName='SingleSP',
            Mandatory=$false,
            ValueFromPipelineByPropertyName=$true,
            Position=1)]
        $EntityBase,
        [string]$ConfigFile,
        [string]$LocalMetadataFile,
        [string[]]$ForcedEntityCategories,
        [Parameter(ParameterSetName='AllSPs')]
        [switch]
        $ProcessWholeMetadata,
        [switch]$ForceUpdate,
        [Parameter(ParameterSetName='AllSPs')]
        [switch]
        $AddRemoveOnly,
        #The time in minutes the chached metadatafile live
        [int]
        $CacheTime = 60,
        #The maximum SPs to add in one run (to prevent throttling). Is used when the script recusrive calls itself
        [int]
        $MaxSPAdditions = 80
    )


    process 
    {


    try {


    # Add some variables
    $md5 = new-object -TypeName System.Security.Cryptography.MD5CryptoServiceProvider
    $utf8 = new-object -TypeName System.Text.UTF8Encoding

    # load configuration file
    if (!(Test-Path ( $ConfigFile )))
    {
   
        Write-Error -message "Msg: Path:$mypath configFile: $ConfigFile" 
        throw "throwing. Path:$mypath configfile:$ConfigFile" 
    }
    else
    {
        [xml]$Settings=Get-Content ($ConfigFile)
    }


    # set appropriate logging via EventLog mechanisms
    $logOk = $false

    if (Verify-ADFSTkEventLogUsage)
    {
        #If we evaluated as true, the eventlog is now set up and we link the WriteADFSTklog to it
        Write-ADFSTkLog   -SetEventLogName $Settings.configuration.logging.LogName -SetEventLogSource $Settings.configuration.logging.Source
        $logOK = $true

    }

    $logFileName = $Settings.configuration.logging.LogFileName
    if ($logFileName) {
        $logFileFullName = Join-Path $Settings.configuration.WorkingPath -ChildPath $logFileName
        Write-ADFSTkLog -SetLogFilePath $logFileFullName
        $logOk = $true
    }

    if (!$logOk) {

        # No Event logging is enabled
        Throw "Missing eventlog settings in config!"   
    
    }
    
    #region Get static values from configuration file
    $mypath= $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath('.\')

    $myVersion=(get-module ADFSToolkit-IDEM).version.ToString()

    Write-ADFSTkVerboseLog "Import-ADFSTkMetadata $myVersion started" -EntryType Information
    Write-ADFSTkLog "Import-ADFSTkMetadata started on $ConfigFile"

    #endregion


    #region Get SP Hash
    if ([string]::IsNullOrEmpty($Settings.configuration.SPHashFile))
    {
        Write-Error -message "Halting: Missing SPHashFile setting from  $ConfigFile" 
        throw "SPHashFile missing from configfile"
    }
    else
    {
        $SPHashFile = Join-Path $Settings.configuration.WorkingPath -ChildPath $Settings.configuration.CacheDir | Join-Path -ChildPath $Settings.configuration.SPHashFile
        Write-ADFSTkVerboseLog "Setting SPHashFile to: $SPHashFile"
    }

    if (Test-Path $SPHashFile)
    {
        try 
        {
            $SPHashList = Import-Clixml $SPHashFile
        }
        catch
        {
            Write-ADFSTkVerboseLog "Could not import SP Hash File!"
            $SPHashFileItem  = Get-ChildItem $SPHashFile
            Rename-Item -Path $SPHashFile -NewName ("{0}_{1}.{2}" -f $SPHashFileItem.BaseName, ([guid]::NewGuid()).Guid, $SPHashFileItem.Extension)
            $SPHashList = @{}
        }
    }
    else
    {
        $SPHashList = @{}
    }

    #endregion
    
    #region Get SP Hash To Exclude
    $SPHashListToExclude = @{}

    if ($Settings.configuration.SPHashFileToExclude) {
        $SPHashFileToExclude = Join-Path $Settings.configuration.WorkingPath -ChildPath $Settings.configuration.CacheDir | Join-Path -ChildPath $Settings.configuration.SPHashFileToExclude
        Write-ADFSTkVerboseLog "Setting SPHashFileToExclude to: $SPHashFileToExclude"
        if (Test-Path $SPHashFileToExclude) {
            try 
            {
                $SPHashListToExclude = Import-Clixml $SPHashFileToExclude
            }
            catch
            {
                Write-ADFSTkVerboseLog "Could not import SP Hash File To Exclude!"
                $SPHashFileToExcludeItem  = Get-ChildItem $SPHashFileToExclude
                Rename-Item -Path $SPHashFileToExclude -NewName ("{0}_{1}.{2}" -f $SPHashFileToExcludeItem.BaseName, ([guid]::NewGuid()).Guid, $SPHashFileToExcludeItem.Extension)
            }
        }
        else {
            Write-ADFSTkVerboseLog "SPHashFileToExclude Not Found: ignoring..."
        }
    }

    #endregion

    #region Getting Metadata

    #Cached Metadata file
    $CachedMetadataFile = Join-Path $Settings.configuration.WorkingPath -ChildPath $Settings.configuration.CacheDir | Join-Path -ChildPath $Settings.configuration.MetadataCacheFile
    #Join-Path $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath('.\cache\') SwamidMetadata.cache.xml
    Write-ADFSTkVerboseLog "Setting CachedMetadataFile to: $CachedMetadataFile"


    if ($LocalMetadataFile)
    {
        try
        {
            $MetadataXML = new-object Xml.XmlDocument
            $MetadataXML.PreserveWhitespace = $true
            $MetadataXML.Load($LocalMetadataFile)
            Write-ADFSTkVerboseLog "Successfully loaded local MetadataFile..." -EntryType Information
        }
        catch
        {
            Write-ADFSTkLog "Could not load LocalMetadataFile!" -MajorFault
        }
    }

    if ($MetadataXML -eq $null)
    {
        $UseCachedMetadata = $false
        if (($CacheTime -eq -1 -or $CacheTime -gt 0) -and (Test-Path $CachedMetadataFile)) #CacheTime = -1 allways use cached metadata if exists
        {
            if ($CacheTime -eq -1 -or (Get-ChildItem $CachedMetadataFile).LastWriteTime.AddMinutes($CacheTime) -ge (Get-Date))
            {
                $UseCachedMetadata =  $true
                try 
                {
                    #[xml]$MetadataXML = Get-Content $CachedMetadataFile
                    $MetadataXML = new-object Xml.XmlDocument
                    $MetadataXML.PreserveWhitespace = $true
                    $MetadataXML.Load($CachedMetadataFile)
                    
                    if ([string]::IsNullOrEmpty($MetadataXML))
                    {
                        Write-ADFSTkLog "Cached Metadata file was empty. Downloading instead!" -EntryType Error
                        $UseCachedMetadata =  $false
                    }
                }
                catch
                {
                    Write-ADFSTkLog "Could not parse cached Metadata file. Downloading instead!" -EntryType Error
                    $UseCachedMetadata =  $false
                }
            }
            else
            {
                $UseCachedMetadata = $false
                Remove-Item $CachedMetadataFile -Confirm:$false
            }
        }

        if (!$UseCachedMetadata)
        {
            
            #Get Metadata URL from config
            if ([string]::IsNullOrEmpty($Settings.configuration.metadataURL))
            {
                $metadataURL = 'https://localhost/metadata.xml' #Just for fallback
            }
            else
            {
                $metadataURL = $Settings.configuration.metadataURL
            }

            Write-ADFSTkVerboseLog "Downloading Metadata from $metadataURL " -EntryType Information
            
            try
            {
                Write-ADFSTkVerboseLog "Downloading From: $metadataURL to file $CachedMetadataFile" -EntryType Information
               
                #$Metadata = Invoke-WebRequest $metadataURL -OutFile $CachedMetadataFile -PassThru
                $myUserAgent = "ADFSToolkit-IDEM/"+(get-module ADFSToolkit-IDEM).Version.toString()
 
                $webClient = New-Object System.Net.WebClient 
                $webClient.Headers.Add("user-agent", "$myUserAgent")
                $webClient.DownloadFile($metadataURL, $CachedMetadataFile) 
                
                Write-ADFSTkVerboseLog "Successfully downloaded Metadata from $metadataURL" -EntryType Information
            }
            catch
            {
                Write-ADFSTkLog "Could not download Metadata from $metadataURL" -MajorFault
            }
        
            try
            {
                Write-ADFSTkVerboseLog "Parsing downloaded Metadata XML..." -EntryType Information
                $MetadataXML = new-object Xml.XmlDocument
                $MetadataXML.PreserveWhitespace = $true
                $MetadataXML.Load($CachedMetadataFile)            
                #$MetadataXML = [xml]$Metadata.Content
                Write-ADFSTkVerboseLog "Successfully parsed downloaded Metadata from $metadataURL" -EntryType Information
            }
            catch
            {
                Write-ADFSTkLog "Could not parse downloaded Metadata from $metadataURL" -MajorFault
            }
        }
    }

    # Assert that the metadata we are about to process is not zero bytes after all this


    if (Test-Path $CachedMetadataFile) {

        $MyFileSize=(Get-Item $CachedMetadataFile).length 
        if ((Get-Item $CachedMetadataFile).length -gt 0kb) {
            Write-ADFSTkVerboseLog "Metadata file size is $MyFileSize"
        } else {
            Write-ADFSTkLog "Note: $CachedMetadataFile  is 0 bytes" 
        }
    }
    #endregion

    #region Verify Sign
    
    #Verify Metadata Signing Cert

    if ($Settings.configuration.bypassSignVerify -ne $null -and $Settings.configuration.bypassSignVerify -eq 'true' ) {
        Write-ADFSTkLog "Metadata signature verify skipped in configuration!!"
    }
    else {
        Write-ADFSTkVerboseLog "Verifying metadata signing cert..." -EntryType Information
  
        Write-ADFSTkVerboseLog "Ensuring SHA256 Signature validation is present..." -EntryType Information
        Update-SHA256AlgXmlDSigSupport


        if (Verify-ADFSTkSigningCert $MetadataXML.EntitiesDescriptor.Signature.KeyInfo.X509Data.X509Certificate)
        {
            Write-ADFSTkVerboseLog "Successfully verified metadata signing cert!" -EntryType Information
        }
        else
        {
            Write-ADFSTkLog "Metadata signing cert is incorrect! Please check metadata URL or signature fingerprint in config." -MajorFault
        }

        #Verify Metadata Signature
        Write-ADFSTkVerboseLog "Verifying metadata signature..." -EntryType Information
        if (Verify-ADFSTkMetadataSignature $MetadataXML)
        {
            Write-ADFSTkVerboseLog "Successfully verified metadata signature!" -EntryType Information
        }
        else
        {
            Write-ADFSTkLog "Metadata signature test did not pass. Aborting!" -MajorFault
        }
    }
    #endregion




    #region Read/Create file with 


    $RawAllSPs = $MetadataXML.EntitiesDescriptor.EntityDescriptor | ? {$_.SPSSODescriptor -ne $null}
    $myRawAllSPsCount= $RawALLSps.count
    Write-ADFSTkVerboseLog "Total number of Sps observed: $myRawAllSPsCount"


    if ($ProcessWholeMetadata)
    {
        Write-ADFSTkVerboseLog "Processing whole Metadata file..." -EntryType Information
   
        $AllSPs = $MetadataXML.EntitiesDescriptor.EntityDescriptor | ? {$_.SPSSODescriptor -ne $null}
#        $AllSPs = $MetadataXML.EntitiesDescriptor.EntityDescriptor | ? {$_.SPSSODescriptor -ne $null -and $_.Extensions -ne $null}

        $myAllSPsCount= $ALLSPs.count
        Write-ADFSTkLog "Total number of Sps observed: $myAllSPsCount"

        Write-ADFSTkVerboseLog "Calculating changes..."
        $AllSPs | % {
            $SwamidSPs = @()
            $SwamidSPsToProcess = @()
        }{
            Write-ADFSTkVerboseLog "Working with `'$($_.EntityID)`'..."

            if (Check-ADFSTkSPToInclude $_.EntityID) {
                $SwamidSPs += $_.EntityId
                if (Check-ADFSTkSPHasChanged $_)
                {
                    $SwamidSPsToProcess += $_
                }
                #else
                #{
                #    Write-ADFSTkVerboseLog "Skipped due to no changes in metadata..."
                #}
            }
            #else {
            #    Write-ADFSTkVerboseLog "$($_.EntityID) Excluded (or not included) via configuration!"
            #}

        }{
            Write-ADFSTkVerboseLog "Done!"
            $n = $SwamidSPsToProcess.Count
            Write-ADFSTkLog "Found $n new/changed SPs."
            $batches = [Math]::Ceiling($n/$MaxSPAdditions)
            Write-ADFSTkVerboseLog "Batches count: $batches"

            if ($n -gt 0)
            {
                if ($batches -gt 1)
                {
                    for ($i = 1; $i -le $batches; $i++)
                    {
                        #$ADFSTkModuleBase= Join-Path (get-module ADFSToolkit-IDEM).ModuleBase ADFSToolkit-IDEM.psm1
                        #Write-ADFSTkLog "Working with batch $($i)/$batches with $ADFSTkModuleBase"
                        Write-ADFSTkLog "Running batch $($i)/$batches ..."
                        $string = "-Command & {Get-Module -ListAvailable ADFSToolkit-IDEM |Import-Module ; Import-ADFSTkMetadata -MaxSPAdditions $MaxSPAdditions -CacheTime -1 "
                        if ($ForceUpdate) { $string += "-ForceUpdate " }
                        if ($AddRemoveOnly) { $string += "-AddRemoveOnly " }
                        if ($VerbosePreference -eq 'Continue') {$string += "-Verbose "}
                        $string += "-ConfigFile '$ConfigFile' ;Exit}"
                        Start-Process -WorkingDirectory $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath('.\') -FilePath "$env:SystemRoot\system32\WindowsPowerShell\v1.0\powershell.exe" -ArgumentList "-NoExit", $string -Wait -NoNewWindow
                        Write-ADFSTkVerboseLog "Done!"
                    }
                }
                else
                {
                    $SwamidSPsToProcess | % {
                        Processes-ADFSTkRelyingPartyTrust $_
                    }
                }
            }

            # Checking if any Relying Party Trusts show be removed
       
            $NamePrefix = $Settings.configuration.MetadataPrefix 
            $Sep= $Settings.configuration.MetadataPrefixSeparator      
            $FilterString="$NamePrefix$Sep"

            Write-ADFSTkVerboseLog "Checking for Relying Parties removed from Metadata using Filter:$FilterString* ..." 

            $CurrentSwamidSPs = Get-ADFSRelyingPartyTrust | ? {$_.Name -like "$FilterString*"} | select -ExpandProperty Identifier
            if ($CurrentSwamidSPs -eq $null)
            {
                $CurrentSwamidSPs = @()
            }

            #$RemoveSPs = Compare-ADFSTkObject $CurrentSwamidSPs $SwamidSPs | ? SideIndicator -eq "<=" | select -ExpandProperty InputObject
            $CompareSets = Compare-ADFSTkObject -FirstSet $CurrentSwamidSPs -SecondSet $SwamidSPs -CompareType InFirstSetOnly

            Write-ADFSTkLog "Found $($CompareSets.MembersInCompareSet) RPs that should be removed."


## Tolta l'interazione: un SP eliminato dal Metadata viene sempre rimosso !!
#            if ($ForceUpdate)
#            {
                foreach ($rp in $CompareSets.CompareSet)
                {
                    Write-ADFSTkVerboseLog "Removing `'$($rp)`'..."
                    try 
                    {
                        Remove-ADFSRelyingPartyTrust -TargetIdentifier $rp -Confirm:$false -ErrorAction Stop
                        Remove-ADFStkEntityHash $rp
                        Write-ADFSTkLog "Successfully removed `'$($rp)`'!" -EntryType Information
                    }
                    catch
                    {
                        Write-ADFSTkLog "Could not remove `'$($rp)`'! Error: $_" -EntryType Error
                    }
                }
#            }
#            else
#            {
#                # $RemoveSPs | Get-ADFSTkAnswer -Caption "Do you want to remove Relying Party trust that are not in Swamid metadata?" | Remove-ADFSRelyingPartyTrust -Confirm:$false 
#                foreach ($rp in ($CompareSets.CompareSet | Get-ADFSTkAnswer -Caption "Do you want to remove Relying Party trust that are not in Swamid metadata?"))
#                {
#                    Write-ADFSTkVerboseLog "Removing `'$($rp)`'..."
#                    try 
#                    {
#                        Remove-ADFSRelyingPartyTrust -TargetIdentifier $rp -Confirm:$false -ErrorAction Stop
#                        Write-ADFSTkVerboseLog "Done!"
#                    }
#                    catch
#                    {
#                        Write-ADFSTkLog "Could not remove `'$($rp)`'! Error: $_" -EntryType Error
#                    }
#                }
#            }
        }
    }
    elseif($PSBoundParameters.ContainsKey('MaxSPAdditions') -and $MaxSPAdditions -gt 0)
    {
        Write-ADFSTkLog "Processing $MaxSPAdditions SPs..." -EntryType Information
       
        $AllSPsInMetadata = $MetadataXML.EntitiesDescriptor.EntityDescriptor | ? {$_.SPSSODescriptor -ne $null }
#        $AllSPsInMetadata = $MetadataXML.EntitiesDescriptor.EntityDescriptor | ? {$_.SPSSODescriptor -ne $null -and $_.Extensions -ne $null}

        $i = 0
        $n = 0
        $m = $AllSPsInMetadata.Count - 1
        $SPsToProcess = @()
        do
        {
            if ( (Check-ADFSTkSPToInclude $AllSPsInMetadata[$i].EntityID) -and (Check-ADFSTkSPHasChanged $AllSPsInMetadata[$i])) {
                $SPsToProcess += $AllSPsInMetadata[$i]
                $n++
            }
            #else
            #{
            #    Write-ADFSTkVerboseLog "Skipped due to no changes in metadata..."
            #}
            $i++
        }
        until ($n -ge $MaxSPAdditions -or $i -ge $m)

        $SPsToProcess | % {
            Processes-ADFSTkRelyingPartyTrust $_
        }
    }
    elseif(! ([string]::IsNullOrEmpty($EntityID) ) )
    {
    #Enter so that SP: N is checked against the can and ask if you want to force update. Insert the hash!

        Write-ADFSTkVerboseLog "Working with `'$EntityID`'..."
        if ([string]::IsNullOrEmpty($EntityBase)) {
            $sp = $MetadataXML.EntitiesDescriptor.EntityDescriptor | ? {$_.entityId -eq $EntityId}
        }
        else {
            $sp = $MetadataXML.EntitiesDescriptor.EntityDescriptor | ? {$_.entityId -eq $EntityId -and $_.base -eq $EntityBase}
        }

        if ($sp.count -gt 1) {
            $tmpSP = $null
            $sp | % {
                if (![string]::IsNullOrEmpty($_.Extensions.RegistrationInfo))
                {
                    $tmpSP = $_
                }
            }

            if ($tmpSP -ne $null)
            {
                $sp = $tmpSP
            }
            else
            {
                $sp = $sp[0]
            }
        }

        if ([string]::IsNullOrEmpty($sp)){
            Write-ADFSTkLog "No SP found!" -MajorFault
        }
        else {
            Processes-ADFSTkRelyingPartyTrust $sp
        }
    }
    else {
        Write-ADFSTkVerboseLog "Invoked without -ProcessWholeMetadata <no args> , -EntityID <with quoted URL>, nothing to do, exiting"
    }

    Write-ADFSTkVerboseLog "Script ended!"

    }
        Catch
        {
            Throw $_
        }
    }
}
# SIG # Begin signature block
# MIIYUAYJKoZIhvcNAQcCoIIYQTCCGD0CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUu+rk02Hvn6OWALFh44J95Ced
# 12CgghKwMIIEFDCCAvygAwIBAgILBAAAAAABL07hUtcwDQYJKoZIhvcNAQEFBQAw
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
# AYI3AgEVMCMGCSqGSIb3DQEJBDEWBBR6CO+1ZDwiOX5X2aMB1gVTKRyBvzANBgkq
# hkiG9w0BAQEFAASCAQCxhn7rIpVHy05zCGqMDFvW8uGrdaFF0srRfO76fC4a3Ihk
# GgvnXzXZmgYtHU3EAztrfBjYBRoQomaFEiTgcqa9W3Rp6umAhii6qGV3zQgznhKP
# Y6lQAE+Hn2r+Jyi4P17HnLwuc7BgtA9f4x3VKcnzx4a7lnxTLeIcrI/sbK5HKwVe
# AfclWnXo4BepYISm7CQYJM4QOweXQKvS4XrqNjhUO8DSlaiL+ZMi6YCypNxG9d0n
# uKLJrJcpIvMzw7zU7Rdo4+0XQq78Kioj1C60f7pI9TsBjXaA09dJqYjZRuuO28cY
# eYjI7z5Xfc3V5vU1UK+bgMfipya/P9QJW6JbgGwIoYICojCCAp4GCSqGSIb3DQEJ
# BjGCAo8wggKLAgEBMGgwUjELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNp
# Z24gbnYtc2ExKDAmBgNVBAMTH0dsb2JhbFNpZ24gVGltZXN0YW1waW5nIENBIC0g
# RzICEhEh1pmnZJc+8fhCfukZzFNBFDAJBgUrDgMCGgUAoIH9MBgGCSqGSIb3DQEJ
# AzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTE4MDQxODE2NDkxMlowIwYJ
# KoZIhvcNAQkEMRYEFCfnliwLFiVICKtSOed8T3iDkpReMIGdBgsqhkiG9w0BCRAC
# DDGBjTCBijCBhzCBhAQUY7gvq2H1g5CWlQULACScUCkz7HkwbDBWpFQwUjELMAkG
# A1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExKDAmBgNVBAMTH0ds
# b2JhbFNpZ24gVGltZXN0YW1waW5nIENBIC0gRzICEhEh1pmnZJc+8fhCfukZzFNB
# FDANBgkqhkiG9w0BAQEFAASCAQA5Wui/70x9IosUJDVGjZTckz4eDnjTORSIKYVx
# Wchi/VSRWBQ2+nMtbUgbG0GbDtRwxoLgMkDUXAfcDMitHKg4Dfhz0goHbqD8M/rH
# UdDrKI5o6OL1HHimg5hEH6/UL4CmhlKIOo8v1CXF1EWg+HGyn3Zx3tTQeeJ2sUOT
# 1+fORLay8n2Fmt0y1bJLdDOIunBkUziD0eFQCD+ZG3j0VYB45mgJjK8dMOs7MNdx
# wRqNnCm7fJbG9Uh03lN+hNDvhmU5wNXgLvXt4UzI5gTKoIfo4VvDhRi7axL9x0RP
# NllOHRcUd2JMcm0kwcWXgZi1brnEfCJClZ1jjjYKW3AU2nRt
# SIG # End signature block
