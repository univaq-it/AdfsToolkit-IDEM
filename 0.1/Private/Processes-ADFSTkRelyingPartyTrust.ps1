function Processes-ADFSTkRelyingPartyTrust {
param (
    $sp
)

    $adfsSP = Get-ADFSRelyingPartyTrust -Identifier $sp.EntityID

    if ($adfsSP -eq $null)
    {
        Write-ADFSTkVerboseLog "'$($sp.EntityID)' not in ADFS database."
        Add-ADFSTkSPRelyingPartyTrust $sp
    }
    else
    {
        $toUpdate = $false
        #$Name = (Split-Path $sp.entityID -NoQualifier).TrimStart('/') -split '/' | select -First 1
        if ($adfsSP.Name.StartsWith($Settings.configuration.MetadataPrefix + $Settings.configuration.MetadataPrefixSeparator)) {
            Write-ADFSTkLog "'$($sp.EntityID)' in ADFS database and internal managed: updating..."
            $toUpdate = $true
        }
        elseif ($ForceUpdate) {
            Write-ADFSTkLog "'$($sp.EntityID)' in ADFS database, forcing update due to -ForceUpdate switch..."
            $toUpdate = $true
        }
        else {
            Write-ADFSTkLog "'$($sp.EntityID)' in ADFS database and NOT internal managed: skipping update..."
            $toUpdate = $false
        }

        if ($toUpdate) {
            Write-ADFSTkVerboseLog "Deleting '$($sp.EntityID)'..."
            try
            {
                Remove-ADFSRelyingPartyTrust -TargetIdentifier $sp.EntityID -Confirm:$false -ErrorAction Stop
                Write-ADFSTkVerboseLog "Deleting $($sp.EntityID) done!"
                Add-ADFSTkSPRelyingPartyTrust $sp
            }
            catch
            {
                Write-ADFSTkLog "Could not delete '$($sp.EntityID)'... Error: $_" -EntryType Error
            }
        }
        
    }
}
