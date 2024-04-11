xquery version "3.1";

module namespace wdbe = "https://github.com/dariok/wdbplus/entity";

import module namespace wdb     = "https://github.com/dariok/wdbplus/wdb" at "app.xqm";
import module namespace console = "http://exist-db.org/xquery/console";

declare namespace tei = "http://www.tei-c.org/ns/1.0";

(: $ent   ID-String of the entity to be displayed – must be globally unique
   $ed    ID of the project from which specific information shall be drawn :)
declare function wdbe:getEntity ( $node as node(), $model as map(*), $ent as xs:string, $ed as xs:string ) as map(*) {
  let $edPath := (wdbFile:getFullPath($ed))?projectPath
    , $entry := collection($edPath || "/index")/id($ent)
  
  return map { "entry": $entry, "ent": $ent, "ed": $ed, "pathToEd": $edPath }
};

declare function wdbe:getEntityBody( $node as node(), $model as map(*) ) as element() {
  let $xsl := if ( doc-available($model?pathToEd || "/resources/tei-index.xsl") )
        then doc($model?pathToEd || "/resources/tei-index.xsl")
        else doc("/db/apps/edoc/resources/tei-index.xsl")
    , $result := transform:transform($model?entry, $xsl, ())
  
  return if ( count($result) = 1 )
    then $result
    else <div id="{$model?ent}"><p>Keine Informationen gefunden.</p></div>
};
