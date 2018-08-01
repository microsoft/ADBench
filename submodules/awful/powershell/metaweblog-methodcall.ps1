param($endPoint, $methodName)

$postTemplate = @"
<methodCall> 
  <methodName>metaWeblog.$methodName</methodName> 
    <params> 
"@
foreach ($a in $args) {
 $postTemplate += "<param> <value>$a</value> </param> ";
}
 $postTemplate += @"
    </params> 
</methodCall> 
"@ 

$wc = new-object System.Net.WebClient
$result = $wc.UploadString($endPoint, $postTemplate) 

if ($result -eq '') {
  throw "No response from server [$endPoint]"
}

## Perform the actual post to the server, and transform the response to 
## XML 
$results = [xml] $result

$results
