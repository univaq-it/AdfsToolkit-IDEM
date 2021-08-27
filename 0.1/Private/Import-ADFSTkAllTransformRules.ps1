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