xquery version "3.1";

module namespace wdbfp = "https://github.com/dariok/wdbplus/functionpages";

import module namespace request      = "http://exist-db.org/xquery/request";
import module namespace templates    = "http://exist-db.org/xquery/html-templating";
import module namespace util         = "http://exist-db.org/xquery/util";
import module namespace wdb          = "https://github.com/dariok/wdbplus/wdb"         at "/db/apps/edoc/modules/app.xqm";
import module namespace wdba         = "https://github.com/dariok/wdbplus/auth"        at "/db/apps/edoc/modules/auth.xqm";
import module namespace wdbAddinMain = "https://github.com/dariok/wdbplus/addins-main" at "/db/apps/edoc/modules/addin.xqm";
import module namespace wdbErr       = "https://github.com/dariok/wdbplus/errors"      at "/db/apps/edoc/modules/error.xqm";
import module namespace wdbSearch    = "https://github.com/dariok/wdbplus/wdbs"        at "/db/apps/edoc/modules/search.xqm";
import module namespace wdbst        = "https://github.com/dariok/wdbplus/start"       at "/db/apps/edoc/modules/start.xqm";
import module namespace xstring      = "https://github.com/dariok/XStringUtils"        at "/db/apps/edoc/include/xstring/string-pack.xql";

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
declare function wdbfp:populateModel ( $id as xs:string?, $ed as xs:string, $p as xs:string?, $q as xs:string? ) as item()+ {
  try {
    if ( request:exists() and contains(request:get-uri(), 'addins') ) then
      let $addinName := substring-before(substring-after(request:get-uri(), 'addins/'), '/')
        , $path := $wdb:edocBaseDB || "/addins/" || $addinName
        , $pp := try {
            parse-json($p)
          } catch * {
            normalize-space($p)
          }
        , $functions := load-xquery-module("https://github.com/dariok/wdbplus/projectFiles", map { "location-hints": $wdb:data || "/instance.xqm" })
      
      return map {
        "requestUrl": request:get-uri(),
        "pathToEd":   $path,
        "p":          $pp,
        "job":        $q,
        "id":         $id,
        "functions":  $functions?functions,
        "ed":         $ed,
        "auth":       sm:id()/sm:id
      }
    else if ( request:exists() and request:get-uri() => ends-with('/toc.html') ) then
      map {
        "auth":      sm:id()/sm:id,
        "title":     $wdb:configFile//*:name || " – Table of Contents",
        "pathToEd":  $wdb:data
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
      let $proFile := wdb:findProjectXQM($pathToEd)
      
      let $projectFunctions := for $function in doc($pathToEd || "/project-functions.xml")//function
            return $function/@name || '#' || count($function/argument)
        , $instanceFunctions := for $function in doc($wdb:data || "/instance-functions.xml")//function
            return $function/@name || '#' || count($function/argument)
      
      return map {
        "p":                $pp,
        "pathToEd":         $pathToEd,
        "q":                $q,
        "ed":               $ed,
        "auth":             sm:id()/sm:id,
        "functions":        map { "project": $projectFunctions, "instance": $instanceFunctions },
        "infoFileLoc":      $infoFileLoc,
        "title":            doc($infoFileLoc)//meta:title[1]/text(),
        "projectFile":      $proFile,
        "projectResources": $pathToEd || "/resources/",
        "requestUrl":       if ( request:exists() ) then request:get-url() else ""
      }
    else
      let $map := wdb:populateModel($id, "", map{})
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

(:~
 : create the outer HTML shell for a function page, including an html:lang attribute
 :)
declare
    %templates:default("q", "")
    %templates:default("p", "")
    %templates:default("id", "")
    %templates:default("ed", "")
    %templates:wrap
function wdbfp:start ( $node as node(), $model as map(*), $id as xs:string, $ed as xs:string, $p as xs:string,
    $q as xs:string ) as item()* {
  let $newModel := wdbfp:populateModel($id, $ed, $p, $q)

  (: TODO: use a function to get the actual content language :)
  return
    <html lang="de">
      {
        for $h in $node/* return
          if ( $h/*[@data-template] )
            then for $c in $h/* return try { templates:apply($c, $wdbfp:lookup, $newModel) } catch * { util:log("error", $err:description) }
            else templates:apply($h, $wdbfp:lookup, $newModel)
      }
    </html>
};

declare function wdbfp:getVal ($node as node(), $model as map(*), $key as xs:string) {
  element { local-name($node) } {
    $model($key)
  }
};

declare function wdbfp:getHead ( $node as node(), $model as map(*), $templateFile as xs:string* ) as element(head) {
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="wdb-template" content="templates/{$templateFile}.html"/>
    <meta name="id" content="{$model("id")}" />
    <meta name="ed" content="{$model("ed")}" />
    <meta name="rest" content="{$wdb:restURL}" />
    <title>{$model("title")}</title>
    {
      if ( wdb:findProjectFunction($model, "wdbPF:overrideFunctionCssJs", 2) ) then
        (wdb:getProjectFunction($model, "wdbPF:overrideFunctionCssJs", 2))($model, $templateFile)
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
      templates:apply(doc($model("projectResources") || '/' || $name || 'Header.html'), $wdbfp:lookup, $model)
    (: 1b. :)
    else if ( wdb:findProjectFunction($model, 'wdbPF:get' || $unam || 'Header', 1) ) then
      (wdb:getProjectFunction($model, 'wdbPF:get' || $unam || 'Header', 1))($model)
    (: 2a. :)
    else if ( doc-available($model?projectResources || "functionHeader.html") ) then
      templates:apply(doc($model?projectResources || "functionHeader.html"), $wdbfp:lookup, $model)
    (: 2b. :)
    else if ( wdb:findProjectFunction($model, 'wdbPF:getFunctionHeader', 1) ) then
      (wdb:getProjectFunction($model, 'wdbPF:getFunctionHeader', 1))($model)
    (: 3a. :)
    else if ( doc-available($wdb:data || '/resources/' || $name || 'Header.html') ) then
      templates:apply(doc($wdb:data || '/resources/' || $name || 'Header.html'), $wdbfp:lookup, $model)
    (: 4a. :)
    else if ( doc-available($wdb:data || "/resources/functionHeader.html") ) then
      templates:apply(doc($wdb:data|| "/resources/functionHeader.html"), $wdbfp:lookup, $model)
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
          then <script src="{$wdb:edocBaseURL}/data/resources/function.js" />
          else ()
      let $spec := if ( util:binary-doc-available($wdb:data || "/resources/" || $name || ".js") )
        then <link rel="stylesheet" type="text/css" href="{$wdb:edocBaseURL}/data/resources/{$name}.js" />
        else ()
      return ($ins, $gen, $pro, $add, $spec)
    default return <meta name="specFile" value="{$name}" />
};

(: get the footer for function pages from either projectSpec HTML, projectSpec function or an empty sequence :)
declare function wdbfp:getFooter($node as node(), $model as map(*)) as node()* {
  if (doc-available($model("projectResources") || 'functionFooter.html')) then 
    templates:apply(doc($model("projectResources") || 'functionFooter.html'),  $wdbfp:lookup, $model)
  else if (wdb:findProjectFunction($model, 'wdbPF:getFunctionFooter', 1)) then
    (wdb:getProjectFunction($model, 'wdbPF:getFunctionFooter', 1))($model)
  else if ( doc-available($wdb:data || "/resources/mainFooter.html") ) then
    doc($wdb:data || "/resources/mainFooter.html")
  else if (wdb:findProjectFunction($model, 'wdbPF:getMainFooter', 1)) then
    (wdb:getProjectFunction($model, 'wdbPF:getMainFooter', 1))($model)
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
