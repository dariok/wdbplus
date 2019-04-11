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

declare function wdbPN:body ( $node as node(), $model as map(*), $pName as xs:string*, $pShort as xs:string*,
  $pID as xs:string*, $pColl as xs:string*, $pDate as xs:string*, $pDesc as xs:string*, $pLic as xs:string* ) {
  let $user := sm:id()
  
  return
  if (not($user//sm:group = 'dba'))
  then <p>Diese Seite ist nur für Administratoren zugänglich!</p>
  else if (string-length($pName) = 0 or string-length($pID) = 0 or string-length($pColl) = 0) then
    <form method="POST">
      <label for="pName">Projekttitel: </label><input type="text" name="pName" /><br />
      <label for="pShort">Kurztitel: </label><input type="text" name="pShort" /><br />
      <label for="pID">ID (xs:NCName): </label><input type="text" name="pID" /><br />
      <label for="pColl">Collection: </label><input type="text" name="pColl" /><br />
      <label for="pDate">Zeitraum der Texte (ISO): </label><input type="text" name="pDate" /><br />
      <label for="pDesc">Beschreibung der (Haupt-)Inhalte: </label><input type="text" name="pDesc" /><br />
      <label for="pLic">Lizenz der (Haupt-)Inhalte: </label><input type="text" name="pLic" /><br />
      <input type="submit" name="erstellen" />
    </form>
  else
    let $contents := 
    <projectMD xmlns="https://github.com/dariok/wdbplus/wdbmeta"
      xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
      xsi:schemaLocation="https://github.com/dariok/wdbplus/wdbmeta ../include/wdbmeta/wdbmeta.xsd"
      xml:id="{$pID}">
      <projectID>{$pID}</projectID>
      <titleData>
        <title>{$pName}</title>
        {if (string-length($pShort) > 0) then <short>{$pShort}</short> else ()}
        <involvement></involvement>
        <date>{if (string-length($pDate) > 0) then $pDate else current-date()}</date>
        <place></place>
        <language></language>
        <type></type>
      </titleData>
      <metaData>
        <contentGroup>
          <content xml:id="c1">
            <description>{if (string-length($pDesc) > 0) then $pDesc else ""}</description>
          </content>
        </contentGroup>
        <involvement></involvement>
        <legal>
          <licence content="#c1">{if (string-length($pLic) > 0) then $pLic else ""}</licence>
        </legal>
      </metaData>
      <files></files>
      <process target="">
        <command type=""></command>
      </process>
      <struct></struct>
    </projectMD>
    
    let $collection-uri := xmldb:create-collection($wdb:data, $pColl)
    let $saveMetaFile := xmldb:store($collection-uri, "wdbmeta.xml", $contents)
    return
        <p>
            <span>{$collection-uri}</span>
            <span>{$saveMetaFile}</span>
        </p>
};