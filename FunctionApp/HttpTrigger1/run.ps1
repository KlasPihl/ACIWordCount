using namespace System.Net
<#
.SYNOPSIS
    Converts text on web page and returns the n number of most common words with a minimum length of y
.DESCRIPTION
    Build for Azure function app.  At least one parameter must be defined.
.EXAMPLE
    PS C:\> Invoke-RestMethod -Method Post -Uri 'http://uri:7071/api/HttpTrigger1'-Body '{"MinimumLength":7}'  | Select-Object SelectionCriteria

    PS C:\> Invoke-RestMethod -Method Post -Uri 'http://localhost:7071/api/HttpTrigger1' `
        -Body '{"uri":"https://docs.microsoft.com/en-us/dotnet/api/system.net.httpstatuscode?view=netcore-3.1"}' |
        Select-Object -ExpandProperty Data
.PARAMETER uri
    URI of source text, can be formatted plain or in html
.PARAMETER NumberWords
    Number of words to return
.PARAMETER MinimumLength
    Minimal length of words to be in scope.
.OUTPUTS
    json formatted table with source, arguments and result in table
.NOTES
    2020-06-19 Versio 1 Klas.Pihl@gmail.com
        Test project to use Azure function app and ACI
        A windows native rewrite of https://github.com/seanmck/aci-wordcount
#>
# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)
function Convert-HtmlToText {
    #stolen from http://winstonfassett.com/blog/2010/09/21/html-to-text-conversion-in-powershell/
    param([System.String] $html)

    # remove line breaks, replace with spaces
    $html = $html -replace "(`r|`n|`t)", " "
    # write-verbose "removed line breaks: `n`n$html`n"

    # remove invisible content
    @('head', 'style', 'script', 'object', 'embed', 'applet', 'noframes', 'noscript', 'noembed') | ForEach-Object {
     $html = $html -replace "<$_[^>]*?>.*?</$_>", ""
    }
    # write-verbose "removed invisible blocks: `n`n$html`n"

    # Condense extra whitespace
    $html = $html -replace "( )+", " "
    # write-verbose "condensed whitespace: `n`n$html`n"

    # Add line breaks
    @('div','p','blockquote','h[1-9]') | ForEach-Object { $html = $html -replace "</?$_[^>]*?>.*?</$_>", ("`n" + '$0' )}
    # Add line breaks for self-closing tags
    @('div','p','blockquote','h[1-9]','br') | ForEach-Object { $html = $html -replace "<$_[^>]*?/>", ('$0' + "`n")}
    # write-verbose "added line breaks: `n`n$html`n"

    #strip tags
    $html = $html -replace "<[^>]*?>", ""
    # write-verbose "removed tags: `n`n$html`n"

    # replace common entities
    @(
     @("&amp;bull;", " * "),
     @("&amp;lsaquo;", "<"),
     @("&amp;rsaquo;", ">"),
     @("&amp;(rsquo|lsquo);", "'"),
     @("&amp;(quot|ldquo|rdquo);", '"'),
     @("&amp;trade;", "(tm)"),
     @("&amp;frasl;", "/"),
     @("&amp;(quot|#34|#034|#x22);", '"'),
     @('&amp;(amp|#38|#038|#x26);', "&amp;"),
     @("&amp;(lt|#60|#060|#x3c);", "<"),
     @("&amp;(gt|#62|#062|#x3e);", ">"),
     @('&amp;(copy|#169);', "(c)"),
     @("&amp;(reg|#174);", "(r)"),
     @("&amp;nbsp;", " "),
     @("&amp;(.{2,6});", "")
    ) | ForEach-Object { $html = $html -replace $_[0], $_[1] }
    # write-verbose "replaced entities: `n`n$html`n"

    return $html

   }
# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Interact with query parameters or the body of the request.
$InputData = $Request.RawBody | ConvertFrom-Json


if ($InputData) {
    $status = [HttpStatusCode]::OK
    #region wordcount
$uri = if($InputData.uri) {
    $InputData.uri
} else {
    'http://shakespeare.mit.edu/romeo_juliet/full.html'
    Write-Warning "Parameter uri not defined, using default 'http://shakespeare.mit.edu/romeo_juliet/full.html'"

}

$NumberWords = if($InputData.NumberWords) {
    $InputData.NumberWords
} else {
    10
    Write-Warning "Parameter NumberWords not defined, using default value of 10"
}
$MinimumLength = if($InputData.MinimumLength) {
    $InputData.MinimumLength
} else {
    5
    Write-Warning "Parameter MinimumLength not defined, using default value of 5"

}
Write-Debug $uri
Write-Debug $NumberWords
Write-Debug $MinimumLength



try {
    Write-Verbose "Loading data from $uri"
    $WordDef = '^[a-z]+' #'[^A-Za-z0-9]+" "'
    $HTMLBody = Invoke-WebRequest $uri -UseBasicParsing

    Write-Verbose "Converting HTML result to text"
    $Text = Convert-HtmlToText -html $HTMLBody

    Write-Verbose "Filter words of desired length of $minimumlength chars"
    $Words = $Text -split ' ' | ForEach-Object {
        ($PSItem | select-string -pattern $WordDef).matches.value | Where-Object {
            $psitem.length -ge $MinimumLength
        }
    }
    Write-Verbose "Found $($Words.count) number of words, start grouping"
    $GroupedWords = $Words | Group-Object | Sort-Object Count -Descending | Select-Object -First $NumberWords Count,Name

    Write-Verbose "Constructing output"
    $OutputJason = [PSCustomObject]@{
        Source = $uri
        Data = $GroupedWords
        SelectionCriteria = [PSCustomObject]@{
            NumberWords = $NumberWords
            MinimumLength = $MinimumLength

        }
    } | ConvertTo-Json

    $body =  $OutputJason




} catch {
    Write-Error "Can not get text from $uri"
    Write-output $error.Exception
    exit 1
}

#endregion wordcount
} else {
    $status = [HttpStatusCode]::BadRequest
    $body = 'Request body missing arguments, use -Body "{"uri":"http://shakespeare.mit.edu/romeo_juliet/full.html"}'
}







# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $status
    Body = $body
    #Body = $Request.Body
})
