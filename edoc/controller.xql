(: wdb+ controller
 : based on the generic eXist-DB controller
 :
 : author: Dario Kampkaspar <dario.kampkaspar@ulb.tu-darmstadt.de>
 :)
xquery version "3.1";

import module namespace login   = "http://exist-db.org/xquery/login"           at "resource:org/exist/xquery/modules/persistentlogin/login.xql";
import module namespace request = "http://exist-db.org/xquery/request"         at "java:org.exist.xquery.functions.request.RequestModule";
(: import module namespace sm      = "http://exist-db.org/xquery/securitymanager" at "java:org.exist.xquery.functions.securitymanager.SecurityManagerModule";:)
import module namespace wdba    = "https://github.com/dariok/wdbplus/auth"     at "modules/auth.xqm";

declare namespace exist = "http://exist.sourceforge.net/NS/exist";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
(: declare variable $exist:root external; :)

declare variable $local:isget := request:get-method() = ("GET","get");

declare function local:user-allowed() as xs:boolean {
  request:get-attribute("wd.user")
  and request:get-attribute("wd.user") != "guest"
};

util:log("info", "request:get-method(): " || request:get-method()),
util:log("info", "exist:path: " || $exist:path),

(: static HTML page for API documentation should be served directly to make sure it is always accessible :)
if (
    ($local:isget and $exist:path eq "/apiv2.html") or 
    ($local:isget and matches($exist:path, "^/[^/]+\.json$", "s"))
) then
  <dispatch xmlns="http://exist.sourceforge.net/NS/exist" />
else if ( $exist:resource = 'login' ) then
  (
    login:set-user("wd", substring-before(request:get-uri(), $exist:path), xs:dayTimeDuration("P2D"), false()),
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
else if ( contains($exist:path, 'api/v2') ) then
  (: REST API :)
  <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    <forward url="{$exist:controller}/rest2/api.xq"/>
  </dispatch>
else if ( $exist:resource eq '' or $exist:resource eq 'index.html' ) then
  <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    <forward url="{$exist:controller}/global/index.html"/>
  </dispatch>
(: admin pages :)
else if ( ends-with($exist:resource, ".html") and contains($exist:path, '/admin/') ) then
  <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    { login:set-user("wd", substring-before(request:get-uri(), $exist:path), xs:dayTimeDuration("P2D"), false()) }
    <view>
      <set-header name="Cache-Control" value="no-cache"/>
      <forward url="{$exist:controller}/admin/view.xql">
      <!--  { login:set-user("wd", $cookiePath, $duration, false()) } -->
      </forward>
    </view>
    <error-handler>
      <forward url="{$exist:controller}/templates/error-page.html" method="get"/>
      <forward url="{$exist:controller}/admin/view.xql"/>
    </error-handler>
  </dispatch>
(: other HTML :)
else if ( ends-with($exist:resource, ".html") ) then
  <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    <view>
      <forward url="{$exist:controller}/modules/view.xql">
				<!-- { login:set-user("wd", $cookiePath, $duration, false()) } -->
			</forward>
    </view>
  </dispatch>
else if ( contains($exist:path, "/$shared/") ) then
  <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    <forward url="{$exist:controller}/resources/{substring-after($exist:path, '/$shared/')}">
      <set-header name="Cache-Control" value="max-age=604800, must-revalidate"/>
    </forward>
  </dispatch>
else if ( ends-with($exist:path, ".xql") ) then
  <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    <!-- { login:set-user("wd", $cookiePath, $duration, false()) } -->
    <set-header name="Cache-Control" value="no-cache"/>
    <set-attribute name="app-root" value="{$exist:prefix}{$exist:controller}"/>
  </dispatch>
else
  (: everything else is passed through :)
  <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    <cache-control cache="yes"/>
    <set-header name="Cache-Control" value="max-age=604800, must-revalidate"/>
  </dispatch>
