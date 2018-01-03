xquery version "3.0";

module namespace wdbs = "https://github.com/dariok/wdbplus/stats";

import module namespace templates	= "http://exist-db.org/xquery/templates";
import module namespace wdb				= "https://github.com/dariok/wdbplus/wdb"	at "app.xql";

declare namespace mets		= "http://www.loc.gov/METS/";
declare namespace mods		= "http://www.loc.gov/mods/v3";
declare namespace tei			= "http://www.tei-c.org/ns/1.0";
declare namespace wdbmeta	= "https://github.com/dariok/wdbplus/wdbmeta";

declare function wdbs:getEd($node as node(), $model as map(*)) {
	wdbs:projectList(false())
};

declare function wdbs:projectList($admin as xs:boolean) {
	let $editionsM := collection($wdb:edocBaseDB)//mets:mets
	let $editionsW := collection($wdb:edocBaseDB)//wdbmeta:projectMD
	return
		<table>
			<tr>
				<th>Eintrag</th>
				<th>Titel</th>
				{if ($admin = true()) then
					(
						<th>Metadaten-Datei</th>,
						<th>verwalten</th>
					)
					else ()
				}
			</tr>
			
			{(for $mets in $editionsM
				let $name := $mets/mets:dmdSec[1]/mets:mdWrap[1]/mets:xmlData[1]/mods:mods[1]/mods:titleInfo[1]/mods:title[1]
				let $id := substring-after($mets/@OBJID, '/')
				let $metsFile := document-uri(root($mets))
				order by $id
				return
					<tr>
						<td>{$id}</td>
						<td><a href="{concat($id, '/start.html')}">{normalize-space($name)}</a></td>
						{if ($admin = true()) then
							(	
								<td style="padding-right: 5px;"><a href="{concat($wdb:edocBaseDB, $metsFile)}">{$metsFile}</a></td>,
								<td><a href="project.html?ed={$id}">verwalten</a></td>
							)
							else ()
						}
					</tr>,
				for $w in $editionsW
					let $name := $w/wdbmeta:titleData/wdbmeta:title[1]
					let $metaFile := document-uri(root($w))
					return
						<tr>
							<td>{wdb:getEd($metaFile)}</td>
							<td>{normalize-space($name)}</td>
							{if ($admin = true()) then
								(
									<td><a href="{wdb:getUrl($metaFile)}">{xs:string($metaFile)}</a></td>,
									<td><a href="projects.html?ed={wdb:getEd($metaFile)}">verwalten</a></td>
								)
								else ()
							}
						</tr>
				)
			}
		</table>
};

declare function wdbs:chronologicalOrder($ed) {
	for $fi in $ed
				let $dates := $fi//tei:date/@when
				
				for $date in $dates
					let $parsed := if (matches($date, '^\d{4}-\d{2}-\d{2}'))
						then datetime:parse-date($date, 'yyyy-MM-dd')
						else (if (matches($date, '^\d{4}-\d{2}'))
							then datetime:parse-date($date, 'yyyy-MM')
							else (if (matches($date, '^\d{4}'))
								then datetime:parse-date($date, 'yyyy')
								else ()))
					let $cast :=  if ($date castable as xs:date)
						then $date cast as xs:date
						else '?'
					where $parsed lt datetime:parse-date('1900-01-01', 'yyyy-MM-dd')
					return
						<dl>
							<dd>{base-uri($fi)}</dd>
							<dt>{$date}{$parsed}</dt>
							<dt>{$cast}</dt>
						</dl>
};