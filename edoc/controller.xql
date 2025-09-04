(: wdb+ controller
 : based on the generic eXist-DB controller
 :
 : author: Dario Kampkaspar <dario.kampkaspar@ulb.tu-darmstadt.de>
 :)
xquery version "3.1";

import module namespace login   = "http://exist-db.org/xquery/login"           at "resource:org/exist/xquery/modules/persistentlogin/login.xql";
import module namespace request = "http://exist-db.org/xquery/request"         at "java:org.exist.xquery.functions.request.RequestModule";
(: import module namespace sm      = "http://exist-db.org/xquery/securitymanager" at "java:org.exist.xquery.functions.securitymanager.SecurityManagerModule";
import module namespace wdba    = "https://github.com/dariok/wdbplus/auth"     at "modules/auth.xqm"; :)

declare namespace exist = "http://exist.sourceforge.net/NS/exist";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;

declare variable $local:isget := request:get-method() = ("GET","get");

if ( contains($exist:path, 'api/v2') ) then
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
    <!-- { login:set-user("wd", $cookiePath, $duration, false()) } -->
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
