xquery version "3.1";

module namespace wdbPN = "https://github.com/dariok/wdbplus/ProjectNew";

import module namespace config = "https://github.com/dariok/wdbplus/config"          at "../modules/wdb-config.xqm";
import module namespace wdbRc  = "https://github.com/dariok/wdbplus/RestCollections" at "../rest/rest-coll.xql";
import module namespace sm     = "http://exist-db.org/xquery/securitymanager";

declare namespace http   = "http://expath.org/ns/http-client";
declare namespace map    = "http://www.w3.org/2005/xpath-functions/map";
declare namespace meta   = "https://github.com/dariok/wdbplus/wdbmeta";
declare namespace tei    = "http://www.tei-c.org/ns/1.0";

declare function wdbPN:body ( $node as node(), $model as map(*), $pName as xs:string*, $pShort as xs:string*,
  $pID as xs:string*, $pColl as xs:string*, $pDate as xs:string*, $pDesc as xs:string*, $pLic as xs:string* ) {
  let $user := sm:id()
  
  return if (not($user//sm:group = 'dba'))
    then <p>Diese Seite ist nur für Administratoren zugänglich!</p>
    else if (0 = (string-length($pName), string-length($pID), string-length($pColl)))
    then
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
      let $collectionData :=
        <data>
          <name>{$pName}</name>
          <id>{$pID}</id>
          <collectionName>{$pColl}</collectionName>
        </data>
      
      let $targetCollection := if ( $model?ed eq '' ) then 'data' else $model?ed
        , $create := wdbRc:createSubcollectionXml ($collectionData, $targetCollection)
      
      return if ( ($create)[1]//http:response/@status = '201')
      then
        (: TODO: this should be done in wdbRc:createSubcollection #424 :)
        let $collection-uri := $create[2]

        let $textCollection := xmldb:create-collection($collection-uri, "texts")
        (: create collection resources and project.xqm only if this is a main project :)
        let $resources := if ( $targetCollection = 'data' )
          then
            let $resourcesCollection := xmldb:create-collection($collection-uri, "resources")
            return (
              xmldb:create-collection($collection-uri || "/resources", "blobs"),
              xmldb:create-collection($collection-uri || "/resources", "css"),
              xmldb:create-collection($collection-uri || "/resources", "html"),
              xmldb:create-collection($collection-uri || "/resources", "images"),
              xmldb:create-collection($collection-uri || "/resources", "js"),
              xmldb:create-collection($collection-uri || "/resources", "xq"),

              xmldb:copy-collection($config:edocBaseDB || "/admin/project-template/resources/xsl", $resourcesCollection),

              sm:chmod(xs:anyURI($resourcesCollection), 'rwxrwxr-x'),
              sm:chown(xs:anyURI($resourcesCollection), "wdb:wdbusers"),
              for $c in xmldb:get-child-collections($resourcesCollection)
                return (
                    sm:chmod(xs:anyURI($resourcesCollection || '/' || $c), 'rwxrwxr-x'),
                    sm:chown(xs:anyURI($resourcesCollection || '/' || $c), "wdb:wdbusers")
                  ),
              for $f in xmldb:get-child-resources($resourcesCollection || "/xsl")
                return (
                  sm:chmod(xs:anyURI($resourcesCollection || "/xsl/" || $f), "rwxrwxr-x"),
                  sm:chown(xs:anyURI($resourcesCollection || "/xsl/" || $f), "wdb:wdbusers")
                ),
              
              xmldb:copy-resource($config:edocBaseDB || "/admin/project-template", "project.xqm", $collection-uri, "project.xqm"),
              sm:chown(xs:anyURI($collection-uri || "/project.xqm"), "wdb:wdbusers"),
              sm:chmod(xs:anyURI($collection-uri || "/project.xqm"), "rwxrwxr-x")
            )
          else ()
        
        let $metaFile := $collection-uri || "/wdbmeta.xml"
          , $MD := doc($metaFile)
          (: $targetCollection != 'data': sub-project; here, we use process inheritance as standard behaviour :)
          , $changeProcess := if ( $targetCollection != 'data' )
                then update replace $MD//meta:process[@target = 'html']
                  with <process xmlns="https://github.com/dariok/wdbplus/wdbmeta" target="html" />
                else ()
        
        let $chmod := (
          sm:chmod(xs:anyURI($collection-uri), 'rwxrwxr-x'),
          sm:chmod(xs:anyURI($textCollection), 'rwxrwxr-x'),
          sm:chmod(xs:anyURI($metaFile), 'rw-rw-r--'),
          sm:chown(xs:anyURI($collection-uri), "wdb:wdbusers"),
          sm:chown(xs:anyURI($textCollection), "wdb:wdbusers"),
          sm:chown(xs:anyURI($metaFile), "wdb:wdbusers")
        )
        
        let $addMD := (
          if ($pShort != "")
            then
              update insert <title type="sub" xmlns="https://github.com/dariok/wdbplus/wdbmeta"
              >{$pShort}</title> into $MD//meta:titleData
            else (),
          if ($pDate != "")
            then
              update insert <date xmlns="https://github.com/dariok/wdbplus/wdbmeta"
              >{$pDate}</date> into $MD//meta:titleData
            else (),
          if ($pLic != "")
            then
              update insert <licence xmlns="https://github.com/dariok/wdbplus/wdbmeta"
              >{$pLic}</licence> into $MD//meta:legal
            else ()
        )
        
        return
          <dl>
            <dd>Collection</dd>
            <dt>{$create[2]}</dt>
            <dd>wdbmeta.xml:</dd>
            <dt>{$metaFile}</dt>
            <dd>Admin</dd>
            <dt>
              <ul>
                <li><a href="directoryForm.html?ed={$pID}">Upload</a></li>
                <li><a href="new.html?ed={$pID}">Unterprojekt erstellen</a></li>
              </ul>
            </dt>
          </dl>
      else $create
};
