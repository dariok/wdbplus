(:~
 : Generic renderer, e.g. for function pages
 :)
xquery version "3.1";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

(: 
 : The following modules provide functions which will be called by the 
 : templating.
 :)
import module namespace templates    = "http://exist-db.org/xquery/html-templating";
(: import module namespace wdb          = "https://github.com/dariok/wdbplus/wdb"           at "app.xqm";
import module namespace wdba         = "https://github.com/dariok/wdbplus/auth"          at "auth.xqm";
import module namespace wdbAddinMain = "https://github.com/dariok/wdbplus/addins-main"   at "addin.xqm";
import module namespace wdbe         = "https://github.com/dariok/wdbplus/entity"        at "entity.xqm"; :)
import module namespace wdbErr       = "https://github.com/dariok/wdbplus/errors"        at "../modules/error.xqm";
(: import module namespace wdbFiles     = "https://github.com/dariok/wdbplus/files"         at "wdb-files.xqm"; :)
import module namespace wdbfp        = "https://github.com/dariok/wdbplus/functionpages" at "function.xqm";
import module namespace wdbm      = "https://github.com/dariok/wdbplus/model"           at "../modules/model.xqm";
(: import module namespace wdbpq        = "https://github.com/dariok/wdbplus/pquery"        at "pquery.xqm";
import module namespace wdbi         = "https://github.com/dariok/wdbplus/index"         at "index.xqm"; :)
import module namespace wdbrh     = "https://github.com/dariok/wdbplus/renderer-helper" at "renderer-helper.xqm";
import module namespace wdbSearch    = "https://github.com/dariok/wdbplus/wdbs"          at "search.xqm";
(: import module namespace wdbst        = "https://github.com/dariok/wdbplus/start"         at "start.xqm"; :)

declare option output:method "html";
declare option output:version "5.0";
declare option output:media-type "text/html";

try {
  let $config := map {
          $templates:CONFIG_APP_ROOT: "/db/apps/edoc",
          $templates:CONFIG_STOP_ON_ERROR: true(),
          $templates:CONFIG_FILTER_ATTRIBUTES: true()
        }
    , $lookup := function( $functionName as xs:string, $arity as xs:integer ) {
          function-lookup(xs:QName($functionName), $arity)
        }
    , $content := request:get-data()
    , $model := wdbm:populateModel((), request:get-parameter("ed", ""), request:get-parameter("view", ""), request:get-parameter("p", ""), request:get-parameter("q", ""))

  return templates:apply($content, $lookup, $model, $config)
} catch * {
  wdbErr:error(map{
    "code": $err:code,
    "desc": $err:description,
    "value": $err:value,
    "additional": $err:additional,
    "location": $err:module || '@' || $err:line-number || ':' || $err:column-number
  })
}