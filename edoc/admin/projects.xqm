xquery version "3.0";

module namespace wdbPL = "https://github.com/dariok/wdbplus/ProjectList";

import module namespace wdb		= "https://github.com/dariok/wdbplus/wdb"	at "../modules/app.xql";
import module namespace wdbs	= "https://github.com/dariok/wdbplus/stats"	at "../modules/stats.xqm";
import module namespace console	= "http://exist-db.org/xquery/console";
import module namespace xstring	= "https://github.com/dariok/XStringUtils"	at "../include/xstring/string-pack.xql";

declare namespace meta	= "https://github.com/dariok/wdbplus/wdbmeta";
declare namespace tei	= "http://www.tei-c.org/ns/1.0";

declare function wdbPL:body ( $node as node(), $model as map(*) ) {
	let $ed := request:get-parameter('ed', '')
	let $file := request:get-parameter('file', '')
	let $job := request:get-parameter('job', '')
	
	return
		if (xmldb:get-current-user() != 'admin')
			then <p>Diese Seite ist nur für Administratoren zugänglich!</p>
		else if ($job != '') then
			let $edition := wdb:getEdPath($file)
			let $metaFile := doc($wdb:edocBaseDB || '/' || $edition || '/wdbmeta.xml')
			let $relativePath := substring-after($file, $edition||'/')
			let $subColl := xstring:substring-before-last($file, '/')
			let $resource := xstring:substring-after-last($file, '/')
			let $fileEntry := $metaFile//meta:file[@path = $relativePath]
			let $xml := doc($file)
			
			return switch ($job)
				case 'add' return
					let $ins := <file xmlns="https://github.com/dariok/wdbplus/wdbmeta" path="{$relativePath}" uuid="{util:uuid($xml)}" 
						date="{xmldb:last-modified(xstring:substring-before-last($file, '/'), xstring:substring-after-last($file, '/'))}"
						xml:id="{$xml/tei:TEI/@xml:id}" />
					let $up1 := update insert $ins into $metaFile//meta:files
					return local:getFileStat($edition, $file)
				
				case 'uuid' return
					let $ins := <wdbmeta:file uuid="{util:uuid($xml)}"/>
					let $up1 := update insert $ins/@uuid into $fileEntry
					return local:getFileStat($edition, $file)
				
				case 'date' return
					let $ins := <wdbmeta:file date="{xmldb:last-modified($subColl, $resource)}" />
					let $up1 := update insert $ins/@date into $fileEntry
					return local:getFileStat($edition, $file)
				
				case 'id' return
					let $id := normalize-space($xml/tei:TEI/@xml:id)
					let $ins := <wdbmeta:file xml:id="{$id}" />
					let $upd1 := update insert $ins/@xml:id into $fileEntry
					return local:getFileStat($edition, $file)
				
				default return
					<div id="data"><div><h3>Strange Error</h3></div></div>
					
		else if ($ed = '' and $file = '') then
			<div id="content">
				<h3>Liste der Projekte</h3>
				{wdbs:projectList(true())}
			</div>
		else if ($ed != '' and $file = '') then
			local:getFiles($ed)
		else
			local:getFileStat($ed, $file)
};

declare function wdbPL:head ($node as node(), $model as map(*)) {
	let $ed := request:get-parameter('ed', '')
	return if ($ed = '')
		then <h1>Projekte</h1>
		else <h1>Projekt {$ed}</h1>
};

