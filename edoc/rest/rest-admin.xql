xquery version "3.1";

module namespace wdbRAd = "https://github.com/dariok/wdbplus/RestAdmin";

import module namespace sm      = "http://exist-db.org/xquery/securitymanager" at "java:org.exist.xquery.functions.securitymanager.SecurityManagerModule";
import module namespace xstring = "https://github.com/dariok/XStringUtils"     at "../include/xstring/string-pack.xql";
import module namespace wdb     = "https://github.com/dariok/wdbplus/wdb"      at "../modules/app.xqm";

declare namespace http = "http://expath.org/ns/http-client";
declare namespace meta = "https://github.com/dariok/wdbplus/wdbmeta";
declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace tei  = "http://www.tei-c.org/ns/1.0";
