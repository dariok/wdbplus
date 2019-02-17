xquery version "3.0";

import module namespace wdbm	= "https://github.com/dariok/wdbplus/nav"	at "nav.xqm";
import module namespace wdb		= "https://github.com/dariok/wdbplus/wdb"	at "app.xql";
import module namespace console	= "http://exist-db.org/xquery/console";

declare namespace match 	= "http://www.w3.org/2005/xpath-functions";
declare namespace mets		= "http://www.loc.gov/METS/";
declare namespace mods		= "http://www.loc.gov/mods/v3";
declare namespace tei		= "http://www.tei-c.org/ns/1.0";
declare namespace output	= "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace wdbmeta	= "https://github.com/dariok/wdbplus/wdbmeta";
declare namespace wdbPF		= "https://github.com/dariok/wdbplus/projectFiles";

declare option output:method "html5";
declare option output:media-type "text/html";

let $pPath := request:get-parameter('path', ())
let $pId := request:get-parameter('id', ())
let $pEd := request:get-parameter('ed', ())

(: general behaviour: IDs always take precedence :)
let $path := if ($pId)
	then wdb:getEdPath(base-uri((collection($wdb:data)/id($pId))[1]), true())
	else if ($pEd)
	then $wdb:edocBaseDB || '/' || $pEd
	else wdb:getEdPath($wdb:edocBaseDB || $pPath, true())

let $metaFile := if (doc-available($path || '/wdbmeta.xml'))
	then doc($path || '/wdbmeta.xml')
	else doc($path || '/mets.xml')

let $model := if ($metaFile/wdbmeta:*)
	then
		let $id := $metaFile//wdbmeta:projectID/text()
		let $title := normalize-space($metaFile//wdbmeta:title[1])
		return map { "id" := $id, "title" := $title, "infoFileLoc" := $path || '/wdbmeta.xml',
			"ed" := substring-after($path, $wdb:data), "pathToEd" := $path, "fileLoc" := "start.xql" }
	else
		let $id := analyze-string($path, '^/?(.*)/([^/]+)$')//match:group[1]/text()
		let $title := normalize-space(($metaFile//mods:title)[1])
		return map { "id" := $id, "title" := $title , "infoFileLoc" := $path || '/mets.xml',
			"ed" := substring-after($path, $wdb:data), "pathToEd" := $path, "fileLoc" := "start.xql" }

let $t := console:log($model)
return 
<html>
	<head>
		{wdb:getHead(<void/>, $model)}
	</head>
	<body>
		<header>
			{
				if (wdb:findProjectFunction($model, 'getStartHeader', 1))
				then wdb:eval('wdbPF:getStartHeader($model)', false(), (xs:QName('model'), $model))
				else (
					<h1>{$model("title")}</h1>,
					<hr/>
				)
			}
		</header>
		<main>
			<div>
				<nav>
				{
				if (wdb:findProjectFunction($model, 'getStartLeft', 1))
					then wdb:eval('wdbPF:getStartLeft($model)', false(), (xs:QName('model'), $model))
					else (<h1>Inhalt</h1>,
						wdbm:getLeft(<void />, $model))
				}
				</nav>
			</div>
			<aside id="wdbRight">
				{
				if (wdb:findProjectFunction($model, 'getStart', 1))
					then wdb:eval('wdbPF:getStart($model)', false(), (xs:QName('model'), $model))
					else wdbm:getRight(<void/>, $model)
				}
			</aside>
		</main>
	</body>
</html>