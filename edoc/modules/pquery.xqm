(: kontrolliert die Verarbeitung von projektspezifischen XQuery;
 : Bearbeiter:DK Dario Kampkaspar kampkaspar@hab.de
 : erstellt 2016-11-03 DK :)
xquery version "3.0";

module namespace habpq = "https://github.com/dariok/wdbplus/pquery";

import module namespace templates	= "http://exist-db.org/xquery/templates" ;
import module namespace hab				= "https://github.com/dariok/wdbplus/hab" at "app.xql";

declare %templates:default("q", "") %templates:default("q2", "")
	function habpq:start($node as node(), $model as map(*), $edition as xs:string, $query as xs:string, $q as xs:string, $q2 as xs:string) as map(*) {
	(: die weiteren Inhalte über das Modul app holen; 2017-03-27 DK :)
	let $mo := hab:populateModel($edition)
	let $mo2 := map{ "query" := $query, "ed" := $edition }
	
	return map:merge(($mo, $mo2))
(:	return $mo:)
};

declare function habpq:pageTitle ($node as node(), $model as map(*)) {
	let $ti := $model("shortTitle")
	
	return <title>WDB – {$ti}</title>
};

(: die angegebene Datei laden. Die Eingangsfunktion muß gegeben sein; 2016-11-03 DK :)
(: TODO geht das auch anders? :)
(: Wir nehmen grundsätzlich an, daß die Skripte im Unterverzeichnis scripts innerhalb des Projektordners liegen
		(vgl. Mail Thomas 2017-01-04T12:05) :)
declare function habpq:body($node as node(), $model as map(*)) {
	let $path := concat($hab:edoc, '/', $model("ed"), '/scripts/', $model("query"))
	let $module := util:import-module(xs:anyURI("https://github.com/dariok/wdbplus/habq"), 'habq', xs:anyURI($path))
	
		return util:eval("habq:query()", xs:boolean('false'), (xs:QName('map'), $model))
};

(: gibt das h2 für die navbar aus; neu 2017-03-27 DK :)
declare function habpq:getTask($node as node(), $model as map(*)) {
	let $path := concat($hab:edoc, '/', $model("ed"), '/scripts/', $model("query"))
	let $module := util:import-module(xs:anyURI("https://github.com/dariok/wdbplus/habq"), 'habq', xs:anyURI($path))
	
	return util:eval("habq:getTask()", xs:boolean('false'), (xs:QName('map'), $model))
};