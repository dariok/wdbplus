(:~
 : renderer for view.html
 :)
xquery version "3.1";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

import module namespace templates = "http://exist-db.org/xquery/html-templating";
import module namespace wdbErr    = "https://github.com/dariok/wdbplus/errors"          at "../modules/error.xqm";
import module namespace wdbFiles  = "https://github.com/dariok/wdbplus/files"           at "../modules/wdb-files.xqm";
import module namespace wdbm      = "https://github.com/dariok/wdbplus/model"           at "../modules/model.xqm";
import module namespace wdbrh     = "https://github.com/dariok/wdbplus/renderer-helper" at "renderer-helper.xqm";
import module namespace wdbView   = "https://github.com/dariok/wdbplus/mView"           at "view.xqm";

declare option output:method "html";
declare option output:version "5.0";
declare option output:media-type "text/html";

try {
  if ( request:get-method() = 'HEAD' ) then
    let $requestedModified := (
          request:get-attribute("if-modified"),
          request:get-header("If-Modified-Since")
        )[1]
      , $id := request:get-parameter("id", "")
      , $isModified := if ( $requestedModified != '' )
          then wdbFiles:evaluateIfModifiedSince($id, $requestedModified)
          else 200
    
    return if ( $isModified = 200 ) then
        response:set-header(
          "Last-Modified",
          wdbFiles:getModificationDate($id) => wdbFiles:ietfDate()
        )
      else
        response:set-status-code(304)
  else
    let $config := map {
            $templates:CONFIG_APP_ROOT: "/db/apps/edoc",
            $templates:CONFIG_STOP_ON_ERROR: true(),
            $templates:CONFIG_FILTER_ATTRIBUTES: true()
          }
      , $lookup := function( $functionName as xs:string, $arity as xs:integer ) {
            function-lookup(xs:QName($functionName), $arity)
          }
      , $content := request:get-data()
      , $model := wdbm:populateModel(request:get-parameter("id", ""), "", request:get-parameter("view", ""), request:get-parameter("p", ""), request:get-parameter("q", ""))
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
