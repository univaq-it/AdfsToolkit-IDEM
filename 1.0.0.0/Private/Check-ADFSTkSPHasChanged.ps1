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
            $currentSPHash = [System.BitConverter]::ToString($md5.ComputeHash($utf8.GetBytes($SP)))
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
    
    #if (![string]::IsNullOrEmpty($SP))
    #{
    #    $currentSPHash = [System.BitConverter]::ToString($md5.ComputeHash($utf8.GetBytes($SP)))
    #}
    #
    #if ($SPHashList.ContainsKey($SP.EntityID))
    #{
    #    if ($currentSPHash -eq $SPHashList.($SP.EntityID))
    #    {
    #        return $false
    #    }
    #    else
    #    {
    #        Add-ADFSTkEntityHash $SP -spHash $currentSPHash
    #        return $true
    #    }
    #
    #    #return ($currentSPHash -ne $SPHash.($SP.EntityID))
    #}
    #else
    #{
    #    Add-ADFSTkEntityHash $SP -spHash $currentSPHash
    #    return $true #EntityID didn't exist ie it has changed
    #}
}

# SIG # Begin signature block
# MIIYUAYJKoZIhvcNAQcCoIIYQTCCGD0CAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUCy+58sbRbSAhtSXxA+Mh7dkD
# XU2gghKwMIIEFDCCAvygAwIBAgILBAAAAAABL07hUtcwDQYJKoZIhvcNAQEFBQAw
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
# AYI3AgEVMCMGCSqGSIb3DQEJBDEWBBSpOtNZgK9t8eufNUlX4nzxZv1JTzANBgkq
# hkiG9w0BAQEFAASCAQA5OiwPsNpeT4XdAHcDM+1+9rELJJ6hTb9A57HHpq4hZjgr
# 2mTyqh1PiJLj+xBjdvvL174eS8A7el4UpUSG0u1OE89J/kkBzPYMcvpjLUpXb7a+
# GJr1Xo3NaO3pDgvJ+FxGw6qH8B43RDyz+J+zGsO0UXiIko5xStlyoKyQiQ9ob0OY
# btHyA15tfsjfuankh7kqBXOfkVpWA6E6CFfWsecT25lDmEz4d56LJ4MMGXa6cMIj
# RZGbvgF3mfOKXVS283Qv++gz/J0HaCNEPxtoMpU+rBPjVr8LUrTXf5Il0CSwQ/j6
# mCNM01BZyMLjuxNHyYleINa4PovYSbTThSlwXv98oYICojCCAp4GCSqGSIb3DQEJ
# BjGCAo8wggKLAgEBMGgwUjELMAkGA1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNp
# Z24gbnYtc2ExKDAmBgNVBAMTH0dsb2JhbFNpZ24gVGltZXN0YW1waW5nIENBIC0g
# RzICEhEh1pmnZJc+8fhCfukZzFNBFDAJBgUrDgMCGgUAoIH9MBgGCSqGSIb3DQEJ
# AzELBgkqhkiG9w0BBwEwHAYJKoZIhvcNAQkFMQ8XDTE4MDQxODE2NDkwNVowIwYJ
# KoZIhvcNAQkEMRYEFFDa+Rmrp2vShAB7TWCn9px4hyKkMIGdBgsqhkiG9w0BCRAC
# DDGBjTCBijCBhzCBhAQUY7gvq2H1g5CWlQULACScUCkz7HkwbDBWpFQwUjELMAkG
# A1UEBhMCQkUxGTAXBgNVBAoTEEdsb2JhbFNpZ24gbnYtc2ExKDAmBgNVBAMTH0ds
# b2JhbFNpZ24gVGltZXN0YW1waW5nIENBIC0gRzICEhEh1pmnZJc+8fhCfukZzFNB
# FDANBgkqhkiG9w0BAQEFAASCAQAQ4vaLYiMBntM36gyXG4veFhmnUpgs/hos/bKc
# h16Rkn1CZulDRcYVg5J9z5OCFW9WEuUIJ58KFvJkeBNjM3VSG08Qp91v3gwC/07P
# bDuk9aeiHQLfwg2gtEtcISvTLxt8PXKNco8HCdZeV3R/2lUGtmWIWHOnAbh+193s
# XxLEji+K56pAB1L29746KUOGZBJW2IM9xQgLLNTsZqDvSh9zjpTccZUMiSx2ypWc
# VnS38YWHv+ITi+00JjahlalwPGWuTsiZBdZTY0lLnRYCwOJdYoE3nCa0ZbllpQXU
# NLeDnEZavh8RzLw18MzDcuIapv8WJNjqUPuTvoAkOg8U+YEs
# SIG # End signature block
