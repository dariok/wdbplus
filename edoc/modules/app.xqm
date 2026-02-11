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

import module namespace config    = "https://github.com/dariok/wdbplus/config"       at "wdb-config.xqm";
import module namespace wdbErr    = "https://github.com/dariok/wdbplus/errors"       at "error.xqm";
import module namespace wdbFiles  = "https://github.com/dariok/wdbplus/files"        at "wdb-files.xqm";
import module namespace wdbPF     = "https://github.com/dariok/wdbplus/projectFiles" at "../data/instance.xqm";
import module namespace xstring   = "https://github.com/dariok/XStringUtils"         at "../include/xstring/string-pack.xql";

declare namespace main = "https://github.com/dariok/wdbplus";
declare namespace meta = "https://github.com/dariok/wdbplus/wdbmeta";
declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace tei  = "http://www.tei-c.org/ns/1.0";

(: FUNCTIONS TO GET SERVER INFO :)
(:~
 : get some test info about variables and other properties of the framework
 : 
 : @return (node()) HTML div
 :)
declare function wdb:test( $node as node(), $model as map(*) ) as node() {
<div>
  <h1>APP CONTEXT test on {$config:configFile//config:name}</h1>
  <div>
    <h2>global variables (function.xqm)</h2>
    <dl>
      {
        for $var in inspect:inspect-module(xs:anyURI("app.xqm"))//variable
          where not(contains($var/@name, 'lookup'))
          let $variable := '$' || normalize-space($var/@name)
          return (
            <dt>{$variable}</dt>,
            <dd><pre>{
              let $s := util:eval($variable)
              return typeswitch ($s)
              case node() return serialize($s)
              default return $s
            }</pre></dd>
          )
      }
    </dl>
  </div>
    <div>
    <h2>populateModel (model.xqm)</h2>
    <dl>
      {
        if (exists($model?id))
        then "currently, no model view is available"
          (: let $computedModel := wdb:populateModel($model?id, "", map {})
          return wdbErr:get($computedModel, "") :)
        else "Keine ID zur Auswertung vorhanden"
      }
    </dl>
  </div>
  <div>
    <h2>HTTP request parameters</h2>
    <dl>
      {
        for $var in request:get-header-names()
          return (
            <dt>{$var}</dt>,
            <dd><pre>{request:get-header($var)}</pre></dd>
          )
      }
    </dl>
  </div>
  <div>
    <h2>$model (from function.xqm)</h2>
    { wdbErr:get($model, "") }
  </div>
</div>
};
(: END FUNCTIONS TO GET SERVER INFO :)

(: FUNCTIONS USED BY THE TEMPLATING SYSTEM :)
(:~
 : generic function to wrap some info from the model in an HTML element via templating
 :)
declare function wdb:wrapText ( $node as node(), $model as map(*), $key as xs:string ) {
  element { node-name($node) } { $model($key) }
};

declare function wdb:getAnnotationDialogue ( $node as node(), $model as map(*) ) {
  ()
};
(: END FUNCTIONS USED BY THE TEMPLATING SYSTEM :)

(: FUNCTIONS DEALING WITH PROJECTS AND RESOURCES :)
(:~
 : Tries to return an absolute path for a path within a project
 : 
 : @param $ed the ID of the project
 : @param $path the path to a file within that project
 : @return the absolute path to this file
 :)
declare function wdb:getAbsolutePath ( $ed as xs:string, $path as xs:string ) {
  if ( starts-with($path, '/') )
    then $path
    else (wdbFiles:getFullPath($ed))?projectPath || "/" || $path
};

(: ~
 : Return the path to a project
 : 
 : @param $path a path to a file within the project
 : @param absolute (boolean) whether or not to return an absolute path
 : 
 : @return the path
 :)
declare function wdb:getEdFromPath($path as xs:string, $absolute as xs:boolean) as xs:string {
  let $tok := tokenize(xstring:substring-after($path, $config:edocBaseDB||'/'), '/')
  
  let $pa := for $i in 1 to count($tok)
    let $t := $config:edocBaseDB || '.*' || string-join ($tok[position() < $i+1], '/')
    return xmldb:match-collection($t)
  
  let $path := if (count($pa) = 0)
  then
    wdbErr:error(map{"code": "wdbErr:wdb2001", "additional": <additional><path>{$path}</path></additional>})
  else for $p in $pa
    order by string-length($p) descending
    
    return if ( doc-available($p || '/wdbmeta.xml') ) then $p else ()
  
  return if ( $absolute )
    then $path[1]
    else substring-after($path[1], $config:edocBaseDB||'/')
};
(:~
 : Try ro load project specific XQuery to import CSS and JS
 : @created 2018-02-02 DK
 :)
declare function wdb:getProjectFiles ( $node as node(), $model as map(*), $type as xs:string ) as node()* {
  let $files := if ( wdb:findProjectFunction($model, 'wdbPF:getProjectFiles', 1) ) then
      (wdb:getProjectFunction($model, "wdbPF:getProjectFiles", 1))($model)
    else
      let $css := wdb:findProjectFile($model?projectResources, "/css/project.css")
        , $js := wdb:findProjectFile($model?projectResources, "/js/project.js")
      
      return (
        if ( $css != "" )
          then <link rel="stylesheet" type="text/css" href="{wdb:getUrl($css)}" />
          else (),
        if ( $js != "" )
          then <script src="{wdb:getUrl($js)}" />
          else ()
      )
  
  return if ($type = 'css')
    then $files[self::*:link]
    else $files[self::*:script]
};

(:~ 
 : Check whether the function given in $name with arity $arity has been loaded into $model?functions
 : 
 : @param $model a map of parameters that conforms to the global structure
 : @param $name the FQName of the function to be looked for
 : @param $arity the arity (i.e. number of arguments) of said function
 : @return true() if the signature was found in 1) project, 2) instance specifics, false() otherwise
 :)
