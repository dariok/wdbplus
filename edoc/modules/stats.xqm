xquery version "3.0";

module namespace wdbs = "https://github.com/dariok/wdbplus/stats";

import module namespace templates	= "http://exist-db.org/xquery/templates";
import module namespace wdb				= "https://github.com/dariok/wdbplus/wdb"	at "app.xql";

declare namespace mets		= "http://www.loc.gov/METS/";
declare namespace mods		= "http://www.loc.gov/mods/v3";
declare namespace tei			= "http://www.tei-c.org/ns/1.0";
declare namespace wdbmeta	= "https://github.com/dariok/wdbplus/wdbmeta";

declare function wdbs:getEd($node as node(), $model as map(*)) {
	let $editionsM := collection($wdb:edocBaseDB)//mets:mets
	let $editionsW := collection($wdb:edocBaseDB)//wdbmeta:projectMD
	return
		<table>
			<tr>
				<th>Eintrag</th>
				<th>Titel</th>
				<th>METS</th>
			</tr>
			
			{(for $mets in $editionsM
				let $name := $mets/mets:dmdSec[1]/mets:mdWrap[1]/mets:xmlData[1]/mods:mods[1]/mods:titleInfo[1]/mods:title[1]
				let $id := substring-after($mets/@OBJID, '/')
				let $metsFile := document-uri(root($mets))
				order by $id
				return
					<tr>
						<td style="padding-right: 5px;">{$id}</td>
						<td style="padding-right: 5px;"><a href="{concat($id, '/start.html')}">{normalize-space($name)}</a></td>
						<td style="padding-right: 5px;"><a href="{concat($wdb:edocBaseDB, $metsFile)}">{$metsFile}</a></td>
					</tr>,
				for $w in $editionsW
					let $name := $w/wdbmeta:titleData/wdbmeta:title[1]
					let $metaFile := document-uri($w)
					return
						<tr>
							<td style="padding-right: 5px;"></td>
							<td style="padding-right: 5px;">{normalize-space($name)}</td>
							<td style="padding-right: 5px;">{xs:string($metaFile)}</td>
						</tr>
				)
			}
			</table>
};

declare function wdbs:getEE($node as node(), $model as map(*), $edoc as xs:string) {
	let $ed := collection('/db/edoc/' | $edoc)//tei:TEI/tei:teiHeader
	return
		<div>
			<h1>Insgesamt {count($wdb)} EE</h1>
			
			{for $fi in $ed
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
			}
		</div>
};