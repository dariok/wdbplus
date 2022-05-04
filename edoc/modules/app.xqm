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

import module namespace console   = "http://exist-db.org/xquery/console";
import module namespace templates = "http://exist-db.org/xquery/html-templating";
import module namespace wdbErr    = "https://github.com/dariok/wdbplus/errors"   at "error.xqm";
import module namespace wdbFiles  = "https://github.com/dariok/wdbplus/files"    at "wdb-files.xqm";
import module namespace xConf     = "http://exist-db.org/xquery/apps/config"     at "config.xqm";
import module namespace xstring   = "https://github.com/dariok/XStringUtils"     at "../include/xstring/string-pack.xql";

declare namespace config = "https://github.com/dariok/wdbplus/config";
declare namespace main   = "https://github.com/dariok/wdbplus";
declare namespace meta   = "https://github.com/dariok/wdbplus/wdbmeta";
declare namespace mets   = "http://www.loc.gov/METS/";
declare namespace rest   = "http://exquery.org/ns/restxq";
declare namespace tei    = "http://www.tei-c.org/ns/1.0";
declare namespace wdbPF  = "https://github.com/dariok/wdbplus/projectFiles";
declare namespace xlink  = "http://www.w3.org/1999/xlink";

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
  if ($wdb:configFile//config:data)
  then normalize-space($wdb:configFile//config:data)
  else 
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
    
    return wdb:getServerApp() || replace($path, '//', '/')
;

(: ~
 : get the base URL for REST calls
 :)
declare variable $wdb:restURL := 
  if ($wdb:configFile//config:rest)
  then normalize-space($wdb:configFile//config:rest)
  else if ($wdb:edocBaseURL = "") 
  then rest:base-uri() || "/edoc"
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
    return if ($scheme != "") then $scheme || '//' || $server else ()
  
  let $origin := try { request:get-header("Origin") } catch * { () }
  let $request := try {
    let $scheme := if (request:get-header-names() = 'X-Forwarded-Proto')
      then normalize-space(request:get-header('X-Forwarded-Proto'))
      else normalize-space(request:get-scheme())
    
    return if (request:get-server-port() != 80)
      then $scheme || '://' || request:get-server-name() || ':' || request:get-server-port()
      else $scheme || '://' || request:get-server-name()
  } catch * { () }
  let $ref := try {
    let $r := request:get-header('referer')
    let $scheme := substring-before($r, '://')
    let $server := substring-before(substring-after($r, '://'), '/')
    return $scheme || '://' || $server
  } catch * { () }
  
  let $server := ($config, $request, $ref, $origin)
  return if (count($server) > 0)
    then $server[1]
    else ""
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
  let $newModel := wdb:populateModel($id, $view, $model, $p)
  
  (: TODO: use a function to get the actual content language :)
  return 
    <html lang="de">
      {
        for $h in $node/* return
          if ( $h/*[@data-template] )
            then for $c in $h/* return try { templates:apply($c, $wdb:lookup, $newModel) } catch * { util:log("error", $err:description) }
            else templates:apply($h, $wdb:lookup, $newModel)
      }
    </html>
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
try {
  let $pTF := wdb:getFilePath($id)
  let $pathToFile := if ( sm:has-access($pTF, "r") )
    then $pTF
    else error(xs:QName("wdbErr:wdb0004"))
  
  let $pathToEd := wdb:getEdPath($id, true())
  let $pathToEdRel := substring-after($pathToEd, $wdb:edocBaseDB||'/')
  
  (: The meta data are taken from wdbmeta.xml or a mets.xml as fallback :)
  let $infoFileLoc := wdb:getMetaFile($pathToEd)
  
  let $ed := if (ends-with($infoFileLoc, 'wdbmeta.xml'))
    then string(doc($infoFileLoc)/meta:projectMD/@xml:id)
    else string(doc($infoFileLoc)/mets:mets/@OBJID)
  
  let $xsl := if (ends-with($infoFileLoc, 'wdbmeta.xml'))
    then wdb:getXslFromWdbMeta($infoFileLoc, $id, 'html')
    else wdb:getXslFromMets($infoFileLoc, $id, $pathToEdRel)
  
  let $xslt := if (doc-available($xsl))
    then $xsl
    else if (doc-available($pathToEd || '/' || $xsl))
    then $pathToEd || '/' || $xsl
    else ""
  
  let $title := normalize-space((doc($pathToFile)//tei:title)[1])
  
  let $proFile := wdb:findProjectXQM($pathToEd)
  let $resource := substring-before($proFile, "project.xqm") || "resources/"
  
  (: TODO read global parameters from config.xml and store as a map :)
  let $map := map {
    "ed":               $ed,
    "fileLoc":          $pathToFile,
    "functions":        load-xquery-module(
                            "https://github.com/dariok/wdbplus/projectFiles",
                            map { "location-hints": $proFile }
                        ),
    "id":               $id,
    "infoFileLoc":      $infoFileLoc,
    "p":                $p,
    "pathToEd":         $pathToEd,
    "projectFile":      $proFile,
    "projectResources": $resource,
    "title":            $title,
    "view":             $view,
    "xslt":             $xslt
  }
  
  return $map
} catch * {
  wdbErr:error(map {
    "code":     $err:code,
    "pathToEd": $wdb:data,
    "ed":       $wdb:data,
    "model":    $model,
    "value":    $err:value,
    "desc":     $err:description,
    "location": $err:module || '@' || $err:line-number ||':'||$err:column-number
  })
}
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
      if ( wdb:findProjectFunction(map { "pathToEd": $wdb:data }, "overrideCssJs", 1) ) then
        wdb:eval("wdbPF:overrideCssJs($model)", false(), (xs:QName("model"), $model))
      else (
        <link rel="stylesheet" type="text/css" href="$shared/css/wdb.css" />,
        if ( util:binary-doc-available($wdb:data || "/resources/wdb.css") )
          then <link rel="stylesheet" type="text/css" href="$shared/../data/resources/wdb.css" />
          else (),
        <link rel="stylesheet" type="text/css" href="$shared/css/view.css" />,
        if ( util:binary-doc-available($wdb:data || "/resources/view.css") )
          then <link rel="stylesheet" type="text/css" href="$shared/../data/resources/view.css" />
          else (),
        if ( $model?annotation = true() )
          then <link rel="stylesheet" type="text/css" href="https://code.jquery.com/ui/1.12.1/themes/base/jquery-ui.min.css" />
          else (),
        wdb:getProjectFiles($node, $model, 'css'),
        <script src="https://code.jquery.com/jquery-3.5.1.min.js"></script>,
        if ( $model?annotation = true() )
          then <script src="https://code.jquery.com/ui/1.12.1/jquery-ui.min.js"></script>
          else (),
        <script src="$shared/scripts/js.cookie.js"></script>,
        <script src="$shared/scripts/legal.js"></script>,
        <script src="$shared/scripts/function.js"></script>,
        if ( util:binary-doc-available($wdb:data || "/resources/function.js") )
          then <script src="$shared/../data/resources/function.js"></script>
          else (),
        wdb:getProjectFiles($node, $model, 'js')
      )
    }
  </head>
};

(:~
 : return the header - if there is a project specific function, use it
 :)
declare function wdb:getHeader ( $node as node(), $model as map(*) ) as element() {
  <header>{
    if ( wdb:findProjectFunction($model, 'getHeader', 1) ) then (
      util:eval("wdbPF:getHeader($model)", false(), (xs:QName('map'), $model))
    )
    else (
      <div class="headerSide" role="navigation">{
        if ( wdb:findProjectFunction($model, 'getHeaderLeft', 1) ) then
          util:eval("wdbPF:getHeaderLeft($model)", false(), (xs:QName('map'), $model))
        else if ( doc-available($wdb:data || "/resources/headerLeft.html") )
        then templates:apply(doc($wdb:data || "/resources/headerLeft.html"),  $wdb:lookup, $model)/*
        else <p />
      }</div>,
      <div class="headerCentre">{
        (: TODO: this is a proof of concept; this whole part has to be updated for #507 and #508 :)
        let $f := wdb:getProjectFunction($model, 'getHeaderCentre', 1)
        return if ( count($f) eq 1 ) then
          $f($model)
        else if ( doc-available($wdb:data || "/resources/headerCentre.html") ) then
          templates:apply(doc($wdb:data || "/resources/headerCentre.html"),  $wdb:lookup, $model)/*
        else
          <h1>{$model("title")}</h1>
      }</div>,
      <div class="headerMenu" role="navigation">{(
        if ( wdb:findProjectFunction($model, 'getHeaderMenu', 1) ) then
          util:eval("wdbPF:getHeaderMenu($model)", false(), (xs:QName('map'), $model))
        else if ( doc-available($wdb:data || "/resources/headerMenu.html") )
        then templates:apply(doc($wdb:data || "/resources/headerMenu.html"),  $wdb:lookup, $model)/*
        else <button type="button" class="dispOpts respNav" tabindex="0">≡</button>
      )}</div>,
      <div class="headerSide" role="navigation">{
        if ( wdb:findProjectFunction($model, 'getHeaderRight', 1) ) then
          util:eval("wdbPF:getHeaderRight($model)", false(), (xs:QName('map'), $model))
        else if ( doc-available($wdb:data || "/resources/headerRight.html") )
        then templates:apply(doc($wdb:data || "/resources/headerRight.html"),  $wdb:lookup, $model)/*
        else <p />
      }</div>
    )
  }</header>
};

declare function wdb:pageTitle($node as node(), $model as map(*)) {
	let $ti := $model("title")
	return <title>{normalize-space($wdb:configFile//main:short)} – {$ti}</title>
};

(:~
 : return the body
 :)
declare function wdb:getContent($node as node(), $model as map(*)) {
  let $file := $model("fileLoc")
  
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
  
  return
    try {
      <main>
        { transform:transform(doc($file), doc($xslt), $params, $attr, "expand-xincludes=no") }
        { wdb:getLeftFooter($node, $model) }
      </main>
    } catch * { (console:log(
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

declare function wdb:getGlobalFooter($node as node(), $model as map(*)) {
  if ( doc-available($wdb:data || "/resources/mainFooter.html") )
  then templates:apply(doc($wdb:data || "/resources/mainFooter.html"),  $wdb:lookup, $model)
  else ()
};

declare function wdb:getLeftFooter($node as node(), $model as map(*)) {
  let $projectAvailable := wdb:findProjectXQM($model?pathToEd)
  let $functionsAvailable := if ($projectAvailable)
    then util:import-module(xs:anyURI("https://github.com/dariok/wdbplus/projectFiles"), 'wdbPF',
        xs:anyURI($projectAvailable))
    else false()
  
  return if (doc-available($model?projectResources || "/footer.html"))
  then templates:apply(doc($model?projectResources || "/footer.html"),  $wdb:lookup, $model)
  else if (wdb:findProjectFunction($model, "getProjectFooter", 1))
  then wdb:eval("wdbPF:getProjectFooter($model)", false(), (xs:QName("model"), $model))
  else if (doc-available($wdb:edocBaseDB || "/resources/footer.html"))
  then doc($wdb:edocBaseDB || "/resources/footer.html")
  else ()
};
declare function wdb:getRightFooter($node as node(), $model as map(*)) {
  if (doc-available($model?projectResources || "/projectRightFooter.html"))
  then doc($model?projectResources || "/projectRightFooter.html")
  else if (wdb:findProjectFunction($model, "getProjectRightFooter", 1))
  then wdb:eval("wdbPF:getProjectRightFooter($model)", false(), (xs:QName("model"), $model))
  else if (doc-available($wdb:data || "/resources/rightFooter.html"))
  then doc($wdb:data || "/resources/rightFooter.html")
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
 :)
declare function wdb:getFilePath($id as xs:string) as xs:string {
  let $files := wdbFiles:getFilePaths($wdb:data, $id)
  
  (: do not just return a random URI but add some checks for better error messages:
   : no files found or more than one TEI file found or only wdbmeta entry but no other info :)
  let $pathToFile := if (count($files) = 0)
      then fn:error(fn:QName('https://github.com/dariok/wdbErr', 'wdb0000'), "no file with ID " || $id || " in " || $wdb:data)
    else if (count($files) > 1)
      then fn:error(fn:QName('https://github.com/dariok/wdbErr', 'wdb0001'), "multiple files with ID " || $id || " in " || $wdb:data)
    else (: (count($files) = 1) :)
      xstring:substring-before-last(base-uri($files[1]), '/') || '/' || $files[1]
  
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
  let $file := (collection($wdb:data)/id($id)[self::meta:file or self::meta:projectMD or self::mets:mets],
                collection($wdb:data)//mets:file[@ID = $id])[1]
  
  let $edPath := if (count($file) = 1)
    then xstring:substring-before-last(base-uri($file), '/')
    else if (count($file) > 1)
    then fn:error(fn:QName('https://github.com/dariok/wdbErr', 'wdb0001'))
    else fn:error(fn:QName('https://github.com/dariok/wdbErr', 'wdb0200'))
  
  return if ($absolute) then replace($edPath, '//', '/') else substring-after($edPath, $wdb:edocBaseDB)
};

(:~
 : Return the relative path to the project
 : 
 : @param $id the ID of a resource within a project
 : @return the path relative to the app root
 :)
declare function wdb:getEdPath($id as xs:string) as xs:string {
  wdb:getEdPath($id, false())
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
    else wdb:getEdPath($ed, true()) || "/" || $path
};

(:~
 : Return the ID of a project from a resource ID within the project
 : 
 : @param $id the ID of a resource within a project
 : @return the ID of the project
 :)
declare function wdb:getEdFromFileId ($id as xs:string) as xs:string {
  let $file := (collection($wdb:data)/id($id)[self::meta:file],
                collection($wdb:data)//mets:file[@ID = $id])[1]
  return if ($file[self::meta:file])
    then $file/ancestor::meta:projectMD/@xml:id
    else $file/ancestor::mets:mets/@OBJID
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
    let $p1 := $p || '/wdbmeta.xml'
    let $p2 := $p || '/mets.xml'
    
    return if (doc-available($p1) or doc-available($p2)) then $p else ()
  
  return if ($absolute)
    then $path[1]
    else substring-after($path[1], $wdb:edocBaseDB||'/')
};
(:~
 : Try ro load project specific XQuery to import CSS and JS
 : @created 2018-02-02 DK
 :)
declare function wdb:getProjectFiles ( $node as node(), $model as map(*), $type as xs:string ) as node()* {
  let $files := if (wdb:findProjectFunction($model, 'getProjectFiles', 1))
  then util:eval("wdbPF:getProjectFiles($model)", false(), (xs:QName('map'), $model)) 
  else
    (: no specific function available, so we assume standards
     : this requires some eXistology: binary-doc-available does not return false, if the file does not exist,
     : but rather throws an error... :)
    let $css := $model?pathToEd || "/scripts/project.css",
        $js := $model?pathToEd || "/scripts/project.js"
	
    return
    (
      try {
        if (util:binary-doc-available($css))
        then <link rel="stylesheet" type="text/css" href="{wdb:getUrl($css)}" />
        else ()
      } catch * { () },
      try {
        if (util:binary-doc-available($js))
        then <script src="{wdb:getUrl($js)}" />
        else ()
      } catch * { () }
    )
  
  return if ($type = 'css')
    then $files[self::*:link]
    else $files[self::*:script]
};

(:~ 
 : Look up $function in the given project's project.xqm if it exists
 : This involves registering the module: if the function is available, it can
 : immediately be used by the calling script if this lookup is within the caller's scope
 : The scope is the project as given in $model("pathToEd")
 : !!! A global data/project.xqm will interfere with this mechanism as the new module will not be loaded due to
 :     conflicting module URIs
 : 
 : @param $model a map of parameters that conforms to the global structure
 : @param $name the (local) name of the function to be looked for
 : @param $arity the arity (i.e. number of arguments) of said function
 : @return true() if project.xqm exists for the project and contains a function
 : with the given parameters; else() otherwise.
 :)
declare function wdb:findProjectFunction ($model as map(*), $name as xs:string, $arity as xs:integer) as xs:boolean {
  let $location := wdb:findProjectXQM($model("pathToEd"))
  let $functionName := if (starts-with($name, 'wdbPF:')) then $name else 'wdbPF:' || $name
  
  return if ($location instance of xs:boolean and $location = false())
  then false()
  else
    let $module := util:import-module(xs:anyURI("https://github.com/dariok/wdbplus/projectFiles"), 'wdbPF',
        xs:anyURI($location))
    return system:function-available(xs:QName($functionName), $arity)
};

(:~ 
 : Load the project.xqm given in $model?projectFile and return the function with the given name and arity iif it exists
 : 
 : @param $model a map of parameters that conforms to the global structure
 : @param $name the (local) name of the function to be looked for
 : @param $arity the arity (i.e. number of arguments) of said function
 : @return function(*)? a function item representing the function if it was found, the empry sequence otherwise
 :)
declare function wdb:getProjectFunction ( $model as map(*), $name as xs:string, $arity as xs:integer ) as function(*)? {
  try {
    let $functionName := if ( starts-with($name, 'wdbPF:') ) then $name else 'wdbPF:' || $name
    
    return $model?functions?functions(xs:QName($functionName))($arity)
  } catch * {
    ()
  }
};

(:~
 : Lookup a project's project.xqm: if present in $model("pathToEd"), use it; else, ascend and look for project.xqm
 : there. Use if present. Ulitmately, if even $wdb:data/project.xqm does not exist, panic.
 :
 : @param $project a string representation of the path to the project
 : @returns the path to a project.xqm if one was found; false() otherwise
 :)
declare function wdb:findProjectXQM ($project as xs:string) {
  if (util:binary-doc-available($project || "/project.xqm"))
  then $project || "/project.xqm"
  else if (substring-after($project, $wdb:data) = '')
  then fn:error(fn:QName('https://github.com/dariok/wdbErr', 'wdb0020'), "cannae find project.xqm anywhere")
  else wdb:findProjectXQM(xstring:substring-before-last($project, '/'))
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
 : @param $ed The ID of a project, to be found in meta:projectMD/@xml:id or mets:mets/@OBJID
 : @return The path to the project 
 :)
declare function wdb:getProjectPathFromId ( $ed as xs:string ) as xs:string {
  let $md := (
    collection($wdb:data)/id($ed)[self::meta:projectMD],
    collection($wdb:data)/mets:mets[@OBJID = $ed]
  )
  return xstring:substring-before-last(base-uri(($md)[1]), '/')
};

(:~
 : Get the meta data file from the ed path
 :)
declare function wdb:getMetaFile($pathToEd) {
  if (doc-available($pathToEd||'/wdbmeta.xml'))
    then $pathToEd || '/wdbmeta.xml'
    else if (doc-available($pathToEd || '/mets.xml'))
    then $pathToEd || '/mets.xml'
    else fn:error(fn:QName('https://github.com/dariok/wdbErr', 'wdbErr:wdb0003'))
};

(:~
 : Get the meta data file by project ID
 : 
 : @param $ed The project ID to be evaluated
 :)
declare function wdb:getMetaElementFromEd ( $ed as xs:string ) as element() {
  collection($wdb:data)/id($ed)[self::meta:projectMD or self::mets:mets]
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
  let $metaFile := doc($infoFileLoc),
      $process := (
        $metaFile//meta:process[@target = $target],
        $metaFile//meta:process[1]
      )[1]
  
  let $sel := for $c in $process/meta:command
    return if ( $c/@refs )
      then
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
  
  (: As we check from most specific to default, the first command in the sequence is the right one :)
  return ($sel)[1]/text()
};
declare function wdb:getXslFromMets ($metsLoc, $id, $ed) {
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
declare function wdb:parseMultipart ( $data, $postHeader ) {
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
        let $t := 'abs'

        return if ( $q ) then
          'application/xquery'
        else
          $t
    
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
(: END HELPERS FOR REST AND HTTP REQUESTS :)
