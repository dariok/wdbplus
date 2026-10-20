xquery version "3.1";

(: Note: default values set automatically during installation
   - default user and group:   wdb:wdbusers  – set in repo.xml
   - default mode:             rw-rw-r--     – set in repo.xml
   - execute flag:             rwxrwxr-x     – set automatically https://exist-db.org/exist/apps/doc/repo.xml#sect-repoxml
 :)

let $targetCollection := '/db/apps/edoc'
  , $collsr := ("/modules", "/templates", "/resources/css", "/resources/js", "/resources/xsl")

(: Make global resources and collections read-only
   This is to remind admins that these are not to be edited but the cascading logic (i.e., files in data/resources) must
   be used instead.
 :)
return (
  for $coll in $collsr
    let $resources := xmldb:get-child-resources($targetCollection || $coll)
    return for $resource in $resources
      let $res := $targetCollection || $coll || '/' || $resource
      return sm:chmod(xs:anyURI($res), 'r--r--r--'),
  
  for $html in xmldb:get-child-resources($targetCollection)[ends-with(., '.html')]
    return sm:chmod(xs:anyURI($targetCollection || '/' || $html), 'r--r--r--'),
  
  for $s in xmldb:get-child-collections($targetCollection)
    return sm:chmod(xs:anyURI($targetCollection || '/' || $s), "r-xr-xr-x"),
  
  (: /data/ must be writable for admins so that projects can be created :)
  sm:chmod(xs:anyURI($targetCollection || '/data'), 'rwxrwxr-x'),

  (: /addins/ must be writable for admins so that addins can be installed or created :)
  sm:chmod(xs:anyURI($targetCollection || '/addins'), 'rwxrwxr-x')
)
