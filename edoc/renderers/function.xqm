xquery version "3.1";

module namespace wdbfp = "https://github.com/dariok/wdbplus/functionpages";

import module namespace config    = "https://github.com/dariok/wdbplus/config"          at "wdb-config.xqm";
import module namespace templates = "http://exist-db.org/xquery/html-templating";
import module namespace wdb       = "https://github.com/dariok/wdbplus/wdb"             at "../modules/app.xqm";
import module namespace wdbrh     = "https://github.com/dariok/wdbplus/renderer-helper" at "renderer-helper.xqm";

declare variable $wdbfp:resourceName := request:get-attribute("$exist:resource") => substring-before('.html');
declare variable $wdbfp:uppercaseName := "project" || upper-case(substring($wdbfp:resourceName, 1, 1)) || substring($wdbfp:resourceName, 2, string-length($wdbfp:resourceName) - 1);

declare function wdbfp:getHead ( $node as node(), $model as map(*) ) as element(head) {
  <head>
    <!-- created by wdbfp:getHead -->
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="id" content="{$model("id")}" />
    <meta name="ed" content="{$model("ed")}" />
    { $config:restMetaElement }
    <title>{$model("title")}</title>
    <link rel="stylesheet" type="text/css" href="$shared/css/wdb.css"/>
    {
      if ( util:binary-doc-available($config:data || "/resources/css/wdb.css") )
        then <link rel="stylesheet" type="text/css" href="$global/css/wdb.css" />
        else ()
    }
    <link rel="stylesheet" type="text/css" href="$shared/css/function.css" />
    {
      if ( util:binary-doc-available($config:data || "/resources/css/function.css") )
        then <link rel="stylesheet" type="text/css" href="$global/css/function.css" />
        else ()
    }
    <link rel="stylesheet" type="text/css" href="$shared/css/{ $wdbfp:resourceName }.css" />
    {
      if ( util:binary-doc-available($config:data || "/resources/css/" || $wdbfp:resourceName || ".css") )
        then <link rel="stylesheet" type="text/css" href="$global/css/{ $wdbfp:resourceName }.css" />
        else ()
    }
    { 
      if ( util:binary-doc-available($model?projectResources || 'css/project.css') )
        then <link rel="stylesheet" type="text/css"
          href="{ substring-after($model?projectResources, $config:edocBaseDB||'/') }css/project.css" />
        else ()
    }
    {
      if ( util:binary-doc-available($model?projectResources || 'css/' || $wdbfp:uppercaseName || '.css') )
        then <link rel="stylesheet" type="text/css"
          href="{ substring-after($model?projectResources, $config:edocBaseDB||'/') }css/{$wdbfp:uppercaseName}.css" />
        else ()
    }
    { wdbrh:getBlob($node, $model, 'jquery') }
    <script src="./$shared/js/js.cookie.js"/>
    <script src="./$shared/js/legal.js"/>
    <script src="./$shared/js/function.js"/>
    <script src="./$shared/js/{ $wdbfp:resourceName }.js" />
    {
      if ( util:binary-doc-available($model?projectResources || 'js/project.js') )
        then <script src="{ substring-after($model?projectResources, $config:edocBaseDB||'/')}js/project.js" />
        else ()
    }
    {
      if ( util:binary-doc-available($model?projectResources || 'js/' || $wdbfp:uppercaseName || '.js') )
        then <script src="{ substring-after($model?projectResources, $config:edocBaseDB||'/')}js/{ $wdbfp:uppercaseName }.js" />
        else ()
    }
  </head>
};

(:~
 : Return the header for function pages. Uses the usual approcach:
 : 1. project specific HTML, then project specific function for the page (e.g. toc.html)
 : 2. project specific HTML, then project specific function for function pages in general
 : 3. instance specific HTML, then instance specific function for the page (e.g. toc.html)
 : 4. instance specific HTML, then instance specific function for function pages in general
 : 5. generic HTML
 : To limit complexity, the complete header is templated here, not its specific parts as is the case in app.xqm.
 :
 : @see https://github.com/dariok/wdbplus/wiki/Instance-specifics
 : @see https://github.com/dariok/wdbplus/wiki/Project-specifics
 : @return element(html:header)
 :)
declare function wdbfp:getHeader ( $node as node(), $model as map(*) ) as element(header) {
  (: 1a. :)
  if ( doc-available($model("projectResources") || '/html/' || $wdbfp:resourceName || 'Header.html') ) then
    templates:apply(doc($model("projectResources") || '/html/' || $wdbfp:resourceName || 'Header.html'), $model?configuration?fn-resolver, $model)
  (: 1b. :)
  else if ( wdb:findProjectFunction($model, 'wdbPF:get' || $wdbfp:uppercaseName || 'Header', 1) ) then
    (wdb:getProjectFunction($model, 'wdbPF:get' || $wdbfp:uppercaseName || 'Header', 1))($model)
  (: 2a. :)
  else if ( doc-available($model?projectResources || "html/functionHeader.html") ) then
    templates:apply(doc($model?projectResources || "html/functionHeader.html"), $model?configuration?fn-resolver, $model)
  (: 2b. :)
  else if ( wdb:findProjectFunction($model, 'wdbPF:getFunctionHeader', 1) ) then
    (wdb:getProjectFunction($model, 'wdbPF:getFunctionHeader', 1))($model)
  (: 3a. :)
  else if ( doc-available($config:data || '/resources/html/' || $wdbfp:resourceName || 'Header.html') ) then
    templates:apply(doc($config:data || '/resources/html/' || $wdbfp:resourceName || 'Header.html'), $model?configuration?fn-resolver, $model)
  (: 4a. :)
  else if ( doc-available($config:data || "/resources/html/functionHeader.html") ) then
    templates:apply(doc($config:data|| "/resources/html/functionHeader.html"), $model?configuration?fn-resolver, $model)
  (: 5. :)
  else
    <header>
      <div class="headerSide"/>
      <div class="headerCentre">
        <h1>{ $model?title }</h1>
      </div>
      <div class="headerMenu" role="navigation">
        <button type="button" class="dispOpts respNav" tabindex="0">≡</button>
      </div>
      <div class="headerSide" />
    </header>
};

declare function wdbfp:getMainFooter ( $node as node(), $model as map(*) ) as node()* {
 let $specifics := wdbrh:getProjectSpecifics($node, $model, "mainFooter")
  return (
    comment { "created in function.xqm, " || $node/@data-template },
    if ( exists($specifics) )
      then $specifics
      else ()
  )
};

declare function wdbfp:getBodyFooter ( $node as node(), $model as map(*) ) as node()* {
 let $specifics := wdbrh:getProjectSpecifics($node, $model, "bodyFooter")
  return (
    comment { "created in function.xqm, " || $node/@data-template },
    if ( exists($specifics) )
      then $specifics
      else ()
  )
};
