(:~
 : APP.XQM
 : 
 : all basic functions that may be used globally: these keep the framework together
 : 
 : function nunc denuo emendata et novissime excusa III Id Mar MMXIX
 : 
 : Vienna, Dario Kampkaspar – dario.kampkaspar@oeaw.ac.at
 :)
xquery version "3.1";

module namespace wdb = "https://github.com/dariok/wdbplus/wdb";

import module namespace console = "http://exist-db.org/xquery/console";
import module namespace wdbErr  = "https://github.com/dariok/wdbplus/errors" at "error.xqm";
import module namespace xConf   = "http://exist-db.org/xquery/apps/config"   at "config.xqm";
import module namespace xstring = "https://github.com/dariok/XStringUtils"   at "../include/xstring/string-pack.xql";

declare namespace config = "https://github.com/dariok/wdbplus/config";
declare namespace main   = "https://github.com/dariok/wdbplus";
declare namespace meta   = "https://github.com/dariok/wdbplus/wdbmeta";
declare namespace mets   = "http://www.loc.gov/METS/";
declare namespace rest   = "http://exquery.org/ns/restxq";
declare namespace tei    = "http://www.tei-c.org/ns/1.0";
declare namespace xlink  = "http://www.w3.org/1999/xlink";