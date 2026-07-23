xquery version "3.1";

let $targetCollection := '/db/apps/edoc'
  , $collsr := ("/modules", "/templates", "/resources/css", "/resources/js", "/resources/xsl")

return (
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
  for $global in xmldb:get-child-resources($targetCollection || '/logs')
    return sm:chmod(xs:anyURI($targetCollection || '/logs/' || $global), 'rw-rw-rw-'),
  sm:chmod(xs:anyURI($targetCollection || '/config.xml'), 'rw-rw-r--'),
  sm:chmod(xs:anyURI($targetCollection || '/controller.xql'), 'r-xr-xr-x'),
  sm:chmod(xs:anyURI($targetCollection || '/data/wdbmeta.xml'), 'rw-rw-r--'),
  sm:chmod(xs:anyURI($targetCollection || '/data/instance.xqm'), 'rw-rw-r--'),
  for $s in xmldb:get-child-collections($targetCollection)
    return sm:chmod(xs:anyURI($targetCollection || '/' || $s), "r-xr-xr-x"),
  sm:chown(xs:anyURI($targetCollection || '/annotations'), 'wdb:wdbusers'),
  sm:chown(xs:anyURI($targetCollection || '/data'), 'wdb:wdbusers'),
)
