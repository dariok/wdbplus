(:~
 : This is the main XQuery which will (by default) be called by controller.xql
 : to process any URI ending with ".html". It receives the HTML from
 : the controller and passes it to the templating system.
 :)
xquery version "3.1";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

(: 
 : The following modules provide functions which will be called by the 
 : templating.
 :)
import module namespace config       = "http://exist-db.org/xquery/apps/config"          at "/db/apps/edoc/modules/config.xqm";
import module namespace templates    = "http://exist-db.org/xquery/html-templating";
import module namespace wdb          = "https://github.com/dariok/wdbplus/wdb"           at "/db/apps/edoc/modules/app.xqm";
import module namespace wdba         = "https://github.com/dariok/wdbplus/auth"          at "/db/apps/edoc/modules/auth.xqm";
import module namespace wdbAddinMain = "https://github.com/dariok/wdbplus/addins-main"   at "/db/apps/edoc/modules/addin.xqm";
import module namespace wdbe         = "https://github.com/dariok/wdbplus/entity"        at "/db/apps/edoc/modules/entity.xqm";
import module namespace wdbfp        = "https://github.com/dariok/wdbplus/functionpages" at "/db/apps/edoc/modules/function.xqm";
import module namespace wdbpq        = "https://github.com/dariok/wdbplus/pquery"        at "/db/apps/edoc/modules/pquery.xqm";
import module namespace wdbs         = "https://github.com/dariok/wdbplus/stats"         at "/db/apps/edoc/modules/stats.xqm";
import module namespace wdbSearch    = "https://github.com/dariok/wdbplus/wdbs"          at "/db/apps/edoc/modules/search.xqm";
import module namespace wdbst        = "https://github.com/dariok/wdbplus/start"         at "/db/apps/edoc/modules/start.xqm";

declare option output:method "html5";
declare option output:media-type "text/html";

let $config := map {
    $templates:CONFIG_APP_ROOT:      $config:app-root,
    $templates:CONFIG_STOP_ON_ERROR: true()
}

(:
 : We have to provide a lookup function to templates:apply to help it
 : find functions in the imported application modules. The templates
 : module cannot see the application modules, but the inline function
 : below does see them.
 :)
let $lookup := function($functionName as xs:string, $arity as xs:integer) {
    try {
        function-lookup(xs:QName($functionName), $arity)
    } catch * {
        ()
    }
}
(:
 : The HTML is passed in the request from the controller.
 : Run it through the templating system and return the result.
 :)

let $content := request:get-data()
  , $id := request:get-parameter("id", "")

return if ( request:get-method() = 'GET' )
    then templates:apply($content, $lookup, (), $config)
    else if ( request:get-method() = 'HEAD' ) then
      let $requestedModified := (
            request:get-attribute("if-modified"),
            request:get-header("If-Modified-Since")
          )[1]
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
    else templates:apply($content, $lookup, (), $config)
