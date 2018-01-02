xquery version "3.0";

module namespace wdbGS = "https://github.com/dariok/wdbplus/GlobalSettings";

import module namespace wdb = "https://github.com/dariok/wdbplus/wdb" at "../modules/app.xql";
import module namespace console 	= "http://exist-db.org/xquery/console";

declare namespace config = "https://github.com/dariok/wdbplus";

declare function wdbGS:body ( $node as node(), $model as map(*) ) {
	let $param := request:get-parameter('job', 'main')

	return switch ( $param )
		case 'main' return
			<div>
				<h3>Optionen</h3>
				<ul>
					<li><a href="global.html?job=title">Titeldaten verändern</a></li>
				</ul>
			</div>
			
		case 'title' return
			let $metaFile := doc('../config.xml')
			return local:titleForm($metaFile)
				
		case 'chgTitle' return
			let $metaFile := doc('../config.xml')
			let $t1 := console:log(request:get-parameter('longTitle', ''))
			let $t2 := console:log(request:get-parameter('shortTitle', ''))
			let $u1 := update replace $metaFile/config:config/config:meta/config:name
					with <config:name>{request:get-parameter('longTitle', '')}</config:name>
			let $u1 := update replace $metaFile/config:config/config:meta/config:short
					with <config:short>{request:get-parameter('shortTitle', '')}</config:short>
			return local:titleForm($metaFile)
		default return
			<div>
				<h1>666</h1>
				<p>A strange error has occurred...</p>
			</div>
};

declare function local:titleForm($metaFile) {
	<div>
		<h3>Titeldaten verändern</h3>
		<form action="global.html">
			<input type="hidden" name="job" value="chgTitle" />
			<input style="width: 100%;" type="text" name="longTitle" value="{$metaFile/config:config/config:meta/config:name}" /><br />
			<input style="width: 100%;" type="text" name="shortTitle" value="{$metaFile/config:config/config:meta/config:short}" /><br />
			<input type="submit" />
		</form>
	</div>
};