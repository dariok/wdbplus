xquery version "3.1";

declare namespace anno = "annotate";
import module namespace json = "http://www.json.org";

let $file := request:get-parameter('file', '')
let $anno := <anno>{doc('/db/apps/edoc/anno.xml')//anno:file[. = $file]/parent::anno:entry}</anno>

return json:contents-to-json($anno)