xquery version "3.0";

module namespace habm = "http://diglib.hab.de/ns/mets";
import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace hab = "http://diglib.hab.de/ns/hab" at "app.xql";

declare namespace mets	= "http://www.loc.gov/METS/";
declare namespace mods	= "http://www.loc.gov/mods/v3";
declare namespace tei		= "http://www.tei-c.org/ns/1.0";
declare namespace match = "http://www.w3.org/2005/xpath-functions";

declare 
function habm:getEE($node as node(), $model as map(*), $path as xs:string) as map(*) {
	let $mets := doc(concat($hab:edoc,"/mets.xml"))
	let $title := $mets//mods:title/text()
	
	let $id := analyze-string($path, '^/?(.*)/([^/]+)$')//match:group[1]/text()
	
	return map { "id" := $id, "title" := $title , "mets" := $mets }
};

declare function habm:pageTitle($node as node(), $model as map(*)) {
	let $bogus := ""
	return <title>{$model("title")}</title>
};

declare function habm:getLeft($node as node(), $model as map(*)) {
	let $xml := doc(concat('xmldb:exist:///db/edoc/', $model("id"), '/mets.xml'))
	let $xsl := doc('xmldb:exist:///db/edoc/resources/mets.xsl')
	
	return
		transform:transform($xml, $xsl, ())
};

declare function habm:getRight($node as node(), $model as map(*)) {
	let $xml := doc(concat('xmldb:exist:///db/edoc/', $model("id"), '/start.xml'))
	let $xsl := doc(concat('xmldb:exist:///db/edoc/', $model("id"), '/start.xsl'))
	
	return
		transform:transform($xml, $xsl, ())
};