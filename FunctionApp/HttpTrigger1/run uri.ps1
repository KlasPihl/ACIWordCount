using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

# Interact with query parameters or the body of the request.
$name = $Request.Query.NumberWords
Write-Host "Body: $($Request.Body | out-string)"

Write-Host "Query: $($Request.query | out-string)"

write-host "Trigger $($TriggerMetadata.Keys | out-string)"

write-host $TriggerMetadata.NumberWords
$NumberWords=$TriggerMetadata.NumberWords

if (-not $name) {
    $name = $Request.Body.Name
}
<#
switch ($Request.Body) {
    condition {  }
    Default {}
}
#>
if ($name) {
    $status = [HttpStatusCode]::OK
    $body = "Hello $name"
    #region wordcount
$uri = if($TriggerMetadata.uri) {
    $TriggerMetadata.uri
} else {
    'http://shakespeare.mit.edu/romeo_juliet/full.html'
}

$NumberWords = if($TriggerMetadata.NumberWords) {
    $TriggerMetadata.NumberWords
} else {
    10
}
$MinimumLength = if($TriggerMetadata.MinimumLength) {
    $TriggerMetadata.MinimumLength
} else {
    5
}
Write-Host $uri
Write-Host $NumberWords
Write-Host $MinimumLength
function Convert-HtmlToText {
    #stolen from http://winstonfassett.com/blog/2010/09/21/html-to-text-conversion-in-powershell/
    param([System.String] $html)

    # remove line breaks, replace with spaces
    $html = $html -replace "(`r|`n|`t)", " "
    # write-verbose "removed line breaks: `n`n$html`n"

    # remove invisible content
    @('head', 'style', 'script', 'object', 'embed', 'applet', 'noframes', 'noscript', 'noembed') | % {
     $html = $html -replace "<$_[^>]*?>.*?</$_>", ""
    }
    # write-verbose "removed invisible blocks: `n`n$html`n"

    # Condense extra whitespace
    $html = $html -replace "( )+", " "
    # write-verbose "condensed whitespace: `n`n$html`n"

    # Add line breaks
    @('div','p','blockquote','h[1-9]') | % { $html = $html -replace "</?$_[^>]*?>.*?</$_>", ("`n" + '$0' )}
    # Add line breaks for self-closing tags
    @('div','p','blockquote','h[1-9]','br') | % { $html = $html -replace "<$_[^>]*?/>", ('$0' + "`n")}
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
    ) | % { $html = $html -replace $_[0], $_[1] }
    # write-verbose "replaced entities: `n`n$html`n"

    return $html

   }


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
    $body = "Please pass a name on the query string or in the request body."
}







# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = $status
    Body = $body
    #Body = $Request.Body
})
