xquery version "3.0";
(: erstellt 2016-07-26 Bearbeiter:DK Dario Kampkaspar :)

module namespace wdbe = "https://github.com/dariok/wdbplus/entity";

import module namespace wdb		= "https://github.com/dariok/wdbplus/wdb"		at "app.xql";
import module namespace console	= "http://exist-db.org/xquery/console";

declare namespace tei	= "http://www.tei-c.org/ns/1.0";

(: 	$id		ID-String der Entität (z.B. URI der GND)
	$ed		edoc-Nummer der Edition (dient ggfs. der Wiedergabe nur editionsspezifischer Informationen
	$reg	Register-Datei, falls editionsspezifische Datei vorhanden ist :)
declare function wdbe:getEntity($node as node(), $model as map(*), $id as xs:string, $ed as xs:string?, $reg as xs:string?, $xsl as xs:string?) as map(*) {
	(: für die Recherche nur nötig ID und ggfs. Nr. der Edition; 2016-08-17 DK :)
	(: TODO falls XML und XSLT übergeben werden, diese verwenden :)
	
	(: da die ID innerhalb der Edition einzigartig sein muß, reicht eine Abfrage innerhalb der Edition :)
	let $entryEd := doc($reg)/id($id)
	(: TODO: wenn hier nicht gefunden, im zentralen Register suchen :)
	
	return map { "entry" := $entryEd, "id" := $id, "ed" := $ed }
};

(: generiert die Überschrift für die Ausgabe; 2016-08-17 DK :)
declare function wdbe:getEntityName($node as node(), $model as map(*)) {
	let $entryEd := $model("entry")
	return <h1>{
	typeswitch ($entryEd)
		case element(tei:person)
			return if ($entryEd/tei:persName[@type='index'])
				then wdbe:passthrough($entryEd/tei:persName[@type='index'], $model)
				else wdbe:shortName($entryEd/tei:persName[1])
		case element(tei:bibl)
			return wdbe:shortTitle($entryEd, $model)
		case element(tei:place)
			return wdbe:shortPlace($entryEd)
		default
			return name($entryEd[1])
	}</h1>
};

declare function wdbe:getEntityBody($node as node(), $model as map(*)) {
	let $ent := $model("entry")
	
	return wdbe:transform($ent, $model)
};

declare function wdbe:transform($node, $model as map(*)) as item()* {
	typeswitch ($node)
		case text() return $node
		case element(tei:person) return <table class="noborder">{wdbe:passthrough($node, $model)}</table>
		case element(tei:persName) return wdbe:persName($node, $model)
		case element(tei:birth) return wdbe:bd($node, $model)
		case element(tei:death) return wdbe:bd($node, $model)
		case element(tei:floruit) return wdbe:bd($node, $model)
		case element(tei:listBibl) return wdbe:listBibl($node, $model)
		case element(tei:note) return wdbe:note($node, $model)
		case element(tei:bibl) return 
			if ($node/ancestor::tei:person or count($node/ancestor::tei:place)>0) (: Literatur zu anderen Entitäten: Kurzausgabe :)
				then wdbe:listBiblBibl($node, $model)
				else wdbe:bibl($node)
		case element(tei:name) return
			if ($node/parent::tei:abbr)
				then <span class="nameSC">{$node}</span>
				else wdbe:passthrough($node, $model)
		case element(tei:title) return
			if ($node/parent::tei:abbr)
				then <i>{string($node)}</i>
				else wdbe:passthrough($node, $model)
		case element(tei:placeName) return
			if ($node/ancestor::tei:person)
				then wdbe:shortPlace($node)
				else wdbe:placeName($node)
		case element(tei:place) return <table class="noborder">{wdbe:passthrough($node, $model)}</table>
		case element(tei:idno) return wdbe:idno($node)
		
(:		default return wdbe:passthrough($node):)
		(:default return concat("def: ", name($node)):)
		default return $node
};

declare function wdbe:passthrough($nodes as node()*, $model) as item()* {
	if (count($nodes) > 1 or $nodes instance of text())
	then for $node in $nodes return wdbe:transform($node, $model)
	else for $node in $nodes/node() return wdbe:transform($node, $model)
};

(: die folgenden neu 2016-08-16 DK :)
declare function wdbe:persName($node, $model) {
	for $name in $node/* return wdbe:names($name)
};

declare function wdbe:names($node) {
	<tr>
		<td>{
			typeswitch($node)
				case element(tei:forename) return "Vorname"
				case element(tei:surname) return "Nachname"
				case element(tei:nameLink) return "Prädikat"
				case element(tei:roleName) return "Amt/Titel"
				case element(tei:genName) return ""
				case element(tei:addName) return wdbe:addName($node)
				default return local-name($node)
		}</td>
		<td>{$node/text()}</td>
	</tr>
};

declare function wdbe:addName($node) as xs:string {
let $resp :=
	if ($node/@type = "toponymic") then 'toponymischer Beiname'
	else if ($node/@type = 'cognomen') then 'Cognomen'
	else "Beiname"
	
	return $resp
};

declare function wdbe:bd($node, $model) {
	<tr>
		<td>{
			typeswitch($node)
				case element(tei:birth) return "geb."
				case element(tei:death) return "gest."
				default return "lebte"
		}</td>
		<td>{wdbe:passthrough($node, $model)}</td>
	</tr>
};

declare function wdbe:listBibl($node, $model) {
	<tr>
		<td>Literatur</td>
		<td><ul>{
				for $bibs in $node return wdbe:passthrough($bibs, $model)
			}</ul></td>
	</tr>
};

(: Kurztitelausgaben in einer listBibl; 2016-08-17 DK :)
declare function wdbe:listBiblBibl($node, $model) {
	if ($node/@ref) then
		let $id := substring-after($node/@ref, '#')
		let $entry := collection(concat('/db/', $model('ed')))/id($id)
(:		let $ln := $wdb:edocBaseURL || '/entity.html?id=' || $id || '&amp;ed=' || $model('ed'):)
    let $ln := "javascript:show_annotation('" || $model('ed') || "', '/db/" || $model('ed') || "/register/bibliography.xml', '"
      || $wdb:edocBaseDB || "/resource/bibl.xsl', '" || $id || "', 0, 0);"
		return <li><a href="{$ln}">{wdbe:passthrough($entry/tei:abbr, $model)}</a>{string($node)}</li>
	else
		let $link := $node/tei:ref/@target
		let $text := $node/tei:ref/text()
		return <li><a href="{$link}">{$text}</a></li>
};

(: Ausgabe einer bibliographischen Langangabe; 2016-08-17 DK :)
declare function wdbe:bibl($node) {
	(: TODO erweitern für strukturierte Angaben! :)
	<p>{$node/node()[not(self::tei:abbr)]}</p>
};

(: zur Ausgabe von Kurztiteln eines Buches; 2016-08-17 DK :)
(:	$node		ein Element tei:bibl
		Ausgabe	formatierter Kurztitel :)
declare function wdbe:shortTitle($node, $model) {
	(: Kurztitel: Verarbeitung von tei:abbr. Evtl. enthaltenes tei:name in Kapitälchen, tei:title kursiv :)
	if ($node/tei:abbr) then wdbe:passthrough($node/tei:abbr, $model)
	else substring($node, 1, 50)
};

declare function wdbe:shortName($node) {
	<span>{
		if ($node/tei:name) then $node/tei:name
		else 
			let $tr := string-join(($node/tei:surname, $node/tei:forename), ", ")
			let $add := if ($node/tei:addName) then concat(' (', $node/tei:addName, ')') else ""
			return concat($tr, ' ', $node/tei:nameLink, $add)
	}</span>
};

declare function wdbe:note($node, $model) {
	<tr><td>Anmerkung</td><td>{wdbe:passthrough($node, $model)}</td></tr>
};

declare function wdbe:shortPlace($node) {
	(: TODO tei:head oder tei:label als Standardwert nutzen, falls vorhanden :)
	(: TODO ggfs. sind hier andere Arten zu berücksichtigen (tei:geogName) :)
	<span>{replace($node/tei:placeName[1]/tei:settlement, '!', ', ')}</span>
};

declare function wdbe:placeName($node) {
	(: TODO anpassen an ausführlichere Angaben :)
	if ($node/tei:country)
		then (<tr><td>Name</td><td>{replace($node/tei:settlement, '!', ', ')}</td></tr>,
			<tr><td>Land</td><td>{string($node/tei:country)}</td></tr>)
		else <tr><td>Name</td><td>{replace($node/tei:settlement, '!', ', ')}</td></tr>
};

(: neu 2017-05-22 DK :)
declare function wdbe:idno($node) {
	<tr><td>Normdaten-ID</td><td><a href="{$node}">{$node}</a></td></tr>
};