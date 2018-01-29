xquery version "3.0";

module namespace wdbm = "https://github.com/dariok/wdbplus/mets";

import module namespace templates	= "http://exist-db.org/xquery/templates" ;
import module namespace wdb 		= "https://github.com/dariok/wdbplus/wdb" at "app.xql";
import module namespace console		= "http://exist-db.org/xquery/console";

declare namespace mets		= "http://www.loc.gov/METS/";
declare namespace mods		= "http://www.loc.gov/mods/v3";
declare namespace tei		= "http://www.tei-c.org/ns/1.0";
declare namespace match		= "http://www.w3.org/2005/xpath-functions";
declare namespace wdbmeta	= "https://github.com/dariok/wdbplus/wdbmeta";

declare function wdbm:pageTitle($node as node(), $model as map(*)) {
	<title>{$model("title")}</title>
};

declare function wdbm:getLeft($node as node(), $model as map(*)) {
	let $t1 := console:log($model)
	let $xml := doc($model("infoFileLoc"))
	
	let $xsl := if (contains($model("infoFileLoc"), 'wdbmeta'))
		then if (doc-available(concat($model("ed"), '/wdbmeta.xsl')))
			then doc(concat($wdb:edocBaseDB, '/', $model("ed"), '/wdbmeta.xsl'))
			else doc($wdb:edocBaseDB || '/resources/wdbmeta.xsl')
		else if (doc-available(concat($model("ed"), '/mets.xsl')))
			then doc(concat($wdb:edocBaseDB, '/', $model("ed"), '/mets.xsl'))
			else doc($wdb:edocBaseDB || '/resources/mets.xsl')
	
	let $param := <parameters>
					<param name="footerXML" value="{wdb:getUrl(base-uri($xml))}" />
					<param name="footerXSL" value="{wdb:getUrl(base-uri($xsl))}" />
					<param name="wdb" value="{$wdb:edocBaseURL || '/view.html'}" />
				</parameters>
				
	return
		transform:transform($xml, $xsl, $param)
};

declare function wdbm:getRight($node as node(), $model as map(*)) {
	let $xml := doc(concat($wdb:edocBaseDB, '/', $model("id"), '/start.xml'))
	
(:	TODO eigene start.xsl benutzen, falls vorhanden:)
(:	let $xsl := doc(concat('xmldb:exist:///db/edoc/', $model("id"), '/start.xsl')):)
    let $xsl := doc('../resources/start.xsl')
	
	return
		transform:transform($xml, $xsl, ())
};