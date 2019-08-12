(: allow project specific XQuerys to make easy use of the templating system including project specifics ;
 : DK Dario Kampkaspar
 : created 2016-11-03 DK :)
xquery version "3.0";

module namespace wdbpq = "https://github.com/dariok/wdbplus/pquery";

import module namespace wdb       = "https://github.com/dariok/wdbplus/wdb" at "app.xqm";
import module namespace wdba      = "https://github.com/dariok/wdbplus/auth" at "auth.xqm";
import module namespace wdbErr    = "https://github.com/dariok/wdbplus/errors"	at "error.xqm";

declare namespace wdbq = "https://github.com/dariok/wdbplus/wdbq";

(: load the requested file. It is mandatory these implement wdbq:query($map as map(*)) :)
declare function wdbpq:body($node as node(), $model as map(*)) {
  let $path := $model?pathToEd  || '/' || $model?q
  let $module := try {
    util:import-module(xs:anyURI("https://github.com/dariok/wdbplus/wdbq"), 'wdbq', xs:anyURI($path))
  } catch * {
    wdbErr:error(map {"code" := fn:QName('https://github.com/dariok/wdbErr', 'wdbErr:wdb2001'),
      "path" := $path, "model" := $model, "err" := $err:value, "desc": $err:description })
  }
  
  return try { util:eval("wdbq:query($map)", xs:boolean('false'), (xs:QName('map'), $model))
  } catch * {
    wdbErr:error(map {"code" := fn:QName('https://github.com/dariok/wdbErr', 'wdbErr:wdb2002'),
      "path" := $path, "model" := $model, "err" := $err:value, "module" := $module, "desc": $err:description,
      "available": system:function-available(xs:QName("wdbq:query"), 1),
      "functions": inspect:module-functions(xs:anyURI($path)),
      "location": $err:module || '@' || $err:line-number
    })
  }
};