############################################################################## 
## 
## from http://www.leeholmes.com/blog/2006/05/05/blogging-from-powershell-editing-posts-with-the-metaweblog-api/
##
## Get-BlogPosts.ps1 
## 
## Get the posts to a blog that you own, using the MetaWeblog API 
## Returns a strongly-structured set of object that represent the 
## posts 
## 
## Example Usage: 
##   $endPoint = "http://www.yourblog.com/blogger.aspx" 
##   .\get-posts.ps1 $endPoint $null "username" "password" 3 | ft 
## 
############################################################################## 

param([string] $postUrl, [string] $blogid, [string] $username,  
      [string] $password, [int] $numberOfPosts) 


## Post template as required by the metaWeblog.getRecentPosts 
## call format 
$postTemplate = @" 
<methodCall> 
  <methodName>metaWeblog.getRecentPosts</methodName> 
    <params> 
      <param> 
        <value>$blogid</value> 
      </param> 
      <param> 
        <value>$username</value> 
      </param> 
      <param> 
        <value>$password</value> 
      </param> 
      <param> 
        <value><i4>$numberOfPosts</i4></value> 
      </param> 
    </params> 
</methodCall> 
"@ 

## Perform the actual post to the server, and transform the response to 
## XML 
$responseContent =  
   (new-object System.Net.WebClient).UploadString($postUrl, $postTemplate) 
$results = [xml] $responseContent 

write-host "RES=[$results]"

## Go through each of the items in the response to pick out the properties 
foreach($item in $results.methodResponse.params.param.value.array.data.value) 
{ 
   ## Prepare our synthetic object 
   $blogEntry = new-object System.Management.Automation.PSObject 

   ## Go through each of the properties in the current post 
   ## For each, compare its property name to one that we know.  From there, 
   ## convert the property value into as strongly-typed of a representation 
   ## we can muster 
   foreach($property in $item.struct.member) 
   { 
      $propertyName = $property.name 
      $propertyValue = $property.value 

      switch($propertyName) 
      { 
         ## The date the post was created.  Uses ISO8601, which is not 
         ## natively supported in .Net.  Returned as a [DateTime] 
         "dateCreated"  
         {  
            $propertyValue =  
               [DateTime]::ParseExact($property.value."dateTime.iso8601", ` 
                  "yyyyMMddTHH:mm:ss", ` 
                  [System.Globalization.CultureInfo]::InvariantCulture) 
            break 
         } 
          
         ## Pull the simple description (content of the post) 
         "description" { $propertyValue = $property.value.string; break } 
          
         ## Pull the title of the post 
         "title" { $propertyValue = $property.value.string; break } 

         ## Pull the categories of the post.  Returned as an array 
         ## of strings 
         "categories"  
         { 
            $propertyValue = @() 
             
            foreach($category in $property.value.array.data.value) 
            { 
               $propertyValue += @($category.string) 
            } 
  
            break  
         } 

         ## Pull the link to the post, returned as an [URI] 
         "link" { $propertyValue = [URI] $property.value.string; break } 

         ## And the permalink to the post, returned as an [URI] 
         "permalink" { $propertyValue = [URI] $property.value.string; break } 

         ## Pull the ID of the post 
         "postid" { $propertyValue = $property.value.string; break } 
      } 

      ## Add the synthetic property      
      $blogEntry | add-member NoteProperty $propertyName $propertyValue 
   } 


   ## Add the ToString method 
   ## This method formats the post so that it may be used in an edit 
   $blogEntry | add-member -force ScriptMethod ToString {  

      ## A function that encoded our content into an XML-friendly 
      ## format 
      function encode([string] $xml) 
      { 
         $tempContent = new-object System.IO.StringWriter 
         $textwriter = new-object System.Xml.XmlTextWriter $tempContent 
         $textWriter.WriteString($xml) 
         $tempContent.ToString() 
      } 

      @"
      <struct> 
        <member> 
          <name>dateCreated</name> 
          <value> 
            <dateTime.iso8601>$($this.dateCreated.ToString("yyyyMMddTHH:mm:ss"))</dateTime.iso8601> 
          </value> 
        </member> 
        <member> 
          <name>description</name> 
          <value> 
            <string>$(encode $this.description)</string> 
          </value> 
        </member> 
        <member> 
          <name>title</name> 
          <value> 
            <string>$(encode $this.title)</string> 
          </value> 
        </member> 
        <member> 
          <name>categories</name> 
          <value> 
            <array> 
               <data> 
              $( 
                  foreach($category in $this.categories) 
                  { 
                     if($category -and $category.Trim()) { "<value>$category</value>" } 
                  } 
               ) 
               </data> 
            </array> 
          </value> 
        </member> 
        <member> 
          <name>link</name> 
          <value> 
            <string>$(encode $this.link)</string> 
          </value> 
        </member> 
        <member> 
          <name>permalink</name> 
          <value> 
            <string>$(encode $this.permalink)</string> 
          </value> 
        </member> 
        <member> 
          <name>postid</name> 
          <value> 
            <string>$(encode $this.postid)</string> 
          </value> 
        </member> 
      </struct> 
"@ 
   } 


   ## Finally output the object that represents the post 
   $blogEntry 
}