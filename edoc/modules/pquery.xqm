(: kontrolliert die Verarbeitung von projektspezifischen XQuery;
 : Bearbeiter:DK Dario Kampkaspar kampkaspar@hab.de
 : erstellt 2016-11-03 DK :)
xquery version "3.0";

module namespace habpq = "http://diglib.hab.de/ns/pquery";

import module namespace templates	= "http://exist-db.org/xquery/templates" ;
import module namespace hab				= "http://diglib.hab.de/ns/hab" at "app.xql";

declare %templates:default("q", "") %templates:default("q2", "")
	function habpq:start($node as node(), $model as map(*), $edition as xs:string, $query as xs:string, $q as xs:string, $q2 as xs:string) as map(*) {
	let $ed := $edition
	
	return map { "query" := $query, "ed" := $ed }
};

declare function habpq:pageTitle ($node as node(), $model as map(*)) {
	let $ti := $model("ed")
	
	return <title>WDB – {$ti}</title>
};

(: die angegebene Datei laden. Die Eingangsfunktion muß gegeben sein; 2016-11-03 DK :)
(: TODO geht das auch anders? :)
declare function habpq:body($node as node(), $model as map(*)) {
	let $path := concat($hab:edoc, '/', $model("ed"), '/', $model("query"))
	let $module := util:import-module(xs:anyURI("http://diglib.hab.de/ns/habq"), 'habq', xs:anyURI($path))
(:	let $map := $model("q"):)
	
		return util:eval("habq:query()", xs:boolean('false'), (xs:QName('map'), $model))
};