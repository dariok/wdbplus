xquery version "3.1";

module namespace wdbi = "https://github.com/dariok/wdbplus/index";

import module namespace config = "https://github.com/dariok/wdbplus/config" at "wdb-config.xqm";

declare namespace sm        = "http://exist-db.org/xquery/securitymanager";
declare namespace tei       = "http://www.tei-c.org/ns/1.0";
declare namespace templates = "http://exist-db.org/xquery/html-templating";
declare namespace meta      = "https://github.com/dariok/wdbplus/wdbmeta";

declare
  %templates:default("ed", "")
function wdbi:getEd( $node as node(), $model as map(*) ) as element(table) {
  <table>
    {
      let $meta := doc($config:data || '/wdbmeta.xml')
      for $struct in $meta//meta:struct/meta:struct
        let $f := $meta/id($struct/@file)/@path
          , $file := doc("/db/apps/edoc/data/" || $f)
        
        return <tr>
          <td><a href="/v/{ $struct/@file }"><img src="{ $file//meta:coverImages/meta:image[1]/@href }" /></a></td>
          <td><a href="/v/{ $struct/@file }"><b>{ $struct/@label || $struct/meta:label }</b></a> <br/> { normalize-space($file//meta:projectDesc) }</td>
        </tr>
    }
  </table>
};

declare function wdbi:getInstanceName($node as node(), $model as map(*)) as element(span) {
  <span>{$config:configFile//config:meta/config:name}</span>
};
declare function wdbi:getInstanceShort($node as node(), $model as map(*)) as element(span) {
  <span>{$config:configFile//config:meta/config:short}</span>
};
