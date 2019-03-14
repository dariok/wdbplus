(:~
 : APP.XQM
 : 
 : all basic functions that may be used globally: these keep the framework together
 : 
 : functio nunc denuo emendata et novissime excusa III Id Mar MMXIX
 : 
 : Vienna, Dario Kampkaspar – dario.kampkaspar(at)oeaw.ac.at
 :)
xquery version "3.1";

module namespace wdb = "https://github.com/dariok/wdbplus/wdb";

import module namespace console = "http://exist-db.org/xquery/console";
import module namespace wdbErr  = "https://github.com/dariok/wdbplus/errors" at "error.xqm";
import module namespace xConf   = "http://exist-db.org/xquery/apps/config"   at "config.xqm";
import module namespace xstring = "https://github.com/dariok/XStringUtils"   at "../include/xstring/string-pack.xql";

declare namespace config    = "https://github.com/dariok/wdbplus/config";
declare namespace main      = "https://github.com/dariok/wdbplus";
declare namespace meta      = "https://github.com/dariok/wdbplus/wdbmeta";
declare namespace mets      = "http://www.loc.gov/METS/";
declare namespace rest      = "http://exquery.org/ns/restxq";
declare namespace tei       = "http://www.tei-c.org/ns/1.0";
declare namespace templates = "http://exist-db.org/xquery/templates" ;
declare namespace xlink     = "http://www.w3.org/1999/xlink";

(: ALL-PURPOSE VARIABLES :)
(:~
 : the base of this instance within the db
 :)
declare variable $wdb:edocBaseDB := $xConf:app-root;

(:~
 : load the config file
 : See https://github.com/dariok/wdbplus/wiki/Global-Configuration
 :)
declare variable $wdb:configFile := doc($wdb:edocBaseDB || '/config.xml');

(:~
 : Try to get the data collection. Documentation explicitly tells users to have a wdbmeta.xml
 : in the Collection that contains all projects
 :)
declare variable $wdb:data := 
  let $editionsW := collection($wdb:edocBaseDB)//meta:projectMD
  
  let $paths := for $f in $editionsW
    let $path := base-uri($f)
    where contains($path, '.xml')
    order by string-length($path)
    return $path
  
  return replace(xstring:substring-before-last($paths[1], '/'), '//', '/')
;

(:~
 : get the base URI either from the data of the last call or from the configuration
 :)
