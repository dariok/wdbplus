xquery version "3.0";

module namespace wdbst = "https://github.com/dariok/wdbplus/start";

import module namespace wdbm    = "https://github.com/dariok/wdbplus/nav"	at "nav.xqm";
import module namespace wdb     = "https://github.com/dariok/wdbplus/wdb"	at "app.xql";
import module namespace console = "http://exist-db.org/xquery/console";

declare namespace match   = "http://www.w3.org/2005/xpath-functions";
declare namespace mets    = "http://www.loc.gov/METS/";
declare namespace mods    = "http://www.loc.gov/mods/v3";
declare namespace tei     = "http://www.tei-c.org/ns/1.0";
declare namespace output  = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace wdbmeta = "https://github.com/dariok/wdbplus/wdbmeta";
declare namespace wdbPF   = "https://github.com/dariok/wdbplus/projectFiles";

declare option output:method "html5";
declare option output:media-type "text/html";

declare function wdbst:populateModel ($node as node(), $model as map(*), $id, $ed, $path) {
  (: general behaviour: IDs always take precedence :)
  let $ppath := if ($id)
    then wdb:getEdPath(base-uri((collection($wdb:data)/id($id))[1]), true())
    else if ($ed)
    then $wdb:edocBaseDB || '/' || $ed
    else wdb:getEdPath($wdb:edocBaseDB || $path, true())
  
  let $metaFile := if (doc-available($ppath || '/wdbmeta.xml'))
    then doc($ppath || '/wdbmeta.xml')
    else doc($ppath || '/mets.xml')
  
  return if ($metaFile/wdbmeta:*)
  then
    let $id := $metaFile//wdbmeta:projectID/text()
    let $title := normalize-space($metaFile//wdbmeta:title[1])
    return map { "id" := $id, "title" := $title, "infoFileLoc" := $ppath || '/wdbmeta.xml',
      "ed" := substring-after($ppath, $wdb:data), "pathToEd" := $ppath, "fileLoc" := "start.xql" }
  else
    let $id := analyze-string($ppath, '^/?(.*)/([^/]+)$')//match:group[1]/text()
    let $title := normalize-space(($metaFile//mods:title)[1])
    return map { "id" := $id, "title" := $title , "infoFileLoc" := $ppath || '/mets.xml',
      "ed" := substring-after($ppath, $wdb:data), "pathToEd" := $ppath, "fileLoc" := "start.xql" }
};

declare function wdbst:getHead ($node as node(), $model as map(*)) {
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <meta name="id" content="{$model('id')}"/>
    <meta name="edPath" content="{$model('pathToEd')}" />
    <meta name="path" content="{$model('fileLoc')}"/>
    <title>{normalize-space($wdb:configFile//*:short)} – {$model("title")}</title>
    <link rel="stylesheet" type="text/css" href="{$wdb:edocBaseURL}/resources/css/main.css" />
    {wdb:getProjectFiles($node, $model, 'css')}
    <!--(\: TODO get projectStart.css :\)-->
    <script src="{$wdb:edocBaseURL}/resources/scripts/function.js" />
    {wdb:getProjectFiles($node, $model, 'js')}
    <!--(\: TODO get projectStart.js :\)-->
  </head>
};

declare function wdbst:getStartHeader($node as node(), $model as map(*), $id) as node()* {
  if (wdb:findProjectFunction($model, 'getStartHeader', 1))
  then wdb:eval('wdbPF:getStartHeader($model)', false(), (xs:QName('model'), $model))
  else (
    <h1>{$model("title")}</h1>,
    <hr/>
  )
};

declare function wdbst:getStartLeft($node as node(), $model as map(*)) as node()* {
  if (wdb:findProjectFunction($model, 'getStartLeft', 1))
  then wdb:eval('wdbPF:getStartLeft($model)', false(), (xs:QName('model'), $model))
  else (<h1>Inhalt</h1>,())
};

declare function wdbst:getStart ($node as node(), $model as map(*)) as node()* {
  if (wdb:findProjectFunction($model, 'getStart', 1))
  then wdb:eval('wdbPF:getStart($model)', false(), (xs:QName('model'), $model))
  else wdbm:getRight(<void/>, $model)
};