(: wdbplus: load parts of start.html by means of project specifics
 : created: 2019-02-20
 : creator: DK - Dario Kampkaspar <dario.kampkaspar@oeaw.ac.at>
 : sources: https://github.com/dariok/wdbplus
 : changes:
 :          - 2019-06-08: module now used in function.html context
 :          - 2019-06-28: enable use of templating functions within project
 :                        specific HTML files
 :          – 2023-03-01: enable the use of start.xsl (instance specific or global) to create from wdbmeta.xml
 :)
xquery version "3.1";

module namespace wdbStart = "https://github.com/dariok/wdbplus/start";

import module namespace r2p   = "https://github.com/dariok/wdbplus/rest2/projects"  at "../rest2/projects.xqm";
import module namespace wdbrh = "https://github.com/dariok/wdbplus/renderer-helper" at "renderer-helper.xqm";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace router = "http://e-editiones.org/roaster/router";
declare namespace wdbPF  = "https://github.com/dariok/wdbplus/projectFiles";

declare function wdbStart:getAside ( $node as node(), $model as map(*) ) as node()* {
  let $specifics := wdbrh:getProjectSpecifics($node, $model, "start-aside")
  return (
    comment { "created in start.xqm, " || $node/@data-template },
    if ( exists($specifics) )
      then $specifics
      else (
        <h2>Inhalt</h2>,
        map:get(
          r2p:projectView(
            map{
              "path": $model?infoFileLoc,
              "parameters": map { "view": "navigation", "ed": $model?ed },
              "Accept": "text/html"
            }
          ),
          xs:QName("router:RESPONSE_BODY")
        )
      )
  )
};

(: get the main part of the start page from either projectSpec HTML, projectSpec function or return an empty seq :)
declare function wdbStart:getMain ( $node as node(), $model as map(*) ) as node()* {
  let $specifics := wdbrh:getProjectSpecifics($node, $model, "start-main")
  return (
    comment { "created in start.xqm, " || $node/@data-template },
    if ( exists($specifics) )
      then $specifics
      else map:get(
        r2p:projectView(
          map{
            "path": $model?infoFileLoc,
            "parameters": map { "view": "start", "ed": $model?ed },
            "Accept": "text/html"
          }
        ),
        xs:QName("router:RESPONSE_BODY"))
  )
};
