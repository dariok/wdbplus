xquery version "3.1";

module namespace wdbAdmin = "https://github.com/dariok/wdbplus/Admin";

import module namespace console   = "http://exist-db.org/xquery/console"       at "java:org.exist.console.xquery.ConsoleModule";
import module namespace templates ="http://exist-db.org/xquery/templates"      at "/db/apps/shared-resources/content/templates.xql";
import module namespace wdb       = "https://github.com/dariok/wdbplus/wdb"    at "../modules/app.xqm";

declare namespace meta   = "https://github.com/dariok/wdbplus/wdbmeta";
declare namespace mets   = "http://www.loc.gov/METS/";
declare namespace mods   = "http://www.loc.gov/mods/v3";

(:~
 : populate the model for functions pages (similar but not identical to wdb:populateModel)
 : 
 : @param $ed The ID of a _project_
 : @return    The model
 :)
declare
    %templates:default("ed", "")
function wdbAdmin:start ( $node as node(), $model as map(*), $ed as xs:string ) {
  let $pathToEd := try {
    wdb:getEdPath($ed, true())
  } catch * {()}
  
  (: The meta data are taken from wdbmeta.xml or a mets.xml as fallback :)
  let $infoFileLoc := wdb:getMetaFile($pathToEd)
  
  let $title :=
    (
      normalize-space((doc($infoFileLoc)//meta:title)[1]),
      normalize-space((doc($infoFileLoc)//mods:title)[1])
    )[1]
  
  return map {
    "ed": $ed,
    "infoFileLoc": $infoFileLoc,
    "job": substring-after(request:get-uri(), "admin/"),
    "pathToEd": $pathToEd,
    "title": $title
  }
};

declare function wdbAdmin:heading ($node as node(), $model as map(*)) {
  let $title := if ($model?page = 'admin.html')
    then "Admin-Seite"
    else if ($model?page = 'global.html')
    then "Globale Einstellungen"
    else if ($model?ed = '')
    then "Projekte"
    else "Projekt " || $model?ed
  
  let $opts := if (request:get-parameter('job', '') != '')
    then <span class="dispOpts"><a href="global.html">globale Optionen</a></span>
    else ()
    
  return (<h1>{$title}</h1>,
    $opts)
};

declare function wdbAdmin:getAside ($node as node(), $model as map(*)) as element() {
  <aside>
    {
      switch ($model?job)
        case "projects.html" return
          <button type="button">(Unter-)Projekt erstellen</button>
        default return ()
    }
    <hr />
    <div class="info" role="contentinfo">
      <h2>Projekt-Info</h2>
      {wdb:get($model, "")}
    </div>
  </aside>
};