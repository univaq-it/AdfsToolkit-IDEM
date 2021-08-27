#========================================================================== 
# NAME: Split-Collection.ps1
#
# DESCRIPTION: Splits a collection into smaller collections
#
# 
# AUTHOR: Johan Peterson (adm)
# DATE  : 2014-06-02
#
# PUBLISH LOCATION: C:\Published Powershell Scripts\Functions
#
#=========================================================================
#  Version     Date      	Author              	Note 
#  ----------------------------------------------------------------- 
#   1.0        2014-06-02	Johan Peterson (adm)	Initial Release
#   1.1        2015-02-16	Johan Peterson (adm)	First Publish
#=========================================================================

<#
.Synopsis
   Splits a collection into smaller collections
.DESCRIPTION
   Use this cmdlet to cut down a collection into smaller chunks and process them one at the time.
   Can be used to add lots of users in a group
.EXAMPLE
   PS C:\> Split-Collection -Collection (1..50) -Count 5 | % {$_ -join ','}
.EXAMPLE
   PS C:\> $AllUsers = Get-ADUser -Filter *
   PS C:\> Split-Collection -Collection $AllUsers -Count 500 | % {Add-ADGroupMember AllUsersGroup -Members $_}
#>


function Split-Collection {
[CmdletBinding()]
param (
    [Parameter(Mandatory=$true,
                Position=0)] 
    #The collection to be splitted (ex. 1..100)
    $Collection,
    [Parameter(Mandatory=$true,
                Position=11)] 
    [int]
    #The number of items in each new collection chunk (ex. -Collection (1..10) -Number 3 ==> (1..3) (4..6) (7..9) (10))
    $Count
)
    , @($Collection | Select -First $Count)
    
    if ($Collection.Count -gt $Count)
    {
        Split-Collection -Collection ($Collection | Select -Last ($Collection.Count-$Count)) -Count $Count
    }
}