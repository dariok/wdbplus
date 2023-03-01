xquery version "3.1";

module namespace trigger="http://exist-db.org/xquery/trigger";

declare function trigger:after-update-document ( $uri as xs:anyURI ) as xs:string {
  if ( ends-with($uri, 'instance.xqm') or ends-with($uri, 'project.xqm') ) then
    let $projectPath := if ( ends-with($uri, 'instance.xqm') )
        then "/db/apps/edoc/data"
        else substring-before($uri, '/project.xqm')
      , $statFileName := if ( ends-with($uri, 'instance.xqm') )
        then 'instance-functions.xml'
        else 'project-functions.xml'
    
    return xmldb:store($projectPath, $statFileName, inspect:inspect-module($uri))
  else ""
};
