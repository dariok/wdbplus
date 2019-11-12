(: allow project specific XQuerys to make easy use of the templating system including project specifics ;
 : DK Dario Kampkaspar
 : created 2016-11-03 DK :)
xquery version "3.1";

module namespace wdbpq = "https://github.com/dariok/wdbplus/pquery";

import module namespace wdb    = "https://github.com/dariok/wdbplus/wdb"    at "app.xqm";
import module namespace wdba   = "https://github.com/dariok/wdbplus/auth"   at "auth.xqm";
import module namespace wdbErr = "https://github.com/dariok/wdbplus/errors" at "error.xqm";

declare namespace wdbq = "https://github.com/dariok/wdbplus/wdbq";

(: load the requested file. It is mandatory these implement wdbq:query($map as map(*)) :)
declare function wdbpq:body($node as node(), $model as map(*)) {
  let $path := $model?pathToEd  || '/' || $model?q
  let $map := map { "location-hints": $path }
  let $module := try {
    load-xquery-module("https://github.com/dariok/wdbplus/wdbq", $map)
  } catch * {
    wdbErr:error(map {
      "code": fn:QName('https://github.com/dariok/wdbErr', 'wdbErr:wdb2001'),
      "path": $path, "model": $model, "err": $err:value, "desc": $err:description
    })
  }
  
  return try {
    let $function := $module?functions?(xs:QName("wdbq:query"))?1
    return $function($model)
  } catch * {
    wdbErr:error(map {
      "code": fn:QName('https://github.com/dariok/wdbErr', 'wdbErr:wdb2002'),
      "path": $path, "model": $model, "err": $err:value, "module": $module, "desc": $err:description,
      "available": system:function-available(xs:QName("wdbq:query"), 1),
      "functions": inspect:module-functions(xs:anyURI($path)),
      "location": $err:module || '@' || $err:line-number
    })
  }
};