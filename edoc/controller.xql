(: Bearbeiter DK = Dario Kampkaspar :)
xquery version "3.0";

import module namespace config  = "http://exist-db.org/xquery/apps/config"  at "/db/apps/eXide/modules/config.xqm";
import module namespace login   = "http://exist-db.org/xquery/login"        at "resource:org/exist/xquery/modules/persistentlogin/login.xql";
import module namespace wdba    = "https://github.com/dariok/wdbplus/auth"  at "modules/auth.xqm";

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
        and
    local:user-allowed()
    )
        or
    sm:is-dba((request:get-attribute("wd.user"),request:get-attribute("xquery.user"), 'nobody')[1])
};

if ($exist:resource eq '' or $exist:resource eq 'index.html') then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <forward url="{$exist:controller}/global/index.html"/>
    </dispatch>
(: login :)
else if ($exist:resource = 'login') then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        {login:set-user("wd", (), false())}
        <forward url="{$exist:controller}/auth.xql">
            <set-attribute name="xquery.report-errors" value="yes"/>
            <set-header name="Cache-Control" value="no-cache"/>
            <set-header name="Access-Control-Allow-Origin" value="https://digitarium-app.acdh-dev.oeaw.ac.at"/>
        </forward>
    </dispatch>
(: Konfigurationsseiten :)
else if (ends-with($exist:resource, ".html") and contains($exist:path, '/admin/')) then
  <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
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
    {login:set-user("wd", (), false())}
    <set-header name="Cache-Control" value="no-cache"/>
    <set-attribute name="app-root" value="{$exist:prefix}{$exist:controller}"/>
  </dispatch>
else
  (: everything else is passed through :)
  <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    <cache-control cache="yes"/>
    <set-header name="Cache-Control" value="max-age=604800, must-revalidate"/>
  </dispatch>