declare variable $wdb:edocBaseURL :=
  if ($wdb:configFile//config:server)
  then normalize-space($wdb:configFile//config:server)
  else
    let $dir := try { xstring:substring-before-last(request:get-uri(), '/') } catch * { "" }
    let $db := substring-after($wdb:edocBaseDB, 'db/')
    let $local := xstring:substring-after($dir, $db)
    let $path := if (string-length($local) > 0)
      then xstring:substring-before($dir, $local) (: there is a local part, e.g. 'admin' :)
      else $dir (: no local part, e.g. for view.html in app root :)
    
    return wdb:getServerApp() || $path
;

(: ~
 : get the base URL for REST calls
 :)
declare variable $wdb:restURL := 
  if ($wdb:configFile//config:rest)
  then $wdb:configFile//config:rest
  else substring-before($wdb:edocBaseURL, substring-after($wdb:edocBaseDB, '/db/')) || "restxq/edoc/";

(:~
 :  the server role
 :)
declare variable $wdb:role :=
  ($wdb:configFile//main:role/main:type, "standalone")[1]
;
(:~
 : the peer in a sandbox/publication configuration
 :)
declare variable $wdb:peer :=
  if ($wdb:role != "standalone")
    then $wdb:configFile//main:role/main:peer
    else ""
;
(: END ALL-PURPOSE VARIABLES :)

(: FUNCTIONS TO GET SERVER INFO :)
(:~
 : get some test info about variables and other properties of the framework
 : 
 : @return (node()) HTML div
 :)
declare function wdb:test() as node() {
<div>
  <h1>APP CONTEXT test on {$wdb:configFile//config:name}</h1>
  <h2>global variables (app.xqm)</h2>
  <dl>
    {
      for $var in inspect:module-functions()//variable
        let $variable := '$' || normalize-space($var/@name)
        return (
          <dt>{$variable}</dt>,
          <dd><pre>{
            let $s := util:eval($variable)
            return typeswitch ($s)
            case node() return util:serialize($s, ())
            default return $s
          }</pre></dd>
        )
    }
  </dl>
  <h2>HTTP request parameters</h2>
  <dl>
    {
      for $var in request:get-header-names()
        let $variable := '$' || normalize-space($var)
        return (
          <dt>{$variable}</dt>,
          <dd><pre>{request:get-header($variable)}</pre></dd>
        )
    }
  </dl>
</div>
};
 
(: ~
 : get the name of the server, possibly including the port
 : If resolution fails, set the value in config.xml instead
 : This cannot be used for RESTXQ
 :)
declare function wdb:getServerApp() as xs:string {
  (: config:server contains the full base URL :)
  let $config := 
    let $scheme := substring-before($wdb:configFile//config:server, '//')
    let $server := substring-before(substring-after($wdb:configFile//config:server, '//'), '/')
    return $scheme || '//' || $server
  
  let $origin := try { request:get-header("Origin") } catch * { () }
  let $request := try {
    let $scheme := if (request:get-header-names() = 'X-Forwarded-Proto')
      then normalize-space(request:get-header('X-Forwarded-Proto'))
      else normalize-space(request:get-scheme())
    
    return if (request:get-server-port() != 80)
      then $scheme || '://' || request:get-server-name() || ':' || request:get-server-port()
      else $scheme || '://' || request:get-server-name()
  } catch * { () }
  let $ref := try { request:get-header('referer') } catch * { () }
  
  let $server := ($config, $ref, $origin, $request)
  return if (count($server) > 0)
    then $server[1]
    else wdbErr:error(map {"code" := "wdbErr:wdb0010"})
};
(: END FUNCTIONS TO GET SERVER INFO :)

(: FUNCTIONS USED BY THE TEMPLATING SYSTEM :)
(:~
 : Templating function; called from layout.html
 :)
declare
    %templates:wrap
    %templates:default("view", "")
function wdb:getEE($node as node(), $model as map(*), $id as xs:string, $view as xs:string) as item() {
  wdb:populateModel($id, $view, $model)
};

(:~
 : Populate the model with the most important global settings when displaying a file
 : 
 : @param $id the id for the file to be displayed
 : @param $view a string to be passed to the processing XSLT
 : @return a map; in case of error, an HTML file
 :)
declare function wdb:populateModel($id as xs:string, $view as xs:string, $model as map(*)) as item() {
try {
  let $pathToFile := wdb:getFilePath($id)
  
  let $pathToEd := wdb:getEdPath($id, true())
  let $pathToEdRel := substring-after($pathToEd, $wdb:edocBaseDB||'/')
  
  (: The meta data are taken from wdbmeta.xml or a mets.xml as fallback :)
  let $infoFileLoc := if (doc-available($pathToEd||'/wdbmeta.xml'))
    then $pathToEd || '/wdbmeta.xml'
    else if (doc-available($pathToEd || '/mets.xml'))
    then $pathToEd || '/mets.xml'
    else fn:error(fn:QName('https://github.com/dariok/wdbErr', 'wdbErr:wdb0003'))
  
  let $xsl := if (ends-with($infoFileLoc, 'wdbmeta.xml'))
    then local:getXslFromWdbMeta($infoFileLoc, $id, 'html')
    else local:getXslFromMets($infoFileLoc, $id, $pathToEdRel)
  
  let $xslt := if (doc-available($xsl))
    then $xsl
    else if (doc-available($pathToEd || '/' || $xsl))
    then $pathToEd || '/' || $xsl
    else fn:error(fn:QName('https://github.com/dariok/wdbErr', 'wdbErr:wdb0002'), "no XSLT", <value><label>XSLT</label><item>{$xsl}</item></value>)
  
  let $title := normalize-space((doc($pathToFile)//tei:title)[1])
  
  (: TODO read global parameters from config.xml and store as a map :)
  let $map := map { "fileLoc" := $pathToFile, "xslt" := $xslt, "ed" := doc($infoFileLoc)/*[1]/@xml:id, "infoFileLoc" := $infoFileLoc,
      "title" := $title, "id" := $id, "view" := $view, "pathToEd" := $pathToEd }
  
  (: let $t := console:log($map) :)
  
  return $map
} catch * {
  wdbErr:error(map {"code" := $err:code, "pathToEd" := $wdb:data, "ed" := $wdb:data, "model" := $model, "value" := $err:value })
}
};
(: END FUNCTIONS USED BY THE TEMPLATING SYSTEM :)

(: FUNCTIONS DEALING WITH PROJECTS AND RESOURCES :)
(:~
 : Return the full URI to the (edition) XML file with the given ID
 : The scope is the whole data collection; documentation states in several places that file IDs need to be unique
 : 
 : This function raises errors that are to be caught by the caller
 :
 : @param $id as xs:string: the file ID
 : @return xs:string the full URI to the file within the database
 :)
declare function wdb:getFilePath($id as xs:string) as xs:string {
  let $files := collection($wdb:edocBaseDB)/id($id)
  
  (: do not just return a random URI but add some checks for better error messages:
   : no files found or more than one TEI file found or only wdbmeta entry but no other info :)
  let $pathToFile := if (count($files) = 0)
    then fn:error(fn:QName('https://github.com/dariok/wdbErr', 'wdb0000'))
    else if (count($files[not(namespace-uri() = "https://github.com/dariok/wdbplus/wdbmeta")]) > 1)
    then fn:error(fn:QName('https://github.com/dariok/wdbErr', 'wdb0001'))
    else if (count($files[not(namespace-uri() = "https://github.com/dariok/wdbplus/wdbmeta")]) = 1)
    then base-uri($files[not(namespace-uri() = "https://github.com/dariok/wdbplus/wdbmeta")])
    else if (count($files[namespace-uri() = "https://github.com/dariok/wdbplus/wdbmeta"]) = 1)
    (: TODO do we need to add a check and error if the xml:id is found twice in wdbmeta.xml? :)
    then
      let $p := base-uri($files[1])
      return substring-before($p, 'wdbmeta.xml') || $files[1]/@path
    else fn:error(fn:QName('https://github.com/dariok/wdbErr', 'wdb0000'), "no file with given @xml:id and no fallback")
    
  return $pathToFile
};

(:~
 : Return the (relative or absolute) path to the project
 : 
 : @param $id the ID of a resource within a project
 : @param $absolute (optional) if true(), return an absolute URL
 : 
 : @returns the path (relative) to the app root
 :)
declare function wdb:getEdPath($id as xs:string, $absolute as xs:boolean) as xs:string {
  let $file := collection($wdb:data)/id($id)[self::meta:file]
  
  let $edPath := if (count($file) = 1)
    then xstring:substring-before-last(base-uri($file), '/')
    else if (count($file) > 1)
    then fn:error(fn:QName('https://github.com/dariok/wdbErr', 'wdb0001'))
    else fn:error(fn:QName('https://github.com/dariok/wdbErr', 'wdb0000'))
  
  return if ($absolute) then $edPath else substring-after($edPath, $wdb:edocBaseDB)
};

(:~
 : Return the relative path to the project
 : 
 : @param $id the ID of a file within the project, usually wdbmeta.xml or mets.xml
 : @return the path relative to the app root
 :)
declare function wdb:getEdPath($id as xs:string) as xs:string {
  wdb:getEdPath($id, false())
};

declare function wdb:getEdFromPath($path as xs:string, $absolute as xs:boolean) as xs:string {
  let $tok := tokenize(xstring:substring-after($path, $wdb:edocBaseDB||'/'), '/')
  
  let $pa := for $i in 1 to count($tok)
    let $t := $wdb:edocBaseDB || '.*' || string-join ($tok[position() < $i+1], '/')
    return xmldb:match-collection($t)
  
  let $path := if (count($pa) = 0)
  then
    wdbErr:error(map{"code" := "wdbErr:wdb2001", "additional" := <additional><path>{$path}</path></additional>})
  else for $p in $pa
    order by string-length($p) descending
    let $p1 := $p || '/wdbmeta.xml'
    let $p2 := $p || '/mets.xml'
    
    return if (doc-available($p1) or doc-available($p2)) then $p else ()
  
  return if ($absolute)
    then $path[1]
    else substring-after($path[1], $wdb:edocBaseDB||'/')
};
(: END FUNCTIONS DEALING WITH PROJECTS AND RESOURCES :)

(: LOCAL HELPER FUNCTIONS :)
(:~
 : Evaluate wdbmeta.xml to get the process used for transformation
 :
 : @param $ed The (relative) path to the project
 : @param $id The ID of the file to be processed
 : @param $target The processing target to be used
 :
 : @returns The path to the XSLT
:)
declare function local:getXslFromWdbMeta($infoFileLoc as xs:string, $id as xs:string, $target as xs:string) {
  let $metaFile := doc($infoFileLoc)
  
  let $process := ($metaFile//meta:process[@target = $target],
    $metaFile//meta:process[1])[1]
  
  let $sel := for $c in $process/meta:command
    return if ($c/@refs)
      then
        (: if a list of IDREFS is given, this command matches if $id is part of that list :)
        let $map := tokenize($c/@refs, ' ')
        return if ($map = $id) then $c else ()
      else if ($c/@regex and matches($id, $c/@regex))
        (: if a regex is given and $id matches that regex, the command matches :)
      then $c
      else if (not($c/@refs or $c/@regex))
        (: if no selection method is given, the command is considered the default :)
        then $c
      else () (: neither refs nor regex match and no default given :)
  
  (: As we check from most specific to default, the first command in the sequence is the right one :)
  return $sel[1]/text()
};
declare function local:getXslFromMets ($metsLoc, $id, $ed) {
  let $mets := doc($metsLoc)
  let $structs := $mets//mets:div[mets:fptr[@FILEID=$id]]/ancestor-or-self::mets:div/@ID
  
  let $be := for $s in $structs
    return $mets//mets:behavior[matches(@STRUCTID, concat('(^| )', $s, '( |$)'))]
  let $behavior := for $b in $be
    order by local:val($b, $structs, 'HTML')
    return $b
  let $trans := $behavior[last()]/mets:mechanism/@xlink:href
  
  return concat($wdb:edocBaseDB, '/', $ed, '/', $trans)
};
(: Try to find the most specific mets:behavior
 : $test: mets:behavior to be tested
 : $seqStruct: sequence of mets:div/@ID (ordered by specificity, ascending)
 : $type: return type
 : returns: a weighted value for the behavior's “rank” :)
declare function local:val($test, $seqStruct, $type) {
  let $vIDt := for $s at $i in $seqStruct
    return if (matches($test/@STRUCTID, concat('(^| )', $s, '( |$)')))
      then math:exp10($i)
      else 0
  let $vID := fn:max($vIDt)
  let $vS := if ($test[@BTYPE = $type])
    then 5
    else if ($test[@LABEL = $type])
    then 3
    else if ($test[@ID = $type])
    then 1
    else 0
  
  return $vS + $vID
};
(: END LOCAL HELPER FUNCTIONS :)