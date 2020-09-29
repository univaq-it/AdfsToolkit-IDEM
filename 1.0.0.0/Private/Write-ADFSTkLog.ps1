
function Write-ADFSTkLog {
[CmdletBinding(DefaultParametersetName="Default")]
param (        
    [Parameter(Mandatory=$false,
                ParameterSetName="Set",
                ValueFromPipelineByPropertyName=$false)]
    [string]
    #The path to the logfile. This needs to be set once in the script. The path will be stored in a global variable 'LogFilePath'
    $SetLogFilePath,
    [Parameter(Mandatory=$false,
                ParameterSetName="Set",
                ValueFromPipelineByPropertyName=$false)]
    [string]
    #The name of the eventlog. This needs to be set once in the script. The name will be stored in a global variable 'EventLogName'
    $SetEventLogName,
    [Parameter(Mandatory=$false,
                ParameterSetName="Set",
                ValueFromPipelineByPropertyName=$false)]
    [string]
    <#The Source that will be used in the eventlog.
    
    Use New-EventLog -LogName <EventLogName> -Source <NewSource> to add a new source to a eventlog.
    
    This needs to be set once in the script. The name will be stored in a global variable 'EventLogSource'#>
    $SetEventLogSource,
    [Parameter(Mandatory=$false,
                ParameterSetName="Get",
                ValueFromPipelineByPropertyName=$false)]
    [switch]
    #Returns the path to the LogFile.
    $GetLogFilePath,
    [Parameter(Mandatory=$false,
                ParameterSetName="Get",
                ValueFromPipelineByPropertyName=$false)]
    [switch]
    #Returns the name of the EventLog that will be used.
    $GetEventLogName,
    [Parameter(Mandatory=$false,
                ParameterSetName="Get",
                ValueFromPipelineByPropertyName=$false)]
    [switch]
    #Returns the Source of the EventLog that will be used.
    $GetEventLogSource,
    
    [Parameter(Mandatory=$false,
                ParameterSetName="Default",
                ValueFromPipelineByPropertyName=$true,
                Position=0)]
    [ValidateNotNullOrEmpty()]
    [string]
    #The message to be written in the log...
    $Message,
    
    [Parameter(Mandatory=$false,
                ParameterSetName="Default",
                ValueFromPipelineByPropertyName=$true)]
    [int]
    #The EventID if EventLog is used
    $EventID,
    [Parameter(Mandatory=$false,
                ParameterSetName="Default",
                ValueFromPipelineByPropertyName=$true)]
    [string]
    #Used in LogFile and on Screen to clarify the message. In EventLog the Level on the event is set to EntryType. Default is Information
    [ValidateSet("Information", "Error", "Warning")]
    $EntryType="Information",
    [Parameter(Mandatory=$false,
                ParameterSetName="Default",
                ValueFromPipelineByPropertyName=$true)]
    [switch]
    #If used the EntryType will be set as "Error" the message will be thown as an error. 
    $MajorFault,
    [Parameter(Mandatory=$false,
                ParameterSetName="Default",
                ValueFromPipelineByPropertyName=$true)]
    [int]
    #Only for EventLog. Task Category on the event is set to Category. If -Verbose is used, Category will be set to 4
    $Category=1,
    [Parameter(Mandatory=$false,
                ParameterSetName="Default",
                ValueFromPipelineByPropertyName=$false)]
    [switch]
    #Used in LogFile and on Screen make the message underlined
    $Underline,
    [Parameter(Mandatory=$false,
                ParameterSetName="Default",
                ValueFromPipelineByPropertyName=$false)]
    [char]
    #The char used to make the underline (see parameter Underline). Default is '-'
    $UnderlineChar='-',
    [Parameter(Mandatory=$false,
                ParameterSetName="Default",
                ValueFromPipelineByPropertyName=$true)]
    [switch]
    #Use this to get output on the screen
    $Screen,
    [Parameter(Mandatory=$false,
                ParameterSetName="Default",
                ValueFromPipelineByPropertyName=$true)]
    [switch]
    #Use this to log to file
    $File,
    [Parameter(Mandatory=$false,
                ParameterSetName="Default",
                ValueFromPipelineByPropertyName=$true)]
    [switch]
    #Use this to log to EventLog
    $EventLog,
    [Parameter(Mandatory=$false,
                ParameterSetName="Default",
                ValueFromPipelineByPropertyName=$true)]
    [switch]
    #Doesn't write Date and Time in the beginning of the row
    $SkipDateTime,
    [Parameter(Mandatory=$false,
                ParameterSetName="Default",
                ValueFromPipelineByPropertyName=$true)]
    [ConsoleColor]
    #Sets the color the screen-text should be written in
    $ForegroundColor = [ConsoleColor]::Gray
)
       
Begin {
    
    if ($PsCmdlet.ParameterSetName -eq "Set")
    {
        if ($SetLogFilePath -ne [string]::Empty) 
        {
            $FilePath = $SetLogFilePath.SubString(0,$SetLogFilePath.LastIndexOf('\'))
            if (! (Test-Path ($FilePath)))
            {
                Write-Warning "The path `'$FilePath`' doesn't exist! Please create it and try again..."
            }
            else
            {
                Write-Verbose "Setting LogFilePath to `'$SetLogFilePath`'..."
                $global:LogFilePath = $SetLogFilePath                    
            }
        }
        
        if ($SetEventLogName -ne [string]::Empty)
        {
            try
            {
                $TestEventLog = Get-EventLog $SetEventLogName -Newest 1
                
                Write-Verbose "Setting EventLogName to `'$SetEventLogName`'..."
                $global:EventLogName = $SetEventLogName 
            }
            catch
            {
                Write-Warning "The EventLogName provided does not exist! Please try again with another namne..."
            }
        }
        
        if ($SetEventLogSource -ne [string]::Empty)
        { 
            Write-Verbose "Setting EventLogSource to `'$SetEventLogSource`'..."
            $global:EventLogSource = $SetEventLogSource
        }
    }
    elseif ($PsCmdlet.ParameterSetName -eq "Get")
    {
        if ($GetLogFilePath) { Write-Host "LogFilePath: `'$LogFilePath`'" }
        if ($GetEventLogName) { Write-Host "EventLogName: `'$EventLogName`'" }
        if ($GetEventLogSource) { Write-Host "EventLogSource: `'$EventLogSource`'" }
    }
}
Process {
    ### Write main script below ###
    if ($PsCmdlet.ParameterSetName -eq "Default")
    {
        if ($MajorFault) { $EntryType = "Error" }
        if ($verbosePreference -eq "Continue") { $Category = 4 }
        
        $CurrentTime = (Get-Date).ToString()
        
        if (!$Screen.IsPresent -and !$File.IsPresent -and !$EventLog.IsPresent)
        {
            $Screen = $true

            if ($EventLogName -ne $null -and $EventLogSource -ne $null)
            {
                $EventLog = $true
            }

            if ($LogFilePath -ne $null)
            {
                $File = $true
            }
        }
        
        if ($Screen -and -not $MajorFault -and -not $Silent)
        { 
            #Write-Verbose "Logging to Screen..." 
            
            if (!$SkipDateTime) 
            {
                Write-Host "$($CurrentTime): " -ForegroundColor DarkYellow -NoNewline
            }
            
            if ($EntryType -eq "Error")
            { 
                Write-Error $Message
                if ($Underline) { Write-Error "$([string]::Empty.PadLeft($ScreenMessage.Length,$UnderlineChar))" }
            }
            elseif ($EntryType -eq "Warning")
            {
                Write-Warning $Message
                if ($Underline) { Write-Warning "$([string]::Empty.PadLeft($ScreenMessage.Length,$UnderlineChar))" }
            }
            else
            {
                if ($verbosePreference -eq "Continue")
                { 
                    Write-Verbose $Message
                    if ($Underline) { Write-Verbose "$([string]::Empty.PadLeft($ScreenMessage.Length,$UnderlineChar))" }
                }
                else 
                { 
                    Write-Host $Message -ForegroundColor $ForegroundColor
                    if ($Underline) { Write-Host "$([string]::Empty.PadLeft($ScreenMessage.Length,$UnderlineChar))" }
                    
                }
            }
        }
        
        if ($File) 
        {
            if ($LogFilePath -eq [string]::Empty) { Write-Warning "The LogFilePath is not set! Use -SetLogFilePath first!" }
            else
            {
                $FileMessage = ""
                if (!$SkipDateTime) 
                {
                    $FileMessage = "$CurrentTime - "
                }
                 $FileMessage += "$($EntryType): $Message"

                #Write-Verbose "Logging to File `'$LoggFilePath`'..."
                Add-Content -Path $LogFilePath -Value $FileMessage
                if ($Underline) { Add-Content -Path $LogFilePath -Value "$([string]::Empty.PadLeft($FileMessage.Length,$UnderlineChar))" }
            }
        }
        
        if ($EventLog)
        { 
            if ($EventLogName -eq [string]::Empty) { Write-Warning "The SetEventLogName is not set! Use -SetEventLogName first!" }
            elseif ($EventLogSource -eq [string]::Empty) { Write-Warning "The EventLogSource is not set! Use -SetEventLogSource first!" }
            else
            {
                #Write-Verbose "Logging to EventLog `'$EventLogName`' as Source `'$EventLogSource`'..." 
            
                Write-EventLog -LogName $EventLogName -Source $EventLogSource -EventId $EventID -Message $Message -EntryType $EntryType -Category $Category    
            }
        }

        if($EntryType -eq "Warning")
        {
            $global:Warnings++
            $global:LastWarning = $Message
        }
        elseif($EntryType -eq "Error")
        {
            $global:Errors++
            $global:LastError = $Message
        }
        
        if ($MajorFault) { throw $Message }   
    }
}
<#
.SYNOPSIS
Use this cmdlet to add logging to your script. Can log to Screen/File and EventLog

.DESCRIPTION
Start by setting FilePath and/or EventLogName/EventLogSource. The values are stored in global variables and don't need to be set again.

Call Write-ADFSTkLog with one or more parameters depending on how much logging needed. 

If a Warning is logged the following global variables will be changed:
$Warnings will increase with 1
$LastWarning will be set to $Message

If an Error is logged the following global variables will be changed:
$Errors will increase with 1
$LastError will be set to $Message

If -MajorFault is provided, EntryType will automatically be set as Error and after logging has been done, the Message will be thrown.

If a variable namned $Silent is used and equals $true in the script calling Write-ADFSTkLog, no logging to screen will be done

.EXAMPLE
C:\PS> Write-ADFSTkLog -Message "Hello World!"
2012-02-02 16:40:16: Hello World!

-Message parameter are not needed as long as the message is written first

C:\PS> Write-ADFSTkLog "Hello World!" -EntryType Warning
WARNING: 2012-02-02 16:41:23: Hello World!

C:\PS> Write-ADFSTkLog -SetLogFilePath C:\Logs\myLogfile.txt
C:\PS> Write-ADFSTkLog "Hello textfile!" -File -Screen -Underline
2012-02-02 16:46:31: Hello textfile!
------------------------------------
.EXAMPLE
If none of the parameters (-Screen, -File or -EventLog) is provided, all defined ways will be used.
Default will only be the screen, a -SetLogFilePath has been set, the logging will be to screen and file, etc

C:\PS> Write-ADFSTkLog -SetLogFilePath C:\Logs\myLogfile.txt
C:\PS> Write-ADFSTkLog "Look, I don't use any parameters! :)"
2012-02-02 16:59:46: Look, I don't use any parameters! :)

C:\PS> Get-Content $LogFilePath
2012-02-02 16:46:31 - Information: Hello textfile!
--------------------------------------------------
2012-02-02 16:59:46 - Information: Look, I don't use any parameters! :)

C:\PS> Write-ADFSTkLog "Something isn't quite right!" -EntryType Warning
WARNING: 2012-02-02 17:00:45: Something isn't quite right!

C:\PS> Get-Content $LogFilePath
2012-02-02 16:46:31 - Information: Hello textfile!
--------------------------------------------------
2012-02-02 16:59:46 - Information: Look, I don't use any parameters! :)
2012-02-02 17:00:45 - Warning: Something isn't quite right!
C:PS> $Warnings
2
C:PS> $Errors
0
C:PS> $LastWarning
Something isn't quite right!
#>
}

function Write-ADFSTkVerboseLog {
[CmdletBinding(SupportsShouldProcess=$true)] 
param (
    [parameter(Position=0)]
    [ValidateNotNullOrEmpty()]
    [string]
    #The message to be written in the log...
    $Message,
    [string]
    #Used in LogFile and on Screen to clarify the message. In EventLog the Level on the event is set to EntryType. Default is Information
    [ValidateSet("Information", "Error", "Warning")]
    $EntryType="Information",
    [switch]
    #Use this to log to EventLog
    $EventLog,
    [switch]
    #Use this to log to file
    $File,
    [int]
    #The EventID if EventLog is used
    $EventID
)
    if ($verbosePreference -eq "Continue")
    { 
        if (!$File.IsPresent -and !$EventLog.IsPresent)
        {
            if ($EventLogName -ne $null -and $EventLogSource -ne $null)
            {
                $EventLog = $true
            }

            if ($LogFilePath -ne $null)
            {
                $File = $true
            }
        }

        if ($EventLog)
        {
            Write-ADFSTkLog -Message $Message -EventLog -EventID $EventID -EntryType $EntryType
        }
        
        if($File)
        {
            Write-ADFSTkLog -Message $Message -File -EventID $EventID -EntryType $EntryType
        }
        
        Write-ADFSTkLog -Message $Message -EntryType $EntryType -Screen
        
    }
<#
.SYNOPSIS
Use this cmdlet to add Verbose-logging to your script. Logging will always be to screen, but can also be done to File and/or EventLog

.DESCRIPTION
Start by setting FilePath and/or EventLogName/EventLogSource with Write-ADFSTkLog.

Category will always be set to 4

.EXAMPLE
Scriptfile below (Test-Script.ps1)
---
[CmdletBinding(SupportsShouldProcess=$true)]
param()

Write-VerboseLiULog "This is a verbose message"
---

C:\PS> .\Test-Script.ps1

C:\PS> .\Test-Script.ps1 -Verbose
VERBOSE: This is a verbose message
.EXAMPLE
Scriptfile below (Test-Script.ps1)
---
[CmdletBinding(SupportsShouldProcess=$true)]
param()

Write-ADFSTkLog -SetLogFilePath .\myLogfile.txt
Write-VerboseLiULog "This is a verbose message"
---

C:\PS> .\Test-Script.ps1 -File -Verbose
VERBOSE: Setting LogFilePath to '.\myLogfile.txt'...
VERBOSE: 2012-01-04 12:56:50: This is a verbose message

C:\PS> Get-Content .\myLogfile.txt
2012-01-04 12:58:13 - Information: This is a verbose message
#>
}


# SIG # Begin signature block
# MIIYUAYJKoZIhvcNAQcCoIIYQTCCGD0CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUlWg0iwnh0pVq/A1xHjXISEoZ
# 5OmgghKwMIIEFDCCAvygAwIBAgILBAAAAAABL07hUtcwDQYJKoZIhvcNAQEFBQAw
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
# AYI3AgEVMCMGCSqGSIb3DQEJBDEWBBS6qxh1PaMHwDyIgs0eGVJcgFwYcTANBgkq
# hkiG9w0BAQEFAASCAQB6BQ03bTFSoOZgiVmGILEA3JUZFK0cLKaumXGBUJw4P29p
# J8UD3Kz+BdaWjCQd8oH3S/sI8Tax5y2+yisYNXKCX/543JWduje81iw6zJVc4tfh
# XJ/2Fg9rXpO+p+b2YeIA6Fs0pNZGJ3kdq6mfxcESD5kLP7MTQ2J9sE87JNzi/7ZJ
# Vi+5uTa2LUHqnEe9nGpUFpPaSRP5iXDYoaKTcTNQqgPMzm7vyxDKEqu7H0Itu2GF
# F2IoVhbAeN0BAMvDD+uM/Puz6Fa/SQul6yP4U4EMTgGpbPNrYg2A5QiQ08cK2Jc4
# hPEM/M9s+OuQzQFX/3V+O1hG2ob6YaNLAyR/ngQJoYICojCCAp4GCSqGSIb3DQEJ
# BjGCAo8wggKLAgEBMGgwUjELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNp
# Z24gbnYtc2ExKDAmBgNVBAMTH0dsb2JhbFNpZ24gVGltZXN0YW1waW5nIENBIC0g
# RzICEhEh1pmnZJc+8fhCfukZzFNBFDAJBgUrDgMCGgUAoIH9MBgGCSqGSIb3DQEJ
# AzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTE4MDQxODE2NDkxMlowIwYJ
# KoZIhvcNAQkEMRYEFKXdbZO0Va8JV7m/WZq3EyuyD1JjMIGdBgsqhkiG9w0BCRAC
# DDGBjTCBijCBhzCBhAQUY7gvq2H1g5CWlQULACScUCkz7HkwbDBWpFQwUjELMAkG
# A1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExKDAmBgNVBAMTH0ds
# b2JhbFNpZ24gVGltZXN0YW1waW5nIENBIC0gRzICEhEh1pmnZJc+8fhCfukZzFNB
# FDANBgkqhkiG9w0BAQEFAASCAQB3BGQxmq9/YXbFNQibo3yFmCp6B9+OGzmfTB/R
# xA3xwbex3Fko3jWR42UBeGYKZ8mrRyyVkCE8zkOWyl3qB6x164ZIUYJcfVW7lNAB
# b9nl/OaSkY8goB8TnoqLkdX5PnjSSkhkHgpL2a5juiLEpbyv6fZc8zDZoj5w7dqu
# 1A2qZIUCEbwm1yoW/kXffN0l5trmXFANN8G+auPEaZFkK1nHOqC3xTVO5++gQHGH
# fglLT6JJnffsqydLV15Sk46W22hq7RID4qa4u+yvUNnm7mVFGo92RNq0InD89WOv
# nRbNv9+W/YatYZikCXNidSL3iNE3qIlGH72A2Vu16sY/JopO
# SIG # End signature block
