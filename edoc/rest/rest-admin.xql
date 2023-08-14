xquery version "3.1";

module namespace wdbRAd = "https://github.com/dariok/wdbplus/RestAdmin";

import module namespace console = "http://exist-db.org/xquery/console"         at "java:org.exist.console.xquery.ConsoleModule";
import module namespace sm      = "http://exist-db.org/xquery/securitymanager" at "java:org.exist.xquery.functions.securitymanager.SecurityManagerModule";
import module namespace xstring = "https://github.com/dariok/XStringUtils"     at "/db/apps/edoc/include/xstring/string-pack.xql";
import module namespace wdb     = "https://github.com/dariok/wdbplus/wdb"      at "/db/apps/edoc/modules/app.xqm";

declare namespace http = "http://expath.org/ns/http-client";
declare namespace meta = "https://github.com/dariok/wdbplus/wdbmeta";
declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace tei  = "http://www.tei-c.org/ns/1.0";

declare
  %rest:GET
  %rest:path("/edoc/admin/check/{$collection-id}")
function wdbRAd:eval-meta ( $collection-id as xs:string ) as item()+ {
  let $collection-path := wdb:getEdPath($collection-id, true())
    , $meta := doc($collection-path || "/wdbmeta.xml")
  
  return (
      for $children in $meta//meta:ptr
        return meta:eval-meta($collection-path || "/" || $children/@path)
    , for $file in $meta//meta:file
        let $path := $collection-path || "/" || $file/@path
        return if ( ends-with($path, 'xml') and doc-available($path) )
          then ()
          else if ( unparsed-text-available($path) )
          then ()
          else (
            $path-to-meta || " → " || $path,
            $file
          )
  )
};

