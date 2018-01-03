xquery version "3.0";

module namespace wdbPL = "https://github.com/dariok/wdbplus/ProjectList";

import module namespace wdb			= "https://github.com/dariok/wdbplus/wdb"		at "../modules/app.xql";
import module namespace wdbs		= "https://github.com/dariok/wdbplus/stats"	at "../modules/stats.xqm";
import module namespace console	= "http://exist-db.org/xquery/console";

declare namespace config = "https://github.com/dariok/wdbplus";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

declare function wdbPL:body ( $node as node(), $model as map(*) ) {
	let $ed := request:get-parameter('ed', '')
	let $file := request:get-parameter('file', '')
	return if ($ed = '' and $file = '') then
			<div id="content">
				<h3>Liste der Projekte</h3>
				{wdbs:projectList(true())}
			</div>
		else if ($ed != '' and $file = '') then
			local:getFiles($ed)
		else
			local:getFileStat($ed, $file)
};

declare function local:getFiles($edoc as xs:string) {
	let $ed := collection($wdb:edocBaseDB || '/' || $edoc)//tei:TEI/tei:teiHeader
	return
		<div id="content">
			<h1>Insgesamt {count($ed)} EE</h1>
			<table>
				<tbody>
					<tr>
						<th>Nr.</th>
						<th>Pfad</th>
						<th>Titel</th>
						<th>Status</th>
					</tr>
					{
						for $doc in $ed
							let $docUri := base-uri($doc)
							return
								<tr>
									<td>{$doc/tei:TEI/@n}</td>
									<td>{$docUri}</td>
									<td>{normalize-space($doc//tei:title[1])}</td>
									<td><a href="javascript:show('{$edoc}', '{$docUri}')">anzeigen</a></td>
								</tr>
					}
				</tbody>
			</table>
		</div>
};

declare function local:getFileStat($ed, $file) {
	let $doc := doc($file)
	let $subColl := local:substring-before-last($file, '/')
	let $resource := local:substring-after-last($file, '/')
	let $metaFile := doc($ed || '/wdbmeta.xml')
	let $relativePath := substring-after($file, $ed||'/')
	let $entry := $metaFile/config:config/config:files//config:file[@path = $relativePath]
	let $uuid := util:uuid($doc)
	
	return
		<div id="data">
			<div style="width: 100%;">
				<h3>{$file}</h3>
				<hr />
				<table style="width: 100%;">
					<tbody>
						{
							for $title in $doc//tei:teiHeader/tei:title
								return <tr><td>Titel</td><td>{$title}</td></tr>
						}
						<tr>
							<td>UUID v3</td>
							<td>{$uuid}</td>
						</tr>
						<tr>
							<td>Timestamp</td>
							<td>{xmldb:last-modified($subColl, $resource)}</td>
						</tr>
						<tr>
							<td>Eintrag in <i>wdbmeta.xml</i> vorhanden?</td>
							{
								if ($entry/@path != '')
									then if ($entry/@uuid = $uuid)
										then <td>OK</td>
										else <td>OK, <a href="projects.html?uuid">UUID aktualisieren</a></td>
									else
										<td>fehlt <a href="projects.html?add">hinzufügen</a></td>
							}
						</tr>
					</tbody>
				</table>
			</div>
		</div>
};

declare function local:substring-before-last($s, $c) {
	string-join(tokenize(normalize-space($s), $c)[not(position() = last())], $c)
};

declare function local:substring-after-last($s, $c) {
	tokenize(normalize-space($s), $c)[last()]
};