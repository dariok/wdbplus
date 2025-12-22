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
    <result xmlns="https://github.com/dariok/wdbplus/api/schema/v1"
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
    </result>
  
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
      map:merge(
        (
          $request,
          map:entry(
            'body',
            map:merge(
              (
                $request?body,
                map:entry(
                  "ed",
                  '_' || util:uuid()
                )
              )
            )
          )
        )
      )
    )
};

(:~
 : create a new project with the metadata given in the request
 : PUT /projects/{$parent}/subprojects/{$ed}
 : also called by r2p:createProjectWithoutId
 :)
declare function r2p:createProjectWithId ( $request as map(*) ) as map(*) {
  r2:logMap($request),
  if ( not(exists($request?user)) or $request?user?fullName = 'guest' ) then
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
  else if ( not(r2:mapKeysAllowed($request?body, ('title', 'ed'), ('short', 'collection'))) ) then
    r2:response(422, 'text/plain', 'Wrong content of project information found. Expected `title` (mandatory), `short`, or `collection`.', $r2:allOrigins)
  else
  
  (: TODO: we need to copy the full structure for main projects (i.e., $parent = 'data') :)
  let $collection := doc("/db/apps/edoc/index/project-index.xml")/id($request?parameters?parent)/@path
    , $parentMeta := doc( $collection || "/wdbmeta.xml" )
    , $subCollection := xmldb:create-collection($collection, $request?body?collection)
    , $newMetaPath := xmldb:copy-resource("/db/apps/edoc/admin/project-template", "wdbmeta.xml", $subCollection, "wdbmeta.xml")
    , $collectionPermissions := sm:get-permissions(xs:anyURI($collection))
    , $metaPermissions := sm:get-permissions(xs:anyURI($collection || "/wdbmeta.xml"))
    , $meta := doc($newMetaPath)
  
  return r2:response(
    201,
    'text/plain',
    (
      sm:chown(xs:anyURI($subCollection), $collectionPermissions//@owner || ":" || $collectionPermissions//@group),
      sm:chmod(xs:anyURI($subCollection), $collectionPermissions//@mode),
      sm:chown(xs:anyURI($newMetaPath), $metaPermissions//@owner || ":" || $metaPermissions//@group),
      sm:chmod(xs:anyURI($newMetaPath), $metaPermissions//@mode),
      xmldb:create-collection($collection-uri, "texts"),
      sm:chown(xs:anyURI($subCollection || '/texts'), $collectionPermissions//@owner || ":" || $collectionPermissions//@group),
      sm:chmod(xs:anyURI($subCollection || '/texts'), $collectionPermissions//@mode),
      update insert attribute xml:id { $request?body?ed } into $meta/meta:projectMD,
      update replace $meta//meta:projectID[1]
          with <projectID xmlns="https://github.com/dariok/wdbplus/wdbmeta" type="main">{ $request?body?ed }</projectID>,
      update replace $meta//meta:title[1]
          with <title xmlns="https://github.com/dariok/wdbplus/wdbmeta" type="main">{ $request?body?title }</title>,
      update insert attribute label { $request?body?title } into $meta//meta:struct[1],
      update insert
          <ptr xmlns="https://github.com/dariok/wdbplus/wdbmeta"
            path="{ $request?body?collection }/wdbmeta.xml" xml:id="{ $request?body?ed }"
          /> into $parentMeta//meta:files,
      update insert
          <struct xmlns="https://github.com/dariok/wdbplus/wdbmeta"
            file="{ $request?body?ed }" label="{ $request?body?title }"
          /> into $parentMeta/meta:projectMD/meta:struct,
      $subCollection
    ),
    $r2:allOrigins
  )
};
