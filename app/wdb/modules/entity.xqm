xquery version "3.0";
(: erstellt 2016-07-26 Bearbeiter:DK Dario Kampkaspar – kampkaspar@hab.de :)

module namespace habe = "http://diglib.hab.de/ns/entity";

import module namespace config	= "http://diglib.hab.de/ns/config" at "config.xqm";
import module namespace hab		= "http://diglib.hab.de/ns/hab" at "app.xql";

declare namespace tei	= "http://www.tei-c.org/ns/1.0";

(: 	$id		ID-String der Entität (z.B. URI der GND)
		$ed		edoc-Nummer der Edition (dient ggfs. der Wiedergabe nur editionsspezifischer Informationen
		$reg	Register-Datei, falls editionsspezifische Datei vorhanden ist :)
declare function habe:getEntity($node as node(), $model as map(*), $id as xs:string, $ed as xs:string?) as map(*) {
	(: für die Recherche nur nötig ID und ggfs. Nr. der Edition; 2016-08-17 DK :)
	(: TODO falls XML und XSLT übergeben werden, diese verwenden :)
	
	(: da die ID innerhalb der Edition einzigartig sein muß, reicht eine Abfrage innerhalb der Edition :)
	let $entryEd := collection(concat('/db/', $ed))/id($id)
	(: TODO: wenn hier nicht gefunden, im zentralen Register suchen :)
	
	return map { "entry" := $entryEd, "id" := $id, "ed" := $ed }
};

(: generiert die Überschrift für die Ausgabe; 2016-08-17 DK :)
declare function habe:getEntityName($node as node(), $model as map(*)) {
	let $entryEd := $model("entry")
	return <h1>{
	typeswitch ($entryEd)
		case element(tei:person)
			return if ($entryEd/tei:persName[@type='index'])
				then habe:passthrough($entryEd/tei:persName[@type='index'], $model)
				else habe:shortName($entryEd/tei:persName[1])
		case element(tei:bibl)
			return habe:shortTitle($entryEd, $model)
		case element(tei:place)
			return habe:shortPlace($entryEd)
		default
			return name($entryEd[1])
	}</h1>
};

declare function habe:getEntityBody($node as node(), $model as map(*)) {
	let $ent := $model("entry")
	
	return habe:transform($ent, $model)
};

declare function habe:transform($node, $model as map(*)) as item()* {
	typeswitch ($node)
		case text() return $node
		case element(tei:person) return <table class="noborder">{habe:passthrough($node, $model)}</table>
		case element(tei:persName) return habe:persName($node, $model)
		case element(tei:birth) return habe:bd($node, $model)
		case element(tei:death) return habe:bd($node, $model)
		case element(tei:floruit) return habe:bd($node, $model)
		case element(tei:listBibl) return habe:listBibl($node, $model)
		case element(tei:note) return habe:note($node, $model)
		case element(tei:bibl) return 
			if ($node/ancestor::tei:person or count($node/ancestor::tei:place)>0) (: Literatur zu anderen Entitäten: Kurzausgabe :)
				then habe:listBiblBibl($node, $model)
				else habe:bibl($node)
		case element(tei:name) return
			if ($node/parent::tei:abbr)
				then <span class="nameSC">{$node}</span>
				else habe:passthrough($node, $model)
		case element(tei:title) return
			if ($node/parent::tei:abbr)
				then <i>{string($node)}</i>
				else habe:passthrough($node, $model)
		case element(tei:placeName) return
			if ($node/ancestor::tei:person)
				then habe:shortPlace($node)
				else habe:placeName($node)
		case element(tei:place) return <table class="noborder">{habe:passthrough($node, $model)}</table>
		case element(tei:idno) return habe:idno($node)
		
(:		default return habe:passthrough($node):)
		(:default return concat("def: ", name($node)):)
		default return $node
};

declare function habe:passthrough($nodes as node()*, $model) as item()* {
	if (count($nodes) > 1 or $nodes instance of text())
	then for $node in $nodes return habe:transform($node, $model)
	else for $node in $nodes/node() return habe:transform($node, $model)
};

(: die folgenden neu 2016-08-16 DK :)
declare function habe:persName($node, $model) {
	for $name in $node/* return habe:names($name)
};

declare function habe:names($node) {
	<tr>
		<td>{
			typeswitch($node)
				case element(tei:forename) return "Vorname"
				case element(tei:surname) return "Nachname"
				case element(tei:nameLink) return "Prädikat"
				case element(tei:roleName) return "Amt/Titel"
				case element(tei:genName) return ""
				case element(tei:addName) return habe:addName($node)
				default return local-name($node)
		}</td>
		<td>{$node/text()}</td>
	</tr>
};

declare function habe:addName($node) as xs:string {
let $resp :=
	if ($node/@type = "toponymic") then 'toponymischer Beiname'
	else if ($node/@type = 'cognomen') then 'Cognomen'
	else "Beiname"
	
	return $resp
};

declare function habe:bd($node, $model) {
	<tr>
		<td>{
			typeswitch($node)
				case element(tei:birth) return "geb."
				case element(tei:death) return "gest."
				default return "lebte"
		}</td>
		<td>{habe:passthrough($node, $model)}</td>
	</tr>
};

declare function habe:listBibl($node, $model) {
	<tr>
		<td>Literatur</td>
		<td><ul>{
				for $bibs in $node return habe:passthrough($bibs, $model)
			}</ul></td>
	</tr>
};

(: Kurztitelausgaben in einer listBibl; 2016-08-17 DK :)
declare function habe:listBiblBibl($node, $model) {
	if ($node/@ref) then
		let $id := substring-after($node/@ref, '#')
		let $entry := collection(concat('/db/', $model('ed')))/id($id)
		let $ln := concat($hab:edocBase, '/entity.html?id=', $id)
		return <li><a href="{$ln}">{habe:passthrough($entry/tei:abbr, $model)}</a>{string($node)}</li>
	else
		let $link := $node/tei:ref/@target
		let $text := $node/tei:ref/text()
		return <li><a href="{$link}">{$text}</a></li>
};

(: Ausgabe einer bibliographischen Langangabe; 2016-08-17 DK :)
declare function habe:bibl($node) {
	(: TODO erweitern für strukturierte Angaben! :)
	<p>{$node/node()[not(self::tei:abbr)]}</p>
};

(: zur Ausgabe von Kurztiteln eines Buches; 2016-08-17 DK :)
(:	$node		ein Element tei:bibl
		Ausgabe	formatierter Kurztitel :)
declare function habe:shortTitle($node, $model) {
	(: Kurztitel: Verarbeitung von tei:abbr. Evtl. enthaltenes tei:name in Kapitälchen, tei:title kursiv :)
	if ($node/tei:abbr) then habe:passthrough($node/tei:abbr, $model)
	else substring($node, 1, 50)
};

declare function habe:shortName($node) {
	<span>{
		if ($node/tei:name) then $node/tei:name
		else 
			let $tr := string-join(($node/tei:surname, $node/tei:forename), ", ")
			let $add := if ($node/tei:addName) then concat(' (', $node/tei:addName, ')') else ""
			return concat($tr, ' ', $node/tei:nameLink, $add)
	}</span>
};

declare function habe:note($node, $model) {
	<tr><td>Anmerkung</td><td>{habe:passthrough($node, $model)}</td></tr>
};

declare function habe:shortPlace($node) {
	(: TODO tei:head oder tei:label als Standardwert nutzen, falls vorhanden :)
	(: TODO ggfs. sind hier andere Arten zu berücksichtigen (tei:geogName) :)
	<span>{string($node/tei:placeName[1]/tei:settlement)}</span>
};

declare function habe:placeName($node) {
	(: TODO anpassen an ausführlichere Angaben :)(
		<tr><td>Name</td><td>{string($node/tei:settlement)}</td></tr>,
		<tr><td>Land</td><td>{string($node/tei:country)}</td></tr>
	)
};

(: neu 2017-05-22 DK :)
declare function habe:idno($node) {
	<tr><td>Normdaten-ID</td><td><a href="{$node}">{$node}</a></td></tr>
};