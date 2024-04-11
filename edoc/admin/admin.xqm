xquery version "3.1";

module namespace wdbAdmin = "https://github.com/dariok/wdbplus/Admin";

(: note for code maintenance: as of 2024-04-10, this module uses the following exports from app.xqm:
 : - $wdb:data
 :)
import module namespace templates = "http://exist-db.org/xquery/html-templating";
import module namespace wdb       = "https://github.com/dariok/wdbplus/wdb"      at "/db/apps/edoc/modules/app.xqm";
import module namespace wdbErr    = "https://github.com/dariok/wdbplus/errors"   at "/db/apps/edoc/modules/error.xqm";
import module namespace wdbFiles  = "https://github.com/dariok/wdbplus/files"    at "wdb-files.xqm";

declare namespace meta = "https://github.com/dariok/wdbplus/wdbmeta";
declare namespace sm   = "http://exist-db.org/xquery/securitymanager";

(:~
 : populate the model for functions pages (similar but not identical to wdb:populateModel)
 : 
 : @param $ed The ID of a _project_
 : @return    The model
 :)
declare
    %templates:default("ed", "")
function wdbAdmin:start ( $node as node(), $model as map(*), $ed as xs:string ) {
  try {
    let $pathToEd := if ( $ed = "" )
      then $wdb:data
      else (wdbFiles:getFullPath($ed))?projectPath
    
    (: The meta data are taken from wdbmeta.xml :)
    let $infoFileLoc := $pathToEd || "/wdbmeta.xml"
      , $title := normalize-space((doc($infoFileLoc)//meta:title)[1])
    
    return map {
      "ed":          if ( $pathToEd = $wdb:data ) then "data" else $ed,
      "infoFileLoc": $infoFileLoc,
      "page":        substring-after(request:get-uri(), "admin/"),
      "pathToEd":    $pathToEd,
      "title":       $title,
      "auth":        sm:id()/sm:id
    }
  } catch * {
    util:log("error", "No collection found for project ID " || $ed),
    map {
      "ed": ""
    }
  }
};

declare function wdbAdmin:getEd ( $node as node(), $model as map(*) ) as element(meta) {
  <meta name="ed" content="{ $model?ed }" />
};

declare function wdbAdmin:heading ($node as node(), $model as map(*)) {
  let $opts := if (request:get-parameter('job', '') != '')
    then <span class="dispOpts"><a href="global.html">globale Optionen</a></span>
    else ()
    
  return (
    <h1>{
      if ($model?page = 'admin.html')
      then "Admin-Seite"
      else if ($model?page = 'global.html')
      then "Globale Einstellungen"
      else if ($model?ed = '')
      then "Projekte"
      else ("Projekt ", <i>{$model?title}</i>, " (" || $model?ed || ")")
    }</h1>,
    $opts
  )
};

declare function wdbAdmin:getAside ($node as node(), $model as map(*)) as element() {
  <aside>
    <h3>Funktionen</h3>
    {
      switch ($model?page)
        case "projects.html" return (
          <a href="new.html?ed={$model?ed}">(Unter-)Projekt erstellen</a>,<br/>,
          <a href="directoryForm.html?ed={$model?ed}">Dateien hochladen</a>
        )
        default return ()
    }
    <hr />
    <div id="rightSide" role="contentinfo"/>
    <hr />
    <div class="info" role="contentinfo">
      <h2>Projekt-Info</h2>
      <dl>{ wdbErr:get($model, "") }</dl>
    </div>
  </aside>
};

declare function wdbAdmin:css ( $node as node(), $model as map(*) ) as element()* {
  if ( unparsed-text-available($wdb:data || "/resources/wdb.css") )
    then <link rel="stylesheet" type="text/css" href="../data/resources/wdb.css" />
    else (),
  if ( unparsed-text-available($wdb:data || "/resources/admin.css") )
    then <link rel="stylesheet" type="text/css" href="../data/resources/admin.css" />
    else ()
};
