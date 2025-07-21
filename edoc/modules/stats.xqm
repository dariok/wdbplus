xquery version "3.1";

module namespace wdbs = "https://github.com/dariok/wdbplus/stats";

import module namespace config   = "https://github.com/dariok/wdbplus/config" at "wdb-config.xqm";
import module namespace wdb      = "https://github.com/dariok/wdbplus/wdb"    at "/db/apps/edoc/modules/app.xqm";
import module namespace wdbFiles = "https://github.com/dariok/wdbplus/files"  at "wdb-files.xqm";

declare namespace sm        = "http://exist-db.org/xquery/securitymanager";
declare namespace tei       = "http://www.tei-c.org/ns/1.0";
declare namespace templates = "http://exist-db.org/xquery/html-templating";
declare namespace wdbmeta   = "https://github.com/dariok/wdbplus/wdbmeta";

declare
  %templates:default("ed", "")
function wdbs:getEd( $node as node(), $model as map(*), $ed as xs:string ) as element(table) {
  wdbs:projectList(sm:is-dba(sm:id()//sm:real/sm:username/string()), $ed)
};

declare function wdbs:projectList ( $admin as xs:boolean, $ed as xs:string ) as element(table) {
  let $pathToEd := if ( $ed = "" ) then
      $config:data
    else try {
      (wdbFiles:getFullPath($ed))?projectPath
    } catch * {()}
  
  let $editionsW := collection($pathToEd)//wdbmeta:projectMD
  
  return
    <table>
      <tr>
        <th>Eintrag</th>
        <th>Titel</th>
        {
          if ( $admin ) then ( 
              <th>Metadaten-Datei</th>,
              <th>verwalten</th>
          )
          else ()
        }
      </tr>
      {
        for $w in $editionsW
          let $name := $w/wdbmeta:titleData/wdbmeta:title[1]
            , $metaFile := document-uri(root($w))
            , $id := $w/@xml:id
            , $pa := substring-before(substring-after($metaFile, $config:data), "/wdbmeta.xml")
            , $padding := count(tokenize($pa, '/')) + 0.2
          order by $pa
          return
            <tr>
              <td>{$id}</td>
              <td style="padding-left: {$padding}em;"><a href="{$config:edocBaseURL}/start.html?ed={$w/@xml:id}">{normalize-space($name)}</a></td>
              {
                if ( $admin ) then ( 
                  <td><a href="{wdb:getUrl($metaFile)}">{xs:string($metaFile)}</a></td>,
                  <td><a href="projects.html?ed={$w/@xml:id}">verwalten</a></td>
                )
                else ()
              }
            </tr>
      }
    </table>
};

declare function wdbs:getInstanceName($node as node(), $model as map(*)) as element(span) {
  <span>{$config:configFile//config:meta/config:name}</span>
};
declare function wdbs:getInstanceShort($node as node(), $model as map(*)) as element(span) {
  <span>{$config:configFile//config:meta/config:short}</span>
};
