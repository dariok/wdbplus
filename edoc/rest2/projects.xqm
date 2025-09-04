xquery version "3.1";

module namespace r2p = "https://github.com/dariok/wdbplus/rest2/projects";

import module namespace r2    = "https://github.com/dariok/wdbplus/rest2/common" at "rest-common.xqm";

declare namespace index = "https://github.com/dariok/wdbplus/index";
declare namespace meta  = "https://github.com/dariok/wdbplus/wdbmeta";

declare variable $r2p:base := doc('../config.xml')//*:rest;

(:~
 : List all projects
 : GET {base}/projects
 :)

declare function r2p:listProjects ( $request as map(*) ) as map(*) {
  let $projects := doc("/db/apps/edoc/index/project-index.xml")//index:project
  
  let $result :=
    <result start="1" count="{count($projects)}" xmlns="https://github.com/dariok/wdbplus/api/schema/v1">
      {
        for $project in $projects return
          <project id="{ $r2p:base }{ $request?path }/{ $project/@xml:id }"
              label="{ doc($project/@path || '/wdbmeta.xml')//meta:title[@type='main'] }"
          />
      }
    </result>
  
  return r2:returnXmlOrJson($result)
};
