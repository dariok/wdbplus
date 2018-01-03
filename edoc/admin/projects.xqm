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
			wdbs:getEE($ed)
};