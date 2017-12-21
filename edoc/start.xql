xquery version "3.0";

import module namespace wdbm	= "https://github.com/dariok/wdbplus/mets"	at "modules/mets.xqm";
import module namespace wdb		= "https://github.com/dariok/wdbplus/wdb"		at "modules/app.xql";

declare namespace match 	= "http://www.w3.org/2005/xpath-functions";
declare namespace mets		= "http://www.loc.gov/METS/";
declare namespace mods		= "http://www.loc.gov/mods/v3";
declare namespace tei			= "http://www.tei-c.org/ns/1.0";
declare namespace output	= "http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:method "html5";
declare option output:media-type "text/html";

let $path := request:get-parameter('path', '')
let $dir := analyze-string($path, '^/?(.*)/([^/]+)$')

let $xsl := doc('xmldb:exist:///db/edoc/resources/mets.xsl')
 
	let $id := analyze-string($path, '^/?(.*)/([^/]+)$')//match:group[1]/text()
	let $metsFile := concat($wdb:edocBaseDB, '/', $id,"/mets.xml")
	let $mets := doc($metsFile)
	let $title := ($mets//mods:title)[1]/text()
	
	let $model := map { "id" := $id, "title" := $title , "mets" := $metsFile }
	
let $bogus := <void></void>

return 
<html>
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
	{wdbm:pageTitle($bogus, $model)}
	<link rel="stylesheet" type="text/css" href="$shared/css/start.css" />
	<script src="http://code.jquery.com/jquery-3.1.0.js" type="text/javascript" />
	<script src="$shared/scripts/function.js" type="text/javascript" />
</head>
<body>
	<div id="sideBar" />
	<div id="rightSide">
		{wdbm:getRight($bogus, $model)}
	</div>
	<div id="container">
		<div id="navBar">
			<h1>{$title}</h1>
			<hr />
		</div>
		<div id="content">
			{wdbm:getLeft($bogus, $model)}
		</div>
		<!-- <div id="footer" data-template="habm:footer"/> -->
	</div>
</body>
</html>


(:<p>{$path}</p>
	transform:transform(doc(concat('xmldb:exist:///db/edoc/', $dir//match:group[1]/text(), '/mets.xml')),
		$xsl, ()):)