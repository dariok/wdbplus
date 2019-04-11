(:~
 : This is the main XQuery which will (by default) be called by controller.xql
 : to process any URI ending with ".html". It receives the HTML from
 : the controller and passes it to the templating system.
 :)
xquery version "3.1";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:method "html5";
declare option output:media-type "text/html";

import module namespace templates = "http://exist-db.org/xquery/templates";
import module namespace wdb       = "https://github.com/dariok/wdbplus/wdb"            at "../modules/app.xqm";
import module namespace wdba      = "https://github.com/dariok/wdbplus/auth"           at "../modules/auth.xqm";
import module namespace wdbGS     = "https://github.com/dariok/wdbplus/GlobalSettings" at "global.xqm";
import module namespace wdbPL     = "https://github.com/dariok/wdbplus/ProjectList"    at "projects.xqm";
import module namespace wdbPN     = "https://github.com/dariok/wdbplus/ProjectNew"     at "new.xqm";

(: 
 : The following modules provide functions which will be called by the 
 : templating.
 :)
import module namespace config		= "http://exist-db.org/xquery/apps/config" 	at "config.xqm";

let $config := map {
    $templates:CONFIG_APP_ROOT := $config:app-root,
    $templates:CONFIG_STOP_ON_ERROR := true()
}

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