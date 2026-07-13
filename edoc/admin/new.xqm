xquery version "3.1";

module namespace wdbPN = "https://github.com/dariok/wdbplus/ProjectNew";

import module namespace sm  = "http://exist-db.org/xquery/securitymanager";

declare namespace http = "http://expath.org/ns/http-client";
declare namespace map  = "http://www.w3.org/2005/xpath-functions/map";
declare namespace meta = "https://github.com/dariok/wdbplus/wdbmeta";
declare namespace tei  = "http://www.tei-c.org/ns/1.0";

declare function wdbPN:body ( $node as node(), $model as map(*), $pName as xs:string*, $pShort as xs:string*,
    $pID as xs:string*, $collection as xs:string* )
    (:), $pDate as xs:string*, $pDesc as xs:string*, $pLic as xs:string*, $data as xs:string* ) to be implemented later when a UI for project MD exists :)
    as element() {
  if ( not(sm:id()//sm:group = 'dba') )
    then <p>Diese Seite ist nur für Administratoren zugänglich!</p>
    else if (0 = (string-length($pName), string-length($pID), string-length($collection)))
    then
      <form id="newProjectForm">
        <label for="pName">Projekttitel: </label><input type="text" id="pName" /><br />
        <label for="pShort">Kurztitel: </label><input type="text" id="pShort" /><br />
        <label for="pID">ID (xs:NCName): </label><input type="text" id="pID" /><br />
        <label for="pColl">Collection: </label><input type="text" id="pColl" /><br />
        <!-- we do not use these for now;
          TODO: add later, when a UI for project MD exists () -->
        <!--<label for="pDate">Zeitraum der Texte (ISO): </label><input type="text" name="pDate" /><br />
        <label for="pDesc">Beschreibung der (Haupt-)Inhalte: </label><input type="text" name="pDesc" /><br />
        <label for="pLic">Lizenz der (Haupt-)Inhalte: </label><input type="text" name="pLic" /><br />-->
        <input type="submit" name="erstellen" />
      </form>
    else
      <dl>
        <dd>Collection</dd>
        <dt>{ $collection }</dt>
        <dd>Name</dd>
        <dt>{ $pName }</dt>
        <dd>Short title</dd>
        <dt>{ $pShort }</dt>
        <dd>Admin</dd>
        <dt>
          <ul>
            <li><a href="directoryForm.html?ed={$pID}">Upload</a></li>
            <li><a href="new.html?ed={$pID}">Unterprojekt erstellen</a></li>
          </ul>
        </dt>
      </dl>
};
