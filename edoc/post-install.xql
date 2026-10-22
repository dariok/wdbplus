xquery version "3.1";

(: Note: default values set automatically during installation
   - default user and group:  wdbadmin:wdbadmins – set in repo.xml
   - default mode:            r--r--r--          – set in repo.xml
   - execute flag for XQuery: r-xr-xr-x          – set automatically https://exist-db.org/exist/apps/doc/repo.xml#sect-repoxml
 :)

let $targetCollection := '/db/apps/edoc'

(: All core elements are read-only, set in repo.xml
   We make those writable to the wdbadmin user and wdbadmins group that must be writable
 :)
return (
  (: create wdb and wdbusers :)
  sm:create-group("wdbusers", "wdbadmin", "general user group"),
  sm:create-account("wdb", "wdb", "wdbusers"),

  (: /data/ must be writable for admins so that projects can be created :)
  sm:chmod(xs:anyURI($targetCollection || '/data'), 'rwxrwxr-x'),
  sm:chmod(xs:anyURI($targetCollection || '/data/resources'), 'rwxrwxr-x'),
  for $global in xmldb:get-child-collections($targetCollection || '/data/resources')
    return sm:chmod(xs:anyURI($targetCollection || '/data/resources/'||$global), 'rwxrwxr-x'),
  for $r in xmldb:get-child-resources($targetCollection || '/data/resources/xsl')
    return sm:chmod(xs:anyURI($targetCollection || '/data/resources/xsl/'||$r), 'rw-rw-r--'),
  for $r in xmldb:get-child-resources($targetCollection || '/data/resources/css')
    return sm:chmod(xs:anyURI($targetCollection || '/data/resources/css/'||$r), 'rw-rw-r--'),
  sm:chmod(xs:anyURI($targetCollection || '/data/instance.xqm'), 'rw-rw-r--'),
  sm:chmod(xs:anyURI($targetCollection || '/data/wdbmeta.xml'), 'rw-rw-r--'),

  (: /addins/ must be writable for admins so that addins can be installed or created :)
  sm:chmod(xs:anyURI($targetCollection || '/addins'), 'rwxrwxr-x'),

  (: /index/ must be writable for admins so that the ID index files can be updated for projects and resources :)
  sm:chmod(xs:anyURI($targetCollection || '/index'), 'rwxrwxr-x'),
  sm:chmod(xs:anyURI($targetCollection || '/index/file-index.xml'), 'rw-rw-r--'),
  sm:chmod(xs:anyURI($targetCollection || '/index/project-index.xml'), 'rw-rw-r--'),
  sm:chmod(xs:anyURI($targetCollection || '/index/index-projects.xq'), 'r-xr-x---')
)