declare function local:getFiles($edoc as xs:string) {
	let $ed := collection($wdb:edocBaseDB || '/' || $edoc)//tei:teiHeader
	return 
		<div id="content">
			<h1>Insgesamt {count($ed)} EE</h1>
			{
				if (not(doc-available($wdb:edocBaseDB || '/' || $edoc || '/wdbmeta.xml')))
					then <p>keine <code>wdbmeta.xml</code> vorhanden!</p>
					else ()
			}
			<table class="noborder">
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
	let $subColl := xstring:substring-before-last($file, '/')
	let $resource := xstring:substring-after-last($file, '/')
	let $metaFile := doc($wdb:edocBaseDB || '/' || $ed || '/wdbmeta.xml')
	let $relativePath := substring-after($file, $ed||'/')
	let $entry := $metaFile//meta:file[@path = $relativePath]
	let $uuid := util:uuid($doc)
	let $date := xmldb:last-modified($subColl, $resource)
	let $id := normalize-space($doc/tei:TEI/@xml:id)
	
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
							<td>{$date}</td>
						</tr>
						<tr>
							<td>Eintrag in <i>wdbmeta.xml</i> vorhanden?</td>
							{if ($entry/@path != '')
								then <td>OK</td>
								else <td>fehlt <a href="javascript:job('add', '{$file}')">hinzufügen</a></td>
							}
						</tr>
						{if ($entry/@path != '')
							then (
								<tr>
									<td>UUID in wdbMeta</td>
									{if ($entry/@uuid = $uuid)
										then <td>OK: {$uuid}</td>
										else <td>{normalize-space($entry/@uuid)}<br/><a href="javascript:job('uuid', '{$file}')">UUID aktualisieren</a></td>
									}
								</tr>,
								<tr>
									<td>Timestamp in wdbMeta</td>
									{if ($entry/@date = $date)
										then <td>OK: {$date}</td>
										else <td>{normalize-space($entry/@date)}<br/><a href="javascript:job('date', '{$file}')">Timestamp aktualisieren</a></td>
									}
								</tr>,
								<tr>
									<td><code>@xml:id</code> in wdbMeta</td>
									{if ($entry/@xml:id = $id)
										then <td>OK: {$id}</td>
										else <td>{normalize-space($entry/@xml:id)}<br/><a href="javascript:job('id', '{$file}')">ID aktualisieren</a></td>
									}
								</tr>
							)
							else ()
						}
					</tbody>
				</table>
				{
					if ($wdb:role = 'workbench') then
						let $remoteMetaFile := try {
							 doc($wdb:peer || '/' || $ed || '/wdbmeta.xml')
						} catch * {
							console:log("Peer meta file not found: " || $wdb:peer || '/' || $ed || '/wdbmeta.xml --' ||
								'e: ' ||	$err:code || ': ' || $err:description || ' @ ' || $err:line-number ||':'||$err:column-number || '
								c: ' || $err:value || ' in ' || $err:module || '
								a: ' || $err:additional)
						}
						let $remoteEntry := $remoteMetaFile//meta:file[@path = $relativePath]
						
						return (
							<h3>Peer Info</h3>,
							<table style="width: 100%;">
								<tbody>
									<tr>
										<td>Peer Server</td>
										<td>{$wdb:peer}</td>
									</tr>
									<tr>
										<td>Eintrag in <i>wdbmeta.xml</i> vorhanden?</td>
										{if ($remoteEntry/@path != '')
											then <td>OK</td>
											else <td>fehlt</td>
										}
									</tr>
									{if ($remoteEntry/@path != '')
										then (
											<tr>
												<td>UUID in wdbMeta</td>
												{if ($remoteEntry/@uuid = $uuid)
													then <td>OK: {$uuid}</td>
													else <td>Diff: {normalize-space($remoteEntry/@uuid)}</td>
												}
											</tr>,
											<tr>
												<td>Timestamp in wdbMeta</td>
												{if ($remoteEntry/@date = $date)
													then <td>OK: {$date}</td>
													else <td>Diff: {normalize-space($remoteEntry/@date)}</td>
												}
											</tr>,
											<tr>
												<td><code>@xml:id</code> in wdbMeta</td>
												{if ($remoteEntry/@xml:id = $id)
													then <td>OK: {$id}</td>
													else <td>Diff: {normalize-space($remoteEntry/@xml:id)}</td>
												}
											</tr>
										)
										else ()
									}
								</tbody>
							</table>
						)
					else ()
				}
			</div>
		</div>
};