xquery version "3.0";
(:  neu 2016-07-18 Dario Kampkaspar (DK) – kampkaspar@hab.de  :)

import module namespace habm = "https://github.com/dariok/wdbplus/mets" at "mets.xqm";

let $id := map { "id" := request:get-parameter('id', '') }
let $bogus := <void></void>

return
	habm:getLeft($bogus, $id)