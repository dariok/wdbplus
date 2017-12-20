xquery version "3.0";

module namespace wdbm = "https://github.com/dariok/wdbplus/mets";
import module namespace templates	= "http://exist-db.org/xquery/templates" ;
import module namespace wdb 			= "https://github.com/dariok/wdbplus/wdb" at "app.xql";

declare namespace mets	= "http://www.loc.gov/METS/";
declare namespace mods	= "http://www.loc.gov/mods/v3";
declare namespace tei		= "http://www.tei-c.org/ns/1.0";
declare namespace match = "http://www.w3.org/2005/xpath-functions";

declare 
function wdbm:getEE($node as node(), $model as map(*), $path as xs:string) as map(*) {
	let $mets := doc(concat($wdb:edoc,"/mets.xml"))
	let $title := $mets//mods:title/text()
	
	let $id := analyze-string($path, '^/?(.*)/([^/]+)$')//match:group[1]/text()
	
	return map { "id" := $id, "title" := $title , "mets" := $mets }
};

declare function wdbm:pageTitle($node as node(), $model as map(*)) {
	let $bogus := ""
	return <title>{$model("title")}</title>
};

declare function wdbm:getLeft($node as node(), $model as map(*)) {
	let $xml := doc($model('mets'))
	let $xsl := if (doc-available(concat($model("id"), '/mets.xsl')))
		then doc(concat($wdb:edoc, '/', $model("id"), '/mets.xsl'))
		else doc('../resources/mets.xsl')
	
	return
		transform:transform($xml, $xsl, ())
};

declare function wdbm:getRight($node as node(), $model as map(*)) {
	let $xml := doc(concat($model("id"), '/start.xml'))
	
(:	TODO eigene start.xsl benutzen, falls vorhanden:)
(:	let $xsl := doc(concat('xmldb:exist:///db/edoc/', $model("id"), '/start.xsl')):)
    let $xsl := doc('../resources/start.xsl')
	
	return
		transform:transform($xml, $xsl, ())
};