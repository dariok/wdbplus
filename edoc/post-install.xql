xquery version "3.1";

let $chmod := (sm:chmod(xs:anyURI('/db/apps/edoc/controller.xql'), 'r-xr-xr-x'), sm:chmod(xs:anyURI('/db/apps/edoc/insert.xql'), 'r-xr-xr-x'),
            sm:chmod(xs:anyURI('/db/apps/edoc/return.xql'), 'r-xr-xr-x'), sm:chmod(xs:anyURI('/db/apps/edoc/modules/app.xql'), 'r-xr-xr-x'),
            sm:chmod(xs:anyURI('/db/apps/edoc/modules/nav.xql'), 'r-xr-xr-x'), sm:chmod(xs:anyURI('/db/apps/edoc/modules/start.xql'), 'r-xr-xr-x'),
            sm:chmod(xs:anyURI('/db/apps/edoc/modules/view.xql'), 'r-xr-xr-x'))
let $reindex := xmldb:reindex('/db/apps/edoc/data')

return $chmod