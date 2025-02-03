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

import module namespace config = "https://github.com/dariok/wdbplus/config" at "wdb-config.xqm";
import module namespace wdb    = "https://github.com/dariok/wdbplus/wdb"    at "app.xqm";

(:~
 : Templating function; called from layout.html. Entry point for content pages
 :)
declare
    %templates:default("view", "")
    %templates:default("p", "")
function wdbv:getEE ( $node as node(), $model as map(*), $id as xs:string, $view as xs:string, $p as xs:string ) as item()* {
  try {
    let $newModel := wdb:populateModel($id, $view, $model, $p)
    
    return if ( contains($newModel?fileLoc, 'http') ) then
      $newModel
    else
      let $lastModified :=
        wdbFiles:getModificationDate($newModel?filePathInfo?collectionPath, $newModel?filePathInfo?fileName)
          => wdbFiles:ietfDate()
      
      let $requestedModified := (
            request:get-attribute("if-modified"),
            request:get-header("If-Modified-Since")
          )[1]
      let $isModified := if ( $requestedModified != '' )
            then wdbFiles:evaluateIfModifiedSince($id, $requestedModified)
            else 200
      
      return  if ( count($newModel) = 1 and $isModified = 200 )
        then (
          response:set-header("Last-Modified", $lastModified),
          <html>
            {
              attribute lang { if ( $newModel?language ) then $newModel?language else "de" },
              templates:process($node/node(), $newModel)
            }
          </html>
        )
        else if ( $isModified = 304 ) then
          response:set-status-code(304)
        else
          <html>
            <body>
              <div>
                <p>An unknown error has occurred</p>
              </div>
            </body>
            { util:log("error", $newModel) } 
          </html>
  } catch * {
    util:log("error", $err:code || ': ' || $err:description),
    wdbErr:error(map {
        "code": $err:code,
        "model": $model,
        "err:value": $err:value,
        "err:description": $err:description,
        "err:additional": $err:additional,
        "location": $err:module || '@' || $err:line-number || ':' || $err:column-number
    })
  }
};

(: ~
 : Create the head for HTML files served via the templating system
 : @created 2018-02-02 DK
 :)
declare function wdb:getHead ( $node as node(), $model as map(*) ) as element(head) {
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="id" content="{ $model?id }"/>
    <meta name="ed" content="{ $model?ed }" />
    <meta name="path" content="{ $model?fileLoc }"/>
    <meta name="rest" content="{ $config:restURL }" />
    <title>{ $model("title") } – { normalize-space($config:configFile//config:short) }</title>

    {
      if ( wdb:findProjectFunction($model, "wdbPF:overrideCssJs", 1) ) then
        (wdb:getProjectFunction($model, "wdbPF:overrideCssJs", 1))($model)
      else (
        <link rel="stylesheet" type="text/css" href="$shared/css/wdb.css" />,
        if ( util:binary-doc-available($config:data || "/resources/wdb.css") )
          then <link rel="stylesheet" type="text/css" href="data/resources/wdb.css" />
          else (),
        <link rel="stylesheet" type="text/css" href="$shared/css/view.css" />,
        if ( util:binary-doc-available($config:data || "/resources/view.css") )
          then <link rel="stylesheet" type="text/css" href="data/resources/view.css" />
          else (),
        wdb:getBlob($node, $model, 'jquery-ui-css'),
        wdb:getProjectFiles($node, $model, 'css'),
        wdb:getBlob($node, $model, 'jquery'),
        wdb:getBlob($node, $model, 'jquery-ui-js'),
        <script src="$shared/scripts/js.cookie.js"></script>,
        <script src="$shared/scripts/legal.js"></script>,
        <script src="$shared/scripts/function.js"></script>,
        if ( util:binary-doc-available($config:data || "/resources/function.js") )
          then <script src="data/resources/function.js"></script>
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
 : 1. {$projectResources}/header.html – this must contain one html:header, the
 :    contents of which will be sent through the templating system
 : 2. instance or project specific wdbPF:getHeader#1
 : 3. evaluation of all 4 constituents of the header in a row
 :    a) wdbPF:getHeaderLeft#1 or {$config:data}/resources/headerLeft.html or empty html:p
 :    b) wdbPF:getHeaderCentre#1 or {$config:data}/resources/headerCentre.html or html:h1
 :    c) wdbPF:getHeaderMenu#1 or {$config:data}/resources/headerMenu.html or html:button
 :    d) wdbPF:getHeaderRight#1 or {$config:data}/resources/headerRight.html or empty html:p
 :)
