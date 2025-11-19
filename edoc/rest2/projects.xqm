xquery version "3.1";

module namespace r2p = "https://github.com/dariok/wdbplus/rest2/projects";

import module namespace r2 = "https://github.com/dariok/wdbplus/rest2/common" at "rest-common.xqm";
import module namespace functx = "http://www.functx.com";

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

declare function r2p:createProjectWithoutId ( $request as map(*) ) as map(*) {
  if ( not(exists($request?user)) or $request?user?fullName = 'guest' ) then
    r2:response(401, 'text/plain', 'Unauthorized', $r2:allOrigins)
  else if ( not(r2:writeAllowed($request?user)) ) then
    r2:response(403, 'text/plain', 'Forbidden', $r2:allOrigins)
  else if ( not(r2:mapKeysAllowed($request?body, ('title'), ('short', 'collection'))) ) then
    r2:response(422, 'text/plain', 'Wrong content of project information found. Expected `title` (mandatory), `short`, or `collection`.', $r2:allOrigins)
  else
    r2p:createProjectFromId(map:merge(($request?body, map:entry("id", 'p' || util:uuid()) )))
};

declare function r2p:createProjectFromId ( $request as map(*) ) as map(*) {
  (: Step 2: parse the metadata from the request body :)
  (: Step 3: create the project collection and store the metadata :)
  r2:response(201, 'text/plain', $request?id, $r2:allOrigins)
};
