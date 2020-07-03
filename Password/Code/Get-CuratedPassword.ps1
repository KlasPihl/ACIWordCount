<#
.SYNOPSIS
    Creates randowm password of special characters, letters and numbers in defined compinations
.DESCRIPTION
    Uses chars and special characters that is easy readable for human
.EXAMPLE
    PS C:\> Get-CuratedPassword -Combination nn,lc,uc,nn -PasswordLength 8
    Created as 8 char long password containing numbers, lower case, uppercase and numbers.
.PARAMETER  Combination
    Combination of chars in password
.PARAMETER  PasswordLength
    Requested total length of password


.OUTPUTS
    Password string
.NOTES
    Version 1 by Alexander.Bertz@Atea.se, tweaked by Klas.Pihl@Atea.se
#>
[CmdletBinding()]
param (
    [Parameter()]
    $Combination = @("nn,nn,ss,lc,lc,lc,uc,uc,uv,lc,lc,ss,uc,uc,uc,uc", "ss,uc,uc,uc,lc,lc,lc,lc,uv,ss,nn,nn,uc,uc,uc,uc", "ss,uc,uc,uc,lc,lc,uv,uc,uc,ss,nn,nn,uc,uc,uc,uc"),
    $PasswordLength = 16
)

# Symbols
$SymbolsArray = @()
33, 35, 36, 37, 38, 40, 41, 47 | ForEach-Object { $SymbolsArray += [char][byte]$_ }

# Lower case
$LowerCaseArray = @()
97..122 | ForEach-Object { $LowerCaseArray += [char][byte]$_ }

# Upper case
$UpperCaseArray = @()
65..90 | ForEach-Object { $UpperCaseArray += $_ }

# Lower case vowel. letter o is removed
$LowerCaseVowelArray = @()
97, 101, 105, 117, 121 | ForEach-Object { $LowerCaseVowelArray += [char][byte]$_ }

# Lower case consonant
$LowerCaseConsonantArray = @()
98, 99, 100, 102, 103, 104, 106, 107, 108, 109, 110, 112, 113, 114, 115, 116, 118, 119, 120, 122 | ForEach-Object { $LowerCaseConsonantArray += [char][byte]$_ }

# Upper case vowel
$UpperCaseVowelArray = @()
65, 69, 73, 85, 89 | ForEach-Object { $UpperCaseVowelArray += [char][byte]$_ }

# Upper case consonant
$UpperCaseConsonantArray = @()
66, 67, 68, 70, 71, 72, 74, 75, 76, 77, 78, 80, 81, 82, 83, 84, 86, 87, 88, 90 | ForEach-Object { $UpperCaseConsonantArray += [char][byte]$_ }

# Numbers
$NumbersArray = @()
48..57 | ForEach-Object { $NumbersArray += [char][byte]$_ }



$UseCombination = Get-Random $Combination

$PWOutput = $null

#$UseCombination.split(',').count

$UseCombination.split(',') | Select-Object -First $PasswordLength | ForEach-Object {

    if ($_ -eq 'nn') {
        $PWOutput += Get-Random -InputObject $NumbersArray -Count 1
    } elseif ($_ -eq 'ss') {
        $PWOutput += Get-Random -InputObject $SymbolsArray -Count 1
    } elseif ($_ -eq 'lv') {
        $PWOutput += Get-Random -InputObject $LowerCaseVowelArray -Count 1
    } elseif ($_ -eq 'uv') {
        $PWOutput += Get-Random -InputObject $UpperCaseVowelArray -Count 1
    } elseif ($_ -eq 'lc') {
        $PWOutput += Get-Random -InputObject $LowerCaseConsonantArray -Count 1
    } elseif ($_ -eq 'uc') {
        $PWOutput += Get-Random -InputObject $UpperCaseConsonantArray -Count 1
    } else {

    }
}
Write-Output $PWOutput
