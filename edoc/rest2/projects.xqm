xquery version "3.1";

module namespace r2p = "https://github.com/dariok/wdbplus/rest2/projects";

import module namespace r2       = "https://github.com/dariok/wdbplus/rest2/common" at "rest-common.xqm";
import module namespace wdb      = "https://github.com/dariok/wdbplus/wdb"          at "../modules/app.xqm";
import module namespace wdbFiles = "https://github.com/dariok/wdbplus/files"        at "../modules/wdb-files.xqm";

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
  let $project := try { wdbFiles:getFullPath($request?parameters?parent) } catch * { $err:code }

  return if ( $project instance of xs:QName ) then
    r2:response(404, 'text/plain', 'Project ' || $request?parameters?parent || ' not found', $r2:allOrigins)
  else
    let $meta := doc($project?collectionPath || "/wdbmeta.xml")
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
  let $parent := try { wdbFiles:getFullPath($request?parameters?parent) } catch * { $err:code }
    , $project := try { wdbFiles:getFullPath($request?parameters?ed) } catch * { $err:code }

  return if ( not(exists($request?parameters?parent)) or not(exists($request?parameters?ed)) ) then
    r2:response(400, 'text/plain', 'Bad Request\n parameter `parent` or `ed` missing', $r2:allOrigins)
  else if ( not(exists($request?user)) or $request?user?fullName = 'guest' ) then
    r2:response(401, 'text/plain', 'Unauthorized', $r2:allOrigins)
  else if ( not(r2:writeAllowed($request?user)) ) then
    r2:response(403, 'text/plain', 'Forbidden', $r2:allOrigins)
  else if ( $parent instance of xs:QName ) then
    r2:response(404, 'text/plain', 'Project ' || $request?parameters?parent || ' not found', $r2:allOrigins)
  else if ( not(sm:has-access($parent?collectionPath, "w")) ) then
    r2:response(403, 'text/plain', 'Forbidden', $r2:allOrigins)
  else if ( $project instance of map(*) and exists($project?collectionPath) ) then
    r2:response(409, 'text/plain', 'A project with ID ' || $request?parameters?ed || ' already exists', $r2:allOrigins)
  else if ( xmldb:collection-available($parent?collectionPath || '/' || $request?body?collection) ) then
    r2:response(409, 'text/plain', 'A collection with name ' || $request?body?collection || ' already exists in project ' || $request?parameters?parent, $r2:allOrigins)
  else if ( not(r2:mapKeysAllowed($request?body, ('title', 'collection'), ('short'))) ) then
    r2:response(422, 'text/plain', 'Wrong content of project information found. Expected `title` and `collection`(mandatory), `short`.', $r2:allOrigins)
  else
  
  let $parentCollection := $parent?collectionPath
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

      xmldb:create-collection($subCollection, "edition"),
      sm:chown(xs:anyURI($subCollection || '/edition'), $collectionPermissions//@owner || ":" || $collectionPermissions//@group),
      sm:chmod(xs:anyURI($subCollection || '/edition'), $collectionPermissions//@mode),

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

      $request?parameters?ed
    )[last()], (: create-collection() returns a string; we only want the path to the project collection :)
    $r2:allOrigins
  )
};

(:~
 : List all views for a project
 : GET /projects/{$ed}/views
 :)
declare function r2p:listProjectViews ( $request as map(*) ) as map(*) {
  let $project := try { wdbFiles:getFullPath($request?parameters?ed) } catch * { $err:code }
  
  return if ( $project instance of xs:QName ) then
    r2:response(404, 'text/plain', 'Project ' || $request?parameters?ed || ' not found', $r2:allOrigins)
  else
    r2:returnXmlOrJson(<list xmlns="https://github.com/dariok/wdbplus/api/schema/v1"
        level="project"
        for="{ $r2:base }/projects/{$request?parameters?ed}"
        type="views"
        start="1"
        length="3"
        max="3 ">
        <view name="default"
          label="returns an XML representation of the project"
          href="{ $r2:base }/projects/{$request?parameters?ed}/views/default"/>
        <view name="nav"
          label="returns a navigation structure for the project"
          href="{ $r2:base }/projects/{$request?parameters?ed}/views/navigation"/>
        <view name="start"
          label="returns a start page for the project"
          href="{ $r2:base }/projects/{$request?parameters?ed}/views/start"/>
      </list>)
};

