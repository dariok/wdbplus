xquery version "3.0";
(:  neu 2016-07-18 Dario Kampkaspar (DK) :)

import module namespace wdbm	= "https://github.com/dariok/wdbplus/nav" at "nav.xqm";

let $model := map {"id": request:get-parameter('id', '')}

return
	wdbm:getLeft(<void />, $model)