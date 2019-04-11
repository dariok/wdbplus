xquery version "3.0";

module namespace wdbPN = "https://github.com/dariok/wdbplus/ProjectNew";

import module namespace wdb      = "https://github.com/dariok/wdbplus/wdb"    at "../modules/app.xqm";
import module namespace wdbs     = "https://github.com/dariok/wdbplus/stats"  at "../modules/stats.xqm";
import module namespace console  = "http://exist-db.org/xquery/console";
import module namespace xstring  = "https://github.com/dariok/XStringUtils"   at "../include/xstring/string-pack.xql";
import module namespace sm       = "http://exist-db.org/xquery/securitymanager";

declare namespace config = "https://github.com/dariok/wdbplus/config";
declare namespace meta   = "https://github.com/dariok/wdbplus/wdbmeta";
declare namespace tei    = "http://www.tei-c.org/ns/1.0";

declare function wdbPN:pageTitle ($node as node(), $model as map(*)) {
  let $t := $wdb:configFile//config:short
  
  return <title>{normalize-space($t)} – Admin</title>
};

declare function wdbPN:body ( $node as node(), $model as map(*), $pName as xs:string*, $pShort as xs:string*,
  $pID as xs:string*, $pColl as xs:string* ) {
  if (string-length($pName) = 0 or string-length($pID) = 0) then (
    <form method="POST">
      <label for="pName">Projekttitel: </label><input type="text" id="pName" /><br />
      <label for="pShort">Kurztitel: </label><input type="text" id="pShort" /><br />
      <label for="pID">ID (xs:NCName): </label><input type="text" id="pID" /><br />
      <label for="pColl">Collection: </label><input type="text" id="pColl" /><br />
      <input type="submit" name="erstellen" />
    </form>,
    <!--<script>
      $('form').on('submit', function(e) {
        e.preventDefault();
        let data = {"name": $('#pName').value(), "short": $('#pShort').value(), "id": $('#pID').value(), "coll": $('#pColl')}
        window.location.href=new.xql?id
      });
    </script>--> 
  )
  else
    <p>{$pName}</p>
};