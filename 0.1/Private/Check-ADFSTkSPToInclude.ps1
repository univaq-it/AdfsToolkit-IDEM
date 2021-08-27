function Check-ADFSTkSPToInclude {
param (
    [Parameter(Mandatory=$true, Position=0)]
    $entityID
)
    
    if ($SPHashListToExclude.ContainsKey($entityID)) {
        Write-ADFSTkVerboseLog "SP $entityID in SPHashListToExclude: skipping..."
        return $false
    }

    if ($Settings.configuration.SPToExclude -ne $null -and $Settings.configuration.SPToExclude.entityID.Contains($entityID)) {
        # SP Excluded
        Write-ADFSTkVerboseLog "SP $entityID in Config/SPToExlude: skipping..."
        return $false
    }

    if ($Settings.configuration.SPToInclude -ne $null) {
        if ($Settings.configuration.SPToInclude.entityID.Contains($entityID)) {
            # SP Included
            Write-ADFSTkVerboseLog "SP $entityID in Config/SPToInclude: including..."
            return $true
        }
        else {
            Write-ADFSTkVerboseLog "SP $entityID NOT in Config/SPToInclude: skipping..."
            return $false
        }
    }

    return $true

}
