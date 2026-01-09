xquery version "3.1";

module namespace wdbAdmin = "https://github.com/dariok/wdbplus/Admin";

import module namespace config   = "https://github.com/dariok/wdbplus/config" at "../modules/wdb-config.xqm";
import module namespace wdbErr   = "https://github.com/dariok/wdbplus/errors" at "../modules/error.xqm";
import module namespace wdbFiles = "https://github.com/dariok/wdbplus/files"  at "../modules/wdb-files.xqm";
import module namespace wdbm     = "https://github.com/dariok/wdbplus/model"  at "../modules/model.xqm";

declare namespace meta      = "https://github.com/dariok/wdbplus/wdbmeta";
declare namespace sm        = "http://exist-db.org/xquery/securitymanager";
declare namespace templates = "http://exist-db.org/xquery/html-templating";
declare namespace wdb       = "https://github.com/dariok/wdbplus/wdb";

(:~
 : populate the model for admin pages
 : 
 : @param $ed The ID of a _project_
 : @return    The model
 :)
declare
    %templates:default("ed", "data")
function wdbAdmin:start ( $node as node(), $model as map(*), $ed as xs:string ) as item()* {
  wdbm:populateModel((), $ed, "", "", "")
};

declare function wdbAdmin:getEd ( $node as node(), $model as map(*) ) as item()+ {(
  comment { "Created in admin.xqm for "|| $node/@data-template },
  <meta name="ed" content="{ $model?ed }" />,
  <meta name="path" content="{ $model?pathToEd }" />
)};

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
  if ( unparsed-text-available($config:data || "/resources/css/wdb.css") )
    then <link rel="stylesheet" type="text/css" href="$global/css/wdb.css" />
    else (),
  if ( unparsed-text-available($config:data || "/resources/css/admin.css") )
    then <link rel="stylesheet" type="text/css" href="$global/css/admin.css" />
    else ()
};
