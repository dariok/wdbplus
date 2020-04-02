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
  
  let $public := wdbanno:getAnnoFile($fileURI, "")
  let $private := wdbanno:getAnnoFile($fileURI, $username)
  
  return (
    <rest:response>
      <http:response status="200">
        <http:header name="rest-status" value="REST:SUCCESS" />
        <http:header name="Access-Control-Allow-Origin" value="*"/>
      </http:response>
    </rest:response>,
    <anno:anno>
      <anno:entry><anno:collection>{$public}</anno:collection><anno:user>{$username}</anno:user></anno:entry>
      {for $entry in ($public//anno:entry, $private//anno:entry)
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
      <http:response status="200">
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
        (<rest:response>
            <http:response status="200">
                <http:header name="rest-status" value="REST:ERR" />
            </http:response>
        </rest:response>,
        "User guest is not allowed to create annotations")
    else
    let $ann := 
        <entry xmlns="https://github.com/dariok/wdbplus/annotations">
            <id>{util:uuid()}</id>
            <file>{$fileID}</file>
            <range from="{$data('from')}" to="{$data('to')}" />
            <cat>{$data('text')}</cat>
            <user>{$username}</user>
        </entry>
    let $file := $wdb:data/id($fileID)[not(namespace-uri() = "https://github.com/dariok/wdbplus/wdbmeta")]
    
    return if (count($file) = 0)
        then
    (<rest:response>
        <http:response status="200">
            <http:header name="rest-status" value="REST:ERR" />
        </http:response>
    </rest:response>,
    "no file found for ID " || $fileID)
        else 
          let $annoFile := wdbanno:getAnnoFile(base-uri($file), $username)
          return (
            <rest:response>
              <http:response status="200">
                <http:header name="rest-status" value="REST:SUCCESS" />
                <http:header name="Access-Control-Allow-Origin" value="*"/>
              </http:response>
            </rest:response>,
            update insert $ann into $annoFile/anno:anno
          )
};

(:~
  : surround w with rs and a given type
  :)
declare
  %rest:PUT("{$body}")
  %rest:path("/edoc/anno/entity/{$fileID}")
  %rest:consumes("application/json")
function wdbRa:markEntity ($fileID as xs:string, $body as item()) {
  let $data := parse-json(util:base64-decode($body))
  let $user := xs:string(sm:id()//sm:real/sm:username)
  
  let $check := wdbRa:check($fileID, $data, "w")
  
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
    return false()
    (:let $content := (
      $file/id($data("from")), 
      if ($data("from") != $data("to"))
        then (
          $file/id($data("from"))/following-sibling::node() intersect $file/id($data("to"))/preceding-sibling::node(), 
          $file/id($data("to")))
        else () 
    )
    
    let $ins := element { QName("http://www.tei-c.org/ns/1.0", "rs") } {
      attribute type { $data("type") },
      attribute ref { 'per:' || translate($data("identity"), ' ,', '_') },
      $content }
      return (
        <rest:response>
          <http:response status="200">
            <http:header name="rest-status" value="REST:SUCCESS" />
            <http:header name="Access-Control-Allow-Origin" value="*"/>
          </http:response>
        </rest:response>,
        update replace $content[1] with $ins,
        update delete $content[position() > 1]
      ):)
};

declare
  %rest:POST("{$body}")
  %rest:path("/edoc/anno/word/{$fileID}")
  %rest:consumes("application/json")
  %rest:produces("application/json")
  %output:method("json")
function wdbRa:changeWords ($fileID as xs:string, $body as item()) {
  let $data := parse-json(util:base64-decode($body))
  let $filePath := wdb:getFilePath(xs:anyURI($fileID))
  let $doc := doc($filePath)
  
  (: check the job :)
  let $checkJob := if ($data("job") = ("edit"))
    then ()
    else <error>Unknown job description</error>
  
  return if ($checkData | $checkWrite | $checkID | $checkJob)
    then (
      <rest:response>
        <http:response status="500">
          <http:header name="rest-status" value="REST:ERR" />
        </http:response>
      </rest:response>,
      string-join(($checkData, $checkWrite, $checkID, $checkJob), ' – ')
    )
    else (
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
        return $doc/id($data("id"))
      default return ""
    )
};

declare
  %private
function wdbRa:check ($fileID, $data, $mode) {
  let $user := xs:string(sm:id()//sm:real/sm:username)
  (: check whether all necessary data are present :)
  let $checkData := if (not($data("text") or $data("from")))
    then (400, "Missing content in message body: at least start and text must be supplied")
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