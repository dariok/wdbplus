xquery version "3.0";

import module namespace validate = "http://exist-db.org/xquery/validation";

let $file := xs:anyURI("/db/edoc/ed000216/texte/001/001_introduction.xml")

(:return validate:jaxp-report($file, false()):)
(:return validate:show-grammar-cache():)
return validate:clear-grammar-cache()
