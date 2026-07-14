(: wdb+ controller
 : based on the generic eXist-DB controller
 :
 : author: Dario Kampkaspar <dario.kampkaspar@ulb.tu-darmstadt.de>
 :)
xquery version "3.1";

import module namespace request = "http://exist-db.org/xquery/request" at "java:org.exist.xquery.functions.request.RequestModule";

declare namespace config = "https://github.com/dariok/wdbplus/config";
declare namespace exist  = "http://exist.sourceforge.net/NS/exist";
declare namespace meta = "https://github.com/dariok/wdbplus/wdbmeta";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;

declare variable $local:isget := request:get-method() = ("GET","get");
declare variable $local:config := doc("/db/apps/edoc/config.xml")/config:config;

(: util:log("info", "Request-Path: " || $exist:path || "; Resource: " || $exist:resource || "; Controller: " || $exist:controller || "; Prefix: " || $exist:prefix || "; Root: " || $exist:root), :)
(: util:log("info", request:get-method() || " " || request:get-url() || ' ? ' || request:get-query-string() || " → resource: " || $exist:resource), :)

(: static HTML page for API documentation should be served directly to make sure it is always accessible :)
if ( $local:isget and $exist:resource = ('v2.json', 'v2.html', 'v2.yaml') ) then
  <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    <forward url="{$exist:controller}/rest2/{$exist:resource}"/>
  </dispatch>

(: login :)
else if ( $exist:resource = 'login' ) then
  <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    <forward url="{$exist:controller}/rest2/api.xq">
      { 
        if ( $local:config//config:origin = request:get-header('origin') )
        then (
          <set-header name="Access-Control-Allow-Origin" value="{ request:get-header('origin') }" />,
          <set-header name="Access-Control-Allow-Headers" value="Authorization, Content-Type" />
        )
        else ()
      }
    </forward>
  </dispatch>
(: logout :)
else if ( $exist:resource = 'logout' ) then
  <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    <forward url="{$exist:controller}/rest2/api.xq">
      { 
        if ( $local:config//config:origin = request:get-header('origin') )
        then <set-header name="Access-Control-Allow-Origin" value="{ request:get-header('origin') }" />
        else ()
      }
    </forward>
  </dispatch>

(: REST API :)
else if ( contains($exist:path, 'api/v2') ) then
  <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    <forward url="{$exist:controller}/rest2/api.xq">
      {
        (: we currently need this workaround here as Jetty snatches all OPTIONS requests before they can be parsed by roaster :)
        if ( request:get-method() = ('options', 'OPTIONS') and $local:config//config:origin = request:get-header('origin') )
        then (
          <set-header name="Access-Control-Allow-Origin" value="{ request:get-header('origin') }" />,
          <set-header name="Access-Control-Allow-Methods" value="GET, PUT, POST, PATCH, OPTIONS, HEAD" />,
          <set-header name="Access-Control-Allow-Headers" value="Authorization, Content-Type" />,
          <set-header name="Access-Control-Allow-Credentials" value="true" />
        )
        else ()
      }
    </forward>
  </dispatch>

(: global index.html :)
else if ( $exist:resource eq '' or $exist:resource eq 'index.html' ) then
  <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    <forward url="{$exist:controller}/global/index.html"/>
  </dispatch>

(: admin pages :)
else if ( ends-with($exist:resource, ".html") and contains($exist:path, '/admin/') ) then
  <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    <view>
      <forward url="{$exist:controller}/admin/view.xql">
        <set-header name="Cache-Control" value="no-cache"/>
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
    <error-handler>
      <forward url="{$exist:controller}/templates/error-page.html" method="get"/>
      <forward url="{$exist:controller}/modules/view.xql"/>
    </error-handler>
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

else if ( ends-with($exist:path, ".xql") or ends-with($exist:path, ".xq") ) then
  <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    <set-header name="Cache-Control" value="no-cache"/>
    <set-attribute name="app-root" value="{$exist:prefix}{$exist:controller}"/>
  </dispatch>

  (: everything else is passed through :)
else
  <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
    <cache-control cache="yes"/>
    <set-header name="Cache-Control" value="max-age=604800, must-revalidate"/>
  </dispatch>
