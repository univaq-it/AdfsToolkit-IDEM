function Add-ADFSTkSPRelyingPartyTrust {
    param (
        [Parameter(Mandatory=$true,
                   Position=0)]
        $sp
    )
    
    $Continue = $true
     ### EntityId
    $entityID = $sp.entityID

    $rpParams = @{
        Identifier = $entityID
        EncryptionCertificateRevocationCheck = 'None'
        SigningCertificateRevocationCheck = 'None'
        ClaimsProviderName = @("Active Directory")
        IssuanceAuthorizationRules =
@"
    @RuleTemplate = "AllowAllAuthzRule"
     => issue(Type = "http://schemas.microsoft.com/authorization/claims/permit", 
     Value = "true");
"@
        ErrorAction = 'Stop'
    }

   

    Write-ADFSTkLog "Adding $entityId as SP..." -EntryType Information

    ### Name, DisplayName
    $Name = (Split-Path $sp.entityID -NoQualifier).TrimStart('/') -split '/' | select -First 1

#region IssuanceAutorizzationRules

    Write-ADFSTkVerboseLog "Setting Authorization Rules..."
    $optInGroup = $Settings.configuration.optInGroup
    $optOutGroup = $Settings.configuration.optOutGroup

    $issuanceAuthorizationRules = ""
    if ($optOutGroup) {
        $issuanceAuthorizationRules = 
@"
    @RuleName = "OPT-Out Group"
    c:[Type == "http://schemas.microsoft.com/ws/2008/06/identity/claims/groupsid", Value == "$optOutGroup", Issuer == "AD AUTHORITY"]
     => issue(Type = "http://schemas.microsoft.com/authorization/claims/deny", Value = "OptOutGroup");

"@
    Write-ADFSTkVerboseLog "  Added Opt-Out Group"
    }

    if ($optInGroup) {
        $issuanceAuthorizationRules += 
@"
    @RuleName = "OPT-In Group"
    c:[Type == "http://schemas.microsoft.com/ws/2008/06/identity/claims/groupsid", Value == "$optInGroup", Issuer == "AD AUTHORITY"]
     => issue(Type = "http://schemas.microsoft.com/authorization/claims/permit", Value = "true");

"@
    Write-ADFSTkVerboseLog "  Added Opt-In Group"
    }
    else {
        $issuanceAuthorizationRules += 
@"
    @RuleTemplate = "AllowAllAuthzRule"
     => issue(Type = "http://schemas.microsoft.com/authorization/claims/permit", Value = "true");
"@
    }

    $rpParams.IssuanceAuthorizationRules = $issuanceAuthorizationRules

#endregion

#region Token Encryption Certificate 
    Write-ADFSTkVerboseLog "Getting Token Encryption Certificate..."
    
    $CertificateString = ($sp.SPSSODescriptor.KeyDescriptor | ? use -eq "encryption"  | select -ExpandProperty KeyInfo).X509Data.X509Certificate
    
    if ($CertificateString -eq $null)
    {
        #Check if any certificates without 'use'. Should we use this?
        Write-ADFSTkVerboseLog "Certificate with description `'encryption`' not found. Using default certificate..."
        #$CertificateString = ($sp.SPSSODescriptor.KeyDescriptor | select -ExpandProperty KeyInfo -First 1).X509Data.X509Certificate 
        $CertificateString = ($sp.SPSSODescriptor.KeyDescriptor | ? use -ne "signing"  | select -ExpandProperty KeyInfo).X509Data.X509Certificate #or shoud 'use' not be present?
    }
    
    if ($CertificateString -ne $null)
    {
        $rpParams.EncryptionCertificate = $null
        try
        {
            #May be more certificates! Be sure to check it out and drive foreach. 
            #If more than one, choose the one with furthest end date.
            $CertificateString | % {
                Write-ADFSTkVerboseLog "Converting Token Encryption Certificate string to Certificate..."
                $EncryptionCertificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
    
                $CertificateBytes  = [system.Text.Encoding]::UTF8.GetBytes($_)
                $EncryptionCertificate.Import($CertificateBytes)
                
                if ($rpParams.EncryptionCertificate -eq $null) 
                {
                    $rpParams.EncryptionCertificate = $EncryptionCertificate
                }
                elseif($rpParams.EncryptionCertificate.NotAfter -lt $EncryptionCertificate.NotAfter)
                {
                    $rpParams.EncryptionCertificate = $EncryptionCertificate
                }
                Write-ADFSTkVerboseLog "Convertion of Token Encryption Certificate string to Certificate done!"
            }
        }
        catch
        {
            Write-ADFSTkLog "Could not import Token Encryption Certificate!" -EntryType Error
            $Continue = $false
        }
    }
#endregion

#region Token Signing Certificate 

    #Add all signing certificates if there are more than one
    Write-ADFSTkVerboseLog "Getting Token Signing Certificate..."
    
    $rpParams.SignatureAlgorithm = "http://www.w3.org/2000/09/xmldsig#rsa-sha1"
    
    $CertificateString = ($sp.SPSSODescriptor.KeyDescriptor | ? use -eq "signing"  | select -ExpandProperty KeyInfo).X509Data.X509Certificate
    if ($CertificateString -eq $null)
    {
        Write-ADFSTkVerboseLog "Certificate with description `'signing`' not found. Using Token Decryption certificate..."
        $CertificateString = ($sp.SPSSODescriptor.KeyDescriptor | ? use -ne "encryption"  | select -ExpandProperty KeyInfo).X509Data.X509Certificate #or shoud 'use' not be present?
    }
    
    
    if ($CertificateString -ne $null) #foreach insted create $SigningCertificates array
    {
        try
        {
            $rpParams.RequestSigningCertificate = @()

            $CertificateString | % {

                Write-ADFSTkVerboseLog "Converting Token Signing Certificate string to Certificate..."

                $CertificateBytes  = [system.Text.Encoding]::UTF8.GetBytes($_)
                
                $SigningCertificate = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2                
                $SigningCertificate.Import($CertificateBytes)

                $rpParams.RequestSigningCertificate += $SigningCertificate

                if ($SigningCertificate.SignatureAlgorithm.Value -eq '1.2.840.113549.1.1.11') #Check if Signature Algorithm is SHA256
                {
                    $rpParams.SignatureAlgorithm = "http://www.w3.org/2001/04/xmldsig-more#rsa-sha256"
                }
            }
            
            
            Write-ADFSTkVerboseLog "Convertion of Token Signing Certificate string to Certificate done!"
        }
        catch
        {
            Write-ADFSTkLog "Could not import Token Signing Certificate!" -EntryType Error
            $Continue = $false
        }
    }
#endregion

#region Get SamlEndpoints
    Write-ADFSTkVerboseLog "Getting SamlEndpoints..."
    $rpParams.SamlEndpoint = $sp.SPSSODescriptor.AssertionConsumerService |  % {
        if ($_.Binding -eq "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST")
        {  
            Write-ADFSTkVerboseLog "HTTP-POST SamlEndpoint found!"
            New-ADFSSamlEndpoint -Binding POST -Protocol SAMLAssertionConsumer -Uri $_.Location -Index $_.index 
        }
        elseif ($_.Binding -eq "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Artifact")
        {
            Write-ADFSTkVerboseLog "HTTP-Artifact SamlEndpoint found!"
            New-ADFSSamlEndpoint -Binding Artifact -Protocol SAMLAssertionConsumer -Uri $_.Location -Index $_.index 
        }
    } 

    if ($rpParams.SamlEndpoint -eq $null) 
    {
        Write-ADFSTkLog "No SamlEndpoints found!" -EntryType Error
        $Continue = $false
    }
#endregion

#region Get Issuance Transform Rules
    Write-ADFSTkVerboseLog "Getting Entity Categories..."
    $EntityCategories = @()
    $EntityCategories += $sp.Extensions.EntityAttributes.Attribute | ? Name -eq "http://macedir.org/entity-category" | select -ExpandProperty AttributeValue | % {
        if ($_ -is [string])
        {
            $_
        }
        elseif ($_ -is [System.Xml.XmlElement])
        {
            $_."#text"
        }
    }
    
    Write-ADFSTkVerboseLog "The following Entity Categories found: $($EntityCategories -join ',')"

    if ($ForcedEntityCategories)
    {
        $EntityCategories += $ForcedEntityCategories
        Write-ADFSTkVerboseLog "Added Forced Entity Categories: $($ForcedEntityCategories -join ',')"
    }

    
    ### MOD IDEM  Begin ###
    $nameIDPersistent = $false
    
    if ($sp.SPSSODescriptor.NameIDFormat -ne $null) {
        foreach ($nidf in $sp.SPSSODescriptor.NameIDFormat) {
            if ($nidf -eq 'urn:oasis:names:tc:SAML:2.0:nameid-format:transient') { break }
            elseif ($nidf -eq 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent') {
                $nameIDPersistent = $true
                break
            }
        }
    }    

    ### MOD IDEM  End ###

    

    $IssuanceTransformRulesDict = Get-ADFSTkIssuanceTransformRules $EntityCategories -EntityId $entityID `
                                                                                 -RequestedAttribute $sp.SPSSODescriptor.AttributeConsumingService.RequestedAttribute `
                                                                                 -RegistrationAuthority $sp.Extensions.RegistrationInfo.registrationAuthority -NameIDPersistent $nameIDPersistent

    $rpParams.IssuanceTransformRules = $IssuanceTransformRulesDict.Values


#endregion

    if ((Get-ADFSRelyingPartyTrust -Identifier $entityID) -eq $null)
    {
        $NamePrefix = $Settings.configuration.MetadataPrefix 
        $Sep= $Settings.configuration.MetadataPrefixSeparator      
        $NameWithPrefix = "$NamePrefix$Sep$Name"

        if ((Get-ADFSRelyingPartyTrust -Name $NameWithPrefix) -ne $null)
        {
            $n=1
            Do
            {
                $n++
                $NewName = "$Name ($n)"
            }
            Until ((Get-ADFSRelyingPartyTrust -Name "$NamePrefix$Sep$NewName") -eq $null)

            $Name = $NewName
            $NameWithPrefix = "$NamePrefix$Sep$Name"
            Write-ADFSTkVerboseLog "A RelyingPartyTrust already exist with the same name. Changing name to `'$NameWithPrefix`'..."
        }

        $rpParams.Name = $NameWithPrefix
        
        if ($Continue)
        {
            try 
            {
                Write-ADFSTkVerboseLog "Adding ADFSRelyingPartyTrust `'$entityID`'..."
                
                # Invoking the following command leverages 'splatting' for passing the switches for commands
                # for details, see: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_splatting?view=powershell-6
                # (that's what it's @rpParams and not $rpParams)

                Add-ADFSRelyingPartyTrust @rpParams

                Write-ADFSTkLog "Successfully added `'$entityId`'!" -EntryType Information
                Add-ADFSTkEntityHash -EntityID $entityId

                ### Setting Webtheme ###
                $theme = $Settings.configuration.LoginPageCustomization.AdfsWebTheme
                if ($theme) {
                    Write-ADFSTkVerboseLog "Setting WebTheme ..."
                    Set-AdfsRelyingPartyWebTheme -TargetRelyingPartyName $rpParams.Name -SourceWebThemeName $theme
                }

                ### Customizie Login Page
                $showDesc = $true
                $showAttributes = $true
                
                $spname = ($sp.SPSSODescriptor.Extensions.UIInfo.DisplayName | ? {$_.lang -eq "it"}).'#text'
                $spname_en = ($sp.SPSSODescriptor.Extensions.UIInfo.DisplayName | ? {$_.lang -eq "en"}).'#text'
                
                if ($spname -and !$spname_en) {$spname_en = $spname}
                if ($spname_en -and !$spname) {$spname = $spname_en}
                
                
                if ($spname) {
                    Set-AdfsRelyingPartyWebContent -TargetRelyingPartyName $rpParams.Name -Locale "it" -OrganizationalNameDescriptionText "Accedi a <b>$spname</b>"
                }

                if ($spname_en) {
                    Set-AdfsRelyingPartyWebContent -TargetRelyingPartyName $rpParams.Name -OrganizationalNameDescriptionText "Login to <b>$spname_en</b>"
                }

                
                $desc = ($sp.SPSSODescriptor.Extensions.UIInfo.Description | ? {$_.lang -eq "it"}).'#text'
                $desc_en = ($sp.SPSSODescriptor.Extensions.UIInfo.Description | ? {$_.lang -eq "en"}).'#text'

                if ($desc -and !$desc_en) {$desc_en = $desc}
                if ($desc_en -and !$desc) {$desc = $desc_en}

                $attributeList = ""
                foreach ($attr in $IssuanceTransformRulesDict.Keys) {
                    if ($attr -eq "FirstRule") {continue}
                    $attributeList += "<li>$attr</li>"
                }
                
                $baseText = ($Settings.configuration.LoginPageCustomization.htmlText | ? {$_.lang -eq "it"}).'#cdata-section'
                $baseText_en = ($Settings.configuration.LoginPageCustomization.htmlText | ? {$_.lang -eq "en"}).'#cdata-section'

                if ($baseText -and !$baseText_en) {$baseText_en = $baseText}
                if ($baseText_en -and !$baseText) {$baseText = $baseText_en}

                if ($baseText) {
                    $text = $baseText.Replace("[ReplaceWithDESCRIPTION]",$desc).Replace("[ReplaceWithATTRIBUTELIST]",$attributeList)
                    Set-AdfsRelyingPartyWebContent -TargetRelyingPartyName $rpParams.Name -Locale "it" -SignInPageDescriptionText $text

                }
                if ($baseText_en) {
                    $text_en = $baseText_en.Replace("[ReplaceWithDESCRIPTION]",$desc_en).Replace("[ReplaceWithATTRIBUTELIST]",$attributeList)
                    Set-AdfsRelyingPartyWebContent -TargetRelyingPartyName $rpParams.Name -SignInPageDescriptionText $text_en
                }
                
            }
            catch
            {
                Write-ADFSTkLog "Could not add $entityId as SP! Error: $_" -EntryType Error
                Add-ADFSTkEntityHash -EntityID $entityId
            }
        }
        else
        {
            #There were some error with certificate or endpoints with this SP. Let's only try again if it changes... 
            Add-ADFSTkEntityHash -EntityID $entityId
        }
    }
    else
    {
        Write-ADFSTkLog "$entityId already exists as SP!" -EntryType Warning
    }                
}
# SIG # Begin signature block
# MIIYUAYJKoZIhvcNAQcCoIIYQTCCGD0CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUDgsDCZXBYlie0mqfL3FFg4iu
# J/SgghKwMIIEFDCCAvygAwIBAgILBAAAAAABL07hUtcwDQYJKoZIhvcNAQEFBQAw
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
# AYI3AgEVMCMGCSqGSIb3DQEJBDEWBBQsNceUy9a6jnJgEYJkwphokRlRJDANBgkq
# hkiG9w0BAQEFAASCAQBoAHpk7pgZcLUHwpDyaV0FtHOymEfcsvZKFNVCmwPG8FYd
# 6i7XPVUDBwnIsUPIEJvlxcrTaufzXWZ76kFxXBdr46PkWrNL7Ep4eBFm+KjlV3nt
# YN/WCbAlKy1T+yvGL1UHs6bq1OGRZ1ro07Cr7sw5QNLchw+qbPQqosL6rLmIXrVt
# dPZt89LEPQpZfpI23/yge3mVdAWy0NGcaHN0Pi0sXwVWPhUAlkniT+hLgsJmGkOH
# E/tn+UbcK400EJFYgj5iou6saxYtwrFIc3jTCUW+/8kmQSsOomNzbXHpHoGukm97
# 4jzbCSeajYpR5/TE31DCsFmLGwr6EtyljBwoUCOboYICojCCAp4GCSqGSIb3DQEJ
# BjGCAo8wggKLAgEBMGgwUjELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNp
# Z24gbnYtc2ExKDAmBgNVBAMTH0dsb2JhbFNpZ24gVGltZXN0YW1waW5nIENBIC0g
# RzICEhEh1pmnZJc+8fhCfukZzFNBFDAJBgUrDgMCGgUAoIH9MBgGCSqGSIb3DQEJ
# AzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTE4MDQxODE2NDkwNVowIwYJ
# KoZIhvcNAQkEMRYEFA0sQIXNHFWZx+amZukkptsxrTHuMIGdBgsqhkiG9w0BCRAC
# DDGBjTCBijCBhzCBhAQUY7gvq2H1g5CWlQULACScUCkz7HkwbDBWpFQwUjELMAkG
# A1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExKDAmBgNVBAMTH0ds
# b2JhbFNpZ24gVGltZXN0YW1waW5nIENBIC0gRzICEhEh1pmnZJc+8fhCfukZzFNB
# FDANBgkqhkiG9w0BAQEFAASCAQCUPfz06meMoiN3OLHrgTbF1/YJbxRgbtjP8Xcg
# tD77A9oUnGzQNu1GrxWE6a59Ubou/wkW/nS/r37gR9smD6DczglU+/8Wv7I651Et
# 3NUTs1jR7Gf2IsyD/tgD9mo8otZLWAz31X8zULVTACyf6IRJss1qrur2XXRxjKCm
# p7kMB03ya8junWG8oBU50ATxQKnE99YYyIYOZdMfK/aaSK7SENHDvyWLUempfd1l
# JyCZ+07XHEAGRP8lKmwQFpto/tGG7epTOOBXzazGLdAKPbJ86ahIt6nq8qYS95NH
# 3MojPhjgXQuEXai7rRAsMF3KWkxqgT64iibnP/4X+KdzGHPS
# SIG # End signature block
