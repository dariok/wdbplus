xquery version "3.0";

import module namespace wdbm	= "https://github.com/dariok/wdbplus/mets"	at "mets.xqm";
import module namespace wdb		= "https://github.com/dariok/wdbplus/wdb"	at "app.xql";
import module namespace console	= "http://exist-db.org/xquery/console";

declare namespace match 	= "http://www.w3.org/2005/xpath-functions";
declare namespace mets		= "http://www.loc.gov/METS/";
declare namespace mods		= "http://www.loc.gov/mods/v3";
declare namespace tei		= "http://www.tei-c.org/ns/1.0";
declare namespace output	= "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace wdbmeta	= "https://github.com/dariok/wdbplus/wdbmeta";

declare option output:method "html5";
declare option output:media-type "text/html";

let $path := wdb:getEdPath($wdb:edocBaseDB || request:get-parameter('path', ''), true())

let $metaFile := if (doc-available($path || '/wdbmeta.xml'))
	then doc($path || '/wdbmeta.xml')
	else doc($path || '/mets.xml')

let $t1 := console:log($path)

let $model := if (doc-available($path || '/wdbmeta.xml'))
	then
		let $id := $metaFile//wdbmeta:projectID
		let $title := normalize-space($metaFile//wdbmeta:title[1])
		return map { "id" := $id, "title" := $title, "metaFile" := $path || '/wdbmeta.xml' }
	else
		let $id := analyze-string($path, '^/?(.*)/([^/]+)$')//match:group[1]/text()
		let $title := normalize-space(($metaFile//mods:title)[1])
		return map { "id" := $id, "title" := $title , "metaFile" := $path || '/mets.xml' }

let $bogus := <void></void>

return 
<html>
	<head>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
		<title>{normalize-space($model("title"))}</title>
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
				<h1>{$model("title")}</h1>
				<hr />
			</div>
			<div id="content">
				{wdbm:getLeft($bogus, $model)}
			</div>
			<!-- <div id="footer" data-template="habm:footer"/> -->
		</div>
	</body>
</html>