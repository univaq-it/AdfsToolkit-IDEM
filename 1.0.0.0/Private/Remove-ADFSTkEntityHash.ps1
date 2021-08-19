function Remove-ADFSTkEntityHash {
param (
    [Parameter(Mandatory=$true, Position=0)]
    $EntityID
)
    if ($SPHashList.ContainsKey($EntityID))
    {
        $SPHashList.Remove($EntityID)
        $SPHashList | Export-Clixml $SPHashFile
    }
}