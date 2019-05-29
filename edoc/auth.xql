xquery version "3.1";

import module namespace wdba="https://github.com/dariok/wdbplus/auth" at "/db/apps/edoc/modules/auth.xqm";
import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";
import module namespace login		= "http://exist-db.org/xquery/login"				at "resource:org/exist/xquery/modules/persistentlogin/login.xql";

(: von eXide geklaut :)
declare function local:user-allowed() {
    (
        request:get-attribute("wd.user") and
        request:get-attribute("wd.user") != "guest"
    )
};
declare function local:query-execution-allowed() {
    local:user-allowed()
        or
    xmldb:is-admin-user((xmldb:get-current-user(), request:get-attribute("wd.user"),request:get-attribute("xquery.user"), 'nobody')[1])
};

(: let $loggedIn := xmldb:login("/db/apps/edoc", request:get-parameter("user", ""), request:get-parameter("password", ""), true()) :)
(:let $loggedIn := login:set-user("wd", (), false()):)
let $t := console:log("auth")

return
    try {
        if (request:get-parameter('logout', '') = 'logout') then
            wdba:getAuth(<br/>, map {'res': 'logout'})
        else if (local:user-allowed()) then
            wdba:getAuth(<br/>, map {'res': request:get-attribute("wd.user")})
        else ( 
            response:set-status-code(401),
                <status>fail</status>
            )
    } catch * {
        response:set-status-code(403),
        <status>{$err:description}</status>
    }