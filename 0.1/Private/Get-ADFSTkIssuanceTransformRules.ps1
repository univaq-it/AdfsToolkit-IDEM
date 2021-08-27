function Get-ADFSTkIssuanceTransformRules
{
param (

    [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
    [string[]]$EntityCategories,
    [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
    [string]$EntityId,
    [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=2)]
    $RequestedAttribute,
    [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=3)]
    $RegistrationAuthority,
    [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=3)]
    $NameIDPersistent
    
)


$AllAttributes = Import-ADFSTkAllAttributes
$AllTransformRules = Import-ADFSTkAllTransformRules

#$IssuanceTransformRuleCategories = Import-ADFSTkIssuanceTransformRuleCategories -RequestedAttribute $RequestedAttribute
$IssuanceTransformRulesManualSP = get-ADFSTkManualSPSettings




$AttributesFromStore = @{}
$IssuanceTransformRules = [Ordered]@{}


    ### MOD IDEM  Begin ###
    
### NameID Format
$nameIDRule = 'transient-id'

if ($NameIDPersistent) {
    $nameIDRule = 'persistent-id'
}

$IssuanceTransformRules[$nameIDRule] = $AllTransformRules.$nameIDRule.Rule.Replace("[ReplaceWithSPNameQualifier]",$EntityId)
foreach ($Attribute in $AllTransformRules.$nameIDRule.Attribute) { $AttributesFromStore[$Attribute] = $AllAttributes[$Attribute] }
Write-ADFSTkVerboseLog "--------------- NameID: $nameIDRule"


### Mandatory Attributes

$TransformRulesMandatory = [Ordered]@{}
$TransformRulesMandatory.eduPersonScopedAffiliation = $AllTransformRules.eduPersonScopedAffiliation

foreach ($Rule in $TransformRulesMandatory.Keys) { 
        $IssuanceTransformRules[$Rule] = $AllTransformRules.$Rule.Rule.Replace("[ReplaceWithSPNameQualifier]",$EntityId)
        foreach ($Attribute in $AllTransformRules.$Rule.Attribute) { $AttributesFromStore[$Attribute] = $AllAttributes[$Attribute] }
        Write-ADFSTkVerboseLog "--------------- Mand: $Rule Aggiunto"
}


### EntityCategories

# research-and-scholarship ###

$TransformRulesReS = [Ordered]@{}
    
$TransformRulesReS.eduPersonPrincipalName = $AllTransformRules.eduPersonPrincipalName
$TransformRulesReS.mail = $AllTransformRules.mail
$TransformRulesReS.displayName = $AllTransformRules.displayName
$TransformRulesReS.givenName = $AllTransformRules.givenName
$TransformRulesReS.sn = $AllTransformRules.sn
$TransformRulesReS.eduPersonScopedAffiliation = $AllTransformRules.eduPersonScopedAffiliation

if ($EntityCategories -ne $null -and $EntityCategories.Contains("http://refeds.org/category/research-and-scholarship")) {
    Write-ADFSTkVerboseLog "--------------- Trovato research-and-scholarship"
    foreach ($Rule in $TransformRulesReS.Keys) { 
        $IssuanceTransformRules[$Rule] = $AllTransformRules.$Rule.Rule.Replace("[ReplaceWithSPNameQualifier]",$EntityId)
        foreach ($Attribute in $AllTransformRules.$Rule.Attribute) { $AttributesFromStore[$Attribute] = $AllAttributes[$Attribute] }
        Write-ADFSTkVerboseLog "--------------- ReS: $Rule Aggiunto"
    }
}



### Manual Rules

if ($EntityId -ne $null -and $IssuanceTransformRulesManualSP.ContainsKey($EntityId))
{
    foreach ($Rule in $IssuanceTransformRulesManualSP[$EntityId].Keys) { 
        if ($IssuanceTransformRulesManualSP[$EntityId][$Rule] -ne $null)
        {
            Write-ADFSTkVerboseLog "--------------- MANUAL: $Rule Aggiunto"
            $IssuanceTransformRules[$Rule] = $IssuanceTransformRulesManualSP[$EntityId][$Rule].Rule.Replace("[ReplaceWithSPNameQualifier]",$EntityId)
            foreach ($Attribute in $IssuanceTransformRulesManualSP[$EntityId][$Rule].Attribute) { 
                $AttributesFromStore[$Attribute] = $AllAttributes[$Attribute] 
            }
        }
    }
}



### Explicit Requested Attributes

