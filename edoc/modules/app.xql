xquery version "3.0";

module namespace wdb = "https://github.com/dariok/wdbplus/wdb";

import module namespace templates	= "http://exist-db.org/xquery/templates" ;
import module namespace config		= "https://github.com/dariok/wdbplus/config" 		at "config.xqm";
import module namespace wdbt			= "https://github.com/dariok/wdbplus/transform" at "transform.xqm";
import module namespace console 	= "http://exist-db.org/xquery/console";

declare namespace mets	= "http://www.loc.gov/METS/";
declare namespace mods	= "http://www.loc.gov/mods/v3";
declare namespace xlink	= "http://www.w3.org/1999/xlink";
declare namespace tei		= "http://www.tei-c.org/ns/1.0";
declare namespace main	= "https://github.com/dariok/wdbplus";
declare namespace meta	= "https://github.com/dariok/wdbplus/wdbmeta";

(: VARIABLES :)
(: the config file :)
declare variable $wdb:configFile := doc($wdb:edocBaseDB || '/config.xml');

(: get the name of the server, possibly including the port :)
declare variable $wdb:server := if ( request:get-server-port() != 80 )
	then request:get-scheme() || '://' || request:get-server-name() || ':' || request:get-server-port()
	else request:get-scheme() || '://' || request:get-server-name()
;

(: get the base of this instance within the db (i.e. relative to /db) :)
declare variable $wdb:edocBaseDB := $config:app-root;

(: get the base URI either from the data of the last call or from the configuration :)
declare variable $wdb:edocBaseURL :=
	if ( $wdb:configFile/main:config/main:server )
	then normalize-space($wdb:configFile/main:config/main:server)
	else
		let $dir := string-join(tokenize(normalize-space(request:get-uri()), '/')[not(position() = last())], '/')
		let $url := substring-after($wdb:edocBaseDB, 'db/')
		return $wdb:server || substring-before($dir, $url) || $url
;

(: the server role :)
declare variable $wdb:role :=
	if ($wdb:configFile/main:role/main:type != '')
		then $wdb:configFile/main:role/main:type
		else "standalone"
;

(: the peer :)
declare variable $wdb:peer :=
	if ($wdb:role != "standalone")
		then $wdb:configFile/main:role/main:peer
		else ""
;

(:  :declare option exist:serialize "expand-xincludes=no";:)

