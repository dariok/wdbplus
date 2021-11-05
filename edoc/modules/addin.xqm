(: Main entry point to work with addins.
 : DK Dario Kampkaspar
 : created 2020-10-07 DK :)
xquery version "3.1";

module namespace wdbAddinMain = "https://github.com/dariok/wdbplus/addins-main";

import module namespace request = "http://exist-db.org/xquery/request"       at "java:org.exist.xquery.functions.request.RequestModule";
import module namespace wdb     = "https://github.com/dariok/wdbplus/wdb"    at "/db/apps/edoc/modules/app.xqm";
import module namespace wdba    = "https://github.com/dariok/wdbplus/auth"   at "/db/apps/edoc/modules/auth.xqm";
import module namespace wdbErr  = "https://github.com/dariok/wdbplus/errors" at "/db/apps/edoc/modules/error.xqm";

declare namespace wdbadd = "https://github.com/dariok/wdbplus/addins";

(: load the main XQuery module for the requested addin. It is mandatory these implement wdbadd:main($map as map(*)) :)
declare function wdbAddinMain:body($node as node(), $model as map(*)) {
  let $addinName := substring-before(substring-after(request:get-uri(), 'addins/'), '/')
  let $path := $wdb:edocBaseDB || "/addins/" || $addinName || "/addin.xqm"
  let $map := map { "location-hints": $path }
  
  let $module := try {
    load-xquery-module("https://github.com/dariok/wdbplus/addins", $map)
  } catch * {
    wdbErr:error(map {
      "code":  fn:QName('https://github.com/dariok/wdbErr', 'wdbErr:wdb2101'),
      "path":  $path,
      "model": $model,
      "err":   $err:value,
      "desc":  $err:description
    })
  }
  
  return try {
    let $function := $module?functions?(xs:QName("wdbadd:main"))?1
    return $function($model)
  } catch * {
    wdbErr:error(map {
      "code":      fn:QName('https://github.com/dariok/wdbErr', 'wdbErr:wdb2102'),
      "path":      $path,
      "model":     $model,
      "err":       $err:value,
      "module":    $module,
      "desc":      $err:description,
      "available": system:function-available(xs:QName("wdbadd:main"), 1),
      "functions": inspect:module-functions(xs:anyURI($path)),
      "location":  $err:module || '@' || $err:line-number
    })
  }
};
