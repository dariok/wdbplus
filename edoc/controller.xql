xquery version "3.0";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;

if ($exist:path eq '') then
    <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect url="{request:get-uri()}/"/>
    </dispatch>
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
			<forward url="{$exist:controller}/modules/view.xql"/>
		</error-handler>
	</dispatch>
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
(:  :else if (ends-with($exist:path, '.xql')) then
	<dispatch  xmlns="http://exist.sourceforge.net/NS/exist">
		<forward servlet="XQueryServlet" />
	</dispatch>:)
else
	(: everything else is passed through :)
	<dispatch xmlns="http://exist.sourceforge.net/NS/exist">
		<cache-control cache="yes"/>
	</dispatch>