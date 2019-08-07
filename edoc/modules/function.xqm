xquery version "3.1";

module namespace wdbfp = "https://github.com/dariok/wdbplus/functionpages";

import module namespace console   = "http://exist-db.org/xquery/console"       at "java:org.exist.console.xquery.ConsoleModule";
import module namespace templates ="http://exist-db.org/xquery/templates"      at "/db/apps/shared-resources/content/templates.xql";
import module namespace wdb       = "https://github.com/dariok/wdbplus/wdb"    at "app.xqm";
import module namespace wdbErr    = "https://github.com/dariok/wdbplus/errors" at "error.xqm";
import module namespace wdbSearch = "https://github.com/dariok/wdbplus/wdbs"   at "search.xqm";
import module namespace wdbst     = "https://github.com/dariok/wdbplus/start"  at "start.xqm";
import module namespace xstring   = "https://github.com/dariok/XStringUtils"   at "../include/xstring/string-pack.xql";

declare namespace meta      = "https://github.com/dariok/wdbplus/wdbmeta";

declare
    %templates:default("q", "")
    %templates:default("p", "")
    %templates:default("id", "")
function wdbfp:start($node as node(), $model as map(*), $id as xs:string, $p as xs:string, $q as xs:string) {
try {
  let $pid := if ($id = "")
    then normalize-space(doc($wdb:data || '/wdbmeta.xml')/*[1]/@xml:id)
    else $id
  
  let $map := wdb:populateModel($pid, "", $model)
  let $pp := try {
    parse-json($p)
  } catch * {
    normalize-space($p)
  }
  let $mmap := map { "title" := (doc($map("infoFileLoc"))//*:title)[1]/text(), "p" := $pp, "q" := $q, "id" := $pid }
  
  return map:merge(($map, $mmap))
} catch * {
  wdbErr:error(map { "code" := "wdbErr:wdb3001", "model" := $model, "id" := $id, "p" := $p, "q" := $q, "wdb:data" := $wdb:data,
    "errC" := $err:code, "errA" := $err:additional, "errM" := $err:description, "errLocation" := $err:module || '@' || $err:line-number ||':'||$err:column-number })
}
};

declare function wdbfp:getVal ($node as node(), $model as map(*), $key as xs:string) {
  element { local-name($node) } {
    $model($key)
  }
};

declare function wdbfp:getHead ( $node as node(), $model as map(*) ) {
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="wdb-template" content="templates/function.html"/>
    <meta name="id" content="{$model("id")}" />
    <meta name="ed" content="{$model("id")}" />
    <meta name="rest" content="{$wdb:restURL}" />
    <title>{$model("title")}</title>
    <link rel="stylesheet" type="text/css" href="resources/css/wdb.css"/>
    <link rel="stylesheet" type="text/css" href="resources/css/function.css"/>
    {local:get('css', $model("pathToEd"), $model)}
    <script src="https://cdn.jsdelivr.net/npm/cookieconsent@3/build/cookieconsent.min.js" />
    <script src="resources/scripts/legal.js"/>
    <script src="resources/scripts/jquery.min.js"/>
    <script src="resources/scripts/js.cookie.js"/>
    <script src="resources/scripts/function.js"/>
    {local:get('js', $model("pathToEd"), $model)}
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
      <h1 class="default">{$model("title")}</h1>,
      <hr/>
    </header>
};

declare function wdbfp:test ( $node as node(), $model as map(*) ) {
  wdbErr:error(map { "code" := "wdbErr:Err666", "model" := $model })
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
        then <link rel="stylesheet" type="text/css" href="resources/css/{$name}.css" />
        else()
      let $pro := if (util:binary-doc-available($model?projectResources || $unam || '.css'))
        then <link rel="stylesheet" type="text/css" href="{wdb:getUrl($model("projectResources"))}/{$unam}.css" />
        else()
      return ($fun, $gen, $pro)
    case "js" return
      let $gen := if (util:binary-doc-available($wdb:edocBaseDB || '/resources/scripts/' || $name || '.js'))
        then <script src="resources/scripts/{$name}.js" />
        else()
      let $pro := if (util:binary-doc-available($model?projectResources || $unam || '.js'))
        then <script src="{wdb:getUrl($model("projectResources"))}/{$unam}.js" />
        else()
      return ($gen, $pro)
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