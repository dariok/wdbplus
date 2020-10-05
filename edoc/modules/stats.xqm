xquery version "3.0";

module namespace wdbs = "https://github.com/dariok/wdbplus/stats";

import module namespace templates = "http://exist-db.org/xquery/templates";
import module namespace wdb       = "https://github.com/dariok/wdbplus/wdb"  at "app.xqm";
import module namespace console   = "http://exist-db.org/xquery/console";

declare namespace mets    = "http://www.loc.gov/METS/";
declare namespace mods    = "http://www.loc.gov/mods/v3";
declare namespace tei     = "http://www.tei-c.org/ns/1.0";
declare namespace wdbc    = "https://github.com/dariok/wdbplus/config";
declare namespace wdbmeta = "https://github.com/dariok/wdbplus/wdbmeta";

declare
%templates:default('ed', '')
function wdbs:getEd($node as node(), $model as map(*), $ed as xs:string) {
  wdbs:projectList(sm:is-dba(sm:id()//sm:real/sm:username/string()), $ed)
};

declare function wdbs:projectList($admin as xs:boolean, $ed) {
  let $project := if ($ed = '')
    then $wdb:data
    else $wdb:data || '/' || $ed
  
  let $editionsM := collection($project)//mets:mets
  let $editionsW := collection($project)//wdbmeta:projectMD
  
  return
    <table>
      <tr>
        <th>Eintrag</th>
        <th>Titel</th>
        {if ($admin = true()) then
          ( 
          <th>Metadaten-Datei</th>,
          <th>verwalten</th>
          )
          else ()
        }
      </tr>
      {(for $mets in $editionsM
        let $name := $mets/mets:dmdSec[1]/mets:mdWrap[1]/mets:xmlData[1]/mods:mods[1]/mods:titleInfo[1]/mods:title[1]
        let $metsFile := document-uri(root($mets))
        let $id := wdb:getEdPath($metsFile)
        order by $id
        return
        <tr>
          <td>(M) {$id}</td>
          <td><a href="{$wdb:edocBaseURL || $id || '/start.html'}">{normalize-space($name)}</a></td>
          {if ($admin = true()) then
          (  
            <td style="padding-right: 5px;"><a href="{wdb:getUrl($metsFile)}">{$metsFile}</a></td>,
            <td><a href="{$wdb:edocBaseURL}/admin/projects.html?ed={$id}">verwalten</a></td>
          )
          else ()
          }
        </tr>,
        for $w in $editionsW
          let $name := $w/wdbmeta:titleData/wdbmeta:title[1]
          let $metaFile := document-uri(root($w))
          let $id := substring-before(substring-after($metaFile, $wdb:edocBaseDB), 'wdbmeta')
          let $padding := count(tokenize($id, '/')) + 0.2
          order by $id
          return
            <tr>
              <td>{$id}</td>
              <td style="padding-left: {$padding}em;"><a href="{$wdb:edocBaseURL || $id || 'start.html'}">{normalize-space($name)}</a></td>
              {if ($admin = true()) then ( 
                <td><a href="{wdb:getUrl($metaFile)}">{xs:string($metaFile)}</a></td>,
                <td><a href="{$wdb:edocBaseURL}/admin/projects.html?ed={$w/@xml:id}">verwalten</a></td>
              )
              else ()
              }
            </tr>
      )}
    </table>
};

declare function wdbs:getInstanceName($node as node(), $model as map(*)) {
  <span>{$wdb:configFile//wdbc:meta/wdbc:name}</span>
};
declare function wdbs:getInstanceShort($node as node(), $model as map(*)) {
  <span>{$wdb:configFile//wdbc:meta/wdbc:short}</span>
};