xquery version "3.1";

module namespace wdbRa = "https://github.com/dariok/wdbplus/RestAnnotations";

declare namespace anno = "https://github.com/dariok/wdbplus/annotations";

import module namespace util     = "http://exist-db.org/xquery/util"         at "java:org.exist.xquery.functions.util.UtilModule";
import module namespace wdb      = "https://github.com/dariok/wdbplus/wdb"   at "/db/apps/edoc/modules/app.xqm";
import module namespace wdbanno  = "https://github.com/dariok/wdbplus/anno"  at "/db/apps/edoc/modules/annotations.xqm";
import module namespace wdbFiles = "https://github.com/dariok/wdbplus/files" at "/db/apps/edoc/modules/wdb-files.xqm";
import module namespace console  = "http://exist-db.org/xquery/console";

declare namespace http    = "http://expath.org/ns/http-client";
declare namespace output  = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace rest    = "http://exquery.org/ns/restxq";
declare namespace sm      = "http://exist-db.org/xquery/securitymanager";
declare namespace session = "http://exist-db.org/xquery/session";
declare namespace tei     = "http://www.tei-c.org/ns/1.0";
declare namespace wdbErr  = "https://github.com/dariok/wdbplus/errors";

(:~
  :return all public full text annotations and those of the current user for $fileID
  :)
declare
  %rest:GET
  %rest:path("/edoc/anno/{$fileID}")
  %rest:produces("application/json")
  %output:method("json")
