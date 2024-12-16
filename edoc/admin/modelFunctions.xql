xquery version "3.1";

module namespace trigger="http://exist-db.org/xquery/trigger";

declare namespace meta  = "https://github.com/dariok/wdbplus/wdbmeta";
declare namespace index = "https://github.com/dariok/wdbplus/index";

declare function trigger:after-update-document ( $uri as xs:anyURI ) as xs:string {
  if ( ends-with($uri, 'instance.xqm') or ends-with($uri, 'project.xqm') ) then
    let $projectPath := if ( ends-with($uri, 'instance.xqm') )
        then "/db/apps/edoc/data"
        else substring-before($uri, '/project.xqm')
      , $statFileName := if ( ends-with($uri, 'instance.xqm') )
        then 'instance-functions.xml'
        else 'project-functions.xml'
    
    return xmldb:store($projectPath, $statFileName, inspect:inspect-module($uri))
  else if ( ends-with($uri, '.xml') and not(ends-with($uri, 'wdbmeta.xml')) ) then
    let $id := doc($uri)/*/@xml:id
      , $present := doc("/db/apps/edoc/index/file-index.xml")/id($id)
      , $entry := <file xmlns="https://github.com/dariok/wdbplus/index"
          xml:id="{ $id }"
          project="{ collection('/db/apps/edoc/data')/id($id)[self::meta:file] => base-uri() }"
        />
      , $insert := if ( $present )
          then update replace $present with $entry
          else update insert $entry into doc("/db/apps/edoc/index/file-index.xml")/*
    return $uri
  else ""
};
