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
import module namespace config    = "http://exist-db.org/xquery/apps/config"          at "config.xqm";
import module namespace templates = "http://exist-db.org/xquery/templates";
import module namespace wdb       = "https://github.com/dariok/wdbplus/wdb"           at "app.xqm";
import module namespace wdbs      = "https://github.com/dariok/wdbplus/stats"         at "stats.xqm";
import module namespace wdbe      = "https://github.com/dariok/wdbplus/entity"        at "entity.xqm";
import module namespace wdbpq     = "https://github.com/dariok/wdbplus/pquery"        at "pquery.xqm";
import module namespace wdba      = "https://github.com/dariok/wdbplus/auth"          at "auth.xqm";
import module namespace wdbSearch = "https://github.com/dariok/wdbplus/wdbs"          at "search.xqm";
import module namespace wdbst     = "https://github.com/dariok/wdbplus/start"         at "start.xqm";
import module namespace wdbfp     = "https://github.com/dariok/wdbplus/functionpages" at "function.xqm";
import module namespace _utl      = "https://github.com/dariok/wdbplus/util"          at "util.xqm";

declare option output:method "html5";
declare option output:media-type "text/html";

let $config := map {
    $templates:CONFIG_APP_ROOT:      $config:app-root,
    $templates:CONFIG_STOP_ON_ERROR: true()
}

let $model := map:merge((
    map{'auth': _utl:to-json-map(<json type="object" objects="id real effective groups">{sm:id()}</json>)?id},
    _utl:create-param-map('request-parameters', request:get-parameter-names(), function($param-name) {request:get-parameter($param-name, ())}),
    _utl:create-param-map('request-headers', request:get-header-names(), request:get-header#1),
    _utl:create-param-map('request-attributes', request:attribute-names(), request:get-attribute#1)
    ))

(:
 : We have to provide a lookup function to templates:apply to help it
 : find functions in the imported application modules. The templates
 : module cannot see the application modules, but the inline function
 : below does see them.
 :)
let $lookup := function($functionName as xs:string, $arity as xs:int) {
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
return
    templates:apply($content, $lookup, (), $config)