(:~
 : Get basic information about a project
 : GET /projects/{$ed}
 :)
declare function r2p:getProject ( $request as map(*) ) as map(*) {
  let $project := try { wdbFiles:getFullPath($request?parameters?ed) } catch * { $err:code }
  
  return if ( $project instance of xs:QName ) then
    r2:response(404, 'text/plain', 'Project ' || $request?parameters?ed || ' not found', $r2:allOrigins)
  else
    let $meta := doc( $project?collectionPath || "/wdbmeta.xml" )
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
                id="{ $r2:base }/resources/{ $entry/@xml:id }"
                label="{ $meta//meta:view[@file = $entry/@xml:id]/@label }" />
        }
      </contents>
    )
};

(:~
 : List all resources of a project
 : GET /projects/{$ed}/resources
 :)
declare function r2p:listProjectResources ( $request as map(*) ) as map(*) {
  let $project := try { wdbFiles:getFullPath($request?parameters?ed) } catch * { $err:code }
  return if ( $project instance of xs:QName ) then
    r2:response(404, 'text/plain', 'Project ' || $request?parameters?ed || ' not found', $r2:allOrigins)
  else
    let $meta := doc( $project?collectionPath || "/wdbmeta.xml" )
      , $views := $meta//meta:view
      , $result :=
        <list xmlns="https://github.com/dariok/wdbplus/api/schema/v1"
            start="1"
            total="{ count($views) }"
            id="{ $r2:base }{ $request?path }">
          {
            for $entry in $views
            let $id := string($entry/@file)
            return
              <file
                  id="{ $r2:base }/projects/{ $request?parameters?ed }/resources/{ $id }"
                  label="{ normalize-space($entry/@label) }"
              />
          }
        </list>
    return r2:returnXmlOrJson($result)
};

(:~
 : Create an XML resource in a project (no ID given)
 : This is used for XML files only. Non-XML files need to be created with a full path via PUT, so that the path information is available for the processing of the file.
 : POST /projects/{$ed}/resources
 :)
