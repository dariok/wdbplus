(: kontrolliert die Verarbeitung von projektspezifischen XQuery;
 : Bearbeiter:DK Dario Kampkaspar kampkaspar@hab.de
 : erstellt 2016-11-03 DK :)
xquery version "3.0";

module namespace habpq = "http://diglib.hab.de/ns/pquery";

declare function habpq:start($node as node(), $model as map(*), $edition as xs:string, $query as xs:string) as map(*) {
	let $ed := $edition
	
	return map { "query" := $query, "ed" := $ed }
};

declare function habpq:pageTitle ($node as node(), $model as map(*)) {
	let $ti := $model("ed")
	
	return <title>WDB – {$ti}</title>
};

declare function habpq:body($node as node(), $model as map(*)) {
	let $xq := $model("query")
	
	return <p>{$xq}</p>
};