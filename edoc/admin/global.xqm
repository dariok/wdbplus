xquery version "3.0";

module namespace wdbGS = "https://github.com/dariok/wdbplus/GlobalSettings";

import module namespace wdb = "https://github.com/dariok/wdbplus/wdb" at "../modules/app.xql";
import module namespace console 	= "http://exist-db.org/xquery/console";

declare namespace config = "https://github.com/dariok/wdbplus";

declare function wdbGS:body ( $node as node(), $model as map(*) ) {
	let $param := request:get-parameter('job', 'main')
	let $metaFile := doc('../config.xml')

	return switch ( $param )
		case 'main' return
			<div>
				<h3>Optionen</h3>
				<ul>
					<li><a href="global.html?job=title">Titeldaten verändern</a></li>
					<li><a href="global.html?job=role">Rolle verändern</a></li>
				</ul>
			</div>
			
		case 'title' return
			local:titleForm($metaFile)
				
		case 'chgTitle' return
			let $u1 := update replace $metaFile/config:config/config:meta/config:name
					with <name xmlns="https://github.com/dariok/wdbplus">{request:get-parameter('longTitle', '')}</name>
			let $u1 := update replace $metaFile/config:config/config:meta/config:short
					with <short xmlns="https://github.com/dariok/wdbplus">{request:get-parameter('shortTitle', '')}</short>
			return local:titleForm($metaFile)
		
		case 'role' return
			local:roleForm($metaFile)
		
		case 'chgRole' return
			let $u1 := update replace $metaFile/config:config/config:role/config:type
					with <type xmlns="https://github.com/dariok/wdbplus">{request:get-parameter('role', '')}</type>
			let $u1 := update replace $metaFile/config:config/config:role/config:other
					with <other xmlns="https://github.com/dariok/wdbplus">{request:get-parameter('other', '')}</other>
			return local:roleForm($metaFile)
		
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
			<label style="width: 100%">Titel: <input type="text" name="longTitle"
				value="{$metaFile/config:config/config:meta/config:name}" /></label><br />
			<label style="width: 100%">Kurztitel: <input type="text" name="shortTitle"
				value="{$metaFile/config:config/config:meta/config:short}" /></label><br />
			<input type="submit" />
		</form>
	</div>
};

declare function local:roleForm($metaFile) {
	let $role := $metaFile/config:config/config:role/config:type
	let $other := $metaFile/config:config/config:role/config:other
	
	return
	<div>
		<h3>Rolle</h3>
		<form action="global.html">
			<input type="hidden" name="job" value="chgRole" />
			<label>Rolle: 
				<select name="role">
					<option value="standalone">{if ($role = 'standalone') then attribute selected {'selected'} else () }Standalone</option>
					<option value="workbench">{if ($role = 'workbench') then attribute selected {'selected'} else () }Workbench</option>
					<option value="publisher">{if ($role = 'publisher') then attribute selected {'selected'} else ()}Publikationsumgebung</option>
				</select>
			</label><br />
			<label>zugehörige Instanz: <input type="text" name="other" value="{$other}" /></label><br />
			<input type="submit" />
		</form>
	</div>
};