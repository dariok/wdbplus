xquery version "3.1";

module namespace config = "https://github.com/dariok/wdbplus/config";

(: global variables are defined here. These used to be in app.xqm but have been moved here to avoid circular
 : dependencies when importing app.xqm :)

(:~
 : load the config file
 : See https://github.com/dariok/wdbplus/wiki/Global-Configuration
 :)
declare variable $config:configFile := doc('../config.xml');

(:~
 : the base of this instance within the db
 :)
declare variable $config:edocBaseDB := $config:configFile => base-uri() => substring-before('/config.xml');

(:~
 : Get the data collection. Since v4.0, we only support setting this in the config file – for standard installations,
   the default will do just fine.
 :)
declare variable $config:data := $config:configFile//config:data;

(:~
 : get the base URI from the configuration
 :)
declare variable $config:edocBaseURL := $config:configFile//config:server;

(: ~
 : get the base URL for REST calls
 :)
declare variable $config:restURL := $config:configFile//config:rest;

(:~
 :  the server role
 :)
declare variable $config:role := $config:configFile//config:role/config:type;

(:~
 : the peer in a sandbox/publication configuration
 :)
declare variable $config:peer :=
  if ( $config:role != "standalone" )
    then $config:configFile//config:role/config:peer
    else ""
;