declare function wdb:findProjectFunction ( $model as map(*), $name as xs:string, $arity as xs:integer ) as xs:boolean {
  if ( exists($model?functions) and $model?functions instance of map(*) ) then
    ( $model?functions?project = $name || '#' || $arity )
    or ( $model?functions?instance = $name || '#' || $arity )
  else false()
};

(:~ 
 : Return the function with the given name and arity if it exists in the global model
 : 
 : @param $model a map of parameters that conforms to the global structure
 : @param $name the FQName of the function to be looked for
 : @param $arity the arity (i.e. number of arguments) of said function
 : @return a function item representing the function if it was found, the empty sequence otherwise
 :)
declare function wdb:getProjectFunction ( $model as map(*), $name as xs:string, $arity as xs:integer ) as function(*)? {
  if ( $model?functions?project = $name || "#" || $arity ) then
    ((load-xquery-module("https://github.com/dariok/wdbplus/projectFiles", map{ "location-hints": $model?projectFile} ))?functions)(xs:QName($name))($arity)
  else if ( $model?functions?instance = $name || "#" || $arity ) then
    function-lookup(xs:QName($name), $arity)
  else ()
};

(:~
 : Generic finder for files in the project hierarchy (bottom up)
 : it is assumed that this is a binary file
 : 
 : @param $pathToEd path to the project to search from)
 : @param $fileName name of the file to search
 : @returns the full path to the file in the lowest position; if the file cannot be found, an empty URI is returned
 :)
declare function wdb:findProjectFile ( $path as xs:string, $fileName as xs:string ) as xs:anyURI {
  if ( util:binary-doc-available($path || "/" || $fileName) ) then
    xs:anyURI($path || "/" || $fileName)
  else if ( substring-after($path, $config:data) = '' ) then
    xs:anyURI("")
  else
    wdb:findProjectFile(xstring:substring-before-last($path, '/'), $fileName)
};
(: END FUNCTIONS DEALING WITH PROJECTS AND RESOURCES :)

(: GENERAL HELPER FUNCTIONS :)
declare function wdb:getUrl ( $path as xs:string ) as xs:string {
  $config:edocBaseURL || substring-after($path, $config:edocBaseDB)
};

(:~
 : Evalute the function given by $function.
 : This is nothing but util:eval($function) but as it is within the scope of app.xql, you can evalute a function in a
 : module imported by wdb:findProjetFunction while calling util:eval from any other XQuery will not work
 :
 : @param $function an xs:string to be passed to util:eval
 : @return whatever evaluating the funciton returns
 :)
declare function wdb:eval($function as xs:string) {
  util:eval($function)
};
declare function wdb:eval($function as xs:string, $cache-flag as xs:boolean, $external-variable as item()*) {
  util:eval($function, $cache-flag, $external-variable)
};
(: END GENERAL HELPER FUNCTIONS :)

