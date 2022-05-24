xquery version "3.0";
(: erstellt 2016-07-26 Bearbeiter:DK Dario Kampkaspar :)

module namespace wdbe = "https://github.com/dariok/wdbplus/entity";

import module namespace wdb     = "https://github.com/dariok/wdbplus/wdb" at "app.xqm";

declare namespace tei  = "http://www.tei-c.org/ns/1.0";

(: $id    ID-String of the entity to be displayed – must be globally unique
   $ed    ID of the project from which specific information shall be drawn :)
declare function wdbe:getEntity ( $node as node(), $model as map(*), $ent as xs:string, $ed as xs:string ) as map(*) {
  let $edPath := wdb:getEdPath($ed, true())
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
