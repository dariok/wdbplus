xquery version "3.0";
(:  neu 2016-07-18 Dario Kampkaspar (DK) – kampkaspar@hab.de  :)

import module namespace habm = "http://diglib.hab.de/ns/mets" at "/db/edoc/modules/mets.xqm";

let $id := map { "id" := request:get-parameter('id', '') }
let $bogus := <void></void>

return
	habm:getLeft($bogus, $id)