xquery version "3.1";

import module namespace wdb = "https://github.com/dariok/wdbplus/wdb" at "modules/app.xql";

let $id := "edoc_wd_1703-08-20"

let $model := wdb:populateModel($id, "", map{})

    let $file := $model("fileLoc")
	let $xslt := $model("xslt")
	let $params :=
		<parameters>
			<param name="server" value="eXist"/>
			<param name="exist:stop-on-warn" value="no" />
			<param name="exist:stop-on-error" value="no" />
			<param name="projectDir" value="{$model('ed')}" />
			{
				if ($model("view") != '')
					then <param name="view" value="{$model("view")}" />
					else ()
			}
		</parameters>
	(: ambiguous rule match soll nicht zum Abbruch führen :)
	let $attr := <attributes><attr name="http://saxon.sf.net/feature/recoveryPolicyName" value="recoverSilently" /></attributes>
	
	let $re :=
		try { transform:transform(doc($file), doc($xslt), $params, $attr, "expand-xincludes=no") }
		catch * { 
			<report>
				<file>{$file}</file>
				<xslt>{$xslt}</xslt>
				{$params}
				{$attr}
				<error>{$err:code || ': ' || $err:description}</error>
				<error>{$err:module || '@' || $err:line-number ||':'||$err:column-number}</error>
				<additional>{$err:additional}</additional>
			</report>
		}

return ($model, $re)