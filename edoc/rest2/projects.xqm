xquery version "3.1";

module namespace r2p = "https://github.com/dariok/wdbplus/rest2/projects";

import module namespace r2 = "https://github.com/dariok/wdbplus/rest2/common" at "rest-common.xqm";

declare namespace index = "https://github.com/dariok/wdbplus/index";
declare namespace meta  = "https://github.com/dariok/wdbplus/wdbmeta";

(:~
 : List all projects
 : GET {base}/projects
 :)
declare function r2p:listProjects ( $request as map(*) ) as map(*) {
  let $projects := doc("/db/apps/edoc/index/project-index.xml")//index:project

  let $result :=
    <list xmlns="https://github.com/dariok/wdbplus/api/schema/v1"
        start="1"
        total="{count($projects)}"
        id="{ $r2:base }{ $request?path }"
      >
      {
        for $project in $projects return
          <project
              id="{ $r2:base }{ $request?path }/{ $project/@xml:id }"
              label="{ $project/@title }"
          />
      }
    </list>
  
  return r2:returnXmlOrJson($result)
};

(:~
 : List all subprojects of a project
 : GET /projects/{$parent}/subprojects
 :)
declare function r2p:listSubprojects ( $request as map(*) ) as map(*) {
  let $project := doc("/db/apps/edoc/index/project-index.xml")/id($request?parameters?parent)
  return if ( not(exists($project)) ) then
    r2:response(404, 'text/plain', 'Project ' || $request?parameters?parent || ' not found', $r2:allOrigins)
  else
    let $meta := doc($project/@path || "/wdbmeta.xml")
      , $subprojects := $meta//meta:ptr
      , $labels := map:merge(
          for $struct in $meta//meta:struct
          let $file := string($struct/@file)
          return map:entry($file, string($struct/@label))
        )
      , $result :=
        <list xmlns="https://github.com/dariok/wdbplus/api/schema/v1"
            start="1"
            total="{ count($subprojects) }"
            id="{ $r2:base }{ $request?path }">
          {
            for $entry in $subprojects
            let $ed := string($entry/@xml:id)
            return
              <project
                  id="{ $r2:base }/projects/{ $ed }"
                  label="{ map:get($labels, $ed) }"
              />
          }
        </list>

    return r2:returnXmlOrJson($result)
};

(:~
 : Create a subproject, generating an ID
 : POST /projects/{$parent}/subprojects
 :)
declare function r2p:createProjectWithoutId ( $request as map(*) ) as map(*) {
  if ( not(r2:mapKeysAllowed($request?body, ('title', 'collection'), ('short'))) ) then
    r2:response(422, 'text/plain', 'Wrong content of project information found. Expected `title` and `collection` (mandatory), or `short`.', $r2:allOrigins)
  else
    r2p:createProjectWithId(
      map{
        "parameters": map{
          "parent": $request?parameters?parent,
          "ed": '_' || util:uuid()
        },
        "body": $request?body,
        "user": $request?user
      }
    )
};

(:~
 : create a new project with the metadata given in the request
 : PUT /projects/{$parent}/subprojects/{$ed}
 : also called by r2p:createProjectWithoutId
 :)
