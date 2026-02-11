(: wdb+ controller
 : based on the generic eXist-DB controller
 :
 : author: Dario Kampkaspar <dario.kampkaspar@ulb.tu-darmstadt.de>
 :)
xquery version "3.1";

import module namespace login      = "http://exist-db.org/xquery/login"          at "resource:org/exist/xquery/modules/persistentlogin/login.xql";
import module namespace request    = "http://exist-db.org/xquery/request"        at "java:org.exist.xquery.functions.request.RequestModule";
import module namespace wdbRequest = "https://github.com/dariok/wdbplus/Request" at "modules/wdb-request.xqm";

declare namespace config = "https://github.com/dariok/wdbplus/config";
declare namespace exist  = "http://exist.sourceforge.net/NS/exist";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
(: declare variable $exist:root external; :)

declare variable $local:isget := request:get-method() = ("GET","get");
declare variable $local:config := doc("/db/apps/edoc/config.xml")/config:config;

util:log("info", request:get-method() || " " || request:get-url() || ' ? ' || request:get-query-string() || " -> resource: " || $exist:resource),

(: static HTML page for API documentation should be served directly to make sure it is always accessible :)
if (
    ( $local:isget and $exist:resource = ('v2.json', 'apiv2.html') )
) then
  <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    <forward url="{$exist:controller}/rest2/{$exist:resource}"/>
  </dispatch>
(: login :)
else if ( $exist:resource = 'login' ) then
  <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    <forward url="{$exist:controller}/rest2/api.xq"/>
  </dispatch>
(: logout :)
else if ( $exist:resource = 'logout' ) then
  <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    <forward url="{$exist:controller}/rest2/api.xq">
      <add-parameter name="logout" value="logout" />
    </forward>
  </dispatch>
(: REST API :)
else if ( contains($exist:path, 'api/v2') ) then
  <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    <forward url="{$exist:controller}/rest2/api.xq">
      {
        (: we need to do some manual work here as eXist only parses multipart content for PIST requests, not for PUT
        : In order for PUT or PATCH to work though roaster, we need to set the request parameters here, taking them
        : from the multipart content :)
        if ( request:get-method() = ("PUT", "put", "PATCH", "patch")
            and starts-with(request:get-header('Content-Type'), "multipart/form-data" ) ) then
          let $parsed := wdbRequest:parseMultipart(request:get-data(), request:get-header('Content-Type'))
          return
            for $entry in map:keys($parsed)
              return <add-parameter name="{$entry}" value="{$parsed($entry)?body}"/>
        else ()
      }
    </forward>
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
        {
          for $header in $local:config//config:header
            return <set-header>{ $header/@* }</set-header>
        }
      </forward>
    </view>
  </dispatch>
  (: generic resources :)
  else if ( contains($exist:path, "/$shared/") ) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
      <forward url="{$exist:controller}/resources/{substring-after($exist:path, '/$shared/')}">
        {
          for $header in $local:config//config:header
            return <set-header>{ $header/@* }</set-header>
        }
      </forward>
    </dispatch>
  (: instance specific resources :)
  else if ( contains($exist:path, "/$global/") ) then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
      <forward url="{$exist:controller}/data/resources/{substring-after($exist:path, '/$global/')}">
        {
          for $header in $local:config//config:header
            return <set-header>{ $header/@* }</set-header>
        }
      </forward>
    </dispatch>
else if ( ends-with($exist:path, ".xql") ) then
  <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    <set-header name="Cache-Control" value="no-cache"/>
    <set-attribute name="app-root" value="{$exist:prefix}{$exist:controller}"/>
  </dispatch>
else
  (: everything else is passed through :)
  <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    <cache-control cache="yes"/>
    <set-header name="Cache-Control" value="max-age=604800, must-revalidate"/>
  </dispatch>
