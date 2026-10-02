(: Main entry point to work with addins.
 : DK Dario Kampkaspar
 : created 2020-10-07 DK :)
xquery version "3.1";

module namespace wdbAddinMain = "https://github.com/dariok/wdbplus/addins-main";

import module namespace wdbErr  = "https://github.com/dariok/wdbplus/errors" at "error.xqm";

declare namespace request = "http://exist-db.org/xquery/request";
declare namespace wdbadd = "https://github.com/dariok/wdbplus/addins";

(: load the main XQuery module for the requested addin. It is mandatory these implement wdbadd:main($map as map(*)) :)
declare function wdbAddinMain:body ( $node as node(), $model as map(*) ) as element()+ {
  let $addinName := substring-before(substring-after(request:get-uri(), 'addins/'), '/')
    , $path := "/db/apps/edoc/addins/" || $addinName || "/addin.xqm"
    , $map := map { "location-hints": $path }
  
  let $module := try {
    load-xquery-module("https://github.com/dariok/wdbplus/addins", $map)
  } catch * {
    error(xs:QName('wdbErr:wdb2101'), $err:description, map{
        "path": $path,
        "model": $model,
        "location": $err:module || '@' || $err:line-number || ':' || $err:column-number
      }
    )
  }
  
  return try {
    let $function := $module?functions?(xs:QName("wdbadd:main"))?1
    return $function($model)
  } catch * {
    error(xs:QName('wdbErr:wdb2102'), $err:description, map {
        "path": $path,
        "model": $model,
        "err": $err:value,
        "module": $module,
        "available": system:function-available(xs:QName("wdbadd:main"), 1),
        "functions": inspect:module-functions(xs:anyURI($path)),
        "location": $err:module || '@' || $err:line-number || ':' || $err:column-number
      }
    )
  }
};