function wdbRa:getFileAnno ($fileID as xs:string) {
  (: get the username; use sm:real to avoid setuid conflicts :)
  let $username := xs:string(sm:id()//sm:real/sm:username)
  let $fileURI := xs:anyURI(wdb:getFilePath($fileID))
  
  let $public := wdbanno:getAnnoFile($fileURI, "")//anno:entry
  let $private := wdbanno:getAnnoFile($fileURI, $username)//anno:entry
  let $numEntries := count($public) + count($private)
  
  return if ($numEntries = 0)
  then
    <rest:response>
      <http:response status="204">
        <http:header name="rest-status" value="REST:SUCCESS" />
        <http:header name="Access-Control-Allow-Origin" value="*"/>
      </http:response>
    </rest:response>
  else (
    <rest:response>
      <http:response status="200">
        <http:header name="rest-status" value="REST:SUCCESS" />
        <http:header name="Access-Control-Allow-Origin" value="*"/>
      </http:response>
    </rest:response>,
    <anno:anno>
      <anno:entry><anno:collection>{$public}</anno:collection><anno:user>{$username}</anno:user><anno:entries>{$numEntries}</anno:entries></anno:entry>
      {
        for $entry in ($public//anno:entry, $private//anno:entry)
          return $entry
      }
    </anno:anno>
  )
};

(:~
  : insert a new full text annotation
  :)
declare
  %rest:POST("{$body}")
  %rest:path("/edoc/anno/{$fileID}")
  %rest:consumes("application/json")
function wdbRa:insertAnno ($fileID as xs:string, $body as item()) {
  let $data := parse-json(util:base64-decode($body))
  (: TODO update these checks like in changeWords! :)
  (: check for minimum data before continuing :)
return if (not($data('from') or $data('text')))
  then (
    <rest:response>
      <http:response status="400">
        <http:header name="rest-status" value="REST:ERR" />
      </http:response>
    </rest:response>,
    "Missing content in message body: at least start and text must be supplied"
  )
  else
    let $username := xs:string(sm:id()//sm:real/sm:username)
    
    (: check whether the user may write :)
    return if ($username = 'guest')
    then
      (
        <rest:response>
            <http:response status="401">
                <http:header name="rest-status" value="REST:ERR" />
                <http:header name="rest-user" value="{$username}" />
            </http:response>
        </rest:response>,
        "User " || $username || " is not allowed to create annotations"
      )
    else
      let $file := doc(wdb:getFilePath($fileID))
    
      return if (count($file) = 0)
        then (
          <rest:response>
            <http:response status="404">
              <http:header name="rest-status" value="REST:notFound" />
            </http:response>
          </rest:response>,
          "no file found for ID " || $fileID
        )
        else
          let $ann := 
            <entry xmlns="https://github.com/dariok/wdbplus/annotations">
              <id>{util:uuid()}</id>
              <file>{$fileID}</file>
              <range from="{$data('from')}" to="{$data('to')}" />
              <cat>{$data('text')}</cat>
              <user>{$username}</user>
            </entry>
          let $annoFile := if ($data?public = "on")
            then wdbanno:getAnnoFile(base-uri($file), "")
            else wdbanno:getAnnoFile(base-uri($file), $username)
          
          return (
            <rest:response>
              <http:response status="200">
                <http:header name="rest-status" value="REST:SUCCESS" />
                <http:header name="Access-Control-Allow-Origin" value="*"/>
              </http:response>
            </rest:response>,
            (
              update insert $ann into $annoFile/anno:anno,
              $ann
            )
          )
};

(:~
  : surround w with rs and a given type
  :)
declare
  %rest:POST("{$body}")
  %rest:path("/edoc/anno/entity/{$fileID}")
  %rest:consumes("application/json")
function wdbRa:markEntity ($fileID as xs:string, $body as item()) {
  let $data := parse-json(util:base64-decode($body))
  let $user := xs:string(sm:id()//sm:real/sm:username)
  
  let $check := wdbRa:check($fileID, $data, "w", ("from", "to", "type", "identity"))
  
  return if ($check[1] != 200)
  then (
    <rest:response>
      <http:response status="{$check[1]}">
        <http:header name="X-Rest-Status" value="{$check[2]}" />
        <http:header name="Access-Control-Allow-Origin" value="*"/>
        <http:header name="Content-Type" value="text/plain" />
      </http:response>
    </rest:response>,
    for $err in $check
      return $err || "&#x0A;"
  )
  else
    let $file := doc($check[2])
    
    let $from := $file/id($data?from)
    let $to := if ($data?to = '')
      then $from
      else $file/id($data?to)
    
    let $ancs := wdbRa:commons($from, $to)
    
    let $common := util:node-by-id($file, $ancs?common)
    let $value := $data?type || ':' || $data?identity
    
    let $change := try {
      if ($common/self::tei:rs)
      then (: change identification :)
        update value $common/@ref with $value
      else (: create a new identification :)
        let $type := switch ($data?type)
          case "per" return "person"
          case "pla" return "place"
          case "org" return "organization"
          case "evt" return "event"
          case "bib" return "bibl"
          default return "unknown"
        
        let $sequence :=
          let $A := util:node-by-id($file, $ancs?A)
          let $B := util:node-by-id($file, $ancs?B)
          return if ($A is $B)
            then if ($A/parent::*[self::tei:rs])
              then update value $A/parent::tei:rs/@ref with $value
              else $A
            else ($A, $A/following-sibling::* intersect $B/preceding-sibling::*, $B)
        
        let $replacement :=
          <rs xmlns="http://www.tei-c.org/ns/1.0" type="{$type}" ref="{$data?type}:{$data?identity}">{
            $sequence
          }</rs>
          
        return ( 
          update replace $sequence[1] with $replacement,
          update delete $sequence[position() gt 1]
        )
    } catch * {
      (500)
    }
    
    return ( 
      <rest:response>
        <http:response status="{if ($change = 500) then 500 else 200}">
          <http:header name="rest-status" value="REST:SUCCESS" />
          <http:header name="Access-Control-Allow-Origin" value="*"/>
        </http:response>
      </rest:response>,
      $change
    )
};

declare
  %rest:POST("{$body}")
  %rest:path("/edoc/anno/word/{$fileID}")
  %rest:consumes("application/json")
  %rest:produces("application/json")
  %output:method("json")
function wdbRa:changeWords ($fileID as xs:string, $body as item()) {
  let $data := parse-json(util:base64-decode($body))
    let $check := wdbRa:check($fileID, $data, "w", ("from", "job", "text"))
  (: TODO check for correct value of job, else 400 :)
  return if ($check[1] != 200)
  then (
    <rest:response>
      <http:response status="{$check[1]}">
        <http:header name="X-Rest-Status" value="{$check[2]}" />
        <http:header name="Access-Control-Allow-Origin" value="*"/>
        <http:header name="Content-Type" value="text/plain" />
      </http:response>
    </rest:response>,
    for $err in $check
      return $err || "&#x0A;"
  )
  else
    let $file := doc($check[2])
    let $token := $file/id($data?from)
    return (
      <rest:response>
        <http:response status="200">
          <http:header name="rest-status" value="REST:SUCCESS" />
          <http:header name="Access-Control-Allow-Origin" value="*"/>
        </http:response>
      </rest:response>,
      switch ($data("job"))
      case "edit" return
        let $d := console:log($token)
        let $u := if ($token/tei:lb)
          then
            let $id := $token/@xml:id
            let $lb := $token/tei:lb
            let $text := tokenize($data("text"), '\|')
            let $pid := if ($token/tei:pc)
              then $token/tei:pc/@xml:id
              else ()
            let $pc := <pc>{$pid, substring($text[1], string-length($text[1]))}</pc>
            let $d1 := console:log($text)
            let $repl :=
              <w xmlns="http://www.tei-c.org/ns/1.0">{$id,
                substring($text[1], 1, string-length($text[1]) - 1),
                $pc,
                $lb,
                $text[2]
              }</w>
            return update replace $token with $repl
          else update value $token with $data("text")
        return $doc/id($data?from)
      default return ""
    )
};

declare
  %private
function wdbRa:check ($fileID, $data, $mode, $keys) {
  let $user := xs:string(sm:id()//sm:real/sm:username)
  
  (: check whether all necessary data are present :)
  let $keyCheck := for $key in map:keys($data)
    return $key = $keys
  let $checkData := if (false() = $keyCheck)
    then (400, "Missing content in message body. Expected keys: " || string-join($keys, ', '))
    else ()
  
  let $noID := if ($fileID = "")
    then (400, "No ID supplied")
    else ()
  
  (: check whether a file with the given ID exists and is accessible :)
  let $accessible := try { 
      let $ac := wdbFiles:hasAccess($wdb:data, $fileID, $mode)
      return if ($ac)
        then (true(), $ac)
        else (false(), 403, "User " || $user || " does not have sufficient rights to access resource " || $fileID || " in mode " || $mode)
    }
    catch wdbErr:wdb0000 { (false(), 404, "No Resource found for the given ID") }
    catch * { (false(), 500, "Error trying to get a resource for the given ID (usually due to some error in the project): " || $err:code || "&#x0A;" || $err:description) }
  
  let $doc := if ($accessible[1])
    then doc($accessible[2])
    else ()
  
  (: check whether the token ID exists :)
  let $tokenError := (
    wdbRa:checkToken($doc, $data?from),
    if ($data?to) then wdbRa:checkToken($doc, $data?to) else ()
  )
    
  let $checkToken := if(count($tokenError))
    then (416, string-join($tokenError, "&#x0A;"))
    else ()
  
  return if (count($checkData) or not($accessible[1]) or count($checkToken))
    then ($checkData, if (not($accessible[1])) then ($accessible[2], $accessible[3]) else (), $checkToken)
    else (200, $accessible[2])
};
declare %private function wdbRa:checkToken ($doc, $id) {
  let $token := $doc/id($id)
  return if (count($token) = 1 and $token[self::tei:w or self::tei:pc])
      then ()
      else "Wrong number of items for ID " || $id || ": " || count($token)
};


(: ~
 : returns the node IDs of the first common ancestor and the sibling ancestor
 :
 : The ancestor are the first two ancestors of $a and $b that are siblings
 : The common ancestor is the first node that is the parent of these two
 :
 : $a must be before $b in the document order, else only their ancestor-or-selfs will be returned
 : 
 : @param $a the first, “from”-sibling
 : @param $b the second, “to”-sibling
 : @param $file the node within which to search
 : 
 : @return map(*) of the three node IDs
 : :)
declare function wdbRa:commons ($a as node(), $b as node()) as map(*) {
  if ($a = $b)
  then map { "common": util:node-id($a), "A": util:node-id($a), "B": util:node-id($a) }
  else
    let $as := for $node in $a/ancestor-or-self::* return util:node-id($node)
    let $bs := for $node in $b/ancestor-or-self::* return util:node-id($node)
    
    let $commons := for $id in $as return if ($id = $bs) then $id else ()
    let $common := $commons[last()]
    
    let $A := $as[count($commons) + 1]
    let $B := $bs[index-of($bs, $common) + 1]
    
    return map { "common": $common, "A": $A, "B": $B }
};