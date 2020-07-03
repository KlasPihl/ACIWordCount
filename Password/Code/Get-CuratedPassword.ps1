<#
.SYNOPSIS
    Creates randowm password of special characters, letters and numbers in defined compinations
.DESCRIPTION
    Uses chars and special characters that is easy readable for human
.EXAMPLE
    PS C:\> .\Get-CuratedPassword.ps1  -PasswordLength 4 -PasswordPattern @("nn,nn,ss,lc,lc,lc,uc")
    Created as 4 char long password containing numbers, lower case, uppercase and numbers.
.PARAMETER  PasswordPattern
    PasswordPattern of chars in password separated by ','. If Pattern is shorter then requested password length the pattern is looped until password length is met.
    Valid patterns;
        nn - numbers
        ss - special chars
        lv - lower case vowel
        uv - upper case vowel
        lc - lower case consonant
        uc - upper case consonant
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
    $PasswordPattern = @("nn,nn,ss,lc,lc,lc,uc,uc,uv,lc,lc,ss,uc,uc,uc,uc", "ss,uc,uc,uc,lc,lc,lc,lc,uv,ss,nn,nn,uc,uc,uc,uc", "ss,uc,uc,uc,lc,lc,uv,uc,uc,ss,nn,nn,uc,uc,uc,uc"),
    [int]$PasswordLength = 16
)
Try {
    if($PasswordPattern.count -gt 1) {
        $PasswordPattern = (Get-Random $PasswordPattern).split(',')
    } else {
        $PasswordPattern = $PasswordPattern.split(',')
    }
    Write-Verbose "Pasword pattern: $PasswordPattern"
    Write-Verbose "Password length: $PasswordLength"
    #region definition of chars
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
        #endregion definition of chars




    #region Validete and ad pattern to reach requested password length
    if($PasswordPattern.count -lt $PasswordLength) {
        $MissingChars =  $PasswordLength - $PasswordPattern.count
        Write-Verbose "Specified pattern do not met Password length of $PasswordLength chars, add $MissingChars char combinations from pattern"
        do {
            $i++
            Write-Debug "Loop $i of adding pattern to fulfill password length"
            $PasswordPattern += $PasswordPattern | Select-Object -First $MissingChars
        } until ($PasswordPattern.count -ge $PasswordLength)
    }
        #endregion Validete and ad pattern to reach requested password length
    Write-Debug "Contruction password"
    $PWOutput = $PasswordPattern | Select-Object -First $PasswordLength | ForEach-Object {
        switch ($psitem) {
            'nn' {Get-Random -InputObject $NumbersArray -Count 1}
            'ss' {Get-Random -InputObject $SymbolsArray -Count 1}
            'lv' {Get-Random -InputObject $LowerCaseVowelArray -Count 1}
            'uv' {Get-Random -InputObject $UpperCaseVowelArray -Count 1}
            'lc' {Get-Random -InputObject $LowerCaseConsonantArray -Count 1}
            'uc' {Get-Random -InputObject $UpperCaseConsonantArray -Count 1}
            Default {Write-Error "$psitem not a valid pattern"}
        }
    }
} Catch {
    Write-Error "Can not create password"
    exit 1
}

Write-Output ($PWOutput  -join '')
