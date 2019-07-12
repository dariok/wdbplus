xquery version "3.1";

let $targetCollection := '/db/apps/edoc'

let $cp := xmldb:copy($targetCollection || '/config/edoc', '/db/system/config/db/apps')

let $collsr := (
  "/modules", "/templates", "/resources/css", "/resources/scripts", "/resources/scripts/jquery-ui", "/resources/scripts/jquery-ui/images", "/resources/xsl"
)

let $chmod := (
  for $coll in $collsr
    let $resources := xmldb:get-child-resources($targetCollection || $coll)
    return for $resource in $resources
      let $res := $targetCollection || $coll || '/' || $resource
      return $res || ' (r--r--r--): ' || sm:chmod(xs:anyURI($res), 'r--r--r--'),
  for $html in xmldb:get-child-resources($targetCollection)[ends-with(., '.html')]
    return sm:chmod(xs:anyURI($targetCollection || '/' || $html), 'r--r--r--'),
  for $xql in xmldb:get-child-resources($targetCollection || '/rest')[ends-with(., '.xql')]
    return sm:chmod(xs:anyURI($targetCollection || '/rest/' || $xql), 'r-xr-xr-x'),
  for $xql in xmldb:get-child-resources($targetCollection || '/modules')[ends-with(., '.xql')]
    return sm:chmod(xs:anyURI($targetCollection || '/modules/' || $xql), 'r-xr-xr-x'),
  sm:chmod(xs:anyURI($targetCollection || '/config.xml'), 'rw-rw-r--'),
  sm:chmod(xs:anyURI($targetCollection || '/controller.xql'), 'r-xr-xr-x'),
  sm:chmod(xs:anyURI($targetCollection || '/data/wdbmeta.xml'), 'rw-rw-r--'),
  sm:chmod(xs:anyURI($targetCollection || '/data/project.xqm'), 'rw-rw-r--'),
  sm:chmod(xs:anyURI($targetCollection || '/include/xstring/string-pack.xql'), 'r-xr-xr-x'),
  sm:chown(xs:anyURI($targetCollection || '/annotations'), 'wdb'),
  sm:chgrp(xs:anyURI($targetCollection || '/annotations'), 'wdbusers'),
  xmldb:reindex($targetCollection || '/data')
)

let $reindex := (
  xmldb:reindex($targetCollection || '/data'),
  xmldb:reindex($targetCollection || '/rest'),
  xmldb:reindex($targetCollection || '/annotation')
)

return ($reindex, $chmod)