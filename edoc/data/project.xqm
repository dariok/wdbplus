xquery version "3.1";

module namespace wdbPF	= "https://github.com/dariok/wdbplus/projectFiles";

import module namespace wdb	= "https://github.com/dariok/wdbplus/wdb" at "/db/apps/edoc/modules/app.xqm";
declare namespace tei	= "http://www.tei-c.org/ns/1.0";

declare function wdbPF:getProjectFiles ( $model as map(*) ) as node()* {
    (
        <link rel="stylesheet" type="text/css" href="{$wdb:edocBaseURL}/data/scripts/project.css" />,
        <script src="{$wdb:edocBaseURL}/data/scripts/project.js" />,
        <script src="{$wdb:edocBaseURL}/resources/scripts/annotate.js" />
    )
};

declare function wdbPF:getHeader ( $model as map(*) ) as node()* {
	let $file := doc($model("fileLoc"))
	return (
		<h1>{$file/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[@type = 'main']/text()}</h1>,
		<h2>{$file/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[@type = 'num']/text()}</h2>,
		<span class="dispOpts">[<a href="javascript:anno()">annotieren</a>]</span>
	)
};

declare function wdbPF:getImages ($id as xs:string, $page as xs:string) as xs:string {
  "none"
};

declare function wdbPF:getStart ($model as map(*)) {
	transform:transform(doc($wdb:data||'/resources/start.xml'), doc($wdb:data||'/resources/start.xsl'), ()),
	wdb:getFooter($wdb:data||'/resources/start.xml', $wdb:data||'/resources/start.xsl')
};