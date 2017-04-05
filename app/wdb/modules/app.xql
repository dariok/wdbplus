xquery version "3.0";

module namespace hab = "http://diglib.hab.de/ns/hab";

import module namespace templates	= "http://exist-db.org/xquery/templates" ;
import module namespace config		= "http://diglib.hab.de/ns/config" at "config.xqm";
import module namespace habt			= "http://diglib.hab.de/ns/transform" at "transform.xqm";

declare namespace mets	= "http://www.loc.gov/METS/";
declare namespace mods	= "http://www.loc.gov/mods/v3";
declare namespace xlink	= "http://www.w3.org/1999/xlink";
declare namespace tei		= "http://www.tei-c.org/ns/1.0";

declare variable $hab:edoc := "/db/edoc";
declare variable $hab:edocRestBase := "http://dev2.hab.de/rest";
declare variable $hab:edocRest := concat($hab:edocRestBase, $hab:edoc);
declare variable $hab:edocBase := 'http://dev2.hab.de/edoc';

(:  :declare option exist:serialize "expand-xincludes=no";:)

declare %templates:wrap
function hab:getEE($node as node(), $model as map(*), $id as xs:string) { (:as map(*) {:)
	let $m := hab:populateModel($id)
	return $m
};

declare function hab:populateModel($id as xs:string) { (:as map(*) {:)
	(: Wegen des Aufrufs aus pquery nur mit Nr. hier prüfen; 2017-03-27 DK :)
	let $ed := if (contains($id, 'edoc'))
		then substring-before(substring-after($id, 'edoc_'), '_')
		else $id
	
	let $metsLoc := concat($hab:edoc, '/', $ed, "/mets.xml")
	let $mets := doc($metsLoc)
	let $metsfile := $mets//mets:file[@ID=$id]
	let $fileLoc := $metsfile//mets:FLocat/@xlink:href
	let $file := doc(concat($hab:edoc, '/', $ed, '/', $fileLoc))
	(:let $structId := $metsfile/parent::mets:fileGrp/@ID:)
	let $structId := $mets//mets:div[@TYPE='group']/mets:div[descendant::mets:fptr[@FILEID=$id]]/@ID
	let $structType := $mets//mets:div[mets:fptr[@FILEID=$id]]/@TYPE
	let $xslt := 
		if ($mets//mets:behaviorSec[@ID='html' or @ID='HTML'])
			then if ($mets//mets:behaviorSec[@ID='html' or @ID='HTML']/mets:behavior[@STRUCTID=$structId])
				then $mets//mets:behaviorSec[@ID='html' or @ID='HTML']/mets:behavior[@STRUCTID=$structId]/mets:mechanism/@xlink:href
				(: Unterstützung für den Fall in Karlstadt: in einer div sind Intro und Transcript zusammen :)
				else $mets//mets:behaviorSec[@ID='html' or @ID='HTML']/mets:behavior[@STRUCTID=$structType]/mets:mechanism/@xlink:href
	    else $mets//mets:behavior[(@LABEL='html' or @LABEL='HTML') 
	                and @STRUCTID=$structType]/mets:mechanism/@xlink:href
	let $authors := $file/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:author
	let $shortTitle := $file/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[@type]
	let $nr := $file/tei:TEI/@n
	let $title := element tei:title {
		$nr,
		$file/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[not(@type)]/node()
	}
	
	return map { "fileLoc" := $fileLoc, "xslt" := $xslt, "type" := $structId, "title" := $title ,
			"shortTitle" := $shortTitle, "authors" := $authors, "ed" := $ed, "metsLoc" := $metsLoc }
	(:return <ul>
	    <li>ID: {$id}</li>
	    <li>Mets: {concat($hab:edoc, '/', $ed, "/mets.xml")}; existiert? {doc-available(concat($hab:edoc, '/', $ed, "/mets.xml"))}</li>
	    <li>metsfile: {$metsfile}</li>
	    <li>fileloc: {string($fileLoc)}</li>
	    <li>file: {concat($hab:edoc, '/', $ed, '/', $fileLoc)}</li>
	    <li>structType: {string($structType)}</li>
	    <li>structId: {string($structId)}</li>
	    <li>xslt: {string($xslt)}</li>
	</ul>:)
};

declare function hab:getEdTitle($node as node(), $model as map(*)) as element() {
	let $name := doc($model("metsLoc"))//mods:mods/mods:titleInfo/mods:title
	return <h1>{string($name)}</h1>
};

declare function hab:EEtitle($node as node(), $model as map(*)) as xs:string {
	let $title := habt:transform($model("title"))
	return string-join($title, '|')
};

declare function hab:EEpart($node as node(), $model as map(*)) as xs:string {
	<h2>{
		switch ($model("type"))
			case "introduction"
				return string("Einleitung")
			case "transcript"
				return string("Text")
			default
				return string($model("type"))}
	</h2>
};

declare function hab:EEbody($node as node(), $model as map(*)) {
	let $file := concat($hab:edoc, '/', $model("ed"), '/', $model("fileLoc"))
	(:let $xslt := concat('xmldb:exist://', $hab:edoc, '/', $model("xslt")):)
	let $xslt := concat($hab:edoc, '/', $model("ed"), '/', $model("xslt"))
	let $params := <parameters><param name="server" value="eXist"/></parameters>
	(: ambiguous rule match soll nicht zum Abbruch führen :)
(:	let $attr := <attributes><attr name="http://saxon.sf.net/feature/recoveryPolicyName" value="recoverSilently" /></attributes>:)
let $attr := ()
	
	return
		try { transform:transform(doc($file), doc($xslt), $params, $attr, "expand-xincludes=no") }
		catch * { <ul><li>f: {$file}</li><li>x: {$xslt}</li><li>p: {$params}</li><li>a: {$attr}</li></ul>
				,<ul><li>{$err:code}: {$err:description}</li><li>{$err:line-number}:{$err:column-number}</li><li>a: {$err:additional}</li></ul>}
		(:doc($file):)
};

declare function hab:pageTitle($node as node(), $model as map(*)) {
	let $ti := string ($model("shortTitle"))
	return <title>WDB {string($model("title")/@n)} – {$ti}</title>
};

declare function hab:footer($node as node(), $model as map(*)) {
	let $xml := string($model("fileLoc"))
	let $xsl := string($model("xslt"))
	return
	<div class="footer">
		<div class="footerEntry">XML: <a href="{concat($hab:edocRest, '/', $model("ed"), '/', $xml)}">{$xml}</a></div>
		<div class="footerEntry">XSLT: <a href="{concat($hab:edocRest, '/', $model("ed"), '/', $xsl)}">{$xsl}</a></div>
	</div>
};

declare function hab:authors($node as node(), $model as map(*)) {
	let $max := count($model("authors"))
	for $auth at $i in $model("authors")
		let $t := if ($i > 1 and $i < max)
			then ", "
			else if ($i > 1) then " und " else ""
		return concat($t, $auth)
};

declare function hab:getCSS($node as node(), $model as map(*)) {
    let $ed := $model("ed")
	let $f := if ($model("type") = "transcript")
			then "transcr.css"
			else "intro.css"
			
	(: verschiedene Varianten ausprobieren; 2017-02-20 DK :)
	(:let $path := if (doc-available(concat($ed, "layout/project.css")))
	    then concat($ed, "layout/project.css")
	    else if (doc-available(concat($ed, "layout/common.css")))
	        then concat($ed, "layout/common.css")
	        else "/edoc/resources/css/common.css":)
	let $path := concat($ed, "/scripts/project.css")
	
	return (<link rel="stylesheet" type="text/css" href="resources/css/{$f}" />,
		<link rel="stylesheet" type="text/css" href="{$path}" />
	)
};

declare function hab:getEENr($node as node(), $model as map(*), $id as xs:string) as node() {
	let $ee := substring-before(substring-after($id, 'edoc_'), '_')
	return <meta name="edition" content="{$ee}" />
};

(: neu für das Laden projektspezifischer JS; 2016-11-02 DK :)
declare function hab:getJS($node as node(), $model as map(*)) {
	let $path := concat($model("ed"), "/scripts/project.js")
	return <script src="{$path}" type="text/javascript" />
};