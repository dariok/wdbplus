xquery version "3.1";

module namespace wdbfp = "https://github.com/dariok/wdbplus/functionpages";

import module namespace console   = "http://exist-db.org/xquery/console"         at "java:org.exist.console.xquery.ConsoleModule";
import module namespace templates = "http://exist-db.org/xquery/html-templating" at "/db/system/repo/templating-1.0.2/content/templates.xqm";
import module namespace wdb       = "https://github.com/dariok/wdbplus/wdb"      at "/db/apps/edoc/modules/app.xqm";
import module namespace wdbErr    = "https://github.com/dariok/wdbplus/errors"   at "/db/apps/edoc/modules/error.xqm";
import module namespace wdbSearch = "https://github.com/dariok/wdbplus/wdbs"     at "/db/apps/edoc/modules/search.xqm";
import module namespace wdbst     = "https://github.com/dariok/wdbplus/start"    at "/db/apps/edoc/modules/start.xqm";
import module namespace xstring   = "https://github.com/dariok/XStringUtils"     at "/db/apps/edoc/include/xstring/string-pack.xql";

declare namespace meta = "https://github.com/dariok/wdbplus/wdbmeta";

(:~
 : populate the model for functions pages (similar but not identical to wdb:populateModel)
 : 
 : @param $ed The ID of a _project_
 : @param $id The ID of a _resource_
 : @param $p  A string or a JSON-like string containing additional query parameters
 : @param $q  The main query parameter
 : @return    The model
 :)
declare
    %templates:default("q", "")
    %templates:default("p", "")
    %templates:default("id", "")
    %templates:default("ed", "")
    %templates:wrap
