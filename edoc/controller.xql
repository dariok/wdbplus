(: Bearbeiter DK = Dario Kampkaspar, kampkaspar@hab.de :)
xquery version "3.0";

import module namespace haba = "https://github.com/dariok/wdbplus/auth" at "/apps/wdb/modules/auth.xqm";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;

import module namespace login		= "http://exist-db.org/xquery/login"				at "resource:org/exist/xquery/modules/persistentlogin/login.xql";
import module namespace config	= "http://exist-db.org/xquery/apps/config"	at "/db/apps/eXide/modules/config.xqm";

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

if ($exist:path eq '') then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="{request:get-uri()}/"/>
    </dispatch>
(: login - geklaut von eXide :)
else if ($exist:resource = 'login') then
    let $loggedIn := login:set-user("wd", (), false())
    return
        (:try {
            util:declare-option("exist:serialize", "method=json"),
            if (local:user-allowed()) then
                <status>
                    <user>{request:get-attribute("wd.user")}</user>
                    <isAdmin json:literal="true">{ xmldb:is-admin-user((request:get-attribute("wd.user"),request:get-attribute("xquery.user"), 'nobody')[1]) }</isAdmin>
                </status>
            else 
                (
                    response:set-status-code(401),
                    <status>fail</status>
                ):)
        try {
            if (request:get-parameter('logout', '') = 'logout') then
                haba:getAuth(<br/>, map {'res': 'logout'})
            else if (local:user-allowed()) then
                haba:getAuth(<br/>, map {'res': request:get-attribute("wd.user")})
            else (
                response:set-status-code(401),
                    <status>fail</status>
                )
        } catch * {
            response:set-status-code(403),
            <status>{$err:description}</status>
        }
else if (ends-with($exist:path, 'start.html')) then
	<dispatch xmlns="http://exist.sourceforge.net/NS/exist">
		<!--<view>
			<forward url="{$exist:controller}/start.html" method="get">
				<add-parameter name="path" value="{$exist:path}" />
			</forward>
			<forward url="{$exist:controller}/modules/view.xql"/>
		</view>-->
		<!--<view>-->
			<forward url="/start.xql">
				<add-parameter name="path" value="{$exist:path}" />
			</forward>
		<!--</view>-->
		<error-handler>
			<forward url="{$exist:controller}/error-page.html" method="get"/>
<!--			<forward url="{$exist:controller}/modules/view.xql"/> -->
			<forward url="{$exist:controller}/modules/view.xql"/>
		</error-handler>
	</dispatch>
(: auch von eXide geklaut :)
(:  :else if (ends-with($exist:resource, 'query.html')) then
	let $query := request:get-parameter("query", ())
    let $base := request:get-parameter("edition", ())
    let $doLogin := login:set-user("wd", (), false())
    let $userAllowed := local:query-execution-allowed()
    return
        if ($userAllowed) then
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                <view>
                    {login:set-user("wd", (), false())}
                    <forward url="{$exist:controller}/modules/view.xql"/>
                </view>
            </dispatch>
        else
            response:set-status-code(401):)
(: spezifiziert auf view.html; 2016-11-03 DK :)
(: kann weiter generell bleiben; 2016-11-04 DK :)
else if (ends-with($exist:resource, ".html")) then
	<dispatch xmlns="http://exist.sourceforge.net/NS/exist">
		<view>
<!--			<forward url="{$exist:controller}/modules/view.xql"/> -->
			<forward url="{$exist:controller}/modules/view.xql"/>
		</view>
		<error-handler>
			<forward url="{$exist:controller}/error-page.html" method="get"/>
<!--			<forward url="{$exist:controller}/modules/view.xql"/>-->
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