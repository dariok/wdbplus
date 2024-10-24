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

import module namespace templates = "http://exist-db.org/xquery/html-templating";
import module namespace wdbErr    = "https://github.com/dariok/wdbplus/errors"       at "error.xqm";
import module namespace wdbFiles  = "https://github.com/dariok/wdbplus/files"        at "wdb-files.xqm";
import module namespace wdbPF     = "https://github.com/dariok/wdbplus/projectFiles" at "/db/apps/edoc/data/instance.xqm";
import module namespace xConf     = "http://exist-db.org/xquery/apps/config"         at "config.xqm";
import module namespace xstring   = "https://github.com/dariok/XStringUtils"         at "../include/xstring/string-pack.xql";

declare namespace config = "https://github.com/dariok/wdbplus/config";
declare namespace main   = "https://github.com/dariok/wdbplus";
declare namespace meta   = "https://github.com/dariok/wdbplus/wdbmeta";
declare namespace rest   = "http://exquery.org/ns/restxq";
declare namespace tei    = "http://www.tei-c.org/ns/1.0";

(: ALL-PURPOSE VARIABLES :)
(:~
 : load the config file
 : See https://github.com/dariok/wdbplus/wiki/Global-Configuration
 :)
declare variable $wdb:configFile := doc('../config.xml');

(:~
 : the base of this instance within the db
 :)
declare variable $wdb:edocBaseDB := $wdb:configFile => base-uri() => substring-before('/config.xml');

(:~
 : Get the data collection. Since v4.0, we only support setting this in the config file – for standard installations,
   the default will do just fine.
 :)
declare variable $wdb:data := $wdb:configFile//config:data;

(:~
 : get the base URI either from the configuration
 :)
declare variable $wdb:edocBaseURL := $wdb:configFile//config:server;

(: ~
 : get the base URL for REST calls
 :)
declare variable $wdb:restURL := $wdb:configFile//config:rest;

(:~
 :  the server role
 :)