function wdbfp:start($node as node(), $model as map(*), $id as xs:string, $ed as xs:string, $p as xs:string, $q as xs:string) {
try {
  (: assume a function for the whole instance if no $ed is explicitly stated :)
  let $projectId := if ($ed != "")
    then $ed
    else if ($id != "")
    then wdb:getEdFromFileId ($id)
    else normalize-space(doc($wdb:data || '/wdbmeta.xml')/*[1]/@xml:id)
  
  (: if $p is not JSON-like, assume it is a normal string :)
  let $pp := try {
      parse-json($p)
    } catch * {
      normalize-space($p)
    }
  
  return if ( contains(request:get-uri(), 'addins') )
    then
      let $addinName := substring-before(substring-after(request:get-uri(), 'addins/'), '/')
      let $path := $wdb:edocBaseDB || "/addins/" || $addinName
      
      return map {
        "pathToEd": $path,
        "id":       $id,
        "job":      $q,
        "auth":     sm:id()/sm:id
      }
    else
      let $projectPath := wdb:getProjectPathFromId($projectId)
      let $projectFile := wdb:findProjectXQM($projectPath)
      let $infoFileLoc := wdb:getMetaFile($projectPath)
      
      return map {
        "title": (doc($infoFileLoc)//*:title)[1]/text(),
        "p":                $pp,
        "q":                $q,
        "id":               $id,
        "ed":               $projectId,
        "pathToEd":         $projectPath,
        "infoFileLoc":      $infoFileLoc,
        "projectFile":      $projectFile,
        "projectResources": substring-before($projectFile, "project.xqm") || "resources/",
        "auth":             sm:id()/sm:id
      }
  } catch * {
    wdbErr:error(map {
      "code":        "wdbErr:wdb3001",
      "model":       $model,
      "id":          $id,
      "p":           $p,
      "q":           $q,
      "wdb:data":    $wdb:data,
      "errC":        $err:code,
      "errA":        $err:additional,
      "errM":        $err:description,
      "errLocation": $err:module || '@' || $err:line-number ||':'||$err:column-number
    })
  }
};

declare function wdbfp:getVal ($node as node(), $model as map(*), $key as xs:string) {
  element { local-name($node) } {
    $model($key)
  }
};

declare function wdbfp:getHead ( $node as node(), $model as map(*), $templateFile as xs:string* ) {
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="wdb-template" content="templates/{$templateFile}.html"/>
    <meta name="id" content="{$model("id")}" />
    <meta name="ed" content="{$model("ed")}" />
    <meta name="rest" content="{$wdb:restURL}" />
    <title>{$model("title")}</title>
    <link rel="stylesheet" type="text/css" href="./$shared/css/wdb.css"/>
    {
      if (util:binary-doc-available($wdb:data || "/resources/wdb.css"))
        then <link rel="stylesheet" type="text/css" href="{$wdb:edocBaseURL}/data/resources/wdb.css" />
        else ()
    }
    <link rel="stylesheet" type="text/css" href="./$shared/css/{$templateFile}.css"/>
    { local:get('css', $model?pathToEd, $model) }
    <script src="https://code.jquery.com/jquery-3.5.1.min.js" />
    <script src="./$shared/scripts/js.cookie.js"/>
    <script src="./$shared/scripts/legal.js"/>
    <script src="./$shared/scripts/function.js"/>
    { local:get('js', $model?pathToEd, $model) }
  </head>
};

declare function wdbfp:getHeader ($node as node(), $model as map (*)) {
  let $file := xstring:substring-after-last(request:get-url(), '/')
  let $name := substring-before($file, '.html')
  
  let $psHeader := if (doc-available($model("projectResources") || '/' || $name || 'Header.html'))
    then templates:process(doc($model("projectResources") || '/' || $name || 'Header.html'), $model)
    else if (wdb:findProjectFunction($model, 'get' || $name || 'Header', 1))
    then wdb:eval('wdbPF:get' || $name || 'Header($model)', false(), (xs:QName('model'), $model))
    else if (doc-available($model?projectResources || "functionHeader.html"))
    then templates:process(doc($model?projectResources || "functionHeader.html"), $model)
    else ()
  
  return if (count($psHeader) > 0)
  then $psHeader
  else
    <header>
      <h1 class="default">{$model("title")}</h1>
      <hr/>
    </header>
};

declare function wdbfp:test ( $node as node(), $model as map(*) ) {
  wdbErr:error(map { "code": "wdbErr:Err666", "model": $model })
};

declare function local:get ( $type as xs:string, $edPath as xs:string, $model ) {
  let $file := xstring:substring-after-last(request:get-url(), '/')
  let $name := substring-before($file, '.html')
  let $unam := "project" || upper-case(substring($name, 1, 1)) || substring($name, 2, string-length($name) - 1)
  
  return switch($type)
    case "css" return
      let $fun := if (util:binary-doc-available($model?projectResources || 'projectFunction.css'))
        then <link rel="stylesheet" type="text/css" href="{wdb:getUrl($model?projectResources)}projectFunction.css" />
        else() 
      let $gen := if (util:binary-doc-available($wdb:edocBaseDB || '/resources/css/' || $name || '.css'))
        then <link rel="stylesheet" type="text/css" href="$shared/css/{$name}.css" />
        else()
      let $pro := if (util:binary-doc-available($model?projectResources || $unam || '.css'))
        then <link rel="stylesheet" type="text/css" href="{wdb:getUrl($model("projectResources"))}/{$unam}.css" />
        else()
      let $add := if ( util:binary-doc-available($edPath || "/addin.css") )
        then <link rel="stylesheet" type="text/css" href="{wdb:getUrl($edPath)}/addin.css" />
        else()
      return ($fun, $gen, $pro, $add)
    case "js" return
      let $gen := if (util:binary-doc-available($wdb:edocBaseDB || '/resources/scripts/' || $name || '.js'))
        then <script src="$shared/scripts/{$name}.js" />
        else()
      let $pro := if (util:binary-doc-available($model?projectResources || $unam || '.js'))
        then <script src="{wdb:getUrl($model("projectResources"))}/{$unam}.js" />
        else()
      let $add := if ( util:binary-doc-available($edPath || "/addin.js") )
        then <script src="{wdb:getUrl($edPath)}/addin.js" />
        else()
      return ($gen, $pro, $add)
    default return <meta name="specFile" value="{$name}" />
};

(: get the footerfor function pages from either projectSpec HTML, projectSpec function or an empty sequence :)
declare function wdbfp:getFooter($node as node(), $model as map(*)) as node()* {
  let $projectAvailable := wdb:findProjectXQM($model?pathToEd)
  let $functionsAvailable := if ($projectAvailable)
    then util:import-module(xs:anyURI("https://github.com/dariok/wdbplus/projectFiles"), 'wdbPF',
        xs:anyURI($projectAvailable))
    else false()
    
  return if (doc-available($model("projectResources") || 'functionFooter.html'))
  then 
      templates:apply(doc($model("projectResources") || 'functionFooter.html'),  $wdbst:lookup, $model)
  else if (wdb:findProjectFunction($model, 'getFunctionFooter', 1))
  then wdb:eval('wdbPF:getFunctionFooter($model)', false(), (xs:QName('model'), $model))
  else ()
};

(: we need a lookup function for the templating system to work :)
declare variable $wdbfp:lookup := function($functionName as xs:string, $arity as xs:int) {
    try {
        function-lookup(xs:QName($functionName), $arity)
    } catch * {
        ()
    }
};
