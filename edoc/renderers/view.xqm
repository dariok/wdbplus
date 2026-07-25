(:~
 : VIEW.XQM
 :
 : Central functions that create the representation of an XML in HTML. These are mostly called by the templating system
 : and could also be used by REST functions.
 :
 : 2025-01-30 — dario.kampkaspar@tu-darmstadt.de — Created from functions as previously contained in app.xqm
 :)

xquery version "3.1";

module namespace wdbv = "https://github.com/dariok/wdbplus/mView";

import module namespace config    = "https://github.com/dariok/wdbplus/config"          at "../modules/wdb-config.xqm";
import module namespace templates = "http://exist-db.org/xquery/html-templating";
import module namespace wdb       = "https://github.com/dariok/wdbplus/wdb"             at "../modules/app.xqm";
import module namespace wdbProc   = "https://github.com/dariok/wdbplus/Process"         at "../modules/wdb-process.xqm";
import module namespace wdbrh     = "https://github.com/dariok/wdbplus/renderer-helper" at "renderer-helper.xqm";

(: ~
 : Create the head for HTML files served via the templating system
 : @created 2018-02-02 DK
 :)
declare function wdbv:getHead ( $node as node(), $model as map(*) ) as element(head) {
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="id" content="{ $model?id }"/>
    <meta name="ed" content="{ $model?ed }" />
    <meta name="path" content="{ $model?fileLoc }"/>
    { $config:restMetaElement }
    <meta name="process" content="{ $model?process }" />
    <title>{ $model("title") } – { normalize-space($config:configFile//config:short) }</title>
    <link rel="stylesheet" type="text/css" href="$shared/css/wdb.css" />
    {
      if ( util:binary-doc-available($config:data || "/resources/css/wdb.css") )
        then <link rel="stylesheet" type="text/css" href="$global/css/wdb.css" />
        else ()
    }
    <link rel="stylesheet" type="text/css" href="$shared/css/view.css" />
    {
      if ( util:binary-doc-available($config:data || "/resources/css/view.css") )
        then <link rel="stylesheet" type="text/css" href="$global/css/view.css" />
        else ()
    }
    { wdbrh:getBlob($node, $model, 'jquery-ui-css') }
    { if ( util:binary-doc-available($model?projectResources || 'css/project.css') )
        then <link rel="stylesheet" type="text/css"
          href="{ substring-after($model?projectResources, $config:edocBaseDB||'/')}css/project.css" />
        else ()
    }
    {
      wdbrh:getBlob($node, $model, 'jquery'),
      wdbrh:getBlob($node, $model, 'jquery-ui-js')
    }
    <script src="$shared/js/js.cookie.js"></script>
    <script src="$shared/js/legal.js"></script>
    <!-- this should be `view.js` in both instances; cf. https://github.com/dariok/wdbplus/issues/504 -->
    <script src="$shared/js/function.js"></script>
    {
      if ( util:binary-doc-available($config:data || "/resources/js/function.js") )
        then <script src="$global/js/function.js"></script>
        else ()
    }
    { if ( util:binary-doc-available($model?projectResources || 'js/project.js') )
        then <script src="{ substring-after($model?projectResources, $config:edocBaseDB||'/')}js/project.js" />
        else ()
    }
  </head>
};

(:~
 : return the header - if there is a project specific function, use it
 :
 : order of evaluation:
 : 1. {$projectResources}/html/header.html – this must contain one html:header, the
 :    contents of which will be sent through the templating system
 : 2. instance or project specific wdbPF:getHeader#1
 : 3. evaluation of all 4 constituents of the header in a row
 :    a) wdbPF:getHeaderLeft#1   or {$config:data}/resources/html/headerLeft.html or empty html:p
 :    b) wdbPF:getHeaderCentre#1 or {$config:data}/resources/html/headerCentre.html or html:h1
 :    c) wdbPF:getHeaderMenu#1   or {$config:data}/resources/html/headerMenu.html or html:button
 :    d) wdbPF:getHeaderRight#1  or {$config:data}/resources/html/headerRight.html or empty html:p
 :)
declare %templates:wrap function wdbv:getHeader ( $node as node(), $model as map(*) ) as element()+ {
  if ( doc-available($model?projectResources || '/html/header.html') )
    then templates:apply(doc($model?projectResources || '/html/header.html')/header/*, $model?configuration?fn-resolver, $model)
  else if ( wdb:findProjectFunction($model, 'wdbPF:getHeader', 1) ) then
    (wdb:getProjectFunction($model, "wdbPF:getHeader", 1))($model)
  else (
    <div class="headerSide" role="navigation">{
      if ( wdb:findProjectFunction($model, 'wdbPF:getHeaderLeft', 1) ) then
        (wdb:getProjectFunction($model, "wdbPF:getHeaderLeft", 1))($model)
      else if ( doc-available($config:data || "/resources/html/headerLeft.html") ) then
        templates:apply(doc($config:data || "/resources/html/headerLeft.html"), $model?configuration?fn-resolver, $model)/*
      else <p />
    }</div>,
    <div class="headerCentre">{
      if ( wdb:findProjectFunction($model, 'wdbPF:getHeaderCentre', 1) ) then
        (wdb:getProjectFunction($model, "wdbPF:getHeaderCentre", 1))($model)
      else if ( doc-available($config:data || "/resources/html/headerCentre.html") ) then
        templates:apply(doc($config:data || "/resources/html/headerCentre.html"), $model?configuration?fn-resolver, $model)/*
      else
        <h1>{$model("title")}</h1>
    }</div>,
    <div class="headerMenu" role="navigation">{(
      if ( wdb:findProjectFunction($model, 'wdbPF:getHeaderMenu', 1) ) then
        (wdb:getProjectFunction($model, "wdbPF:getHeaderMenu", 1))($model)
      else if ( doc-available($config:data || "/resources/html/headerMenu.html") ) then
        templates:apply(doc($config:data || "/resources/html/headerMenu.html"), $model?configuration?fn-resolver, $model)/*
      else <button type="button" class="dispOpts respNav" tabindex="0">≡</button>
    )}</div>,
    <div class="headerSide" role="navigation">{
      if ( wdb:findProjectFunction($model, 'wdbPF:getHeaderRight', 1) ) then
        (wdb:getProjectFunction($model, "wdbPF:getHeaderRight", 1))($model)
      else if ( doc-available($config:data || "/resources/html/headerRight.html") ) then
        templates:apply(doc($config:data || "/resources/html/headerRight.html"), $model?configuration?fn-resolver, $model)/*
      else <p />
    }</div>
  )
};

(:~
 : return the body
 :)
declare function wdbv:getContent ( $node as node(), $model as map(*) ) as element()+ {
  (: TODO: consider removing this entirely and instead load content of main via AJAX :)
  (wdbProc:getContent($model))?content
};
