xquery version "3.1";

module namespace wdbe = "https://github.com/dariok/wdbplus/entity";

import module namespace wdbFiles = "https://github.com/dariok/wdbplus/files" at "wdb-files.xqm";

declare namespace tei    = "http://www.tei-c.org/ns/1.0";
declare namespace wdbErr = "https://github.com/dariok/wdbplus/errors";

(: $id    ID-String of the entity to be displayed – must be globally unique
   $ed    ID of the project from which specific information shall be drawn :)
declare function wdbe:getEntity ( $node as node(), $model as map(*), $ent as xs:string, $ed as xs:string, $q as xs:string ) as map(*) {
  let $fullPath := wdbFiles:getFullPath($ed)
    , $collection := collection($fullPath?mainProject)
    
  let $entryEd := switch ( $q )
    case "per"
      return $collection/id($ent)[self::tei:person and ancestor::*:text]
    case "org"
      return $collection/id($ent)[self::tei:org and ancestor::*:text]
    case "pla"
      return $collection/id($ent)[self::tei:place and ancestor::*:text]
    case "bib"
      return $collection/id($ent)[self::tei:bibl and ancestor::*:text]
    default
      return error(xs:QName("wdbErr:wdb3010"), "unknown entity type", map { "type": $q })
    
  (: TODO: this only uses a project specific list* file; we want ot use (or at least support) globals files :)
  return map { "entry": $entryEd[1], "ed": $ed, "pathToEd": $fullPath?mainProject } 
};

declare function wdbe:getEntityBody( $node as node(), $model as map(*) ) as element() {
  let $xsl := if ( doc-available($model?pathToEd || "/resources/tei-index.xsl") )
        then doc($model?pathToEd || "/resources/tei-index.xsl")
        else if ( doc-available("/db/apps/edoc/data" || "/resources/tei-index.xsl") )
        then doc("/db/apps/edoc/data" || "/resources/tei-index.xsl")
        else doc("/db/apps/edoc/resources/xsl/tei-index.xsl")
    , $result := transform:transform($model?entry, $xsl, ())
  
  return if ( count($result) = 1 )
    then $result
    else <div id="{$model?ent}"><p>Keine Informationen gefunden.</p></div>
};