(: LOCAL HELPER FUNCTIONS :)
(:~
 : Evaluate wdbmeta.xml to get the process used for transformation
 :
 : @param $id The ID of the file to be processed
 : @param $target The processing target to be used
 : @param $infoFileLoc The location of the wdbmeta.xml file
 : @param $view (optional) a view parameter for selecting the right process
 :
 : @returns The path to the XSLT
:)
declare function wdb:getXslFromWdbMeta ( $infoFileLoc as xs:string, $id as xs:string, $target as xs:string ) as element(process)? {
    wdb:getXslFromWdbMeta($infoFileLoc, $id, $target, "")
};
declare function wdb:getXslFromWdbMeta ( $infoFileLoc as xs:string, $id as xs:string, $target as xs:string, $view as xs:string? ) as element(process)? {
  let $metaFile := doc($infoFileLoc)
    , $process := (
        $metaFile//meta:process[@target = $target and @view = $view],
        $metaFile//meta:process[@target = $target],
        $metaFile//meta:process[1]
      )[1]
    , $base := substring-before(base-uri($metaFile), 'wdbmeta.xml')
  
  let $sel := if ( $process/meta:command )
    then
      for $c in $process/meta:command
        return if ( $c/@refs ) then
          (: if a list of IDREFS is given, this command matches if $id is part of that list :)
          let $map := tokenize($c/@refs, ' ')
          return if ( $map = $id ) then $base || $c else ()
        else if ( $c/@regex and matches($id, $c/@regex) )
          (: if a regex is given and $id matches that regex, the command matches :)
          then $base || $c
        else if ( $c/@group and $metaFile/id($id)/parent::meta:filegroup/@xml:id = $c/@group )
          then $base || $c
        else if ( not($c/@refs or $c/@regex or $c/@group) )
          (: if no selection method is given, the command is considered the default :)
          then $base || $c
        else () (: neither refs nor regex match and no default given :)
    (: if no command is defined, traverse up the project ancestors :)
    else if ( $metaFile/meta:projectMD/meta:struct/*[1][self::meta:import] ) then
      let $path := xstring:substring-before-last($infoFileLoc, '/')
        , $parent := $metaFile/meta:projectMD/meta:struct/meta:import
      return
        wdb:getXslFromWdbMeta ($path || '/' || $parent/@path, $id, $target, $view)
    else ( util:log("error", $metaFile) )
  
  (: As we check from most specific to default, the first command in the sequence is the right one :)
  return if ( $sel[1] instance of element(meta:process) )
    then $sel[1]
    else if ( $sel[1] instance of xs:string )
      then <meta:process target="{$target}" view="{$view}">
              <meta:command type="{$process/meta:command/@type}">{$sel[1]}</meta:command>
           </meta:process>
    else
      error(
        QName('wdbRErr', 'wdb0002'),
        "no process found for target '" || $target || "' and view '" || $view || "' in " || $infoFileLoc
      )
};

(:~
 : Apply a project specific XSLT to some XML
 :
 : @param $xml The XML to be transformed
 : @param $edPath The path to the project
 : @param $name The name of the XSLT file to be applied
 :
 : @returns The transformed XML
 :
 : The lookup order is:
 : 1) project resources
 : 2) instance resources
 : 3) global resources
 :)
declare function wdb:applySpecificXsl ( $xml as node(), $edPath as xs:string, $name as xs:string ) as node() {
  wdb:applySpecificXsl($xml, $edPath, $name, ())
};
(:~
 : Apply a project specific XSLT to some XML
 :
 : @param $xml The XML to be transformed
 : @param $edPath The path to the project
 : @param $name The name of the XSLT file to be applied
 : @param $parameters (optional) parameters to be passed to the XSLT
 :
 : @returns The transformed XML
 :
 : The lookup order is:
 : 1) project resources
 : 2) instance resources
 : 3) global resources
 :)
declare function wdb:applySpecificXsl ( $xml as node(), $edPath as xs:string, $name as xs:string, $parameters as element(parameters)? ) as node() {
  let $xsl := if ( doc-available($edPath || "/resources/xsl/" || $name) ) then
        doc($edPath || "/resources/xsl/" || $name)
      else if ( doc-available("/db/apps/edoc/data/resources/xsl/" || $name) ) then
        doc("/db/apps/edoc/data/resources/xsl/" || $name)
      else
        doc("/db/apps/edoc/resources/xsl/" || $name)
   
   return transform:transform($xml, $xsl, $parameters)
};
(: END LOCAL HELPER FUNCTIONS :)

(: HELPERS FOR REST AND HTTP REQUESTS :)
(:~
 : Get a MIME type from an extension and an optional XML namespace
 :
 : @param $extension (string): the file extension
 : @param $namespace (string) optional: a namespace URI for more detailed MIME types of XML files
 : @return (string): the MIME type
 :)
declare function wdb:getContentTypeFromExt ( $extension as xs:string, $namespace as xs:anyURI? ) as xs:string {
  switch ( $extension )
    case 'css'
      return
        'text/css'
    case 'js'
      return
        'application/javascript'
    case 'xql'
    case 'xqm'
      return
          'application/xquery'
    case 'html'
      return
        'text/html'
    case 'gif'
      return
        'image/gif'
    case 'png'
      return
        'image/png'
    case 'json'
      return
        'application/json'
    case 'zip'
      return
        'application/zip'
    case 'xml'
      return
        if ( $namespace = 'http://www.tei-c.org/ns/1.0' ) then
          'application/tei+xml'
        else
          'application/xml'
    case 'xsl'
      return
        'application/xslt+xml'
    default
      return
        'application/octet-stream'
};

declare function wdb:getBlob ( $node as node(), $model as map(*), $name as xs:string ) {
  let $path := $config:configFile//config:source[@name = $name]/@path
  
  return if ( ends-with($path, 'js') )
    then <script src="{ $path }"></script>
    else <link rel="stylesheet" type="text/css" href="{ $path }" />
};
(: END HELPERS FOR REST AND HTTP REQUESTS :)
