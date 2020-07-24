xquery version "3.1";

module namespace wdbAdmin = "https://github.com/dariok/wdbplus/Admin";

import module namespace console   = "http://exist-db.org/xquery/console"       at "java:org.exist.console.xquery.ConsoleModule";
import module namespace templates ="http://exist-db.org/xquery/templates"      at "/db/apps/shared-resources/content/templates.xql";
import module namespace wdb       = "https://github.com/dariok/wdbplus/wdb"    at "../modules/app.xqm";

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
  
  return map {
    "ed": $ed,
    "pathToEd": $pathToEd
  }
};