declare function r2p:createProjectWithId ( $request as map(*) ) as map(*) {
  r2:logMap($request),
  if ( not(exists($request?parameters?parent)) or not(exists($request?parameters?ed)) ) then
    r2:response(400, 'text/plain', 'Bad Request\n parameter `parent` or `ed` missing', $r2:allOrigins)
  else if ( not(exists($request?user)) or $request?user?fullName = 'guest' ) then
    r2:response(401, 'text/plain', 'Unauthorized', $r2:allOrigins)
  else if ( not(r2:writeAllowed($request?user)) ) then
    r2:response(403, 'text/plain', 'Forbidden', $r2:allOrigins)
  else if ( not(doc("/db/apps/edoc/index/project-index.xml")/id($request?parameters?parent)) ) then
    r2:response(404, 'text/plain', 'Project ' || $request?parameters?parent || ' not found', $r2:allOrigins)
  else if ( not(sm:has-access(doc("/db/apps/edoc/index/project-index.xml")/id($request?parameters?parent)/@path, "w")) ) then
    r2:response(403, 'text/plain', 'Forbidden', $r2:allOrigins)
  else if ( doc("/db/apps/edoc/index/project-index.xml")/id($request?parameters?ed) ) then
    r2:response(409, 'text/plain', 'A project with ID ' || $request?parameters?ed || ' already exists', $r2:allOrigins)
  else if ( xmldb:collection-available(doc("/db/apps/edoc/index/project-index.xml")/id($request?parameters?parent)/@path || $request?body?collection) ) then
    r2:response(409, 'text/plain', 'A collection with name ' || $request?body?collection || ' already exists in project ' || $request?parameters?parent, $r2:allOrigins)
  else if ( not(r2:mapKeysAllowed($request?body, ('title', 'collection'), ('short'))) ) then
    r2:response(422, 'text/plain', 'Wrong content of project information found. Expected `title` and `collection`(mandatory), `short`.', $r2:allOrigins)
  else
  
  let $parentCollection := doc("/db/apps/edoc/index/project-index.xml")/id($request?parameters?parent)/@path
    , $parentMeta := doc( $parentCollection || "/wdbmeta.xml" )
    , $subCollection := xmldb:create-collection($parentCollection, $request?body?collection)
    , $newMetaPath := xmldb:copy-resource("/db/apps/edoc/admin/project-template", "wdbmeta.xml", $subCollection, "wdbmeta.xml")
    , $collectionPermissions := sm:get-permissions(xs:anyURI($parentCollection))
    , $metaPermissions := sm:get-permissions(xs:anyURI($parentCollection || "/wdbmeta.xml"))
    , $meta := doc($newMetaPath)
  
  return r2:response(
    201,
    'text/plain',
    (
      sm:chown(xs:anyURI($subCollection), $collectionPermissions//@owner || ":" || $collectionPermissions//@group),
      sm:chmod(xs:anyURI($subCollection), $collectionPermissions//@mode),
      sm:chown(xs:anyURI($newMetaPath), $metaPermissions//@owner || ":" || $metaPermissions//@group),
      sm:chmod(xs:anyURI($newMetaPath), $metaPermissions//@mode),

      xmldb:create-collection($subCollection, "texts"),
      sm:chown(xs:anyURI($subCollection || '/texts'), $collectionPermissions//@owner || ":" || $collectionPermissions//@group),
      sm:chmod(xs:anyURI($subCollection || '/texts'), $collectionPermissions//@mode),

      update insert attribute xml:id { $request?parameters?ed } into $meta/meta:projectMD,
      update replace $meta//meta:projectID[1]
          with <projectID xmlns="https://github.com/dariok/wdbplus/wdbmeta">{ $request?parameters?ed }</projectID>,
      update replace $meta//meta:title[1]
          with <title xmlns="https://github.com/dariok/wdbplus/wdbmeta" type="main">{ $request?body?title }</title>,
      update insert attribute label { $request?body?title } into $meta//meta:struct[1],
      if ( exists($request?body?short) ) then
          update insert
              <title type="sub" xmlns="https://github.com/dariok/wdbplus/wdbmeta">{ $request?body?short }</title>
              following $meta//meta:title[@type = 'main'][1]
        else (),
      
      update insert
          <ptr xmlns="https://github.com/dariok/wdbplus/wdbmeta"
            path="{ $request?body?collection }/wdbmeta.xml" xml:id="{ $request?parameters?ed }"
          /> into $parentMeta//meta:files,
      update insert
          <struct xmlns="https://github.com/dariok/wdbplus/wdbmeta"
            file="{ $request?parameters?ed }" label="{ $request?body?title }"
          /> into $parentMeta/meta:projectMD/meta:struct,
      
      (: copy the full project structure for main projects (i.e., $parent = 'data') only :)
      if ( $request?parameters?parent = 'data' ) then
          (
            xmldb:create-collection($subCollection, "resources"),
            xmldb:create-collection($subCollection || "/resources", "blobs"),
            xmldb:create-collection($subCollection || "/resources", "css"),
            xmldb:create-collection($subCollection || "/resources", "html"),
            xmldb:create-collection($subCollection || "/resources", "images"),
            xmldb:create-collection($subCollection || "/resources", "js"),
            xmldb:create-collection($subCollection || "/resources", "xq"),

            xmldb:copy-collection("/db/apps/edoc/admin/project-template/resources/xsl", $subCollection || "/resources"),

            sm:chmod(xs:anyURI($subCollection || "/resources"), 'rwxrwxr-x'),
            sm:chown(xs:anyURI($subCollection || "/resources"), "wdb:wdbusers"),
            for $c in xmldb:get-child-collections($subCollection || "/resources")
              return (
                  sm:chmod(xs:anyURI($subCollection || "/resources/" || $c), 'rwxrwxr-x'),
                  sm:chown(xs:anyURI($subCollection || "/resources/" || $c), "wdb:wdbusers")
                ),
            for $f in xmldb:get-child-resources($subCollection || "/resources/xsl")
              return (
                sm:chmod(xs:anyURI($subCollection || "/resources/xsl/" || $f), "rwxrwxr-x"),
                sm:chown(xs:anyURI($subCollection || "/resources/xsl/" || $f), "wdb:wdbusers")
              ),
            
            xmldb:copy-resource("/db/apps/edoc/admin/project-template", "project.xqm", $subCollection, "project.xqm"),
            sm:chown(xs:anyURI($subCollection || "/project.xqm"), "wdb:wdbusers"),
            sm:chmod(xs:anyURI($subCollection || "/project.xqm"), "rwxrwxr-x")
          )
        else (),

      $subCollection
    )[last()], (: create-collection() returns a string; we only want the path to the project collection :)
    $r2:allOrigins
  )
};

(:~
 : List all views for a project
 : GET /projects/{$ed}/views
 :)
declare function r2p:listProjectViews ( $request as map(*) ) as map(*) {
  let $project := doc("/db/apps/edoc/index/project-index.xml")/id($request?parameters?ed)
  
  return if ( not(exists($project)) ) then
    r2:response(404, 'text/plain', 'Project ' || $request?parameters?ed || ' not found', $r2:allOrigins)
  else
    r2:returnXmlOrJson(<list xmlns="https://github.com/dariok/wdbplus/api/schema/v1"
        level="project"
        for="{ $r2:base }/projects/{$request?parameters?ed}"
        type="views"
        start="1"
        length="3"
        max="3 ">
        <view name="default" label="returns an XML representation of the project"/>
        <view name="nav" label="returns a navigation structure for the project"/>
        <view name="start" label="returns a start page for the project"/>
      </list>)
};

(:~
 : Get basic information about a project
 : GET /projects/{$ed}
 :)
declare function r2p:getProject ( $request as map(*) ) as map(*) {
  let $project := doc("/db/apps/edoc/index/project-index.xml")/id($request?parameters?ed)
  
  return if ( not(exists($project)) ) then
    r2:response(404, 'text/plain', 'Project ' || $request?parameters?ed || ' not found', $r2:allOrigins)
  else
    let $meta := doc( $project/@path || "/wdbmeta.xml" )
    return r2:returnXmlOrJson(
      <contents xmlns="https://github.com/dariok/wdbplus/api/schema/v1"
        for="{ $r2:base }{ $request?path }"
        start="1"
        total="{ count($meta//meta:file) + count($meta//meta:ptr) }">
        {
          for $entry in $meta//meta:ptr return
            <project xmlns="https://github.com/dariok/wdbplus/api/schema/v1"
                id="{ $r2:base }/projects/{ $entry/@xml:id }"
                label="{ $meta//meta:struct[@file = $entry/@xml:id]/@label }" />
        }
        {
          for $entry in $meta//meta:file return
            <file xmlns="https://github.com/dariok/wdbplus/api/schema/v1"
                id="{ $r2:base }/resource/{ $entry/@xml:id }"
                label="{ $meta//meta:view[@file = $entry/@xml:id]/@label }" />
        }
      </contents>
    )
};

(:~
 : Delete a project
 : DELETE /projects/{$ed}
 :)
declare function r2p:deleteProject ( $request as map(*) ) as map(*) {
  if ( not(exists($request?parameters?ed)) ) then
    r2:response(400, 'text/plain', 'Bad Request\n parameter `ed` missing', $r2:allOrigins)
  else if ( not(exists($request?user)) or $request?user?fullName = 'guest' ) then
    r2:response(401, 'text/plain', 'Unauthorized', $r2:allOrigins)
  else if ( not(r2:writeAllowed($request?user)) ) then
    r2:response(403, 'text/plain', 'Forbidden', $r2:allOrigins)
  else
    let $project := doc("/db/apps/edoc/index/project-index.xml")/id($request?parameters?ed)
    return if ( not(exists($project)) ) then
      r2:response(404, 'text/plain', 'Project ' || $request?parameters?ed || ' not found', $r2:allOrigins)
    else if ( not(sm:has-access($project/@path, "w")) ) then
      r2:response(403, 'text/plain', 'Forbidden', $r2:allOrigins)
    else
      let $projectPath := string($project/@path)
        , $parentPath := replace($projectPath, "/[^/]+$", "")
        , $parentMeta := if ( doc-available($parentPath || "/wdbmeta.xml") )
            then doc($parentPath || "/wdbmeta.xml")
            else ()
        , $projectMeta := if ( doc-available($projectPath || "/wdbmeta.xml") )
            then doc($projectPath || "/wdbmeta.xml")
            else ()
        , $fileIds := if ( $projectMeta )
            then (
              $projectMeta//meta:file/@xml:id/string(),
              $projectMeta//meta:struct[@xml:id]/@xml:id/string()
            )
            else ()
        , $collectionName := replace($projectPath, "^.*/", "")
        , $projectIndex := doc("/db/apps/edoc/index/project-index.xml")
        , $fileIndex := doc("/db/apps/edoc/index/file-index.xml")
      
      return r2:response(
        204,
        'text/plain',
        (
          if ( $parentMeta ) then (
            update delete $parentMeta//meta:ptr[@xml:id = $request?parameters?ed],
            update delete $parentMeta//meta:struct[@file = $request?parameters?ed]
          ) else (),
          update delete $projectIndex/id($request?parameters?ed),
          for $id in $fileIds return update delete $fileIndex/id($id),
          xmldb:remove($projectPath),
          ''
        )[last()],
        $r2:allOrigins
      )
};
