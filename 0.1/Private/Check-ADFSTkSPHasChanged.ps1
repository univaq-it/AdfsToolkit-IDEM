function Check-ADFSTkSPHasChanged {
param (
    [Parameter(Mandatory=$true, Position=0)]
    $SP
)
 
    #Try to get the cached Entity
    try
    {
        if ($SPHashList.ContainsKey($SP.EntityID))
        {
            $currentSPHash = [System.BitConverter]::ToString($md5.ComputeHash($utf8.GetBytes($SP.InnerXML)))
            return $currentSPHash -ne $SPHashList.($SP.EntityID)
        }
        else
        {
            return $true #Can't find the cached entity so it has changed
        }
    }
    catch
    {
        Write-ADFSTkVerboseLog "Could not get cached entity or compute the hash for it..."
    }
    
}