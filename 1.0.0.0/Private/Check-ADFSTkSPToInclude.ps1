function Check-ADFSTkSPToInclude {
param (
    [Parameter(Mandatory=$true, Position=0)]
    $entityID
)
    
    if ($Settings.configuration.SPToExclude -ne $null -and $Settings.configuration.SPToExclude.entityID.Contains($entityID)) {
        # SP Excluded
        return $false
    }

    if ($Settings.configuration.SPToInclude -ne $null) {
        if ($Settings.configuration.SPToInclude.entityID.Contains($entityID)) {
            # SP Included
            return $true
        }
        else {
            return $false
        }
    }

    return $true

}
