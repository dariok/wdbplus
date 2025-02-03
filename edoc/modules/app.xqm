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
import module namespace templates = "http://exist-db.org/xquery/html-templating";
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
    <h2>populateModel (app.xqm)</h2>
    <dl>
      {
        if (exists($model?id))
        then
          let $computedModel := wdb:populateModel($model?id, "", map {})
          return wdbErr:get($computedModel, "")
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
 : Populate the model with the most important global settings when displaying a file
 : Moved to a separate function as this one may be called by other functions, too
 : 
 : @param $id the id for the file to be displayed
 : @param $view a string to be passed to the processing XSLT
 : @param $p general parameter to be passed to the processing XSLT
 : @return a map; in case of error, an HTML file
 :)
declare function wdb:populateModel ( $id as xs:string, $view as xs:string, $model as map(*) ) as item()* {
    wdb:populateModel($id, $view, $model, "")
};
declare function wdb:populateModel ( $id as xs:string, $view as xs:string, $model as map(*), $p as xs:string ) as item()* {
  let $filePathInfo := wdbFiles:getFullPath($id)
    , $pathToFile := if ( map:keys($filePathInfo) = 'fileURL' )
        then
          $filePathInfo?fileURL
        else
          $filePathInfo?collectionPath || '/' || $filePathInfo?fileName
    , $pathToEd := $filePathInfo?projectPath
    , $infoFileLoc := $filePathInfo?projectPath || '/wdbmeta.xml'
    
  let $ed := string(doc($infoFileLoc)/meta:projectMD/@xml:id)
  
  let $xsl := if ( $filePathInfo?fileName = "wdbmeta.xml" )
    then
      (: TODO get path to XSL via function (use what’s in rest-files.xql) :)
      xs:anyURI($config:data || '/resources/nav.xsl')
    else wdb:getXslFromWdbMeta($infoFileLoc, $id, 'html')
    
    let $xslt := if (doc-available($xsl))
      then $xsl
      else if (doc-available($pathToEd || '/' || $xsl))
      then $pathToEd || '/' || $xsl
      else ""
    
    let $doc := doc($pathToFile)
      , $title := normalize-space(($doc//tei:title)[1])
      , $language := normalize-space($doc//tei:langUsage/tei:language[1]/@ident)
    
    let $proFile := $filePathInfo?mainProject || "/project.xqm"
      , $mainProject := $filePathInfo?mainProject
      , $resource := $filePathInfo?mainProject || "/resources/"
    
    let $projectFunctions := for $function in doc($mainProject || "project-functions.xml")//function
          return $function/@name || '#' || count($function/argument)
      , $instanceFunctions := for $function in doc($config:data || "/instance-functions.xml")//function
          return $function/@name || '#' || count($function/argument)

    let $header := if ( request:exists() )
          then map:merge( for $header in request:get-header-names() return map:entry($header, request:get-header($header)) )
          else ()
      , $requestUrl := if ( request:exists() )
          then request:get-url()
          else ()
    
    (: TODO read global parameters from config.xml and store as a map :)
    let $map := map {
      "ed":               $ed,
      "fileLoc":          $pathToFile,
      "filePathInfo":     $filePathInfo,
      "functions":        map { "project": $projectFunctions, "instance": $instanceFunctions }, 
      "header":           $header,
      "id":               $id,
      "infoFileLoc":      $infoFileLoc,
      "language":         $language,
      "mainEd":           substring-after($mainProject, 'data/') => substring-before('/'),
      "p":                $p,
      "pathToEd":         $pathToEd,
      "projectFile":      $proFile,
      "projectResources": $resource,
      "requestUrl":       $requestUrl,
      "title":            $title,
      "view":             $view,
      "xslt":             $xslt
    }
    
    return map:merge( ($model, $map) )
};

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
 : Return the full URI to the (edition) XML file with the given ID
 : The scope is the whole data collection; documentation states in several places that file IDs need to be unique
 : 
 : This function raises errors that are to be caught by the caller
 :
 : @param $id as xs:string: the file ID
 : @return xs:string the full URI to the file within the database
 : @throws wdbErr:wdb0000
 : @throws wdbErr:wdb0001
 :)
declare function wdb:getFilePath ( $id as xs:string ) as xs:string {
  let $files := wdbFiles:getFilePaths($config:data, $id)
  
  (: do not just return a random URI but add some checks for better error messages:
   : no files found or more than one TEI file found or only wdbmeta entry but no other info :)
  let $pathToFile := if ( count($files) = 0 ) then
      error(
        QName('https://github.com/dariok/wdbErr', 'wdb0000'),
        "no file with ID " || $id || " in " || $config:data,
        map { "id": $id, "request": request:get-url() }
      )
    else if ( count($files) > 1 ) then
      error(
        QName('https://github.com/dariok/wdbErr', 'wdb0001'),
        "multiple files with ID " || $id || " in " || $config:data,
        map { "id": $id, "request": request:get-url() }
      )
    else if ( local-name($files[1]) = 'id' ) then
      base-uri($files[1]) || '#' || $id
    else
      xstring:substring-before-last(base-uri($files[1]), '/') || '/' || $files[1]
  
  return if ( starts-with($files[1], '$') )
    then
      let $peer := $files[1] => substring(2) => substring-before('/')
        , $id := $files[1] => substring-after('/')
      return $config:configFile/id($peer) || '/' || $id
    else $pathToFile
};

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
      let $css := wdb:findProjectFile($model?pathToEd, "/scripts/project.css")
        , $js := wdb:findProjectFile($model?pathToEd, "/scripts/project.js")
      
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
declare function wdb:findProjectFile ( $pathToEd as xs:string, $fileName as xs:string ) as xs:anyURI {
  if ( util:binary-doc-available($pathToEd || "/" || $fileName) ) then
    xs:anyURI($pathToEd || "/" || $fileName)
  else if ( substring-after($pathToEd, $config:data) = '' ) then
    xs:anyURI("")
  else
    wdb:findProjectFile(xstring:substring-before-last($pathToEd, '/'), $fileName)
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
 : @param $ed The (relative) path to the project
 : @param $id The ID of the file to be processed
 : @param $target The processing target to be used
 :
 : @returns The path to the XSLT
:)
declare function wdb:getXslFromWdbMeta ( $infoFileLoc as xs:string, $id as xs:string, $target as xs:string ) as xs:string {
  let $metaFile := doc($infoFileLoc)
    , $process := (
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
        wdb:getXslFromWdbMeta ($path || '/' || $parent/@path, $id, $target)
    else ( util:log("error", $metaFile) )
  
  (: As we check from most specific to default, the first command in the sequence is the right one :)
  return normalize-space($sel[1])
};

(: we need a lookup function for the templating system to work :)
declare variable $wdb:lookup := function($functionName as xs:string, $arity as xs:int) {
    try {
        function-lookup(xs:QName($functionName), $arity)
    } catch * {
        ()
    }
};
(: END LOCAL HELPER FUNCTIONS :)

(: HELPERS FOR REST AND HTTP REQUESTS :)
declare function wdb:parseMultipart ( $data, $header ) {
  let $boundary := $header => substring-after('boundary=') => translate('"', '')
  return map:merge(
    for $m in tokenize($data, "--" || $boundary) return
      if (string-length($m) lt 6)
      then ()
      else
        let $parts := (tokenize($m, "(^\s*$){2}", "m"))[normalize-space() != ""]
        let $header := map:merge( 
          for $line in tokenize($parts[1], "\n") return
            if (normalize-space($line) eq "")
            then ()
            else
              let $val := $line => substring-after(': ') => normalize-space()
              let $value := if (contains($val, '; '))
                then map:merge( 
                  for $entry in tokenize($val, '; ') return
                    if (contains($entry, '='))
                    then map:entry ( substring-before($entry, '='), translate(substring-after($entry, '='), '"', '') )
                    else map:entry ( "text", $entry )
                )
                else $val
              return map:entry(substring-before($line, ': '), $value)
        )
        
        (: empty lines in the body will also cause splitting; hence, recombine everything except the header :)
        return map:entry(($header?Content-Disposition?name, 'name')[1],
            map { "header" : $header, "body" : string-join($parts[position() > 1], '\n') }
        )
  )
};

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
