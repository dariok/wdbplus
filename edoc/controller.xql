(: Bearbeiter DK = Dario Kampkaspar, kampkaspar@hab.de :)
xquery version "3.0";

import module namespace wdba = "https://github.com/dariok/wdbplus/auth" at "modules/auth.xqm";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;

import module namespace login		= "http://exist-db.org/xquery/login"				at "resource:org/exist/xquery/modules/persistentlogin/login.xql";
import module namespace config	= "http://exist-db.org/xquery/apps/config"	at "/db/apps/eXide/modules/config.xqm";
import module namespace console = "http://exist-db.org/xquery/console";

(: von eXide geklaut :)
declare function local:user-allowed() {
    (
        request:get-attribute("wd.user") and
        request:get-attribute("wd.user") != "guest"
    ) or config:get-configuration()/restrictions/@guest = "yes"
};
declare function local:query-execution-allowed() {
    (
    config:get-configuration()/restrictions/@execute-query = "yes"
        and
    local:user-allowed()
    )
        or
    xmldb:is-admin-user((request:get-attribute("wd.user"),request:get-attribute("xquery.user"), 'nobody')[1])
};

let $t := console:log($exist:path)
return

if ($exist:path eq '') then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="{request:get-uri()}/"/>
    </dispatch>
(: login - geklaut von eXide :)
else if ($exist:resource = 'login') then
    let $loggedIn := login:set-user("wd", (), false())
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
(: Projekt-Startseite :)
else if (ends-with($exist:path, 'start.html')) then
	<dispatch xmlns="http://exist.sourceforge.net/NS/exist">
			<forward url="/start.xql">
				<add-parameter name="path" value="{$exist:path}" />
			</forward>
		<error-handler>
			<forward url="{$exist:controller}/error-page.html" method="get"/>
			<forward url="{$exist:controller}/modules/view.xql"/>
		</error-handler>
	</dispatch>
(: Konfigurationsseiten :)
else if (ends-with($exist:resource, ".html") and contains($exist:path, '/admin/')) then
	<dispatch xmlns="http://exist.sourceforge.net/NS/exist">
		<view>
			<forward url="{$exist:controller}/admin/view.xql"/>
		</view>
		<error-handler>
			<forward url="{$exist:controller}/error-page.html" method="get"/>
			<forward url="{$exist:controller}/admin/view.xql"/>
		</error-handler>
	</dispatch>
(: generelle HTML :)
else if (ends-with($exist:resource, ".html")) then
	<dispatch xmlns="http://exist.sourceforge.net/NS/exist">
		<view>
			<forward url="{$exist:controller}/modules/view.xql"/>
		</view>
		<error-handler>
			<forward url="{$exist:controller}/error-page.html" method="get"/>
			<forward url="{$exist:controller}/modules/view.xql"/>
		</error-handler>
	</dispatch>
else if (contains($exist:path, "/$shared/")) then
	<dispatch xmlns="http://exist.sourceforge.net/NS/exist">
		<forward url="{$exist:controller}/resources/{substring-after($exist:path, '/$shared/')}">
			<set-header name="Cache-Control" value="max-age=3600, must-revalidate"/>
		</forward>
	</dispatch>
else if (ends-with($exist:path, ".xql")) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        {login:set-user("wd", (), false())}
        <set-header name="Cache-Control" value="no-cache"/>
        <set-attribute name="app-root" value="{$exist:prefix}{$exist:controller}"/>
    </dispatch>
else
	(: everything else is passed through :)
	<dispatch xmlns="http://exist.sourceforge.net/NS/exist">
		<cache-control cache="yes"/>
	</dispatch>