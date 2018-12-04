xquery version "3.0";

module namespace wdbs = "https://github.com/dariok/wdbplus/stats";

import module namespace templates	= "http://exist-db.org/xquery/templates";
import module namespace wdb				= "https://github.com/dariok/wdbplus/wdb"	at "app.xql";
import module namespace console 	= "http://exist-db.org/xquery/console";

declare namespace mets		= "http://www.loc.gov/METS/";
declare namespace mods		= "http://www.loc.gov/mods/v3";
declare namespace tei			= "http://www.tei-c.org/ns/1.0";
declare namespace wdbmeta	= "https://github.com/dariok/wdbplus/wdbmeta";

declare
%templates:default('ed', '')
function wdbs:getEd($node as node(), $model as map(*), $ed as xs:string) {
	wdbs:projectList(xmldb:is-admin-user(xmldb:get-current-user()), $ed)
};

declare function wdbs:projectList($admin as xs:boolean, $ed) {
	let $project := if ($ed = '')
		then $wdb:edocBaseDB
		else $wdb:data || '/' || $ed
	let $editionsM := collection($project)//mets:mets
	let $editionsW := collection($project)//wdbmeta:projectMD
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
				let $metsFile := document-uri(root($mets))
				let $id := wdb:getEdPath($metsFile)
				order by $id
				return
					<tr>
						<td>{$id}</td>
						<td><a href="{$wdb:edocBaseURL || $id || '/start.html'}">{normalize-space($name)}</a></td>
						{if ($admin = true()) then
							(	
								<td style="padding-right: 5px;"><a href="{wdb:getUrl($metsFile)}">{$metsFile}</a></td>,
								<td><a href="{$wdb:edocBaseURL}/admin/projects.html?ed={$id}">verwalten</a></td>
							)
							else ()
						}
					</tr>,
				for $w in $editionsW
					let $name := $w/wdbmeta:titleData/wdbmeta:title[1]
					let $metaFile := document-uri(root($w))
					let $id := substring-before(substring-after($metaFile, $wdb:edocBaseDB), 'wdbmeta')
					let $padding := count(tokenize($id, '/')) + 0.2
					order by $id
					return if ($w//wdbmeta:view[not(@private) or @private='false']
						or $w//wdbmeta:struct[@file]) then
						<tr>
							<td>{$id}</td>
							<td style="padding-left: {$padding}em;">
								<a href="{$wdb:edocBaseURL || $id || 'start.html'}">{normalize-space($name)}</a>
							</td>
							{if ($admin = true()) then
								(
									<td><a href="{wdb:getUrl($metaFile)}">{xs:string($metaFile)}</a></td>,
									<td><a href="{$wdb:edocBaseURL}/admin/projects.html?ed={substring-after($id, '/')}">verwalten</a></td>
								)
								else ()
							}
						</tr>
						else ()
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