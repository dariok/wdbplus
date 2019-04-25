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
declare namespace templates = "http://exist-db.org/xquery/templates";
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
    
    return wdb:getServerApp() || replace($path, '//', '/')
;

(: ~
 : get the base URL for REST calls
 :)
declare variable $wdb:restURL := 
  if ($wdb:configFile//config:rest)
  then normalize-space($wdb:configFile//config:rest)
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
  <h2>global variables (app.xqm)</h2>
  <dl>
    {
      for $var in inspect:inspect-module(xs:anyURI("app.xqm"))//variable
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
        return (
          <dt>{$var}</dt>,
          <dd><pre>{request:get-header($var)}</pre></dd>
        )
    }
  </dl>
  <h2>$model</h2>
  { local:get($model, "") }
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
    %templates:wrap
    %templates:default("view", "")
function wdb:getEE($node as node(), $model as map(*), $id as xs:string, $view as xs:string) as item() {
  wdb:populateModel($id, $view, $model)
};

(:~
 : Populate the model with the most important global settings when displaying a file
 : Moved to a separate function as this one may be called by other functions, too
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
    else ""
  
  let $title := normalize-space((doc($pathToFile)//tei:title)[1])
  
  let $proFile := wdb:findProjectXQM($pathToEd)
  let $resource := substring-before($proFile, "project.xqm") || "resources/"
  
  (: TODO read global parameters from config.xml and store as a map :)
  let $map := map {
    "ed" := normalize-space(doc($infoFileLoc)/*[1]/@xml:id),
    "fileLoc" := $pathToFile,
    "id" := $id,
    "infoFileLoc" := $infoFileLoc,
    "pathToEd" := $pathToEd,
    "projectFile" := $proFile,
    "projectResources" := $resource,
    "title" := $title,
    "view" := $view,
    "xslt" := $xslt}
  
  (: let $t := console:log($map) :)
  
  return $map
} catch * {
  wdbErr:error(map {"code" := $err:code, "pathToEd" := $wdb:data, "ed" := $wdb:data, "model" := $model, "value" := $err:value, "desc": $err:description })
}
};

(: ~
 : Create the head for HTML files served via the templating system
 : @created 2018-02-02 DK
 :)
declare function wdb:getHead ($node as node(), $model as map(*)) {
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <meta name="id" content="{$model('id')}"/>
    <meta name="ed" content="{$model("ed")}" />
    <meta name="path" content="{$model('fileLoc')}"/>
    <meta name="rest" content="{$wdb:restURL}" />
    <title>{normalize-space($wdb:configFile//main:short)} – {$model("title")}</title>
    <link rel="stylesheet" type="text/css" href="{$wdb:edocBaseURL}/resources/css/wdb.css" />
    <link rel="stylesheet" type="text/css" href="{$wdb:edocBaseURL}/resources/css/view.css" />
    <link rel="stylesheet" type="text/css" href="{$wdb:edocBaseURL}/resources/scripts/jquery-ui/jquery-ui.min.css" />
    {wdb:getProjectFiles($node, $model, 'css')}
    <script src="https://cdn.jsdelivr.net/npm/cookieconsent@3/build/cookieconsent.min.js" />
    <script src="resources/scripts/legal.js"/>
    <script src="{$wdb:edocBaseURL}/resources/scripts/jquery.min.js" />
    <script src="{$wdb:edocBaseURL}/resources/scripts/jquery-ui/jquery-ui.min.js" />
    <script src="{$wdb:edocBaseURL}/resources/scripts/js.cookie.js" />
    <script src="{$wdb:edocBaseURL}/resources/scripts/function.js" />
    {wdb:getProjectFiles($node, $model, 'js')}
  </head>
};
(:~
 : return the header - if there is a project specific function, use it
 :)
declare function wdb:getHeader ( $node as node(), $model as map(*) ) {
  let $functionAvailable := if (wdb:findProjectFunction($model, 'getHeader', 1))
  then system:function-available(xs:QName("wdbPF:getHeader"), 1)
  else false()
  
  return
    <header>{
      if ($functionAvailable = true())
      then util:eval("wdbPF:getHeader($model)", false(), (xs:QName('map'), $model))
      else
        <h1>{$model("title")}</h1>
      }
      <span class="dispOpts"><a id="searchLink" href="search.html?id={$model("ed")}">Suche</a></span>
      <span class="dispOpts"><a id="showNavLink" href="javascript:toggleNavigation();">Navigation einblenden</a></span>
      <hr/>
      <nav style="display:none;" />
    </header>
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
  
  let $xslt := if ($model("xslt") != "")
  then $model("xslt")
  else wdbErr:error(map {"code" := "wdbErr:wdb0002", "model" := $model})
  
  let $params :=
    <parameters>
      <param name="server" value="eXist"/>
      <param name="exist:stop-on-warn" value="no" />
      <param name="exist:stop-on-error" value="no" />
      <param name="projectDir" value="{$model('ed')}" />
      {
        if ($model("view") != '')
        then <param name="view" value="{$model("view")}" />
        else ()
      }
    </parameters>
  (: do not stop transformation on ambiguous rule match and similar warnings :)
  let $attr := <attributes><attr name="http://saxon.sf.net/feature/recoveryPolicyName" value="recoverSilently" /></attributes>
  
  return
    try {
      <div id="wdbContent">
        { transform:transform(doc($file), doc($xslt), $params, $attr, "expand-xincludes=no") }
        {wdb:getFooter($file, $xslt)}
      </div>
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
      wdbErr:error(map{"code" := "wdbErr:wdb1001", "model" := $model, "additional" := $params}))
    }
};

declare function wdb:getFooter($xm as xs:string, $xs as xs:string) {
  let $xml := if (starts-with($xm, 'http'))
  then $xm
  else wdb:getUrl($xm)
  
  let $xsl := if (starts-with($xs, 'http'))
  then $xs
  else wdb:getUrl($xs)
  
  return
    <footer>
      <span>XML: <a href="{$xml}" target="_blank">{$xml}</a></span>
      <span>XSL: <a href="{$xsl}" target="_blank">{$xsl}</a></span>
    </footer>
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
  let $files := collection($wdb:data)/id($id)
  
  (: do not just return a random URI but add some checks for better error messages:
   : no files found or more than one TEI file found or only wdbmeta entry but no other info :)
  let $pathToFile := if (count($files) = 0)
    then fn:error(fn:QName('https://github.com/dariok/wdbErr', 'wdb0000'), "no file with ID " || $id || " in " || $wdb:data)
    else if (count($files[not(namespace-uri() = "https://github.com/dariok/wdbplus/wdbmeta")]) > 1)
    then fn:error(fn:QName('https://github.com/dariok/wdbErr', 'wdb0001'))
    else if (count($files[not(namespace-uri() = "https://github.com/dariok/wdbplus/wdbmeta")]) = 1)
    then base-uri($files[not(namespace-uri() = "https://github.com/dariok/wdbplus/wdbmeta")])
    else if (count($files[self::meta:file]) = 1
        and (starts-with($files[1]/@path, '/') or contains($files[1]/@path, '://')))
    then $files[1]/@path
    else if (contains(base-uri($files[1]), 'wdbmeta.xml'))
    then
        let $p := base-uri($files[1])
        return substring-before($p, 'wdbmeta.xml') || $files[1]/@path
    else
    fn:error(fn:QName('https://github.com/dariok/wdbErr', 'wdb0100'), "no single file with given @xml:id (" || $id || ") and no fallback")
    
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
  let $file := collection($wdb:data)/id($id)[self::meta:file or self::meta:projectMD]
  
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
 : @param $path a path to a file within the project, usually wdbmeta.xml or mets.xml
 : @return the path relative to the app root
 :)
declare function wdb:getEdPath($path as xs:string) as xs:string {
  wdb:getEdPath($path, false())
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
    (
      try {
        if (util:binary-doc-available($wdb:edocBaseURL||"/"||$model('ed')||"/scripts/project.css"))
        then <link rel="stylesheet" type="text/css" href="{$wdb:edocBaseURL}/{$model('ed')}/scripts/project.css" />
        else ()
      } catch * { () },
      try {
        if (util:binary-doc-available($wdb:edocBaseURL||"/"||$model('ed')||"/scripts/project.js"))
        then <script src="{$wdb:edocBaseURL}/{$model('ed')}/scripts/project.js" />
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
 : 
 : @param $model a map of parameters that conforms to the global structure
 : @param $name the (local) name of the function to be looked for
 : @param $arity the arity (i.e. number of arguments) of said function
 : @return true() if project.xqm exists for the project and contains a function
 : with the given parameters; else() otherwise.
 :)
declare function wdb:findProjectFunction ($model as map(*), $name as xs:string, $arity as xs:integer) as xs:boolean {
  let $location := wdb:findProjectXQM($model("pathToEd"))
  
  return if ($location instance of xs:boolean and $location = false())
  then false()
  else
    let $module := util:import-module(xs:anyURI("https://github.com/dariok/wdbplus/projectFiles"), 'wdbPF',
        xs:anyURI($location))
    return system:function-available(xs:QName("wdbPF:" || $name), $arity)
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
declare
function local:getXslFromWdbMeta($infoFileLoc as xs:string, $id as xs:string, $target as xs:string) {
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

(: format a map’s content (identical to error.xqm) :)
declare function local:get($map as map(*), $prefix as xs:string) {
  for $key in map:keys($map)
    let $pr := if ($prefix = "") then $key else $prefix || ' → ' || $key
    return try {
      local:get($map($key), $pr)
    } catch * {
      let $value := try { xs:string($map($key)) } catch * { "err" }
      return <p><b>{$pr}: </b> {$value}</p>
    }
};
(: END LOCAL HELPER FUNCTIONS :)