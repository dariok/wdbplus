xquery version "3.1";

declare namespace anno = "annotate";

import module namespace wdb = "https://github.com/dariok/wdbplus/wdb" at "modules/app.xql";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:method "json";
declare option output:media-type "application/json";

let $file := request:get-parameter('file', '')
let $anno :=
	<anno:anno>
		<anno:entry><anno:range from="" to=""/></anno:entry>
		{doc($wdb:edocBaseDB || '/anno.xml')//anno:file[. = $file]/parent::anno:entry}
	</anno:anno>

return $anno