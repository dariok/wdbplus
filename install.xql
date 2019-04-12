xquery version "3.1";

import module namespace exgit="http://exist-db.org/xquery/exgit" at "java:org.exist.xquery.modules.exgit.Exgit";

let $cl := exgit:clone("https://github.com/dariok/wdbplus", "{$whereToClone}")
let $ie := exgit:import("{$whereToClone}/wdbplus/edoc", "/db/apps/edoc")
let $ic := exgit:import("{$whereToClone}/wdbplus/config", "/db/system/config/db/apps")

let $chmod := (sm:chmod(xs:anyURI('/db/apps/edoc/controller.xql'), 'r-xr-xr-x'),
    sm:chmod(xs:anyURI('/db/apps/edoc/modules/view.xql'), 'r-xr-xr-x'),
    sm:chmod(xs:anyURI('/db/apps/edoc/rest/rest-anno.xql'), 'r-xr-xr-x'),
    sm:chmod(xs:anyURI('/db/apps/edoc/rest/rest-coll.xql'), 'r-xr-xr-x'),
    sm:chmod(xs:anyURI('/db/apps/edoc/rest/rest-entity.xql'), 'r-xr-xr-x'),
    sm:chmod(xs:anyURI('/db/apps/edoc/rest/rest-files.xql'), 'r-xr-xr-x'),
    sm:chmod(xs:anyURI('/db/apps/edoc/rest/rest-search.xql'), 'r-xr-xr-x'),
    sm:chmod(xs:anyURI('/db/apps/edoc/rest/rest-test.xql'), 'r-xr-xr-x')
)
let $chown := sm:chown(xs:anyURI('/db/apps/edoc/annotations'), 'wdb')
let $chgrp := sm:chgrp(xs:anyURI('/db/apps/edoc/annotations'), 'wdbusers')
let $reindex := xmldb:reindex('/db/apps/edoc/data')

return ($cl, $ie, $ic, $chmod, $chown, $chgrp, $reindex)