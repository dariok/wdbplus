xquery version "3.1";

module namespace r2d = "https://github.com/dariok/wdbplus/rest2/dts";

import module namespace r2 = "https://github.com/dariok/wdbplus/rest2/common" at "rest-common.xqm";

declare function r2d:entryPoint ( $request as map(*) ) as map(*) {
  r2:response(
    200,
    'application/ld+json',
    parse-json('{
        "@context": "https://dtsapi.org/context/v1.0.json",
        "dtsVersion": "1.0",
        "@id": "/api/v2/dts/",
        "@type": "EntryPoint",
        "collection":  "/api/v2/dts/collection/{?id,page,nav}",
        "navigation" : "/api/v2/dts/navigation/{?resource,ref,start,end,down,tree,page}",
        "document":    "/api/v2/dts/document/{?resource,ref,start,end,tree,mediaType}"
      }'),
    $r2:allOrigins
  )
};