declare function r2p:createProjectResourceWithoutId ( $request as map(*) ) as map(*) {
  let $project := try { wdbFiles:getFullPath($request?parameters?ed) } catch * { $err:code }
    , $meta := try { doc( $project?collectionPath || "/wdbmeta.xml" ) } catch * { $err:code }
    , $xml := try { parse-xml($request?body?file?data) } catch * { $err:code }
    , $id := if ( $xml instance of node() )
        then ($xml/*[1]/@xml:id, '_' || util:uuid())[1]
        else ()
    , $uuid := util:uuid($xml)

  return if ( $project instance of xs:QName ) then
    r2:response(404, 'text/plain', 'Project ' || $request?parameters?ed || ' not found', $r2:allOrigins)
  else if ( not(starts-with($request?media-type, "multipart/form-data")) ) then
    r2:response(415, 'text/plain', 'Unsupported Media Type. Expected multipart/form-data with a file field.',
        map:merge(($r2:allOrigins, map:entry("Allow-Post", "multipart/form-data")))
    )
  else if ( not(r2:mapKeysAllowed($request?body, ('path', 'file'), ())) ) then
    r2:response(422, 'text/plain', 'Wrong content of resource information found. Expected `path` and `file`.', $r2:allOrigins)
  else if ( not($xml instance of document-node()) ) then
    r2:response(422, 'text/plain', 'File content is not valid XML.', $r2:allOrigins)
  else if ( not(exists($request?user)) or $request?user?fullName = 'guest' ) then
    r2:response(401, 'text/plain', 'Unauthorized', $r2:allOrigins)
  else if ( not(r2:writeAllowed($request?user)) ) then
    r2:response(403, 'text/plain', 'Forbidden', $r2:allOrigins)
  else if ( not(sm:has-access($project?collectionPath, "w")) ) then
    r2:response(403, 'text/plain', 'Forbidden', $r2:allOrigins)
  else if ( $meta//meta:file[@path = $request?body?path || '/' || $request?body?file?name] ) then
    r2:response(409, 'text/plain', 'A resource with path ' || $request?body?path || '/' || $request?body?file?name || ' already exists in project ' || $request?parameters?ed, $r2:allOrigins)
  else if ( $meta//meta:file[@xml:id = $id] ) then
    r2:response(409, 'text/plain', 'A resource with ID ' || $id || ' already exists in project ' || $request?parameters?ed, $r2:allOrigins)
  else if ( $meta//meta:file[@uuid = $uuid] ) then
    r2:response(409, 'text/plain', 'A resource with a hash of ' || $uuid || ' already exists in project ' || $request?parameters?ed || ' as ' || $meta//meta:file[@uuid = $uuid]/@path, $r2:allOrigins)
  else
    (: TODO: check media type for non-XML files, and handle accordingly (e.g. store as binary) :)
    r2:createXmlResource(
      map{
        "parameters": map:merge((
            $request?parameters,
            map:entry("id", $id)
          )),
        "body": map:merge((
            $request?body,
            map:entry("xml", $xml),
            map:entry("hash", $uuid)
          )),
        "user": $request?user,
        "project": $project
      }
    )
};

(:~
 : Create a resource in a project (ID given – this may overwrite an existing resource)
 : If no entry with this ID, this path, and this hash exists, creates a new resource with the given ID.
  : If an entry with this ID but a different path exists, returns a 409 Conflict,
  : If an entry with this path but a different ID exists, returns a 409 Conflict,
  : If an entry with this hash but a different ID and path exists, returns a 409 Conflict.
  : If all three match an existing entry, return 204
 : PUT /projects/{$ed}/resources/{$id}
 :)
declare function r2p:createProjectResourceWithId ( $request as map(*) )  {
  let $project := try { wdbFiles:getFullPath($request?parameters?ed) } catch * { $err:code }
    , $meta := try { doc( $project?collectionPath || "/wdbmeta.xml" ) } catch * { $err:code }
    , $xml := try { parse-xml($request?body?file?data) } catch * { $err:code }
    , $uuid := util:uuid($xml)
  
  return if ( $project instance of xs:QName ) then
    r2:response(404, 'text/plain', 'Project ' || $request?parameters?ed || ' not found', $r2:allOrigins)
  else if ( not(starts-with($request?media-type, "multipart/form-data")) ) then
    r2:response(415, 'text/plain', 'Unsupported Media Type. Expected multipart/form-data with a file field.',
        map:merge(($r2:allOrigins, map:entry("Allow-Post", "multipart/form-data")))
    )
  else if ( not(r2:mapKeysAllowed($request?body, ('path', 'file'), ())) ) then
    r2:response(422, 'text/plain', 'Wrong content of resource information found. Expected `path` and `file`.', $r2:allOrigins)
  else if ( not($xml instance of document-node()) ) then
    r2:response(422, 'text/plain', 'File content is not valid XML.', $r2:allOrigins)
  else if ( exists($xml/*[1]/@xml:id) and $xml/*[1]/@xml:id != $request?parameters?id ) then
    r2:response(422, 'text/plain', 'ID in the XML content (' || $xml/*[1]/@xml:id || ') does not match the ID in the URL (' || $request?parameters?id || ').', $r2:allOrigins)
  else if ( not(exists($request?user)) or $request?user?fullName = 'guest' ) then
    r2:response(401, 'text/plain', 'Unauthorized', $r2:allOrigins)
  else if ( not(r2:writeAllowed($request?user)) ) then
    r2:response(403, 'text/plain', 'Forbidden', $r2:allOrigins)
  else if ( not(sm:has-access($project?collectionPath, "w")) ) then
    r2:response(403, 'text/plain', 'Forbidden', $r2:allOrigins)
  else if ( $meta//meta:file[@path = $request?body?path || '/' || $request?body?file?name
            and @xml:id = $request?parameters?id
            and @uuid = $uuid
          ] ) then
    r2:response(204, 'text/plain', '', $r2:allOrigins)
  else if ( $meta//meta:file[@path = $request?body?path || '/' || $request?body?file?name and @xml:id != $request?parameters?id] ) then
    r2:response(409, 'text/plain', 'A resource with path ' || $request?body?path || ' already exists in project ' || $request?parameters?ed  || ' with ID ' || $request?parameters?id, $r2:allOrigins)
  else if ( $meta//meta:file[@xml:id = $request?parameters?id and @path != $request?body?path || '/' || $request?body?file?name] ) then
    r2:response(409, 'text/plain', 'A resource with ID ' || $request?parameters?id || ' already exists in project ' || $request?parameters?ed || ' with different path ' || $request?body?path || '/' || $request?body?file?name, $r2:allOrigins)
  else if ( $meta//meta:file[@uuid = $uuid] ) then
    r2:response(409, 'text/plain', 'A resource with a hash of ' || $uuid || ' already exists in project ' || $request?parameters?ed || ' as ' || $meta//meta:file[@uuid = $uuid]/@path, $r2:allOrigins)
  else if ( $meta//id($request?parameters?id)[self::meta:struct] ) then
    r2:response(409, 'text/plain', 'ID ' || $request?parameters?id || ' is already in use for a struct ' || $meta/id($request?parameters?id)/@label || $meta/id($request?parameters?id)/meta:label, $r2:allOrigins)
  else 
  (: TODO: check media type for non-XML files, and handle accordingly (e.g. store as binary) :)
    r2:createXmlResource(
      map{
        "parameters": map:merge((
            $request?parameters,
            map:entry("id", $request?parameters?id)
          )),
        "body": map:merge((
            $request?body,
            map:entry("xml", $xml),
            map:entry("hash", $uuid)
          )),
        "user": $request?user,
        "project": $project
      }
    )
};

(:
TODO: - add a function to update project information (e.g. title, short title) → PATCH

TODO: - check whether we need a uniform “descriptor” element for both projects and files in the project metadata
 (, so that we can have a single endpoint for listing all resources of a project (instead of separate ones for subprojects and files). This would also make it easier to maintain the order of resources in the project metadata, which is currently not possible with the separate <meta:ptr> and <meta:file> elements.)

          <project xmlns="https://github.com/dariok/wdbplus/api/schema/v1">
            <id>{ $r2:base }{ $request?path }</id>
            <title>{ $meta//meta:title[@type = 'main'] }</title>
            {
              if ( exists($meta//meta:title[@type = 'sub']) ) then
                <short>{ $meta//meta:title[@type = 'sub'] }</short>
              else ()
            }
            <collections>
              {
                for $entry in $meta//meta:ptr return
                  <project
                      id="{ $r2:base }/projects/{ $entry/@xml:id }"
                      label="{ $meta//meta:struct[@file = $entry/@xml:id]/@label }" />
              }
            </collections>
            <files>
              {
                for $entry in $meta//meta:file return
                  <file
                      id="{ $r2:base }/resources/{ $entry/@xml:id }"
                      label="{ $meta//meta:view[@file = $entry/@xml:id]/@label }" />
              }
            </files>
          </project>

:)

(:~
 : Delete a project
 : DELETE /projects/{$ed}
 :)
declare function r2p:deleteProject ( $request as map(*) ) as map(*) {
  let $project := try { wdbFiles:getFullPath($request?parameters?ed) } catch * { $err:code }
    , $meta := try { doc( $project?collectionPath || "/wdbmeta.xml" ) } catch * { $err:code }

  return if ( not(exists($request?parameters?ed)) or $request?parameters?ed = '' ) then
      r2:response(400, 'text/plain', 'Bad Request: parameter `ed` missing', $r2:allOrigins)
    else if ( $request?parameters?ed = 'data' ) then
      r2:response(400, 'text/plain', 'Forbidden: main project "data" cannot be deleted', $r2:allOrigins)
    else if ( not(exists($request?user)) or $request?user?fullName = 'guest' ) then
      r2:response(401, 'text/plain', 'Unauthorized', $r2:allOrigins)
    else if ( not(r2:writeAllowed($request?user)) ) then
      r2:response(403, 'text/plain', 'Forbidden', $r2:allOrigins)
    else if ( $project instance of xs:QName ) then
      r2:response(404, 'text/plain', 'Project ' || $request?parameters?ed || ' not found', $r2:allOrigins)
    else if ( not(sm:has-access($project?collectionPath, "w")) ) then
      r2:response(403, 'text/plain', 'Forbidden', $r2:allOrigins)
    else
      let $projectPath := string($project?collectionPath)
        , $parentPath := $project?parentProject
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
        , $subProjectIds := if ( $projectMeta )
            then $projectMeta//meta:ptr/@xml:id/string()
            else ()
        , $collectionName := replace($projectPath, "^.*/", "")
        , $projectIndex := doc("/db/apps/edoc/index/project-index.xml")
        , $fileIndex := doc("/db/apps/edoc/index/file-index.xml")
      
      return r2:response(
        204,
        'text/plain',
        (
          if ( subProjectIds ) then
            for $id in $subProjectIds return r2p:deleteProject(map{
              "parameters": map{ "ed": $id },
              "user": $request?user
            })
          else (),
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

declare function r2p:viewProject ( $request as map(*) ) as map(*) {
  if ( not($request?parameters?view = ('default', 'navigation', 'start')) ) then
    r2:response(400, 'text/plain', 'Bad value for parameter `view`
      Expected one of "default", "navigation", "start", got ' || $request?parameters?view, $r2:allOrigins)
  else if ( ($request?parameters?view = 'default' and request:get-header('Accept') != 'application/xml')
         or ($request?parameters?view = 'navigation' and not(request:get-header('Accept') = ('application/xml', 'application/json', 'text/html')))
         or ($request?parameters?view = 'start' and request:get-header('Accept') != 'text/html') ) then
    r2:response(406, 'text/plain', 'Available representations are:
      for view "default": application/xml
      for view "start": text/html
      for view "navigation": application/xml, application/json, text/html', $r2:allOrigins)
  else
    let $project := try { wdbFiles:getFullPath($request?parameters?ed) } catch * { $err:code }
    return if ( $project instance of xs:QName ) then
      r2:response(404, 'text/plain', 'Project ' || $request?parameters?ed || ' not found', $r2:allOrigins)
    else
      r2:returnXmlOrJson(
        r2p:projectView(map{
          "path" : $project?collectionPath || "/wdbmeta.xml",
          "parameters": $request?parameters,
          "Accept": request:get-header('Accept')
        })
      )
};

declare function r2p:projectView ( $request as map(*) ) as node() {
  let $meta := doc($request?path)
  return if ( $request?parameters?view = 'start' ) then
      wdb:applySpecificXsl($meta, $request?path => substring-before('wdbmeta.xml'), "start.xsl")
    else if ( $request?parameters?view = 'navigation' ) then
      let $struct := $meta//meta:projectMD/meta:struct
      let $content := <struct xmlns="https://github.com/dariok/wdbplus/wdbmeta" ed="{$request?parameters?ed}">{(
          $struct/@*
          , $struct/*
        )}</struct>
      
      let $response := if ( $struct/meta:import )
        then r2p:imported($struct/meta:import, $content)
        else $content

      return if ( $request?Accept = 'text/html' )
        then wdb:applySpecificXsl($response, $request?path => substring-before('wdbmeta.xml'), "nav.xsl")
        else $response
    else
      $meta
};

declare %private function r2p:imported ( $import, $importerContent ) {
  let $base-uri := base-uri($import)
    , $fullImportedPath := substring-before($base-uri, "wdbmeta.xml") || $import/@path
    , $importedMeta := doc($fullImportedPath)
    , $importedContent := $importedMeta/meta:projectMD/meta:struct

    let $conStructed := <struct xmlns="https://github.com/dariok/wdbplus/wdbmeta">
        { $importedContent/@* }
        { if ( $importedMeta/@ed ) then () else attribute ed { $importedMeta/meta:projectMD/@xml:id } }
        { for $elem in $importedContent/* return
            if ( $elem/@file = $importerContent/@ed )
                then $importerContent
                else $elem
        }
    </struct>

    return if ( $importedContent/meta:import )
      then r2p:imported($importedContent/meta:import, $conStructed)
      else $conStructed
};
