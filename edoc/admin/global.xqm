xquery version "3.0";

module namespace wdbGS = "https://github.com/dariok/wdbplus/GlobalSettings";

import module namespace wdb = "https://github.com/dariok/wdbplus/wdb" at "../modules/app.xql";

declare function wdbGS:body ( $node as node(), $model as map(*) ) {
	let $param := request:get-parameter('job', 'main')

	return switch ( $param )
		case 'main'
			return
				<div>
					<h1>Main config</h1>
				</div>
		default return <h1>Strange error</h1>
};