xquery version "3.1";

module namespace r2 = "https://github.com/dariok/wdbplus/rest2/common";

import module namespace router = "http://e-editiones.org/roaster/router";

declare variable $r2:acceptable := ("application/json", "application/xml");

declare variable $r2:allOrigins := map {
  "Access-Control-Allow-Origin"  : "*"
};
(: ,
  "Access-Control-Allow-Methods" : "GET, POST, PUT, DELETE, OPTIONS",
  "Access-Control-Allow-Headers" : "Content-Type, Authorization",
  "Access-Control-Max-Age"       : "86400" :)

declare function r2:returnXmlOrJson ( $data as item() ) as item() {
  let $mediaType := request:get-header("Accept")
  return
    if ( $mediaType = "application/json" ) then
      router:response(200, "application/json", parse-json(xml-to-json(transform:transform($data, doc('api.xsl'), ()))), $r2:allOrigins)
    else if ( $mediaType = $r2:acceptable ) then (
      router:response(200, $mediaType, $data, $r2:allOrigins)
    )
    else
      router:response(406, "text/plain", "Not acceptable", $r2:allOrigins)
};
