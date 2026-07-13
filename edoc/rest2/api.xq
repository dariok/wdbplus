xquery version "3.1";

declare namespace api    = "http://github.com/dariok/wdbplus/rest2";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

import module namespace roaster = "http://e-editiones.org/roaster";

import module namespace auth = "http://e-editiones.org/roaster/auth";
import module namespace r2p  = "https://github.com/dariok/wdbplus/rest2/projects"  at "projects.xqm";
import module namespace r2r  = "https://github.com/dariok/wdbplus/rest2/resources" at "resources.xqm";
import module namespace r2s  = "https://github.com/dariok/wdbplus/rest2/search"    at "search.xqm";

(:~
 : list of definition files to use – relative to the controller path
 :)
declare variable $api:definitions := ("rest2/v2.json");

(:~
 : Loopkup function to look up a function by name – this is necessary because functions are only known to importing modules
 : The name is expected to be a QName, e.g. "rest:listProjects".
 :)
declare function api:lookup ( $name as xs:string ) {
  function-lookup(xs:QName($name), 1)
};

declare function api:addHeader ( $request as map(*), $response as map(*)) as map(*)+ {
  map:put($request, "headers", map {
    "Accept": (request:get-header("Accept") => tokenize(','))[1]
  }),
  $response
};

declare variable $api:use := (
  auth:use-authorization($auth:DEFAULT_STRATEGIES),
  api:addHeader#2  
);

roaster:route($api:definitions, api:lookup#1, $api:use)
