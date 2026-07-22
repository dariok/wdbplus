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

import module namespace config    = "https://github.com/dariok/wdbplus/config"  at "../modules/wdb-config.xqm";
import module namespace templates = "http://exist-db.org/xquery/html-templating";
import module namespace wdb       = "https://github.com/dariok/wdbplus/wdb"     at "../modules/app.xqm";
import module namespace wdbProc   = "https://github.com/dariok/wdbplus/Process" at "../modules/wdb-process.xqm";

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

    {
      if ( wdb:findProjectFunction($model, "wdbPF:overrideCssJs", 1) ) then
        (wdb:getProjectFunction($model, "wdbPF:overrideCssJs", 1))($model)
      else (
        <link rel="stylesheet" type="text/css" href="$shared/css/wdb.css" />,
        if ( util:binary-doc-available($config:data || "/resources/css/wdb.css") )
          then <link rel="stylesheet" type="text/css" href="$global/css/wdb.css" />
          else (),
        <link rel="stylesheet" type="text/css" href="$shared/css/view.css" />,
        if ( util:binary-doc-available($config:data || "/resources/css/view.css") )
          then <link rel="stylesheet" type="text/css" href="$global/css/view.css" />
          else (),
        wdb:getBlob($node, $model, 'jquery-ui-css'),
        wdb:getProjectFiles($node, $model, 'css'),
        wdb:getBlob($node, $model, 'jquery'),
        wdb:getBlob($node, $model, 'jquery-ui-js'),
        <script src="$shared/js/js.cookie.js"></script>,
        <script src="$shared/js/legal.js"></script>,
        <script src="$shared/js/function.js"></script>,
        if ( util:binary-doc-available($config:data || "/resources/js/function.js") )
          then <script src="$global/js/function.js"></script>
          else (),
        wdb:getProjectFiles($node, $model, 'js')
      )
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
declare function wdbv:getHeader ( $node as node(), $model as map(*) ) as element() {
  <header>{
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
  }</header>
};

(:~
 : return the body
 :)
declare function wdbv:getContent ( $node as node(), $model as map(*) ) {
  (: TODO: consider removing this entirely and instead load content of main via AJAX :)
  <main>
    { (wdbProc:getContent($model))?content }
    { wdbv:getLeftFooter($node, $model) }
  </main>
};

(: TODO: replace the repetitive if (doc-avilable(a) then a else if (doc-available(b) then b else c) with a function :)
(:~
 : return the global (i.e., full width) footer
 :
 : order of evaluation:
 : 1. {$config:data}/resources/html/mainFooter.html
 : 2. {$projectResources}/html/mainFooter.html
 : 3. wdbPF:getMainFooter#1
 :)
declare function wdbv:getGlobalFooter ( $node as node(), $model as map(*) ) as element(footer)? {
  if ( doc-available($config:data || "/resources/html/mainFooter.html") )
    then templates:apply(doc($config:data || "/resources/html/mainFooter.html"),  $model?configuration?fn-resolver, $model)
  else if ( doc-available($model?projectResources || '/html/mainFooter.html') ) 
    then templates:apply(doc($model?projectResources || '/html/mainFooter.html'), $model?configuration?fn-resolver, $model)
  else if ( wdb:findProjectFunction($model, "wdbPF:getMainFooter", 1) ) then
    (wdb:getProjectFunction($model, "wdbPF:getMainFooter", 1))($model)
  else ()
};
declare function wdbv:getLeftFooter ( $node as node(), $model as map(*) ) as element(footer)? {
  if (doc-available($model?projectResources || "/html/footer.html")) then
    templates:apply(doc($model?projectResources || "/html/footer.html"), $model?configuration?fn-resolver, $model)
  else if (wdb:findProjectFunction($model, "wdbPF:getProjectFooter", 1)) then
    (wdb:getProjectFunction($model, "wdbPF:getProjectFooter", 1))($model)
  else if (doc-available($config:edocBaseDB || "/resources/html/footer.html")) then
    templates:apply(doc($config:edocBaseDB || "/resources/html/footer.html"), $model?configuration?fn-resolver, $model)
  else ()
};
declare function wdbv:getRightFooter ( $node as node(), $model as map(*) ) as element(footer)? {
  if (doc-available($model?projectResources || "/html/projectRightFooter.html")) then
    templates:apply(doc($model?projectResources || "/html/projectRightFooter.html"), $model?configuration?fn-resolver, $model)
  else if (wdb:findProjectFunction($model, "wdbPF:getProjectRightFooter", 1)) then
    (wdb:getProjectFunction($model, "wdbPF:getProjectRightFooter", 1))($model)
  else if (doc-available($config:data || "/resourceshtml//rightFooter.html")) then
    templates:apply(doc($config:data || "/resources/html/rightFooter.html"), $model?configuration?fn-resolver, $model)
  else ()
};
