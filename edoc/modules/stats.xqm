xquery version "3.0";

module namespace wdbs = "https://github.com/dariok/wdbplus/stats";

import module namespace templates	= "http://exist-db.org/xquery/templates";
import module namespace wdb				= "https://github.com/dariok/wdbplus/wdb";

declare namespace mets	= "http://www.loc.gov/METS/";
declare namespace mods	= "http://www.loc.gov/mods/v3";
declare namespace tei		= "http://www.tei-c.org/ns/1.0";

declare function wdbs:getEd($node as node(), $model as map(*)) {
	let $editions := collection('/db/edoc')//mets:mets
	return
		<table>
			<tr>
				<th>Edoc-Nr</th>
				<th>Titel</th>
				<th>METS</th>
				<th>WDB-Classic</th>
			</tr>
			
			{for $mets in $editions
				let $name := $mets/mets:dmdSec[1]/mets:mdWrap[1]/mets:xmlData[1]/mods:mods[1]/mods:titleInfo[1]/mods:title[1]/text()
				let $link := $mets/mets:dmdSec[1]/mets:mdWrap[1]/mets:xmlData[1]/mods:mods[1]/mods:identifier[1]/text()
				let $id := substring-after($mets/@OBJID, '/')
				let $metsFile := document-uri(root($mets))
				order by $id
				return
					<tr>
						<td style="padding-right: 5px;">{$id}</td>
						<td style="padding-right: 5px;"><a href="{concat($wdb:edocBase, '/', $id, '/start.html')}">{$name}</a></td>
						<td style="padding-right: 5px;"><a href="{concat($wdb:edocRestBase, $metsFile)}">{$metsFile}</a></td>
						<td style="padding-right: 5px;"><a href="{$link}">Link</a></td>
					</tr>
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