declare variable $wdb:role := $wdb:configFile//main:role/main:type;

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
declare function wdb:test($node as node(), $model as map(*)) as node() {
<div>
  <h1>APP CONTEXT test on {$wdb:configFile//config:name}</h1>
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
 : Templating function; called from layout.html. Entry point for content pages
 :)
declare
    %templates:default("view", "")
    %templates:default("p", "")
function wdb:getEE($node as node(), $model as map(*), $id as xs:string, $view as xs:string, $p as xs:string) as item()* {
  try {
    let $newModel := wdb:populateModel($id, $view, $model, $p)
    
    return if ( contains($newModel?fileLoc, 'http') ) then
      $newModel
    else
      let $last-modified :=
        wdbFiles:getModificationDate($newModel?filePathInfo?collectionPath, $newModel?filePathInfo?fileName)
          => wdbFiles:ietfDate()
      
      let $requestedModified := (
            request:get-attribute("if-modified"),
            request:get-header("If-Modified-Since")
          )[1]
      let $isModified := if ( $requestedModified != '' )
            then wdbFiles:evaluateIfModifiedSince($id, $requestedModified)
            else 200
      
      (: TODO: use a function to get the actual content language :)
      return  if ( count($newModel) = 1 and $isModified = 200 )
        then (
          response:set-header("Last-Modified", $last-modified),
          <html lang="de">
            {
              for $h in $node/* return
                if ( $h/*[@data-template] ) then
                  for $c in $h/* return try { 
                    templates:apply($c, $wdb:lookup, $newModel)
                  } catch * {
                    util:log("error", $err:description)
                  }
                else
                  try {
                    templates:apply($h, $wdb:lookup, $newModel)
                  } catch * {
                    util:log("error", $err:description)
                  }
            }
          </html>
        )
        else if ( $isModified = 304 ) then
          response:set-status-code(304)
        else
          <html>
            <body>
              <div>
                <p>An unknown error has occurred</p>
              </div>
            </body>
            { util:log("error", $newModel) } 
          </html>
  } catch * {
    util:log("error", $err:code || ': ' || $err:description),
    wdbErr:error(map {
        "code": $err:code,
        "model": $model,
        "err:value": $err:value,
        "err:description": $err:description,
        "err:additional": $err:additional,
        "location": $err:module || '@' || $err:line-number || ':' || $err:column-number
    })
  }
};

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
      xs:anyURI($wdb:data || '/resources/nav.xsl')
    else wdb:getXslFromWdbMeta($infoFileLoc, $id, 'html')
    
    let $xslt := if (doc-available($xsl))
      then $xsl
      else if (doc-available($pathToEd || '/' || $xsl))
      then $pathToEd || '/' || $xsl
      else ""
    
    let $title := normalize-space((doc($pathToFile)//tei:title)[1])
    
    let $proFile := $filePathInfo?mainProject || "/project.xqm"
      , $mainProject := $filePathInfo?mainProject
      , $resource := $filePathInfo?mainProject || "/resources/"
    
    let $projectFunctions := for $function in doc($mainProject || "project-functions.xml")//function
          return $function/@name || '#' || count($function/argument)
      , $instanceFunctions := for $function in doc($wdb:data || "/instance-functions.xml")//function
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
    
    return $map
};

(: ~
 : Create the head for HTML files served via the templating system
 : @created 2018-02-02 DK
 :)
declare function wdb:getHead ( $node as node(), $model as map(*) ) as element(head) {
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="id" content="{$model('id')}"/>
    <meta name="ed" content="{$model("ed")}" />
    <meta name="path" content="{$model('fileLoc')}"/>
    <meta name="rest" content="{$wdb:restURL}" />
    <title>{ $model("title") } – { normalize-space($wdb:configFile//config:short) }</title>

    {
      if ( wdb:findProjectFunction($model, "wdbPF:overrideCssJs", 1) ) then
        (wdb:getProjectFunction($model, "wdbPF:overrideCssJs", 1))($model)
      else (
        <link rel="stylesheet" type="text/css" href="$shared/css/wdb.css" />,
        if ( util:binary-doc-available($wdb:data || "/resources/wdb.css") )
          then <link rel="stylesheet" type="text/css" href="data/resources/wdb.css" />
          else (),
        <link rel="stylesheet" type="text/css" href="$shared/css/view.css" />,
        if ( util:binary-doc-available($wdb:data || "/resources/view.css") )
          then <link rel="stylesheet" type="text/css" href="data/resources/view.css" />
          else (),
        wdb:getBlob($node, $model, 'jquery-ui-css'),
        wdb:getProjectFiles($node, $model, 'css'),
        wdb:getBlob($node, $model, 'jquery'),
        wdb:getBlob($node, $model, 'jquery-ui-js'),
        <script src="$shared/scripts/js.cookie.js"></script>,
        <script src="$shared/scripts/legal.js"></script>,
        <script src="$shared/scripts/function.js"></script>,
        if ( util:binary-doc-available($wdb:data || "/resources/function.js") )
          then <script src="data/resources/function.js"></script>
          else (),
        wdb:getProjectFiles($node, $model, 'js')
      )
    }
  </head>
};

(:~
 : return the header - if there is a project specific function, use it
 :
 : order of evaluation:
 : 1. {$projectResources}/header.html – this must contain one html:header, the
 :    contents of which will be sent through the templating system
 : 2. instance or project specific wdbPF:getHeader#1
 : 3. evaluation of all 4 constituents of the header in a row
 :    a) wdbPF:getHeaderLeft#1 or {$wdb:data}/resources/headerLeft.html or empty html:p
 :    b) wdbPF:getHeaderCentre#1 or {$wdb:data}/resources/headerCentre.html or html:h1
 :    c) wdbPF:getHeaderMenu#1 or {$wdb:data}/resources/headerMenu.html or html:button
 :    d) wdbPF:getHeaderRight#1 or {$wdb:data}/resources/headerRight.html or empty html:p
 :)
declare function wdb:getHeader ( $node as node(), $model as map(*) ) as element() {
  <header>{
    if ( doc-available($model?projectResources || '/header.html') )
      then templates:apply(doc($model?projectResources || '/header.html')/header/*, $wdb:lookup, $model)
    else if ( wdb:findProjectFunction($model, 'wdbPF:getHeader', 1) ) then
      (wdb:getProjectFunction($model, "wdbPF:getHeader", 1))($model)
    else (
      <div class="headerSide" role="navigation">{
        if ( wdb:findProjectFunction($model, 'wdbPF:getHeaderLeft', 1) ) then
          (wdb:getProjectFunction($model, "wdbPF:getHeaderLeft", 1))($model)
        else if ( doc-available($wdb:data || "/resources/headerLeft.html") ) then
          templates:apply(doc($wdb:data || "/resources/headerLeft.html"), $wdb:lookup, $model)/*
        else <p />
      }</div>,
      <div class="headerCentre">{
        if ( wdb:findProjectFunction($model, 'wdbPF:getHeaderCentre', 1) ) then
          (wdb:getProjectFunction($model, "wdbPF:getHeaderCentre", 1))($model)
        else if ( doc-available($wdb:data || "/resources/headerCentre.html") ) then
          templates:apply(doc($wdb:data || "/resources/headerCentre.html"), $wdb:lookup, $model)/*
        else
          <h1>{$model("title")}</h1>
      }</div>,
      <div class="headerMenu" role="navigation">{(
        if ( wdb:findProjectFunction($model, 'wdbPF:getHeaderMenu', 1) ) then
          (wdb:getProjectFunction($model, "wdbPF:getHeaderMenu", 1))($model)
        else if ( doc-available($wdb:data || "/resources/headerMenu.html") ) then
          templates:apply(doc($wdb:data || "/resources/headerMenu.html"), $wdb:lookup, $model)/*
        else <button type="button" class="dispOpts respNav" tabindex="0">≡</button>
      )}</div>,
      <div class="headerSide" role="navigation">{
        if ( wdb:findProjectFunction($model, 'wdbPF:getHeaderRight', 1) ) then
          (wdb:getProjectFunction($model, "wdbPF:getHeaderRight", 1))($model)
        else if ( doc-available($wdb:data || "/resources/headerRight.html") ) then
          templates:apply(doc($wdb:data || "/resources/headerRight.html"), $wdb:lookup, $model)/*
        else <p />
      }</div>
    )
  }</header>
};

declare function wdb:pageTitle($node as node(), $model as map(*)) {
  <title>{ normalize-space($wdb:configFile//main:short) } – { $model("title") }</title>
};

(:~
 : generic function to wrap some info from the model in an HTML element via templating
 :)
declare function wdb:wrapText ( $node as node(), $model as map(*), $key as xs:string ) {
  element { node-name($node) } { $model($key) }
};

(:~
 : return the body
 :)
declare function wdb:getContent($node as node(), $model as map(*)) {
  let $file := if ( ends-with($model?fileLoc, 'wdbmeta.xml') )
    then $model?fileLoc || '#' || $model?id
    else $model?fileLoc
  
  let $xslt := if (string-length($model?xslt) = 0)
    then wdbErr:error(map {"code": "wdbErr:wdb0002", "model": $model})
    else $model("xslt")
  
  let $params :=
    <parameters>
      <param name="exist:stop-on-warn" value="no" />
      <param name="exist:stop-on-error" value="no" />
      <param name="projectDir" value="{$model?pathToEd}" />
      <param name="ed" value="{$model?ed}" />
      {
        if ($model("view") != '')
        then <param name="view" value="{$model("view")}" />
        else ()
      }
      {
        if ($model("p") != '')
        then <param name="p" value="{$model("p")}" />
        else ()
      }
      <param name="xml" value="{$file}" />
      <param name="xsl" value="{$xslt}" />
    </parameters>
  (: do not stop transformation on ambiguous rule match and similar warnings :)
  let $attr := <attributes><attr name="http://saxon.sf.net/feature/recoveryPolicyName" value="recoverSilently" /></attributes>
  
  (: TODO: use generic processXSL function (currently in restFiles.xql but to be moved) so there is only one way of doing things :)
  (: TODO: consider removing this entirely and instead load content of main via AJAX :)
  return
    try {
      <main>
        { transform:transform(doc($file), doc($xslt), $params, $attr, "") }
        { wdb:getLeftFooter($node, $model) }
      </main>
    } catch * { (util:log("error",
      <report>
        <file>{$file}</file>
        <xslt>{$xslt}</xslt>
        {$params}
        {$attr}
        <error>{$err:code || ': ' || $err:description}</error>
        <error>{$err:module || '@' || $err:line-number ||':'||$err:column-number}</error>
        <additional>{$err:additional}</additional>
      </report>),
      wdbErr:error(map{"code": "wdbErr:wdb1001", "model": $model, "additional": $params, "error": map {
          "code": $err:code, "desc": $err:description, "module": $err:module, "line": $err:line-number,
          "col": $err:column-number, "add": $err:additional
      }}))
    }
};

(:~
 : return the global (i.e., full width) footer
 :
 : order of evaluation:
 : 1. {$wdb:data}/resources/mainFooter.html
 : 2. {$projectResources}/mainFooter.html
 : 3. wdbPF:getMainFooter#1
 :)
declare function wdb:getGlobalFooter($node as node(), $model as map(*)) {
  if ( doc-available($wdb:data || "/resources/mainFooter.html") )
    then templates:apply(doc($wdb:data || "/resources/mainFooter.html"),  $wdb:lookup, $model)
  else if ( doc-available($model?projectResources || '/mainFooter.html') ) 
    then templates:apply(doc($model?projectResources || '/mainFooter.html'), $wdb:lookup, $model)
  else if ( wdb:findProjectFunction($model, "wdbPF:getMainFooter", 1) ) then
    (wdb:getProjectFunction($model, "wdbPF:getMainFooter", 1))($model)
  else ()
};

declare function wdb:getLeftFooter($node as node(), $model as map(*)) as element()? {
  if (doc-available($model?projectResources || "/footer.html")) then
    templates:apply(doc($model?projectResources || "/footer.html"), $wdb:lookup, $model)
  else if (wdb:findProjectFunction($model, "wdbPF:getProjectFooter", 1)) then
    (wdb:getProjectFunction($model, "wdbPF:getProjectFooter", 1))($model)
  else if (doc-available($wdb:edocBaseDB || "/resources/footer.html")) then
    templates:apply(doc($wdb:edocBaseDB || "/resources/footer.html"), $wdb:lookup, $model)
  else ()
};
declare function wdb:getRightFooter($node as node(), $model as map(*)) as element()? {
  if (doc-available($model?projectResources || "/projectRightFooter.html")) then
    templates:apply(doc($model?projectResources || "/projectRightFooter.html"), $wdb:lookup, $model)
  else if (wdb:findProjectFunction($model, "wdbPF:getProjectRightFooter", 1)) then
    (wdb:getProjectFunction($model, "wdbPF:getProjectRightFooter", 1))($model)
  else if (doc-available($wdb:data || "/resources/rightFooter.html")) then
    templates:apply(doc($wdb:data || "/resources/rightFooter.html"), $wdb:lookup, $model)
  else ()
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
  let $files := wdbFiles:getFilePaths($wdb:data, $id)
  
  (: do not just return a random URI but add some checks for better error messages:
   : no files found or more than one TEI file found or only wdbmeta entry but no other info :)
  let $pathToFile := if ( count($files) = 0 ) then
      error(
        QName('https://github.com/dariok/wdbErr', 'wdb0000'),
        "no file with ID " || $id || " in " || $wdb:data,
        map { "id": $id, "request": request:get-url() }
      )
    else if ( count($files) > 1 ) then
      error(
        QName('https://github.com/dariok/wdbErr', 'wdb0001'),
        "multiple files with ID " || $id || " in " || $wdb:data,
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
      return $wdb:configFile/id($peer) || '/' || $id
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
  let $tok := tokenize(xstring:substring-after($path, $wdb:edocBaseDB||'/'), '/')
  
  let $pa := for $i in 1 to count($tok)
    let $t := $wdb:edocBaseDB || '.*' || string-join ($tok[position() < $i+1], '/')
    return xmldb:match-collection($t)
  
  let $path := if (count($pa) = 0)
  then
    wdbErr:error(map{"code": "wdbErr:wdb2001", "additional": <additional><path>{$path}</path></additional>})
  else for $p in $pa
    order by string-length($p) descending
    
    return if ( doc-available($p || '/wdbmeta.xml') ) then $p else ()
  
  return if ( $absolute )
    then $path[1]
    else substring-after($path[1], $wdb:edocBaseDB||'/')
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
  else if ( substring-after($pathToEd, $wdb:data) = '' ) then
    xs:anyURI("")
  else
    wdb:findProjectFile(xstring:substring-before-last($pathToEd, '/'), $fileName)
};
(: END FUNCTIONS DEALING WITH PROJECTS AND RESOURCES :)

(: GENERAL HELPER FUNCTIONS :)
declare function wdb:getUrl ( $path as xs:string ) as xs:string {
  $wdb:edocBaseURL || substring-after($path, $wdb:edocBaseDB)
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

(:~
 : Return the full path to the project collection by trying to find the meta file by the project ID
 :
 : @param $ed The ID of a project, to be found in meta:projectMD/@xml:id
 : @return The path to the project 
 :)
declare function wdb:getProjectPathFromId ( $ed as xs:string ) as xs:string {
  if ( $ed = ( "", "data" ) )
    then $wdb:data
    else string( (doc("/db/apps/edoc/index/project-index.xml")/id($ed))/@path )
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
  
  let $sel := if ( $process/meta:command )
    then
      for $c in $process/meta:command
        return if ( $c/@refs ) then
          (: if a list of IDREFS is given, this command matches if $id is part of that list :)
          let $map := tokenize($c/@refs, ' ')
          return if ( $map = $id ) then $c else ()
        else if ( $c/@regex and matches($id, $c/@regex) )
          (: if a regex is given and $id matches that regex, the command matches :)
          then $c
        else if ( $c/@group and $metaFile/id($id)/parent::meta:filegroup/@xml:id = $c/@group )
          then $c
        else if ( not($c/@refs or $c/@regex or $c/@group) )
          (: if no selection method is given, the command is considered the default :)
          then $c
        else () (: neither refs nor regex match and no default given :)
    (: if no command is defined, traverse up the project ancestors :)
    else if ( $metaFile/meta:projectMD/meta:struct/*[1][self::meta:import] ) then
      let $path := xstring:substring-before-last($infoFileLoc, '/')
        , $parent := $metaFile/meta:projectMD/meta:struct/meta:import
      return
        wdb:getXslFromWdbMeta ($path || '/' || $parent/@path, $id, $target)
    else ( )
  
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
  let $path := $wdb:configFile//config:source[@name = $name]/@path
  
  return if ( ends-with($path, 'js') )
    then <script src="{ $path }"></script>
    else <link rel="stylesheet" type="text/css" href="{ $path }" />
};
(: END HELPERS FOR REST AND HTTP REQUESTS :)
