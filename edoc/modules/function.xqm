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
  
  return map{ "p" := parse-json($p), "q" := $q, "edPath" := $edPath, "title" := $title }
};

declare function wdbfp:getHeader ( $node as node(), $model as map(*) ) {
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
    <meta name="wdb-template" content="templates/function.html"/>
    <meta name="id" data-template="wdbpq:getEd"/>
    <title data-template="wdb:pageTitle"/>
    <link rel="stylesheet" type="text/css" href="resources/css/function.css"/>
    <link data-template="wdbpq:getCSS"/>
    <script src="resources/scripts/jquery.min.js"/>
    <script src="resources/scripts/js.cookie.js"/>
    <script src="resources/scripts/function.js"/>
  </head>
};

declare function wdbfp:test ( $node as node(), $model as map(*) ) {
  wdbErr:error(map { "code" := "wdbErr:Err666", "model" := $model })
};