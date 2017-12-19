(:~
 : This is the main XQuery which will (by default) be called by controller.xql
 : to process any URI ending with ".html". It receives the HTML from
 : the controller and passes it to the templating system.
 :)
xquery version "3.1";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:method "html5";
declare option output:media-type "text/html";

import module namespace templates	= "http://exist-db.org/xquery/templates" ;
import module namespace habm			= "https://github.com/dariok/wdbplus/mets"		at "/db/apps/wdb/modules/mets.xqm";
import module namespace hab				= "https://github.com/dariok/wdbplus/hab"			at "/db/apps/wdb/modules/app.xql";
import module namespace habs			= "https://github.com/dariok/wdbplus/stats"		at "/db/apps/wdb/modules/stats.xqm";
import module namespace habe			= "https://github.com/dariok/wdbplus/entity"	at "/db/apps/wdb/modules/entity.xqm";
import module namespace habpq			= "https://github.com/dariok/wdbplus/pquery"	at "/db/apps/wdb/modules/pquery.xqm";
import module namespace haba			= "https://github.com/dariok/wdbplus/auth"		at "/db/apps/wdb/modules/auth.xqm";

(: 
 : The following modules provide functions which will be called by the 
 : templating.
 :)
import module namespace config		= "https://github.com/dariok/wdbplus/config" 	at "/db/apps/wdb/modules/config.xqm";

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