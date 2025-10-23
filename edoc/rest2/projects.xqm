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