$oidToRule = @{}
$oidToRule.Add("urn:oid:1.3.6.1.4.1.5923.1.1.1.9","eduPersonScopedAffiliation")
$oidToRule.Add("urn:oid:1.3.6.1.4.1.5923.1.1.1.10","eduPersonTargetedID")
$oidToRule.Add("urn:oid:2.5.4.3","cn")
$oidToRule.Add("urn:oid:2.16.840.1.113730.3.1.241","displayName")
$oidToRule.Add("urn:oid:1.3.6.1.4.1.5923.1.1.1.7","eduPersonEntitlement")
$oidToRule.Add("urn:oid:1.3.6.1.4.1.5923.1.1.1.6","eduPersonPrincipalName")
$oidToRule.Add("urn:oid:2.5.4.42","givenName")
$oidToRule.Add("urn:oid:0.9.2342.19200300.100.1.3","mail")
$oidToRule.Add("urn:oid:1.3.6.1.4.1.25178.1.2.9","schacHomeOrganization")
$oidToRule.Add("urn:oid:1.3.6.1.4.1.25178.1.2.10","schacHomeOrganizationType")
$oidToRule.Add("urn:oid:2.5.4.4","sn")
#$oidToRule.Add("urn:oid:0.9.2342.19200300.100.1.41","mobile")

$trueRequestedAttribute = @()
$trueRequestedAttribute = $RequestedAttribute | ? {$_.isRequired -eq "true"}

Write-ADFSTkVerboseLog "--------------- Attributi: $($RequestedAttribute.Count)  Richiesti: $($trueRequestedAttribute.Count)"

if ($trueRequestedAttribute)
{
    foreach ($ra in $trueRequestedAttribute) {
        if ($oidToRule.ContainsKey($ra.Name)) {
            $ruleName = $oidToRule.($ra.Name)
            if ($IssuanceTransformRules.($ruleName) -eq $null) {
                #Write-ADFSTkLog "--------------- $ruleName Non è inserito"
                if ($AllTransformRules.($ruleName) -ne $null) { 
                    #Write-ADFSTkLog "--------------- $ruleName è in AllTransformRules "
                    $IssuanceTransformRules[$ruleName] = $AllTransformRules.$ruleName.Rule.Replace("[ReplaceWithSPNameQualifier]",$EntityId)
                    foreach ($Attribute in $AllTransformRules.$ruleName.Attribute) { $AttributesFromStore[$Attribute] = $AllAttributes[$Attribute] }
                    Write-ADFSTkVerboseLog "--------------- $ruleName Aggiunto"
                }
                else {Write-ADFSTkLog "--------------- ERRORE!! $ruleName non in AllTransformRules non posso fare niente"}
            }
            else {Write-ADFSTkVerboseLog "--------------- $ruleName Già inserito"}
        }
        else {Write-ADFSTkLog "--------------- ERRORE!! $($ra.Name) Attributo sconosciuto!!!"}

        
    }
}

### MOD IDEM  End ###







### This is a good place to remove attributes that shouldn't be sent outside a RegistrationAuthority
$removeRules = @()
foreach ($rule in $IssuanceTransformRules.Keys)
{
    $attribute = $Settings.configuration.storeConfig.attributes.attribute | ? name -eq $rule
    if ($attribute -ne $null -and $attribute.allowedRegistrationAuthorities -ne $null)
    {
        $allowedRegistrationAuthorities = @()
        $allowedRegistrationAuthorities += $attribute.allowedRegistrationAuthorities.registrationAuthority
        if ($allowedRegistrationAuthorities.count -gt 0 -and !$allowedRegistrationAuthorities.contains($RegistrationAuthority))
        {
            $removeRules += $rule
        }
    }
}

$removeRules | % {$IssuanceTransformRules.Remove($_)}

###

#region Create Stores
if ($AttributesFromStore.Count)
{
    $FirstRule = ""
    foreach ($store in ($Settings.configuration.storeConfig.stores.store | sort order))
    {
        #region Active Directory Store
        if ($store.name -eq "Active Directory")
        {
            $currentStoreAttributes = $AttributesFromStore.Values | ? store -eq $store.name
            if ($currentStoreAttributes.Count -gt 0)
            {
                $FirstRule += @"

                @RuleName = "Retrieve Attributes from AD"
                c:[Type == "$($store.type)", Issuer == "$($store.issuer)"]
                => add(store = "$($store.name)", 
                types = ("$($currentStoreAttributes.type -join '","')"), 
                query = ";$($currentStoreAttributes.name -join ',');{0}", param = c.Value);

"@
            }
        }
        #endregion

        #region SQL Store

        #endregion

        #region LDAP Store

        #endregion

        #region Custom Store
        if ($store.name -eq "Custom Store")
        {
            $currentStoreAttributes = $AttributesFromStore.Values | ? store -eq $store.name
            if ($currentStoreAttributes -ne $null)
            {
                $FirstRule += @"

                @RuleName = "Retrieve Attributes from Custom Store"
                c:[Type == "$($store.type)", Issuer == "$($store.issuer)"]
                => add(store = "$($store.name)", 
                types = ("$($currentStoreAttributes.type -join '","')"), 
                query = ";$($currentStoreAttributes.name -join ',');{0}", param = "[ReplaceWithSPNameQualifier]", param = c.Value);

"@
            }
        }
        #endregion
    }

    $IssuanceTransformRules.insert(0,"FirstRule",$FirstRule.Replace("[ReplaceWithSPNameQualifier]",$EntityId))
    
}

return $IssuanceTransformRules

#endregion
}