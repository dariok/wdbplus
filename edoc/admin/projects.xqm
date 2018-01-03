xquery version "3.0";

module namespace wdbPL = "https://github.com/dariok/wdbplus/ProjectList";

import module namespace wdb			= "https://github.com/dariok/wdbplus/wdb"		at "../modules/app.xql";
import module namespace wdbs		= "https://github.com/dariok/wdbplus/stats"	at "../modules/stats.xqm";
import module namespace console	= "http://exist-db.org/xquery/console";

declare namespace config = "https://github.com/dariok/wdbplus";

declare function wdbPL:body ( $node as node(), $model as map(*) ) {
	let $ed := request:get-parameter('ed', '') 
	return if ($ed = '') then
			<div id="content">
				<h3>Liste der Projekte</h3>
				{wdbs:projectList(true())}
			</div>
		else
			local:getEE($ed)
};

declare function local:getEE($edoc as xs:string) {
	let $ed := collection($wdb:edocBaseDB || '/' || $edoc)//tei:TEI/tei:teiHeader
	return
		<div>
			<h1>Insgesamt {count($ed)} EE</h1>
			<table>
				<tbody>
					<tr>
						<th>Nr.</th>
						<th>Pfad</th>
						<th>Titel</th>
						<th>UUID v3</th>
						<th>Status</th>
					</tr>
					{
						for $doc in $ed
							return
								<tr>
									<td>{$doc/tei:TEI/@n}</td>
									<td>{base-uri($doc)}</td>
									<td>{normalize-space($doc//tei:title[1])}</td>
									<td>{util:uuid($doc)}</td>
									<td></td>
								</tr>
					}
				</tbody>
			</table>
		</div>
};
