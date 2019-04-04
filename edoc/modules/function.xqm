xquery version "3.1";

module namespace wdbfp = "https://github.com/dariok/wdbplus/functionpages";

import module namespace console = "http://exist-db.org/xquery/console"       at "java:org.exist.console.xquery.ConsoleModule";
import module namespace wdb     = "https://github.com/dariok/wdbplus/wdb"    at "../modules/app.xqm";
import module namespace wdbErr  = "https://github.com/dariok/wdbplus/errors" at "../modules/error.xqm";
import module namespace xstring = "https://github.com/dariok/XStringUtils"   at "../include/xstring/string-pack.xql";

declare namespace meta      = "https://github.com/dariok/wdbplus/wdbmeta";
declare namespace templates = "http://exist-db.org/xquery/templates";

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

declare function wdbfp:getHeader ( $node as node(), $model as map(*) ) {
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
    <meta name="wdb-template" content="templates/function.html"/>
    <meta name="id" content="{$model("id")}" />
    <meta name="ed" content="{$model("edPath")}" />
    <meta name="rest" content="{$wdb:restURL}" />
    <title>{$model("title")}</title>
    <link rel="stylesheet" type="text/css" href="resources/css/wdb.css"/>
    <link rel="stylesheet" type="text/css" href="resources/css/function.css"/>
    {local:get('css', $model("pathToEd"))}
    <script src="https://cdn.jsdelivr.net/npm/cookieconsent@3/build/cookieconsent.min.js" />
    <script src="resources/scripts/legal.js"/>
    <script src="resources/scripts/jquery.min.js"/>
    <script src="resources/scripts/js.cookie.js"/>
    <script src="resources/scripts/function.js"/>
    {local:get('js', $model("pathToEd"))}
  </head>
};

declare function wdbfp:test ( $node as node(), $model as map(*) ) {
  wdbErr:error(map { "code" := "wdbErr:Err666", "model" := $model })
};

declare function local:get ( $type as xs:string, $edPath as xs:string ) {
  let $file := xstring:substring-after-last(request:get-url(), '/')
  let $name := substring-before($file, '.html')
  let $unam := "project" || upper-case(substring($name, 1, 1)) || substring($name, 2, string-length($name) - 1)
  return switch($type)
    case "css" return
      let $gen := if (util:binary-doc-available($wdb:edocBaseDB || '/resources/' || $name || '.css'))
        then <link rel="stylesheet" type="text/css" href="resources/css/{$name}.css" />
        else()
      let $pro := if (util:binary-doc-available($edPath || '/resources/' || $unam || '.css'))
        then <link rel="stylesheet" type="text/css" href="{$wdb:edocBaseURL}{substring-after($edPath, $wdb:edocBaseDB)}/resources/{$unam}.css" />
        else()
      return ($gen, $pro)
    case "js" return
      let $gen := if (util:binary-doc-available($wdb:edocBaseDB || '/resouces/' || $name || '.js'))
        then <script src="resources/scripts/{$name}.js" />
        else()
      let $pro := if (util:binary-doc-available($edPath || '/resouces/' || $unam || '.js'))
        then <script src="{$wdb:edocBaseURL}{substring-after($edPath, $wdb:edocBaseDB)}/resources/{$unam}.js" />
        else()
      return ($gen, $pro)
    default return <meta name="specFile" value="{$name}" />
};