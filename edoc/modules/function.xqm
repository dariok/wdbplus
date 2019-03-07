xquery version "3.1";

module namespace wdbfp = "https://github.com/dariok/wdbplus/functionpages";

import module namespace wdb    = "https://github.com/dariok/wdbplus/wdb" at "/db/apps/edoc/modules/app.xql";
import module namespace wdbErr = "https://github.com/dariok/wdbplus/errors" at "/db/apps/edoc/modules/error.xqm";

declare namespace meta      = "https://github.com/dariok/wdbplus/wdbmeta";
declare namespace templates = "http://exist-db.org/xquery/templates";

declare
    %templates:default("q", "")
    %templates:default("p", "")
    %templates:default("id", "")
function wdbfp:start($node as node(), $model as map(*), $id as xs:string, $p as xs:string, $q as xs:string) as map(*) {
  let $edPath := wdb:getEdPath((collection($wdb:data)/id($id))[1], true())
  
  let $metaFile := doc($edPath||'/wdbmeta.xml')
  let $title := $metaFile//meta:title/text()
  
  return map{ "p" := parse-json($p), "q" := $q, "edPath" := $edPath, "title" := $title, "id" := $id }
};

declare function wdbfp:getHeader ( $node as node(), $model as map(*) ) {
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
    <meta name="wdb-template" content="templates/function.html"/>
    <meta name="id" content="{$model("id")}" />
    <meta name="ed" content="{$model("edPath")}" />
    <title>{$model("title")}</title>
    <link rel="stylesheet" type="text/css" href="resources/css/function.css"/>
    {local:get('css')}
    <script src="resources/scripts/jquery.min.js"/>
    <script src="resources/scripts/js.cookie.js"/>
    <script src="resources/scripts/function.js"/>
    {local:get('js')}
  </head>
};

declare function wdbfp:test ( $node as node(), $model as map(*) ) {
  wdbErr:error(map { "code" := "wdbErr:Err666", "model" := $model })
};

declare function local:get($type as xs:string) {
  let $file := substring-after(request:get-url(), $wdb:edocBaseURL || '/')
  let $name := substring-before($file, '.html')
  return switch($type)
    case "css" return <link rel="stylesheet" type="text/css" href="resources/css/{$name}.css" />
    case "js" return <script src="resources/scripts/{$name}.js" />
    default return <meta name="specFile" value="{$name}" />
};