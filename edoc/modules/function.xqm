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
try {
  let $pid := if ($id = "")
    then doc($wdb:data || '/wdbmeta.xml')/*[1]/@xml:id
    else $id
  let $edPath := wdb:getEdPath((collection($wdb:data)/id($pid))[1], true())
  
  let $metaFile := if (doc-available($edPath || '/wdbmeta.xml'))
    then doc($edPath || '/wdbmeta.xml')
    else doc($edPath || '/mets.xml')
  
  let $proFile := wdb:findProjectXQM($edPath)
  
  let $title := ($metaFile//*:title)[1]/text()
  
  return map { "p" := parse-json($p), "q" := $q, "pathToEd" := $edPath, "title" := $title, "id" := $pid, "infoFileLoc" := $metaFile }
} catch * {
  wdbErr:error(map { "code" := "wdbErr:wdb3001", "model" := $model, "id" := $id, "p" := $p, "q" := $q })
}
};

declare function wdbfp:getHeader ( $node as node(), $model as map(*) ) {
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
    <meta name="wdb-template" content="templates/function.html"/>
    <meta name="id" content="{$model("id")}" />
    <meta name="ed" content="{$model("edPath")}" />
    <title>{$model("title")}</title>
    <link rel="stylesheet" type="text/css" href="resources/css/function.css"/>
    {local:get('css', $model("pathToEd"))}
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
  let $file := substring-after(request:get-url(), $wdb:edocBaseURL || '/')
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