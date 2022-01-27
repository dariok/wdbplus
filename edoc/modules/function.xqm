xquery version "3.1";

module namespace wdbfp = "https://github.com/dariok/wdbplus/functionpages";

import module namespace request   = "http://exist-db.org/xquery/request"         at "java:org.exist.xquery.functions.request.RequestModule";
import module namespace templates = "http://exist-db.org/xquery/html-templating";
import module namespace util      = "http://exist-db.org/xquery/util"            at "java:org.exist.xquery.functions.util.UtilModule";
import module namespace wdb       = "https://github.com/dariok/wdbplus/wdb"      at "/db/apps/edoc/modules/app.xqm";
import module namespace wdba      = "https://github.com/dariok/wdbplus/auth"     at "/db/apps/edoc/modules/auth.xqm";
import module namespace wdbErr    = "https://github.com/dariok/wdbplus/errors"   at "/db/apps/edoc/modules/error.xqm";
import module namespace wdbst     = "https://github.com/dariok/wdbplus/start"    at "/db/apps/edoc/modules/start.xqm";
import module namespace xstring   = "https://github.com/dariok/XStringUtils"     at "/db/apps/edoc/include/xstring/string-pack.xql";

declare namespace meta = "https://github.com/dariok/wdbplus/wdbmeta";

(:~
 : populate the model for functions pages (similar but not identical to wdb:populateModel)
 : 
 : @param $id The ID of a _resource_
 : @param $ed The ID of a _project_
 : @param $p  A string or a JSON-like string containing additional query parameters
 : @param $q  The main query parameter
 : @return    The model
 :)
declare
    %templates:default("q", "")
    %templates:default("p", "")
    %templates:default("id", "")
    %templates:default("ed", "")
    %templates:wrap
