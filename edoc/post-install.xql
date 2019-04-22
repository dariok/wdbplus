xquery version "3.1";

let $cp := xmldb:copy('/db/apps/edoc/config/edoc', '/db/system/config/db/apps')

let $chmod := (sm:chmod(xs:anyURI('/db/apps/edoc/controller.xql'), 'r-xr-xr-x'),
    sm:chmod(xs:anyURI('/db/apps/edoc/modules/view.xql'), 'r-xr-xr-x'),
    sm:chmod(xs:anyURI('/db/apps/edoc/rest/rest-anno.xql'), 'r-xr-xr-x'),
    sm:chmod(xs:anyURI('/db/apps/edoc/rest/rest-coll.xql'), 'r-xr-xr-x'),
    sm:chmod(xs:anyURI('/db/apps/edoc/rest/rest-entity.xql'), 'r-xr-xr-x'),
    sm:chmod(xs:anyURI('/db/apps/edoc/rest/rest-files.xql'), 'r-xr-xr-x'),
    sm:chmod(xs:anyURI('/db/apps/edoc/rest/rest-search.xql'), 'r-xr-xr-x'),
    sm:chmod(xs:anyURI('/db/apps/edoc/rest/rest-test.xql'), 'r-xr-xr-x')
            )
let $reindex := (
  xmldb:reindex('/db/apps/edoc/data'),
  xmldb:reindex('/db/apps/edoc/rest'),
  xmldb:reindex('/db/apps/edoc/annotation')
)

return $chmod