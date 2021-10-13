(: wdb+ controller
 : based on the generic eXist-DB controller
 :
 : author: Dario Kampkaspar <dario.kampkaspar@ulb.tu-darmstadt.de>
 :)
xquery version "3.0";

import module namespace console = "http://exist-db.org/xquery/console"         at "java:org.exist.console.xquery.ConsoleModule";
import module namespace config  = "http://exist-db.org/xquery/apps/config"     at "/db/apps/eXide/modules/config.xqm";
import module namespace login   = "http://exist-db.org/xquery/login"           at "resource:org/exist/xquery/modules/persistentlogin/login.xql";
import module namespace request = "http://exist-db.org/xquery/request"         at "java:org.exist.xquery.functions.request.RequestModule";
import module namespace sm      = "http://exist-db.org/xquery/securitymanager" at "java:org.exist.xquery.functions.securitymanager.SecurityManagerModule";
import module namespace wdba    = "https://github.com/dariok/wdbplus/auth"     at "/db/apps/edoc/modules/auth.xqm";

declare namespace exist = "http://exist.sourceforge.net/NS/exist";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;

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
    and local:user-allowed()
  )
  or sm:is-dba((request:get-attribute("wd.user"),request:get-attribute("xquery.user"), 'nobody')[1])
};

let $cookiePath := substring-before(request:get-uri(), $exist:path),
    $duration := xs:dayTimeDuration("P2D")

return
if ($exist:resource eq '' or $exist:resource eq 'index.html') then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/global/index.html"/>
    </dispatch>
(: login :)
else if ($exist:resource = 'login') then
  (
    login:set-user("wd", $cookiePath, $duration, false()),
    try {
      if (request:get-parameter('logout', '') = 'logout') then
        wdba:getAuth(<br/>, map {'res': 'logout'})
      else if (local:user-allowed()) then
        wdba:getAuth(<br/>, map {'auth': <sm:id><sm:real><sm:username>{request:get-attribute("wd.user")}</sm:username></sm:real></sm:id>})
      else ( 
        response:set-status-code(401),
        <status>fail</status>
      )
    } catch * {
      response:set-status-code(403),
      <status>{$err:description}</status>
    }
  )
(: Konfigurationsseiten :)
else if (ends-with($exist:resource, ".html") and contains($exist:path, '/admin/')) then
  <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    {login:set-user("wd", $cookiePath, $duration, false())}
    <view>
      <set-header name="Cache-Control" value="no-cache"/>
      <forward url="{$exist:controller}/admin/view.xql"/>
    </view>
    <error-handler>
      <forward url="{$exist:controller}/templates/error-page.html" method="get"/>
      <forward url="{$exist:controller}/admin/view.xql"/>
    </error-handler>
  </dispatch>
(: generelle HTML :)
else if (ends-with($exist:resource, ".html")) then
  <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    {login:set-user("wd", $cookiePath, $duration, false())}
    <view>
      <forward url="{$exist:controller}/modules/view.xql"/>
    </view>
    <error-handler>
      <forward url="{$exist:controller}/templates/error-page.html" method="get"/>
      <forward url="{$exist:controller}/modules/view.xql"/>
    </error-handler>
  </dispatch>
else if (contains($exist:path, "/$shared/")) then
  <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    <forward url="{$exist:controller}/resources/{substring-after($exist:path, '/$shared/')}">
      <set-header name="Cache-Control" value="max-age=604800, must-revalidate"/>
    </forward>
  </dispatch>
else if (ends-with($exist:path, ".xql")) then
  <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    {login:set-user("wd", $cookiePath, $duration, false())}
    <set-header name="Cache-Control" value="no-cache"/>
    <set-attribute name="app-root" value="{$exist:prefix}{$exist:controller}"/>
  </dispatch>
else
  (: everything else is passed through :)
  <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    <cache-control cache="yes"/>
    <set-header name="Cache-Control" value="max-age=604800, must-revalidate"/>
  </dispatch>
