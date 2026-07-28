xquery version "3.1";

(: path to the directory containing the unpacked .xar package :)
declare variable $dir external;

let $configCollection := '/db/system/config/db/apps'

return (
  xmldb:create-collection($configCollection, "edoc"),
  xmldb:create-collection($configCollection || "/edoc", "addins"),
  xmldb:create-collection($configCollection || "/edoc", "annotations"),
  xmldb:create-collection($configCollection || "/edoc", "data"),
  xmldb:create-collection($configCollection || "/edoc", "rest"),
  xmldb:create-collection($configCollection || "/edoc/data", "documentation"),
  
  xmldb:store-files-from-pattern($configCollection || "/edoc/", $dir||"/config/edoc", "**/collection.xconf", "application/xml", true()),
  
  sm:create-group("wdbadmin", "admin", "Administrators for this installation"),
  sm:create-account("wdbadmin", "wdbadmin", ("wdbuser", "wdbadmin"))
)
