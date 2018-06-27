xquery version "3.0";

module namespace wdbm = "https://github.com/dariok/wdbplus/mets";

import module namespace templates	= "http://exist-db.org/xquery/templates" ;
import module namespace wdb 		= "https://github.com/dariok/wdbplus/wdb" at "app.xql";
import module namespace console		= "http://exist-db.org/xquery/console";
import module namespace sm			= "http://exist-db.org/xquery/securitymanager";

declare namespace mets		= "http://www.loc.gov/METS/";
declare namespace mods		= "http://www.loc.gov/mods/v3";
declare namespace tei		= "http://www.tei-c.org/ns/1.0";
declare namespace match		= "http://www.w3.org/2005/xpath-functions";
declare namespace wdbmeta	= "https://github.com/dariok/wdbplus/wdbmeta";

declare function wdbm:getLeft($node as node(), $model as map(*)) {
	let $targetCollection := if(collection($wdb:data)/id($model("ed")))
		then wdb:getEdPath(base-uri((collection($wdb:data)/id($model("ed")))[1]), true())
		else $model("ed")
		
	let $xml := if (doc-available($targetCollection||'/wdbmeta.xml'))
		then ($targetCollection||'/wdbmeta.xml')
		else ($targetCollection||'/mets.xml')
	
	let $xsl := if (contains($xml,'wdbmeta'))
		then if (doc-available($targetCollection || '/wdbmeta.xsl'))
			then $targetCollection || '/wdbmeta.xsl'
			else $wdb:edocBaseDB || '/resources/wdbmeta.xsl'
		else if (doc-available($targetCollection || '/mets.xsl'))
			then $targetCollection || '/mets.xsl'
			else $wdb:edocBaseDB || '/resources/mets.xsl'
	
	let $param := 
		<parameters>
			<param name="footerXML" value="{wdb:getUrl($xml)}" />
			<param name="footerXSL" value="{wdb:getUrl($xsl)}" />
			<param name="wdb" value="{$wdb:edocBaseURL || '/view.html'}" />
			<param name="role" value="{$wdb:role}" />
			<param name="access" value="{sm:has-access($targetCollection, 'w')}" />
		</parameters>
	
	return
		transform:transform(doc($xml), doc($xsl), $param)
};

declare function wdbm:getRight($node as node(), $model as map(*)) {
	let $xml := concat($model("ed"), '/start.xml')
	
	let $xsl := if (doc-available(concat($model("ed"), '/start.xsl')))
		then $model("ed") || '/start.xsl'
		else $wdb:edocBaseDB || '/resources/start.xsl'
	
	return
		<div class="start">
			{transform:transform(doc($xml), doc($xsl), ())}
			{wdb:getFooter($xml, $xsl)}
		</div>
};