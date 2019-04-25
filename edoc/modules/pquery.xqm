(: allow project specific XQuerys to make easy use of the templating system including project specifics ;
 : DK Dario Kampkaspar
 : created 2016-11-03 DK :)
xquery version "3.0";

module namespace wdbpq = "https://github.com/dariok/wdbplus/pquery";

import module namespace wdba      = "https://github.com/dariok/wdbplus/auth" at "auth.xqm";
import module namespace wdbErr    = "https://github.com/dariok/wdbplus/errors"	at "error.xqm";

(: load the requested file. It is mandatory these implement wdbq:query($map as map(*)) :)
declare function wdbpq:body($node as node(), $model as map(*)) {
  let $path := $model("edPath")  || '/' || $model("query")
  let $module := try {
    util:import-module(xs:anyURI("https://github.com/dariok/wdbplus/wdbq"), 'wdbq', xs:anyURI($path))
  } catch * {
    wdbErr:error(map {"code" := fn:QName('https://github.com/dariok/wdbErr', 'wdbErr:wdb2001'),
      "path" := $model("path"), "model" := $model, "err" := $err:value, "desc": $err:description })
  }
  
  return try { util:eval("wdbq:query($map)", xs:boolean('false'), (xs:QName('map'), $model))
  } catch * {
    wdbErr:error(map {"code" := fn:QName('https://github.com/dariok/wdbErr', 'wdbErr:wdb2002'),
      "path" := $model("path"), "model" := $model, "err" := $err:value, "module" := $module , "desc": $err:description})
  }
};

(: return the heading section :)
declare function wdbpq:getTask($node as node(), $model as map(*)) {
  let $path := $model("edPath") || '/' || $model("query")
  let $module := util:import-module(xs:anyURI("https://github.com/dariok/wdbplus/wdbq"), 'wdbq', xs:anyURI($path))
  
  return util:eval("wdbq:getTask()", xs:boolean('false'), (xs:QName('map'), $model))
};

(:~
 : return the header
 :)
declare function wdbpq:getHeader ( $node as node(), $model as map(*) ) {
  <header>
    <h1>{$model("title")}</h1>
    {wdba:getAuth($node, $model)}
    <span class="dispOpts"><a id="showNavLink" href="javascript:toggleNavigation();">Navigation einblenden</a></span>
    <hr/>
    <nav style="display:none;" />
  </header>
};