function wdbfp:start ( $node as node(), $model as map(*), $id as xs:string, $ed as xs:string, $p as xs:string,
    $q as xs:string ) as item()* {
  try {
    if ( contains(request:get-uri(), 'addins') ) then
      let $addinName := substring-before(substring-after(request:get-uri(), 'addins/'), '/')
      let $path := $wdb:edocBaseDB || "/addins/" || $addinName
      
      return map {
        "pathToEd": $path,
        "job":      $q,
        "id":       $id,
        "ed":       $ed,
        "auth":     sm:id()/sm:id
      }
    else if ( request:get-uri() => ends-with('/toc.html') ) then
      map {
        "auth":     sm:id()/sm:id,
        "title":    $wdb:configFile//*:name || " – Table of Contents",
        "pathToEd": $wdb:data
      }
    else if ( $id = "" ) then
      (: no ID: related to a project :)
      let $pathToEd := if ( $ed = "" )
            then $wdb:data
            else wdb:getEdPath($ed, true()),
          $infoFileLoc := wdb:getMetaFile($pathToEd)
        , $pp := try {
              parse-json($p)
            } catch * {
              normalize-space($p)
            }
      
      return map {
        "p":           $pp,
        "pathToEd":    $pathToEd,
        "q":           $q,
        "ed":          $ed,
        "auth":        sm:id()/sm:id,
        "infoFileLoc": $infoFileLoc,
        "title":       doc($infoFileLoc)//meta:title[1]/text(),
        "projectResources": $pathToEd || "/resources/"
      }
    else
      let $map := wdb:populateModel($id, "", $model)
      let $pp := try {
        parse-json($p)
      } catch * {
        normalize-space($p)
      }
      
      return if ( $map instance of map(*) ) then 
        let $mmap := map {
          "title": (doc($map("infoFileLoc"))//*:title)[1]/text(),
          "q":     $q,
          "p":     $pp,
          "id":    $id,
          "ed":    $ed,
          "auth":  sm:id()/sm:id
        }
        return map:merge(($map, $mmap))
      else $map (: if it is an element, this usually means that populateModel has returned an error :)
  } catch * {
    wdbErr:error(map {
      "code":        "wdbErr:wdb3001",
      "model":       $model,
      "id":          $id,
      "ed":          $ed,
      "p":           $p,
      "q":           $q,
      "wdb:data":    $wdb:data,
      "errC":        $err:code,
      "errA":        $err:additional,
      "errM":        $err:description,
      "errLocation": $err:module || '@' || $err:line-number ||':'||$err:column-number
    })
  }
};

declare function wdbfp:getVal ($node as node(), $model as map(*), $key as xs:string) {
  element { local-name($node) } {
    $model($key)
  }
};

declare function wdbfp:getHead ( $node as node(), $model as map(*), $templateFile as xs:string* ) {
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="wdb-template" content="templates/{$templateFile}.html"/>
    <meta name="id" content="{$model("id")}" />
    <meta name="ed" content="{$model("ed")}" />
    <meta name="rest" content="{$wdb:restURL}" />
    <title>{$model("title")}</title>
    {
      if ( wdb:findProjectFunction(map { "pathToEd": $wdb:data }, "overrideFunctionCssJs", 2) ) then
        wdb:eval("wdbPF:overrideFunctionCssJs($model, $templateFile)", false(), (xs:QName("model"), $model, xs:QName("templateFile"), $templateFile))
      else (
        <link rel="stylesheet" type="text/css" href="./$shared/css/wdb.css"/>,
        if ( util:binary-doc-available($wdb:data || "/resources/wdb.css") )
          then <link rel="stylesheet" type="text/css" href="{$wdb:edocBaseURL}/data/resources/wdb.css" />
          else (),
        <link rel="stylesheet" type="text/css" href="./$shared/css/{$templateFile}.css" />,
        if ( util:binary-doc-available($wdb:data || "/resources/" || $templateFile || ".css") )
          then <link rel="stylesheet" type="text/css" href="{$wdb:edocBaseURL}/data/resources/{$templateFile}.css" />
          else (),
        wdbfp:get('css', $model?pathToEd, $model),
        <script src="https://code.jquery.com/jquery-3.5.1.min.js" />,
        <script src="./$shared/scripts/js.cookie.js"/>,
        <script src="./$shared/scripts/legal.js"/>,
        <script src="./$shared/scripts/function.js"/>,
        wdbfp:get('js', $model?pathToEd, $model)
      )
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
  let $file := xstring:substring-after-last(request:get-url(), '/'),
      $name := substring-before($file, '.html'),
      $unam := upper-case(substring($name, 1, 1)) || substring($name, 2, string-length($name) - 1)
  
  return
    (: 1a. :)
    if ( doc-available($model("projectResources") || '/' || $name || 'Header.html') ) then
      templates:apply(doc($model("projectResources") || '/' || $name || 'Header.html'), $wdb:lookup, $model)
    (: 1b. :)
    else if ( wdb:findProjectFunction($model, 'get' || $unam || 'Header', 1) ) then
      wdb:eval('wdbPF:get' || $unam || 'Header($model)', false(), (xs:QName('model'), $model))
    (: 2a. :)
    else if ( doc-available($model?projectResources || "functionHeader.html") ) then
      templates:apply(doc($model?projectResources || "functionHeader.html"), $wdb:lookup, $model)
    (: 2b. :)
    else if ( wdb:findProjectFunction($model, 'getFunctionHeader', 1) ) then
      wdb:eval('wdbPF:getFunctionHeader($model)', false(), (xs:QName('model'), $model))
    (: 3a. :)
    else if ( doc-available($wdb:data || '/resources/' || $name || 'Header.html') ) then
      templates:apply(doc($wdb:data || '/resources/' || $name || 'Header.html'), $wdb:lookup, $model)
    (: 3b. :)
    else if ( wdb:findProjectFunction(map { "pathToEd": $wdb:data }, 'get' || $unam || 'Header', 1) ) then
      wdb:eval('wdbPF:get' || $unam || 'Header($model)', false(), (xs:QName('model'), map { "pathToEd": $wdb:data }))
    (: 4a. :)
    else if ( doc-available($wdb:data || "/resources/functionHeader.html") ) then
      templates:apply(doc($wdb:data|| "/resources/functionHeader.html"), $wdb:lookup, $model)
    (: 4b. :)
    else if ( wdb:findProjectFunction(map { "pathToEd": $wdb:data }, 'getFunctionHeader', 1) ) then
      wdb:eval('wdbPF:getFunctionHeader($model)', false(), (xs:QName('model'), map { "pathToEd": $wdb:data }))
    (: 5. :)
    else
      <header>
        <div class="headerSide">
          { wdba:getAuth($node, $model) }
        </div>
        <div class="headerCentre">
          <h1>{$model("title")}</h1>
        </div>
        <div class="headerMenu" role="navigation">
          <button type="button" class="dispOpts respNav" tabindex="0">≡</button>
        </div>
        <div class="headerSide" />
      </header>
};
(:
let $file := xstring:substring-after-last(request:get-url(), '/'),
      $name := substring-before($file, '.html'),
      $unam := upper-case(substring($name, 1, 1)) || substring($name, 2, string-length($name) - 1)
  
  return
    (: 1a. :)
    if ( doc-available($model("projectResources") || '/' || $name || 'Header.html') ) then
      templates:apply(doc($model("projectResources") || '/' || $name || 'Header.html'), $wdb:lookup, $model)
    (: 1b. :)
    else 
      let $fn := wdb:findProjectFunction($model, 'get' || $unam || 'Header', 1)
      return if ( $fn instance of function(*) ) then
      $fn($model)
    (: 2a. :)
    else if ( doc-available($model?projectResources || "functionHeader.html") ) then
      templates:apply(doc($model?projectResources || "functionHeader.html"), $wdb:lookup, $model)
    (: 2b. :)
    else
      let $fn := wdb:findProjectFunction($model, 'getFunctionHeader', 1)
      return if ( $fn instance of function(*) ) then
      $fn($model)
    (: 3a. :)
    else if ( doc-available($wdb:data || '/resources/' || $name || 'Header.html') ) then
      templates:apply(doc($wdb:data || '/resources/' || $name || 'Header.html'), $wdb:lookup, $model)
    (: 3b. :)
    else
      let $fn := wdb:findProjectFunction(map { "pathToEd": $wdb:data }, 'get' || $unam || 'Header', 1)
      return if ( $fn instance of function(*) ) then
      $fn(map { "pathToEd": $wdb:data })
    (: 4a. :)
    else if ( doc-available($wdb:data || "/resources/functionHeader.html") ) then
      templates:apply(doc($wdb:data|| "/resources/functionHeader.html"), $wdb:lookup, $model)
    (: 4b. :)
    else 
      let $fn := wdb:findProjectFunction(map { "pathToEd": $wdb:data }, 'getFunctionHeader', 1)
      return if ( $fn instance of function(*) ) then
      $fn(map { "pathToEd": $wdb:data })
    (: 5. :)
    else
      <header>
        <div class="headerSide">
          { wdba:getAuth($node, $model) }
        </div>
        <div class="headerCentre">
          <h1>{$model("title")}</h1>
        </div>
        <div class="headerMenu" role="navigation">
          <button type="button" class="dispOpts respNav" tabindex="0">≡</button>
        </div>
        <div class="headerSide" />
      </header>
:)

declare function wdbfp:test ( $node as node(), $model as map(*) ) {
  wdbErr:error(map { "code": "wdbErr:Err666", "model": $model })
};

declare
  %private
function wdbfp:get ( $type as xs:string, $edPath as xs:string, $model ) {
  let $file := xstring:substring-after-last(request:get-url(), '/')
  let $name := substring-before($file, '.html')
  let $unam := "project" || upper-case(substring($name, 1, 1)) || substring($name, 2, string-length($name) - 1)
  
  return switch($type)
    case "css" return
      let $fun := if (util:binary-doc-available($model?projectResources || 'projectFunction.css'))
        then <link rel="stylesheet" type="text/css" href="{wdb:getUrl($model?projectResources)}projectFunction.css" />
        else() 
      let $gen := if (util:binary-doc-available($wdb:edocBaseDB || '/resources/css/' || $name || '.css'))
        then <link rel="stylesheet" type="text/css" href="$shared/css/{$name}.css" />
        else()
      let $pro := if (util:binary-doc-available($model?projectResources || $unam || '.css'))
        then <link rel="stylesheet" type="text/css" href="{wdb:getUrl($model("projectResources"))}/{$unam}.css" />
        else()
      let $add := if ( util:binary-doc-available($edPath || "/addin.css") )
        then <link rel="stylesheet" type="text/css" href="{wdb:getUrl($edPath)}/addin.css" />
        else()
      let $ins := if ( util:binary-doc-available($wdb:data || "/resources/" || $name || ".css") )
        then <link rel="stylesheet" type="text/css" href="{$wdb:edocBaseURL}/data/resources/{$name}.css" />
        else ()
      return ($fun, $gen, $ins, $pro, $add)
    case "js" return
      let $gen := if (util:binary-doc-available($wdb:edocBaseDB || '/resources/scripts/' || $name || '.js'))
        then <script src="$shared/scripts/{$name}.js" />
        else()
      let $pro := if (util:binary-doc-available($model?projectResources || $unam || '.js'))
        then <script src="{wdb:getUrl($model("projectResources"))}/{$unam}.js" />
        else()
      let $add := if ( util:binary-doc-available($edPath || "/addin.js") )
        then <script src="{wdb:getUrl($edPath)}/addin.js" />
        else()
      let $ins := if ( util:binary-doc-available($wdb:data || "/resources/function.js") )
          then <script src="data/resources/function.js" />
          else ()
      return ($ins, $gen, $pro, $add)
    default return <meta name="specFile" value="{$name}" />
};

(: get the footerfor function pages from either projectSpec HTML, projectSpec function or an empty sequence :)
declare function wdbfp:getFooter($node as node(), $model as map(*)) as node()* {
  let $projectAvailable := wdb:findProjectXQM($model?pathToEd)
  let $functionsAvailable := if ($projectAvailable)
    then util:import-module(xs:anyURI("https://github.com/dariok/wdbplus/projectFiles"), 'wdbPF',
        xs:anyURI($projectAvailable))
    else false()
    
  return if (doc-available($model("projectResources") || 'functionFooter.html')) then 
    templates:apply(doc($model("projectResources") || 'functionFooter.html'),  $wdbst:lookup, $model)
  else if (wdb:findProjectFunction($model, 'getFunctionFooter', 1)) then
    wdb:eval('wdbPF:getFunctionFooter($model)', false(), (xs:QName('model'), $model))
  else if ( doc-available($wdb:data || "/resources/mainFooter.html") ) then
    doc($wdb:data || "/resources/mainFooter.html")
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
