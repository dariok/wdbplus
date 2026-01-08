xquery version "3.1";

module namespace r2 = "https://github.com/dariok/wdbplus/rest2/common";

import module namespace router = "http://e-editiones.org/roaster/router";

declare namespace sm = "http://exist-db.org/xquery/securitymanager";

declare variable $r2:acceptable := ("application/json", "application/xml", "text/html");

(:~
 : Base URL for the REST API
 :)
declare variable $r2:base := doc('../config.xml')//*:rest[@version = "2"];

(:~
 : list of allowed origins
 :)
declare variable $r2:origins := doc('../config.xml')//*:origins/*;

declare variable $r2:allOrigins := if ( request:get-header('origin') != '' )
  then map { 
    "Access-Control-Allow-Origin"      : request:get-header('origin'),
    "Access-Control-Allow-Credentials" : "true"
  }
  else map {
    "Access-Control-Allow-Origin" : "*"
  };
(: ,
  "Access-Control-Allow-Methods" : "GET, POST, PUT, DELETE, OPTIONS",
  "Access-Control-Allow-Headers" : "Content-Type, Authorization",
  "Access-Control-Max-Age"       : "86400" :)

declare variable $r2:mediaTypes := map {
  "Access-Control-Allow-Origin": "*",
  "AllowPost": string-join($r2:acceptable, ' ')
};

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

declare function r2:response ( $status as xs:integer, $mediaType as xs:string, $body as item(), $headers as map(*) ) as item() {
  router:response($status, $mediaType, $body, $headers)
};

declare function r2:parseBody ( $request as map(*) ) as item() {
  let $mediaType := $request?media-type
    , $t1 := util:log("info", $request?body)
    (: , $checkMediaType := $mediaType = $r2:acceptable :)
    (: , $t0 := util:log("info", $mediaType || ': ' || $checkMediaType) :)

  return
    (: Roaster should handle unsupported media types and return 415 :)
    (: if ( not($checkMediaType) ) then
      ( util:log("error", "unsupported: " || $mediaType),
      r2:response(415, 'text/plain', 'Unsupported Media Type', $r2:mediaTypes)
      )
    else :)
     if ( $mediaType = "application/json" and $request?body instance of map(*) ) then
      $request?body?title
    else if ( $mediaType = "application/xml" ) then
      $request?body
    else
      "I don’t know what to do…!"
};

declare function r2:writeAllowed ( $user as map(*) ) as xs:boolean {
  $user?groups = ('dba', 'wdbadmin')
};

declare function r2:mapKeysAllowed(
  $m as map(*) ,
  $required as xs:string*,
  $optional as xs:string*
) as xs:boolean {
  let $keys := map:keys($m)
  let $allowed := ($required, $optional)
  return
    (every $r in $required  satisfies $r = $keys)
    and
    (every $k in $keys      satisfies $k = $allowed)
};

declare function r2:logMap ( $request as map(*) ) {
  for $key in map:keys($request) return if ( $key = ('spec', 'config', 'schema') ) then () else ( util:log("info", $key || ':') , util:log("info", $request($key)))
};