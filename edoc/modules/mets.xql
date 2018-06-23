xquery version "3.0";
(:  neu 2016-07-18 Dario Kampkaspar (DK) :)

import module namespace wdbm	= "https://github.com/dariok/wdbplus/mets" at "mets.xqm";
import module namespace wdb		= "https://github.com/dariok/wdbplus/wdb" at "app.xql";

let $model := wdb:populateModel(request:get-parameter('id', ''))
let $bogus := <void></void>

return
	wdbm:getLeft($bogus, $model)