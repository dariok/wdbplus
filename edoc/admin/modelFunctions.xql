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
  else if ( ends-with($uri, 'wdbmeta.xml') ) then
    let $meta := doc($uri)
      , $projectId := $meta/meta:projectMD/@xml:id
      , $files := $meta//meta:file
      , $projectIndex := doc("/db/apps/edoc/index/project-index.xml")
      , $fileIndex := doc("/db/apps/edoc/index/file-index.xml")
      , $projectEntry := <project xmlns="https://github.com/dariok/wdbplus/index"
          xml:id="{ $projectId }"
          path="{ substring-before($uri, '/wdbmeta.xml') }"
        />
      
    (: enter or update project :)
    let $insertProject := if ( exists($projectIndex/id($projectId)) )
      then update replace $projectIndex/id($projectId) with $projectEntry
      else update insert $projectEntry into $projectIndex/index:index
    
    (: enter or update files entries :)
    let $entries := for $file in $files
      let $id := $file/@xml:id
        , $entry := <file xmlns="https://github.com/dariok/wdbplus/index"
            xml:id="{ $id }"
            project="{ $meta => base-uri() }"
          />
      
      return if ( exists($fileIndex/id($id)) )
          then update replace $fileIndex/id($id) with $entry
          else update insert $entry into $fileIndex/index:index
    
    (: enter or update subcorpora :)
    let $subcorpora := for $subcorpus in $meta//meta:struct[@xml:id]
      let $id := $subcorpus/@xml:id
        , $entry := <file xmlns="https://github.com/dariok/wdbplus/index"
            xml:id="{ $id }"
            project="{ $meta => base-uri() }"
          />
      
      return if ( exists($fileIndex/id($id)) )
          then update replace $fileIndex/id($id) with $entry
          else update insert $entry into $fileIndex/index:index
    
    return $uri
  (: else if ( ends-with($uri, '.xml') ) then
    let $id := doc($uri)/*/@xml:id
      , $present := doc("/db/apps/edoc/index/file-index.xml")/id($id)
      , $entry := <file xmlns="https://github.com/dariok/wdbplus/index"
          xml:id="{ $id }"
          project="{ collection('/db/apps/edoc/data')/id($id)[self::meta:file] => base-uri() }"
        />
      , $insert := if ( $present )
          then update replace $present with $entry
          else update insert $entry into doc("/db/apps/edoc/index/file-index.xml")/*
    return $uri :)
  else ""
};
