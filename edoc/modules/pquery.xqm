(: allow project specific XQuerys to make easy use of the templating system including project specifics ;
 : DK Dario Kampkaspar
 : created 2016-11-03 DK :)
xquery version "3.1";

module namespace wdbpq = "https://github.com/dariok/wdbplus/pquery";

import module namespace wdbErr = "https://github.com/dariok/wdbplus/errors" at "error.xqm";

declare namespace wdbq = "https://github.com/dariok/wdbplus/wdbq";

(: load the requested file. It is mandatory these implement wdbq:query($map as map(*)) :)
declare function wdbpq:body ( $node as node(), $model as map(*) ) as item()* {
  let $path := $model?pathToEd  || '/' || $model?q
  let $map := map { "location-hints": $path }
  let $module := try {
    load-xquery-module("https://github.com/dariok/wdbplus/wdbq", $map)
  } catch * {
    error(xs:QName('wdbErr:wdb2001'), "error loading module",
        map{
          "responseCode": 500,
          "path": $path,
          "model": $model
        }
    )
  }
  
  return try {
    let $function := $module?functions?(xs:QName("wdbq:query"))?1
    return $function($model)
  } catch * {
    
    error(xs:QName('wdbErr:wdb2002'), "error executing module function", map {
      "path": $path,
      "model": $model,
      "module": $module,
      "available": exists(function-lookup(xs:QName("wdbq:query"), 1)),
      "functions": inspect:module-functions(xs:anyURI($path)),
      "responseCode": 500
    })
  }
};
