xquery version "3.1";

declare namespace api    = "http://github.com/dariok/wdbplus/rest2";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

import module namespace roaster = "http://e-editiones.org/roaster";

import module namespace r2p = "https://github.com/dariok/wdbplus/rest2/projects" at "projects.xqm";

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

roaster:route($api:definitions, api:lookup#1)
