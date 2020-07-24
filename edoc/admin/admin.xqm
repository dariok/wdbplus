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
    "pathToEd": $pathToEd,
    "infoFileLoc": $infoFileLoc,
    "title": $title
  }
};