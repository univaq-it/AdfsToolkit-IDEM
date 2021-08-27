function Import-ADFSTkAllTransformRules
{
   

    $TransformRules = @{}
 #region Static values from config
    $TransformRules.o = [PSCustomObject]@{
    Rule=@"
    @RuleName = "Send static [o]"
    => issue(type = "urn:oid:2.5.4.10", 
    value = "$($Settings.configuration.StaticValues.o)",
    Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/attributename"] = "urn:oasis:names:tc:SAML:2.0:attrname-format:uri");
"@
    Attribute=""
    AttributeGroup="Static attributes"
    }

    $TransformRules.norEduOrgAcronym = [PSCustomObject]@{
    Rule=@"
    @RuleName = "Send static [norEduOrgAcronym]"
    => issue(type = "urn:oid:1.3.6.1.4.1.2428.90.1.6", 
    value = "$($Settings.configuration.StaticValues.norEduOrgAcronym)",
    Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/attributename"] = "urn:oasis:names:tc:SAML:2.0:attrname-format:uri");
"@
    Attribute=""
    AttributeGroup="Unused"
    }

    $TransformRules.c = [PSCustomObject]@{
    Rule=@"
    @RuleName = "Send static [c]"
    => issue(type = "urn:oid:2.5.4.6", 
    value = "$($Settings.configuration.StaticValues.c)",
    Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/attributename"] = "urn:oasis:names:tc:SAML:2.0:attrname-format:uri");
"@
    Attribute=""
    AttributeGroup="Static attributes"
    }

    $TransformRules.co = [PSCustomObject]@{
    Rule=@"
    @RuleName = "Send static [co]"
    => issue(type = "urn:oid:0.9.2342.19200300.100.1.43", 
    value = "$($Settings.configuration.StaticValues.co)",
    Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/attributename"] = "urn:oasis:names:tc:SAML:2.0:attrname-format:uri");
"@
    Attribute=""
    AttributeGroup="Static attributes"
    }

    $TransformRules.schacHomeOrganization = [PSCustomObject]@{
    Rule=@"
    @RuleName = "Send static [schacHomeOrganization]"
    => issue(type = "urn:oid:1.3.6.1.4.1.25178.1.2.9", 
    value = "$($Settings.configuration.StaticValues.schacHomeOrganization)",
    Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/attributename"] = "urn:oasis:names:tc:SAML:2.0:attrname-format:uri");
"@
    Attribute=""
    AttributeGroup="IDEM"
    }

    $TransformRules.schacHomeOrganizationType = [PSCustomObject]@{
    Rule=@"
    @RuleName = "Send static [schacHomeOrganizationType]"
    => issue(type = "urn:oid:1.3.6.1.4.1.25178.1.2.10", 
    value = "$($Settings.configuration.StaticValues.schacHomeOrganizationType)",
    Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/attributename"] = "urn:oasis:names:tc:SAML:2.0:attrname-format:uri");
"@
    Attribute=""
    AttributeGroup="IDEM"
    }
    #endregion

    #region ID's
    $TransformRules."transient-id" = [PSCustomObject]@{
    Rule=@"
    @RuleName = "synthesize transient-id"
    c1:[Type == "http://schemas.microsoft.com/ws/2008/06/identity/claims/primarysid"]
     && 
     c2:[Type == "http://schemas.microsoft.com/ws/2008/06/identity/claims/authenticationinstant"]
     => add(store = "_OpaqueIdStore", 
     types = ("http://$($Settings.configuration.StaticValues.ADFSExternalDNS)/internal/tpid"),
     query = "{0};{1};{2};{3};{4}", 
     param = "useEntropy", 
     param = "http://$($Settings.configuration.StaticValues.ADFSExternalDNS)/adfs/services/trust![ReplaceWithSPNameQualifier]!" + c1.Value, 
     param = c1.OriginalIssuer, 
     param = "", 
     param = c2.Value);

    @RuleName = "issue transient-id"
    c:[Type == "http://$($Settings.configuration.StaticValues.ADFSExternalDNS)/internal/tpid"]
     => issue(Type = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier", 
     Value = c.Value, 
     Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/format"] = "urn:oasis:names:tc:SAML:2.0:nameid-format:transient", 
     Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/spnamequalifier"] = "[ReplaceWithSPNameQualifier]", 
     Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/namequalifier"] = "http://$($Settings.configuration.StaticValues.ADFSExternalDNS)/adfs/services/trust");
"@
    Attribute=""
    AttributeGroup="ID's"
    }

    $TransformRules."persistent-id" = [PSCustomObject]@{
    Rule=@"
    @RuleName = "Set default seed-id"
    NOT EXISTS([Type == "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/seed-id"])
     => add(Type = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/seed-id", Value = "aa");

    @RuleName = "synthesize persistent-id"
    c1:[Type == "http://schemas.microsoft.com/ws/2008/06/identity/claims/primarysid"]
     && c2:[Type == "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/seed-id"]
     => add(store = "_OpaqueIdStore", 
     types = ("http://$($Settings.configuration.StaticValues.ADFSExternalDNS)/internal/tpid"), 
     query = "{0};{1};{2}", 
     param = "ppid", 
     param = c1.Value, 
     param = c2.Value);

    @RuleName = "issue persistent-id"
    c:[Type == "http://$($Settings.configuration.StaticValues.ADFSExternalDNS)/internal/tpid"]
     => issue(Type = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier", 
     Value = c.Value, 
     Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/format"] = "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent", 
     Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/spnamequalifier"] = "[ReplaceWithSPNameQualifier]", 
     Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/namequalifier"] = "http://$($Settings.configuration.StaticValues.ADFSExternalDNS)/adfs/services/trust");
"@
    Attribute="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/seed-id"
    AttributeGroup="ID's"
    }
    

   
   # eduPersonPrincipalName 
   # Calculated based off an ADFSTk configuration rule keyed to ADFSTkExtractSubjectUniqueId, default to the Claim 'upn'
   # 
   # Origin Claim will have only the left hand side being everything prior to the first @ sign
   # Rest of the string will be surpressed and then it is re-assembled with our SAML2 scope.
   #
   

    $TransformRules.eduPersonPrincipalName = [PSCustomObject]@{
    Rule=@"
    @RuleName = "compose eduPersonPrincipalName"
    c:[Type == "$(($Settings.configuration.storeConfig.transformRules.rule | ? name -eq "ADFSTkExtractSubjectUniqueId").originClaim )" ]
     => issue(Type = "urn:oid:1.3.6.1.4.1.5923.1.1.1.6", 
     Value = RegexReplace(c.Value, "@.*$", "") +"@$($Settings.configuration.StaticValues.schacHomeOrganization)", 
     Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/attributename"] = "urn:oasis:names:tc:SAML:2.0:attrname-format:uri");
"@
    Attribute="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name"
    AttributeGroup="ID's"
    }

    $TransformRules.eduPersonTargetedID = [PSCustomObject]@{
    Rule=@"

    @RuleName = "Set default seed-id for ePTID"
    NOT EXISTS([Type == "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/seed-id"])
     => add(Type = "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/seed-id", Value = "aa");

    @RuleName = "synthesize eduPersonTargetedID"
    c1:[Type == "http://schemas.microsoft.com/ws/2008/06/identity/claims/primarysid"]
     && c2:[Type == "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/seed-id"]
     => add(store = "_OpaqueIdStore", 
     types = ("http://$($Settings.configuration.StaticValues.ADFSExternalDNS)/internal/tpidePTID"), 
     query = "{0};{1};{2}", 
     param = "ppid", 
     param = c1.Value, 
     param = c2.Value);

    @RuleName = "issue eduPersonTargetedID"
    c:[Type == "http://$($Settings.configuration.StaticValues.ADFSExternalDNS)/internal/tpidePTID"]
     => issue(Type = "urn:oid:1.3.6.1.4.1.5923.1.1.1.10", 
     Value = "http://$($Settings.configuration.StaticValues.ADFSExternalDNS)/adfs/services/trust![ReplaceWithSPNameQualifier]!" + c.Value, 
     Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/attributename"] = "urn:oasis:names:tc:SAML:2.0:attrname-format:uri");

"@
    Attribute="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/seed-id"
    AttributeGroup="ID's"
    }

    $TransformRules.eduPersonUniqueID = [PSCustomObject]@{
    Rule=@"
    @RuleName = "compose eduPersonUniqueID"
    c:[Type == "urn:mace:dir:attribute-def:norEduPersonLIN"] 
     => issue(Type = "urn:oid:1.3.6.1.4.1.5923.1.1.1.13", 
     Value = RegExReplace(c.Value, "-", "") + "@$($Settings.configuration.StaticValues.schacHomeOrganization)",
     Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/attributename"] = "urn:oasis:names:tc:SAML:2.0:attrname-format:uri");
"@
    Attribute="urn:mace:dir:attribute-def:norEduPersonLIN"
    AttributeGroup="Unused"
    }

 $TransformRules["LoginName"] = [PSCustomObject]@{
    Rule=@"

    @RuleName = "Transform LoginName"
    c:[Type == "http://schemas.xmlsoap.org/claims/samaccountname"]
     => issue(Type = "LOGINNAME", 
     Value = c.Value, 
     Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/attributename"] = "urn:oasis:names:tc:SAML:2.0:assertion");
"@

    Attribute="http://schemas.xmlsoap.org/claims/samaccountname"
    AttributeGroup="Unused"
    }

    #endregion
    #region Personal attributes
    $TransformRules.givenName = Get-ADFSTkTransformRule -Type "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname" `
                                                  -Oid "urn:oid:2.5.4.42" `
                                                  -AttributeName givenName `                                                  -AttributeGroup "IDEM"

    $TransformRules.sn = Get-ADFSTkTransformRule -Type "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname" `
                                           -Oid "urn:oid:2.5.4.4" `
                                           -AttributeName sn `                                           -AttributeGroup "IDEM"

    $TransformRules.displayName = Get-ADFSTkTransformRule -Type "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/displayname" `
                                           -Oid "urn:oid:2.16.840.1.113730.3.1.241" `
                                           -AttributeName displayName `                                           -AttributeGroup "IDEM"
                                           
    $TransformRules.cn = Get-ADFSTkTransformRule -Type "http://schemas.xmlsoap.org/claims/CommonName" `
                                           -Oid "urn:oid:2.5.4.3" `
                                           -AttributeName cn `                                           -AttributeGroup "IDEM"

    $TransformRules.mail = Get-ADFSTkTransformRule -Type "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress" `
                                             -Oid "urn:oid:0.9.2342.19200300.100.1.3" `
                                             -AttributeName mail `                                             -AttributeGroup "IDEM"

                                             
    ### MOD IDEM  Begin ###
    
    $TransformRules.email = $TransformRules.mail

    ### MOD IDEM  End ###

    #endregion

 #region eduPerson Attributes

    $TransformRules.eduPersonScopedAffiliation = Get-ADFSTkTransformRule -Type "urn:mace:dir:attribute-def:eduPersonScopedAffiliation" `
                                                        -Oid "urn:oid:1.3.6.1.4.1.5923.1.1.1.9" `
                                                        -AttributeName eduPersonScopedAffiliation `                                                        -AttributeGroup "IDEM"

    $TransformRules.eduPersonAffiliation = Get-ADFSTkTransformRule -Type "urn:mace:dir:attribute-def:eduPersonAffiliation" `
                                                        -Oid "urn:oid:1.3.6.1.4.1.5923.1.1.1.1" `
                                                        -AttributeName eduPersonAffiliation `                                                        -AttributeGroup "Unused"

    $TransformRules.norEduPersonNIN = Get-ADFSTkTransformRule -Type "urn:mace:dir:attribute-def:norEduPersonNIN" `
                                                        -Oid "urn:oid:1.3.6.1.4.1.2428.90.1.5" `
                                                        -AttributeName norEduPersonNIN `                                                        -AttributeGroup "Unused"

    $TransformRules.eduPersonEntitlement = Get-ADFSTkTransformRule -Type "urn:mace:dir:attribute-def:eduPersonEntitlement" `
                                                             -Oid "urn:oid:1.3.6.1.4.1.5923.1.1.1.7" `
                                                             -AttributeName eduPersonEntitlement `                                                             -AttributeGroup "IDEM"

    $TransformRules.eduPersonAssurance = Get-ADFSTkTransformRule -Type "urn:mace:dir:attribute-def:eduPersonAssurance" `
                                                           -Oid "urn:oid:1.3.6.1.4.1.5923.1.1.1.11" `
                                                           -AttributeName eduPersonAssurance `                                                           -AttributeGroup "Unused"

    $TransformRules.norEduPersonLIN = Get-ADFSTkTransformRule -Type "urn:mace:dir:attribute-def:norEduPersonLIN" `
                                                        -Oid "urn:oid:1.3.6.1.4.1.2428.90.1.4" `
                                                        -AttributeName norEduPersonLIN `                                                        -AttributeGroup "Unused"

    #endregion


    #region EduGAIN
    $TransformRules.schacPersonalUniqueCode = [PSCustomObject]@{
    Rule=@"
    @RuleName = "issue schacPersonalUniqueCode"
    c:[Type == "http://schemas.xmlsoap.org/ws/2005/05/identity/claims/esi-code"]
     => issue(Type = "urn:oid:1.3.6.1.4.1.25178.1.2.14", 
     Value = "urn:schac:personalUniqueCode:int:esi:$($Settings.configuration.StaticValues.schacHomeOrganization):" + c.Value, 
     Properties["http://schemas.xmlsoap.org/ws/2005/05/identity/claimproperties/attributename"] = "urn:oasis:names:tc:SAML:2.0:attrname-format:uri");
"@
    Attribute="http://schemas.xmlsoap.org/ws/2005/05/identity/claims/esi-code"
    AttributeGroup="EduGAIN"
    }


    


    #endregion


    $TransformRules
}

# SIG # Begin signature block
# MIIYUAYJKoZIhvcNAQcCoIIYQTCCGD0CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUwVuA9pIZa/dJUVBqfjyoaNH6
# e/6gghKwMIIEFDCCAvygAwIBAgILBAAAAAABL07hUtcwDQYJKoZIhvcNAQEFBQAw
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
# AYI3AgEVMCMGCSqGSIb3DQEJBDEWBBRHI9ldGRh65pQELa7dDIEXMgMeljANBgkq
# hkiG9w0BAQEFAASCAQDE0yb3hG/KjZL+opLM+DBFLlpVWnqRV9VDTN9fWnnhsf4e
# guP4Ik1IzV+cdH522/S/m4FlFrbR/LdS0EieHvhpZeIzNeQ5GsCPY0W+i1Xzt8nY
# P3rQF1SttjMaWqUn7ck6w12ysII9sK7FF/NrfHAq/UZoINqorVIJq5m0lPWXyroF
# +h9zSFFPsy50FqgIjwdPbYTleuS/OWwwW3ck1FLNVwn+z9UDrflJBB+x2SXHjyO7
# jSU4UhQdH2Qmi0Ce+dZgdGVWpSauFbdxMJmc1ajyaUspcNi/lUKkImt0Q7iE4U0e
# 2KXQG87BYZx1tJ2TbcZ40gxpb9g0EM/5vvFUah3MoYICojCCAp4GCSqGSIb3DQEJ
# BjGCAo8wggKLAgEBMGgwUjELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNp
# Z24gbnYtc2ExKDAmBgNVBAMTH0dsb2JhbFNpZ24gVGltZXN0YW1waW5nIENBIC0g
# RzICEhEh1pmnZJc+8fhCfukZzFNBFDAJBgUrDgMCGgUAoIH9MBgGCSqGSIb3DQEJ
# AzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTE4MDQxODE2NDkwOFowIwYJ
# KoZIhvcNAQkEMRYEFGSYIjZzLfLjLvejcdwb0jTOoCGTMIGdBgsqhkiG9w0BCRAC
# DDGBjTCBijCBhzCBhAQUY7gvq2H1g5CWlQULACScUCkz7HkwbDBWpFQwUjELMAkG
# A1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExKDAmBgNVBAMTH0ds
# b2JhbFNpZ24gVGltZXN0YW1waW5nIENBIC0gRzICEhEh1pmnZJc+8fhCfukZzFNB
# FDANBgkqhkiG9w0BAQEFAASCAQB3y9pa4dIMiH2COGwXllhm/I00RhICq5rOaykZ
# h73mo3LvQcKHh+PCeRFD8rRiQ/VphnGelef9QBW6KLd0e4GM/4IoSA++A3Yixu/N
# MIuIX1Ub2KV3gBwJsAJBviREWLBiwIMl6AXZ2SxzfCx3kFjCbWRg4TdZuu6uNeOV
# 787lhqdGUELsnYojAz+oz4kifEi2qrZBEQ1FEiigUojaXEt4YpCpCTkmrVwn8GEI
# I6Zk7fOdL7dgGpNJzB9NtkehAFcdr1fRb/63vwlpUDUFG16+ZELDmPacGEDYMhzJ
# ZSVGJgyvVT8CpnhFRvT5bEORHNivMdqm/NDNUwdZfs9JqoZM
# SIG # End signature block
