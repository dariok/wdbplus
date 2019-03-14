(:~
 : APP.XQM
 : 
 : all basic functions that may be used globally: these keep the framework together
 : 
 : functio nunc denuo emendata et novissime excusa III Id Mar MMXIX
 : 
 : Vienna, Dario Kampkaspar – dario.kampkaspar(at)oeaw.ac.at
 :)
xquery version "3.1";

module namespace wdb = "https://github.com/dariok/wdbplus/wdb";

import module namespace console = "http://exist-db.org/xquery/console";
import module namespace wdbErr  = "https://github.com/dariok/wdbplus/errors" at "error.xqm";
import module namespace xConf   = "http://exist-db.org/xquery/apps/config"   at "config.xqm";
import module namespace xstring = "https://github.com/dariok/XStringUtils"   at "../include/xstring/string-pack.xql";

declare namespace config    = "https://github.com/dariok/wdbplus/config";
declare namespace main      = "https://github.com/dariok/wdbplus";
declare namespace meta      = "https://github.com/dariok/wdbplus/wdbmeta";
declare namespace mets      = "http://www.loc.gov/METS/";
declare namespace rest      = "http://exquery.org/ns/restxq";
declare namespace tei       = "http://www.tei-c.org/ns/1.0";
declare namespace templates = "http://exist-db.org/xquery/templates" ;
declare namespace xlink     = "http://www.w3.org/1999/xlink";

(: ALL-PURPOSE VARIABLES :)
(:~
 : the base of this instance within the db
 :)
declare variable $wdb:edocBaseDB := $xConf:app-root;

(:~
 : load the config file
 : See https://github.com/dariok/wdbplus/wiki/Global-Configuration
 :)
declare variable $wdb:configFile := doc($wdb:edocBaseDB || '/config.xml');

(:~
 : Try to get the data collection. Documentation explicitly tells users to have a wdbmeta.xml
 : in the Collection that contains all projects
 :)
declare variable $wdb:data := 
  let $editionsW := collection($wdb:edocBaseDB)//meta:projectMD
  
  let $paths := for $f in $editionsW
    let $path := base-uri($f)
    where contains($path, '.xml')
    order by string-length($path)
    return $path
  
  return replace(xstring:substring-before-last($paths[1], '/'), '//', '/')
;

(:~
 : get the base URI either from the data of the last call or from the configuration
 :)
declare variable $wdb:edocBaseURL :=
  if ($wdb:configFile//config:server)
  then normalize-space($wdb:configFile//config:server)
  else
    let $dir := try { xstring:substring-before-last(request:get-uri(), '/') } catch * { "" }
    let $db := substring-after($wdb:edocBaseDB, 'db/')
    let $local := xstring:substring-after($dir, $db)
    let $path := if (string-length($local) > 0)
      then xstring:substring-before($dir, $local) (: there is a local part, e.g. 'admin' :)
      else $dir (: no local part, e.g. for view.html in app root :)
    
    return wdb:getServerApp() || $path
;

(: ~
 : get the base URL for REST calls
 :)
declare variable $wdb:restURL := 
  if ($wdb:configFile//config:rest)
  then $wdb:configFile//config:rest
  else substring-before($wdb:edocBaseURL, substring-after($wdb:edocBaseDB, '/db/')) || "restxq/edoc/";

(:~
 :  the server role
 :)
declare variable $wdb:role :=
  ($wdb:configFile//main:role/main:type, "standalone")[1]
;
(:~
 : the peer in a sandbox/publication configuration
 :)
declare variable $wdb:peer :=
  if ($wdb:role != "standalone")
    then $wdb:configFile//main:role/main:peer
    else ""
;
(: END ALL-PURPOSE VARIABLES :)

(: FUNCTIONS TO GET SERVER INFO :)

(: ~
 : get the name of the server, possibly including the port
 : If resolution fails, set the value in config.xml instead
 : This cannot be used for RESTXQ
 :)
declare function wdb:getServerApp() as xs:string {
  (: config:server contains the full base URL :)
  let $config := 
    let $scheme := substring-before($wdb:configFile//config:server, '//')
    let $server := substring-before(substring-after($wdb:configFile//config:server, '//'), '/')
    return $scheme || '//' || $server
  
  let $origin := try { request:get-header("Origin") } catch * { () }
  let $request := try {
    let $scheme := if (request:get-header-names() = 'X-Forwarded-Proto')
      then normalize-space(request:get-header('X-Forwarded-Proto'))
      else normalize-space(request:get-scheme())
    
    return if (request:get-server-port() != 80)
      then $scheme || '://' || request:get-server-name() || ':' || request:get-server-port()
      else $scheme || '://' || request:get-server-name()
  } catch * { () }
  let $ref := try { request:get-header('referer') } catch * { () }
  
  let $server := ($config, $ref, $origin, $request)
  return if (count($server) > 0)
    then $server[1]
    else wdbErr:error(map {"code" := "wdbErr:wdb0010"})
};
(: END FUNCTIONS TO GET SERVER INFO :)