declare %templates:wrap
function wdb:getEE($node as node(), $model as map(*), $id as xs:string) { (:as map(*) {:)
	let $m := wdb:populateModel($id)
	return $m
};

declare function wdb:populateModel($id as xs:string) { (:as map(*) {:)
	(: Wegen des Aufrufs aus pquery nur mit Nr. hier prüfen; 2017-03-27 DK :)
	(: Das wird vmtl. verändert werden müssen. Ggf. auslagern für queries :)
	let $pathToFile := base-uri(collection($wdb:edocBaseDB)/id($id)[1])
	let $ed := wdb:getEd($pathToFile)

	(: These can either be read from a mets.xml if present or from wdbmeta.xml :)
	(: Unterscheiden, woher die Info stammen und schauen, welche Parameter des Model wo verwendet werde :)
	let $metsLoc := concat($wdb:edocBaseDB, '/', $ed, "/mets.xml")
	let $wdbMetaFile := $wdb:edocBaseDB || '/' || $ed || '/wdbmeta.xml'
	
	(: wdbMeta is the standard, METS a fallback :)
	let $xslt := if (doc-available($wdbMetaFile))
	(: TODO target aus der Anfrage ablesen :)
		then wdb:getXslFromWdbMeta($ed, $id, 'html')
		else if (doc-available($metsLoc))
			then
				wdb:getXslFromMets($metsLoc, $id, $ed)
			else
				(: throw error :)
				()
	
	let $file := doc($pathToFile)
	
	let $authors := $file/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:author
	let $shortTitle := ($file/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[@type])[1]
	let $nr := $file/tei:TEI/@n
	let $title := element tei:title {
		$nr,
		$file/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[not(@type or @type='main')]/node()
	}
	let $type := if (contains($id, 'transcr'))
		then "transcript"
		else "introduction"
		
	(: TODO parameter aus config.xml einlesen und übergeben:)
	
	return map { "fileLoc" := $pathToFile, "xslt" := $xslt, "title" := $title ,
			"shortTitle" := $shortTitle, "authors" := $authors, "ed" := $ed, "metsLoc" := $metsLoc,
			"type" := $type }

	(:return <ul>
		<li>ID: {$id}</li>
		<li>Ed: {$ed}</li>
		<li>metsLoc: {$metsLoc}; existiert? {doc-available($metsLoc)}</li>
		<li>metsfile: {$metsfile}</li>
		<li>fileloc: {string($fileLoc)}</li>
		<li>file: {$fil}; existiert? {doc-available($fil)}</li>
		<li>structId: {string($behavior[position() = last()]/@ID)}</li>
		<li>xslt: {$xslt}; existiert? {doc-available($xslt)}</li>
		<li>title (@n, title): {string($nr)}, {string($file/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[not(@type or @type='main')])}</li>
	</ul>:)
};

(: Finden der korrekten behavior
 : $test: zu bewertende mets:behavior
 : $seqStruct: sequence von mets:div/@ID, spezifischste zuletzt
 : $type: gesuchter Ausgabetyp
 : returns: einen gewichteten Wert für den Rang der behavior :)
declare function local:val($test, $seqStruct, $type) {
    let $vIDt := for $s at $i in $seqStruct
        return if (matches($test/@STRUCTID, concat('(^| )', $s, '( |$)')))
            then math:exp10($i)
            else 0
    let $vID := fn:max($vIDt)
    let $vS := if ($test[@BTYPE = $type])
        then 5
        else if ($test[@LABEL = $type])
        then 3
        else if ($test[@ID = $type])
        then 1
        else 0
    
    return $vS + $vID
};

declare function wdb:getEdTitle($node as node(), $model as map(*)) as element() {
	let $name := doc($model("metsLoc"))//mods:mods/mods:titleInfo/mods:title
	return <h1>{string($name)}</h1>
};

declare function wdb:EEtitle($node as node(), $model as map(*)) as xs:string {
	let $title := wdbt:transform($model("title"))
	return string-join($title, '|')
};

declare function wdb:EEpart($node as node(), $model as map(*)) as xs:string {
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

declare function wdb:EEbody($node as node(), $model as map(*)) {
	(: von populateModel wird jetzt der komplette Pfad übergeben; 2017-05-22 DK :)
	let $file := $model("fileLoc")
	let $xslt := $model("xslt")
	let $params := <parameters><param name="server" value="eXist"/>
	<param name="exist:stop-on-warn" value="yes" /><param name="exist:stop-on-error" value="yes" /></parameters>
	(: ambiguous rule match soll nicht zum Abbruch führen :)
	let $attr := <attributes><attr name="http://saxon.sf.net/feature/recoveryPolicyName" value="recoverSilently" /></attributes>
(:    let $attr := ():)
	
	let $re :=
		try { transform:transform(doc($file), doc($xslt), $params, $attr, "expand-xincludes=no") }
		catch * { console:log('f: ' || $file || 'x:' || $xslt || 'p: ' || $params || 'a: ' || $attr ||
				$err:code || ': ' || $err:description || $err:line-number ||':'||$err:column-number || 'a: ' || $err:additional)
		}
		return $re
(:		return doc($file):)
};

declare function wdb:pageTitle($node as node(), $model as map(*)) {
	let $ti := string ($model("shortTitle"))
	return <title>{normalize-space($wdb:configFile//main:short)} {string($model("title")/@n)} – {$ti}</title>
};

declare function wdb:footer($node as node(), $model as map(*)) {
	let $xml := substring-after($model("fileLoc"), '/db')
	let $xsl := substring-after($model("xslt"), '/db')
	(: Model beinhaltet die vollständigen Pfade; 2017-05-22 DK :)
	return
	<div class="footer">
		<div class="footerEntry">XML: <a href="{wdb:getUrl($model("fileLoc"))}">{wdb:getUrl($model("fileLoc"))}</a></div>
		<div class="footerEntry">XSLT: <a href="{wdb:getUrl($model('xslt'))}">{wdb:getUrl($model('xslt'))}</a></div>
	</div>
};

declare function wdb:authors($node as node(), $model as map(*)) {
	let $max := count($model("authors"))
	for $auth at $i in $model("authors")
		let $t := if ($i > 1 and $i < max)
			then ", "
			else if ($i > 1) then " und " else ""
		return concat($t, $auth)
};

declare function wdb:getCSS($node as node(), $model as map(*)) {
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

declare function wdb:getEENr($node as node(), $model as map(*), $id as xs:string) as node() {
	let $ee := substring-before(substring-after($id, 'edoc_'), '_')
	return <meta name="edition" content="{$ee}" />
};

(: neu für das Laden projektspezifischer JS; 2016-11-02 DK :)
declare function wdb:getJS($node as node(), $model as map(*)) {
	let $path := concat($model("ed"), "/scripts/project.js")
	return <script src="{$path}" type="text/javascript" />
};

(: Anmeldeinformationen oder Login anzeigen; 2017-05-0 DK :)
declare function wdb:getAuth($node as node(), $model as map(*)) {
    let $current := xmldb:get-current-user()
    let $user := request:get-parameter('user', '')
    return
        if ($user != '') then
            <div>{$user}</div>
        else
        if ($current = 'guest') then
            <div>
                <form enctype="multipart/form-data" method="post" action="auth.xql">
    				<input type="text" name="user"/>
    				<input type="password" name="password" />
    				<input type="submit" value="login"/>
    				<input type="hidden" name="query" value="{request:get-parameter('query', '')}" />
    				<input type="hidden" name="edition" value="{request:get-parameter('edition', '')}" />
    			</form>
    			<p>{$current}</p>
            </div>
        else
            <div>
                User: <a>{$current}</a>
            </div>
};

(: Den Instanznamen ausgeben :)
declare function wdb:getInstanceName($node as node(), $model as map(*)) {
	<h1>{normalize-space(doc('../config.xml')/main:config/main:meta/main:name)}</h1>
};

(: Den Kurznamen ausgeben :)
declare function wdb:getInstanceShort($node as node(), $model as map(*)) {
	<span>{normalize-space(doc('../config.xml')/main:config/main:meta/main:short)}</span>
};

(: die vollständige URL zu einer Resource auslesen :)
declare function wdb:getUrl ( $path as xs:string ) as xs:string {
	$wdb:edocBaseURL || substring-after($path, $wdb:edocBaseDB)
};

(: die Rolle der Instanz auslesen :)
declare function wdb:getRole () as xs:string {
	normalize-space(doc('../config.xml')/main:config/main:role/main:type)
};

(: den Peer der Instanz auslesen :)
declare function wdb:getRolePeer () as xs:string {
	normalize-space(doc('../config.xml')/main:config/main:role/main:peer)
};

declare function wdb:getXslFromMets ($metsLoc, $id, $ed) {
	(: Das XSLT finden :)
	(: Die Ausgabe sollte hier in Dokumentreihenfolge erfolgen und innerhalb der sequence stabil sein;
	 : damit ist die »spezifischste« ID immer die letzte :)
	let $mets := doc($metsLoc)
	let $metsfile := $mets//mets:file[@ID=$id]
	let $structs := $mets//mets:div[mets:fptr[@FILEID=$id]]/ancestor-or-self::mets:div/@ID
	(: Die behavior stehen hier in einer nicht definierten Reihenfolge (idR Dokumentreihenfolge, aber nicht zwingend) :)
	let $be := for $s in $structs
		return $mets//mets:behavior[matches(@STRUCTID, concat('(^| )', $s, '( |$)'))]
	let $behavior := for $b in $be
		order by local:val($b, $structs, 'HTML')
		return $b
	let $trans := $behavior[position() = last()]/mets:mechanism/@xlink:href
	return concat($wdb:edocBaseDB, '/', $ed, '/', $trans)
};

declare function wdb:getXslFromWdbMeta($ed as xs:string, $id as xs:string, $target as xs:string) {
	let $metaFile := $wdb:edocBaseDB || '/' || $ed || '/wdbmeta.xml'
	let $fil := doc($metaFile)
	let $process := doc($metaFile)//meta:process[@target = $target]
	
	let $sel := for $c in $process/meta:command
		return if ($c/@refs)
			then
				let $map := tokenize($c/@refs, ' ')
				return if ($map = $id)
					then
						$c
					else ()
			else
				if ($c/@regex and matches($id, $c/@regex))
					then $c
					else if (not($c/@refs or $c/@regex))
						then $c
						else ()
	
	return $sel[1]
};

declare function wdb:getEd($path as xs:string) {
	let $pathToFile := wdb:getUrl($path)
	return substring-before(substring(substring-after($pathToFile, $wdb:edocBaseURL), 2), '/')
};