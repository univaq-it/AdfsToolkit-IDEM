<#
.Synopsis
   Compares two sets extremely fast
.DESCRIPTION
   Compares two sets extremely fast.
   The sets can be string arrays or an AD Group Object
.EXAMPLE
   $a = 1..100000
   $b=20000...50000
   Compare-ADFSTkObject $a $b -CompareType InFirstSetOnly

Name                           Value                                                                                                                                                                                         
----                           -----                                                                                                                                                                                         
MembersInFirstSet              100000                                                                                                                                                                                        
MembersInSecondSet             20001                                                                                                                                                                                         
MembersInCompareSet            80000                                                                                                                                                                                         
CompareType                    InFirstSetOnly                                                                                                                                                                                
CompareSet                     {20001, 20002, 20003, 20004...}                                                                                                                                                               

.EXAMPLE
   $a = 1..100000
   $b=20000...50000
   Compare-ADFSTkObject $a $b -CompareType InFirstSetOnly -Raw
   20001
   20002
   20003
   .
   .
   .
#>
function Compare-ADFSTkObject {
param (        
    [Parameter(Mandatory=$true,
                Position=0)]
                [AllowEmptyCollection()]
    #The first set to compare
    $FirstSet =@(),
    [Parameter(Mandatory=$true,
                Position=1)]
                [AllowEmptyCollection()]
    #The second set to compare
    $SecondSet =@(),
    [Parameter(Mandatory=$true,
                Position=2)]
    [ValidateSet("InFirstSetOnly","InSecondSetOnly","Union","Intersection","AddRemove")]
    $CompareType,
    [switch]$Raw
)

        
    if ($FirstSet -isnot [string[]] -and $FirstSet -isnot [int[]])
    {
        if ("Microsoft.ActiveDirectory.Management.ADGroup" -as [type] -and $FirstSet -is [Microsoft.ActiveDirectory.Management.ADGroup])
        {
            if (($FirstSet | Get-Member -MemberType Property | ? Name -eq Members) -ne $null)
            {
                $FirstSet = $FirstSet.Members.Value
            }
            else
            { 
                $FirstSet = Get-ADGroup $FirstSet.distinguishedName -Properties Members | Select -ExpandProperty members
            }
        }
    }

    if ($SecondSet -isnot [string[]] -and $SecondSet -isnot [int[]])
    {
        if ("Microsoft.ActiveDirectory.Management.ADGroup" -as [type] -and $SecondSet -is [Microsoft.ActiveDirectory.Management.ADGroup])
        {
            if (($SecondSet | Get-Member -MemberType Property | ? Name -eq Members) -ne $null)
            {
                $SecondSet = $SecondSet.Members.Value
            }
            else
            { 
                $SecondSet = Get-ADGroup $SecondSet.distinguishedName -Properties Members | Select -ExpandProperty members
            }
        }
    }
    
   if (([string]::IsNullOrEmpty($FirstSet) -or $FirstSet[0] -is [String] -or $FirstSet[0] -is [Char]) -and ([string]::IsNullOrEmpty($SecondSet) -or $SecondSet[0] -is [String] -or $SecondSet[0] -is [Char]))
    {
        [System.Collections.Generic.HashSet[String]]$FirstHashSet = $FirstSet
        [System.Collections.Generic.HashSet[String]]$SecondHashSet = $SecondSet
    }
    elseif ($FirstSet[0] -is [Int] -or $SecondSet[0] -is [Int])
    {
        [System.Collections.Generic.HashSet[Int]]$FirstHashSet = $FirstSet
        [System.Collections.Generic.HashSet[Int]]$SecondHashSet = $SecondSet
    }
    else
    {
        throw "Invalid types of object in set! Valid objects are String, Int"
    }

    if (!$Raw) 
    {
        $Info = [ordered]@{
            MembersInFirstSet = $FirstSet.Count
            MembersInSecondSet = $SecondSet.Count
            MembersInCompareset = 0
            CompareType = $CompareType
        }
    }


    switch ($CompareType)
    {
        'InFirstSetOnly' {
            if ([string]::IsNullOrEmpty($FirstHashSet)) {
                $FirstHashSet = $SecondHashSet
            }
            else {
                $FirstHashSet.ExceptWith($SecondHashSet)
            }

            if ($Raw) {
                $FirstHashSet
            }
            else {
                $Info.MembersInCompareSet = $FirstHashSet.Count
                $Info.CompareSet = $FirstHashSet
            }
        }
        'InSecondSetOnly' {
            if ([string]::IsNullOrEmpty($SecondHashSet)) {
                $SecondHashSet = $FirstHashSet
            }
            else {
                $SecondHashSet.ExceptWith($FirstHashSet)
            }

            if ($Raw) {
                $SecondHashSet
            }
            else {
                $Info.MembersInCompareSet = $SecondHashSet.Count
                $Info.CompareSet = $SecondHashSet
            }
        }
        'Union' {

            if ([string]::IsNullOrEmpty($FirstHashSet)) {
                $FirstHashSet = $SecondHashSet
            }
            elseif ([string]::IsNullOrEmpty($SecondHashSet)) {
                $FirstHashSet = @()
            }
            else {
                $FirstHashSet.UnionWith($SecondHashSet)
            }
            

            if ($Raw) {
                $FirstHashSet
            }
            else {
                $Info.MembersInCompareSet = $FirstHashSet.Count
                $Info.CompareSet = $FirstHashSet
            }
        }
        'Intersection' {
            
            if ([string]::IsNullOrEmpty($FirstHashSet)) {
                $FirstHashSet = @()
            }
            elseif ([string]::IsNullOrEmpty($SecondHashSet)) {
                $FirstHashSet = @()
            }
            else {
                $FirstHashSet.IntersectWith($SecondHashSet)
            }

            
            if ($Raw) {
                $FirstHashSet
            }
            else {
                $Info.MembersInCompareSet = $FirstHashSet.Count
                $Info.CompareSet = $FirstHashSet
            }
        }
        'AddRemove' {
            if ($FirstHashSet -is [System.Collections.Generic.HashSet[String]]) {
                $RemoveHashSet = [System.Collections.Generic.HashSet[String]]$FirstSet
                $AddHashSet = [System.Collections.Generic.HashSet[String]]$SecondSet
            }
            elseif ($FirstHashSet -is [System.Collections.Generic.HashSet[Int]]) {
                $RemoveHashSet = [System.Collections.Generic.HashSet[Int]]$FirstSet
                $AddHashSet = [System.Collections.Generic.HashSet[Int]]$SecondSet
            }

            if ([string]::IsNullOrEmpty($FirstHashSet)) {
                $AddHashSet = $SecondHashSet
                $RemoveHashSet = @()
            }
            elseif ([string]::IsNullOrEmpty($SecondHashSet)) {
                $AddHashSet = @()
                $RemoveHashSet = $FirstHashSet
            }
            else {
                $RemoveHashSet.ExceptWith($SecondHashSet)
                $AddHashSet.ExceptWith($FirstHashSet)
            }
            
            

            if ($Raw) {
                @{
                    Add = $AddHashSet
                    Remove = $RemoveHashSet
                }
            }
            else {
                $Info.RemoveSet = $RemoveHashSet
                $Info.MembersInRemoveSet = $RemoveHashSet.Count
                $Info.AddSet = $AddHashSet
                $Info.MembersInAddSet = $AddHashSet.Count
            }
        }
    }

    if (!$Raw) 
    {
        $Info
    }
}
# SIG # Begin signature block
# MIIYUAYJKoZIhvcNAQcCoIIYQTCCGD0CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUntnU0yQAWeRCF0t2kqf3Rrnd
# 9E6gghKwMIIEFDCCAvygAwIBAgILBAAAAAABL07hUtcwDQYJKoZIhvcNAQEFBQAw
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
# AYI3AgEVMCMGCSqGSIb3DQEJBDEWBBR9UYL8gNvZochTGYXozz3YfIQb0zANBgkq
# hkiG9w0BAQEFAASCAQCGGkIsWpB3CzzJM/n1lk7FCds5G3DKQvPNNJspSXYw6GUQ
# qS3Oxgr01y0sIkBj0ehZodtcYvfMppJSRNOGOGUdQsnXsePwDpKnmTycZ0+11Mrh
# j6G2/KQCKiHUG6gzgz0aATlYZ8mS0f85Ukye6BfKbTFIruX43mdUbHPnsAn2WWQz
# ErFa2UJhwiTykJ3Z63d44tD1pAgmW6vXqhbc0o9iELS/SQLX874CyzhPZKzUqbt1
# 7G9Xg+7sP159JQp+fCMXOQH6ZjZFyz8N1Wy2AqTtAtselWzjyRr2hFdncYHsIjtf
# AJZBvNPDJG0DwR0xguyKRZ9tjZm97cg/oBkrQtl6oYICojCCAp4GCSqGSIb3DQEJ
# BjGCAo8wggKLAgEBMGgwUjELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNp
# Z24gbnYtc2ExKDAmBgNVBAMTH0dsb2JhbFNpZ24gVGltZXN0YW1waW5nIENBIC0g
# RzICEhEh1pmnZJc+8fhCfukZzFNBFDAJBgUrDgMCGgUAoIH9MBgGCSqGSIb3DQEJ
# AzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTE4MDQxODE2NDkwNlowIwYJ
# KoZIhvcNAQkEMRYEFLxFlEhCuIC3sJEfyyJdRsQmhzfiMIGdBgsqhkiG9w0BCRAC
# DDGBjTCBijCBhzCBhAQUY7gvq2H1g5CWlQULACScUCkz7HkwbDBWpFQwUjELMAkG
# A1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExKDAmBgNVBAMTH0ds
# b2JhbFNpZ24gVGltZXN0YW1waW5nIENBIC0gRzICEhEh1pmnZJc+8fhCfukZzFNB
# FDANBgkqhkiG9w0BAQEFAASCAQB/E+0WmfvFMuHWCuJRB+Dmd1DkSpnBzCP5fxXM
# /0PhtmVmvE1qNnZv9/ydLAlbs7n8fgvOFpWEx1rgTaRZls3AliF/2zLgyzl0BL3E
# +SAVcyxxyVUk5q2+QskUaz+rCVVshONuLk7ULoudvQDFlLyh4/p4eH6XlCjjWT2/
# 3kp4ummFyUq0hVfXA0x/OqkJzwNT1foGbg+BAvoOqhMlOTpykMw6s1ysOGivdaBm
# zzr6u7MSq/XxWkPJ+E8Qa0O0gHH+spzDpG3ZoZ4OrGqAenzicnhyb8oGADqdB1iC
# Sf6DrtZfJGe9KFBr9y9XsCUFGLYyVlrNZAExrRuihAcMf2FM
# SIG # End signature block