declare function wdb:getHeader ( $node as node(), $model as map(*) ) as element() {
  <header>{
    if ( doc-available($model?projectResources || '/header.html') )
      then templates:apply(doc($model?projectResources || '/header.html')/header/*, $wdb:lookup, $model)
    else if ( wdb:findProjectFunction($model, 'wdbPF:getHeader', 1) ) then
      (wdb:getProjectFunction($model, "wdbPF:getHeader", 1))($model)
    else (
      <div class="headerSide" role="navigation">{
        if ( wdb:findProjectFunction($model, 'wdbPF:getHeaderLeft', 1) ) then
          (wdb:getProjectFunction($model, "wdbPF:getHeaderLeft", 1))($model)
        else if ( doc-available($config:data || "/resources/headerLeft.html") ) then
          templates:apply(doc($config:data || "/resources/headerLeft.html"), $wdb:lookup, $model)/*
        else <p />
      }</div>,
      <div class="headerCentre">{
        if ( wdb:findProjectFunction($model, 'wdbPF:getHeaderCentre', 1) ) then
          (wdb:getProjectFunction($model, "wdbPF:getHeaderCentre", 1))($model)
        else if ( doc-available($config:data || "/resources/headerCentre.html") ) then
          templates:apply(doc($config:data || "/resources/headerCentre.html"), $wdb:lookup, $model)/*
        else
          <h1>{$model("title")}</h1>
      }</div>,
      <div class="headerMenu" role="navigation">{(
        if ( wdb:findProjectFunction($model, 'wdbPF:getHeaderMenu', 1) ) then
          (wdb:getProjectFunction($model, "wdbPF:getHeaderMenu", 1))($model)
        else if ( doc-available($config:data || "/resources/headerMenu.html") ) then
          templates:apply(doc($config:data || "/resources/headerMenu.html"), $wdb:lookup, $model)/*
        else <button type="button" class="dispOpts respNav" tabindex="0">≡</button>
      )}</div>,
      <div class="headerSide" role="navigation">{
        if ( wdb:findProjectFunction($model, 'wdbPF:getHeaderRight', 1) ) then
          (wdb:getProjectFunction($model, "wdbPF:getHeaderRight", 1))($model)
        else if ( doc-available($config:data || "/resources/headerRight.html") ) then
          templates:apply(doc($config:data || "/resources/headerRight.html"), $wdb:lookup, $model)/*
        else <p />
      }</div>
    )
  }</header>
};

(:~
 : return the body
 :)
declare function wdb:getContent ( $node as node(), $model as map ) {
  let $file := if ( ends-with($model?fileLoc, 'wdbmeta.xml') )
    then $model?fileLoc || '#' || $model?id
    else $model?fileLoc
  
  let $xslt := if (string-length($model?xslt) = 0)
    then wdbErr:error(map {"code": "wdbErr:wdb0002", "model": $model})
    else $model("xslt")
  
  let $params :=
    <parameters>
      <param name="exist:stop-on-warn" value="no" />
      <param name="exist:stop-on-error" value="no" />
      <param name="projectDir" value="{$model?pathToEd}" />
      <param name="ed" value="{$model?ed}" />
      {
        if ($model("view") != '')
        then <param name="view" value="{$model("view")}" />
        else ()
      }
      {
        if ($model("p") != '')
        then <param name="p" value="{$model("p")}" />
        else ()
      }
      <param name="xml" value="{$file}" />
      <param name="xsl" value="{$xslt}" />
    </parameters>
  (: do not stop transformation on ambiguous rule match and similar warnings :)
  let $attr := <attributes><attr name="http://saxon.sf.net/feature/recoveryPolicyName" value="recoverSilently" /></attributes>
  
  (: TODO: use generic processXSL function (currently in restFiles.xql but to be moved) so there is only one way of doing things :)
  (: TODO: consider removing this entirely and instead load content of main via AJAX :)
  return
    try {
      <main>
        { transform:transform(doc($file), doc($xslt), $params, $attr, "") }
        { wdb:getLeftFooter($node, $model) }
      </main>
    } catch * { (util:log("error",
      <report>
        <file>{$file}</file>
        <xslt>{$xslt}</xslt>
        {$params}
        {$attr}
        <error>{$err:code || ': ' || $err:description}</error>
        <error>{$err:module || '@' || $err:line-number ||':'||$err:column-number}</error>
        <additional>{$err:additional}</additional>
      </report>),
      wdbErr:error(map{"code": "wdbErr:wdb1001", "model": $model, "additional": $params, "error": map {
          "code": $err:code, "desc": $err:description, "module": $err:module, "line": $err:line-number,
          "col": $err:column-number, "add": $err:additional
      }}))
    }
};

(:~
 : return the global (i.e., full width) footer
 :
 : order of evaluation:
 : 1. {$config:data}/resources/mainFooter.html
 : 2. {$projectResources}/mainFooter.html
 : 3. wdbPF:getMainFooter#1
 :)
declare function wdbv:getGlobalFooter ( $node as node(), $model as map(*) ) as element(footer)? {
  if ( doc-available($config:data || "/resources/mainFooter.html") )
    then templates:apply(doc($config:data || "/resources/mainFooter.html"),  $wdb:lookup, $model)
  else if ( doc-available($model?projectResources || '/mainFooter.html') ) 
    then templates:apply(doc($model?projectResources || '/mainFooter.html'), $wdb:lookup, $model)
  else if ( wdb:findProjectFunction($model, "wdbPF:getMainFooter", 1) ) then
    (wdb:getProjectFunction($model, "wdbPF:getMainFooter", 1))($model)
  else ()
};
declare function wdbv:getLeftFooter ( $node as node(), $model as map(*) ) as element(footer)? {
  if (doc-available($model?projectResources || "/footer.html")) then
    templates:apply(doc($model?projectResources || "/footer.html"), $wdb:lookup, $model)
  else if (wdb:findProjectFunction($model, "wdbPF:getProjectFooter", 1)) then
    (wdb:getProjectFunction($model, "wdbPF:getProjectFooter", 1))($model)
  else if (doc-available($config:edocBaseDB || "/resources/footer.html")) then
    templates:apply(doc($config:edocBaseDB || "/resources/footer.html"), $wdb:lookup, $model)
  else ()
};
declare function wdbv:getRightFooter ( $node as node(), $model as map(*) ) as element(footer)? {
  if (doc-available($model?projectResources || "/projectRightFooter.html")) then
    templates:apply(doc($model?projectResources || "/projectRightFooter.html"), $wdb:lookup, $model)
  else if (wdb:findProjectFunction($model, "wdbPF:getProjectRightFooter", 1)) then
    (wdb:getProjectFunction($model, "wdbPF:getProjectRightFooter", 1))($model)
  else if (doc-available($config:data || "/resources/rightFooter.html")) then
    templates:apply(doc($config:data || "/resources/rightFooter.html"), $wdb:lookup, $model)
  else ()
};
