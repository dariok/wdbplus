xquery version "3.0";

module namespace wdb = "https://github.com/dariok/wdbplus/wdb";

import module namespace templates	= "http://exist-db.org/xquery/templates" ;
import module namespace console 	= "http://exist-db.org/xquery/console";
import module namespace xstring		= "https://github.com/dariok/XStringUtils"		at "../include/xstring/string-pack.xql";
import module namespace wdbErr		= "https://github.com/dariok/wdbplus/errors"	at "error.xqm";
import module namespace xConf			= "http://exist-db.org/xquery/apps/config"	at "config.xqm";

declare namespace mets	    = "http://www.loc.gov/METS/";
declare namespace mods	    = "http://www.loc.gov/mods/v3";
declare namespace xlink	    = "http://www.w3.org/1999/xlink";
declare namespace tei	    = "http://www.tei-c.org/ns/1.0";
declare namespace main	    = "https://github.com/dariok/wdbplus";
declare namespace meta	    = "https://github.com/dariok/wdbplus/wdbmeta";
declare namespace wdbPF     = "https://github.com/dariok/wdbplus/projectFiles";
declare namespace config	= "https://github.com/dariok/wdbplus/config";

(: VARIABLES :)

(: get the base of this instance within the db (i.e. relative to /db) :)
declare variable $wdb:edocBaseDB := $xConf:app-root;

(: the config file :)
declare variable $wdb:configFile := doc($wdb:edocBaseDB || '/config.xml');

(: the data collection :)
declare variable $wdb:data := wdb:getDataCollection();

(: get the name of the server, possibly including the port
	: Admins REALLY SHOULD NOT rely on the resolution but set the
	: value in config.xml instead :)
declare variable $wdb:server :=
	if ($wdb:configFile//config:server) then
		$wdb:configFile//config:server
	else if (string-length(request:get-header("Origin")) = 0)
		then 
			let $scheme := if (request:get-header-names() = 'X-Forwarded-Proto')
				then normalize-space(request:get-header('X-Forwarded-Proto'))
				else normalize-space(request:get-scheme())
			
			return if ( request:get-server-port() != 80 )
				then $scheme || '://' || request:get-server-name() || ':' || request:get-server-port()
				else $scheme || '://' || request:get-server-name()
		else request:get-header("Origin")
;

(:~
 : get the base URI either from the data of the last call or from the configuration
 :)
declare variable $wdb:edocBaseURL :=
	if ( $wdb:configFile//config:server )
	then normalize-space($wdb:configFile//config:server)
	else
		let $dir := string-join(tokenize(normalize-space(request:get-uri()), '/')[not(position() = last())], '/')
		let $url := substring-after($wdb:edocBaseDB, 'db/')
		let $local := xstring:substring-after($dir, $url)
		let $path := if (string-length($local) > 0)
		    then xstring:substring-before($dir, $local) (: there is a local part, e.g. 'admin' :)
		    else $dir (: no local part, e.g. for view.html in app root :)
		
		return $wdb:server || $path
;


(: the server role :)
declare variable $wdb:role :=
	if ($wdb:configFile//main:role/main:type != '')
		then $wdb:configFile//main:role/main:type
		else "standalone"
;

(: the peer :)
declare variable $wdb:peer :=
	if ($wdb:role != "standalone")
		then $wdb:configFile//main:role/main:peer
		else ""
;

(:~
 : Templating function; called from layout.html
:)
declare %templates:wrap %templates:default("view", "")
function wdb:getEE($node as node(), $model as map(*), $id as xs:string, $view as xs:string) { (:as map(*) {:)
	wdb:populateModel($id, $view, $model)
};

(:~
 : Populate the model with the most important global settings when displaying a file
 : 
 : @param $id the id for the file to be displayed
 : @param $view a string to be passed to the processing XSLT
 : @return a map; in case of debugging, a list
 :)
declare function wdb:populateModel($id as xs:string, $view as xs:string, $model as map(*)) { (:as map(*) {:)
	try {
		let $pathToFile := wdb:getFilePath($id)
			
		let $pathToEd := wdb:getEdPath($pathToFile, true())
		let $pathToEdRel := substring-after($pathToEd, $wdb:edocBaseDB||'/')
		
		(: The meta data are taken from wdbmeta.xml or a mets.xml as fallback :)
		let $infoFileLoc := if (doc-available($pathToEd||'/wdbmeta.xml'))
			then $pathToEd || '/wdbmeta.xml'
			else if (doc-available($pathToEd || '/mets.xml'))
			then $pathToEd || '/mets.xml'
			else fn:error(fn:QName('https://github.com/dariok/wdbErr', 'wdbErr:wdb0003'))
		
		let $xsl := if (ends-with($infoFileLoc, 'wdbmeta.xml'))
			then local:getXslFromWdbMeta($pathToEdRel, $id, 'html')
			else local:getXslFromMets($infoFileLoc, $id, $pathToEdRel)
		
		let $xslt := if (doc-available($xsl))
			then $xsl
			else if (doc-available($pathToEd || '/' || $xsl))
			then $pathToEd || '/' || $xsl
			else fn:error(fn:QName('https://github.com/dariok/wdbErr', 'wdbErr:wdb0002'), "no XSLT", <value><label>XSLT</label><item>{$xsl}</item></value>)
		
		let $title := normalize-space((doc($pathToFile)//tei:title)[1])
			
		(: TODO parameter aus config.xml einlesen und übergeben? :)
		let $map := map { "fileLoc" := $pathToFile, "xslt" := $xslt, "ed" := $pathToEdRel, "infoFileLoc" := $infoFileLoc,
		  "title" := $title, "id" := $id, "view" := $view, "pathToEd" := $pathToEd }
		let $t := console:log($map)
		
		return $map
	}
	catch * {
		wdbErr:error(map {"code" := $err:code, "pathToEd" := $wdb:data, "ed" := $wdb:data, "model" := $model, "value" := $err:value })
	}
};

(: ~
 : Create the head for HTML files served via the templating system
 : @created 2018-02-02 DK
 :)
declare function wdb:getHead ( $node as node(), $model as map(*) ) {
    <head>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
		<!-- Kurztitel als title; 2016-05-24 DK -->
		<meta name="wdb-template" content="templates/layout.html" />
		<meta name="id" content="{$model('id')}"/>
		<meta name="path" content="{$model('fileLoc')}"/>
		<title>{normalize-space($wdb:configFile//main:short)} – {$model("title")}</title>
		<!-- this is used in /view.html, so the rel. path does not start with '..'! -->
		<link rel="stylesheet" type="text/css" href="{$wdb:edocBaseURL}/resources/css/main.css" />
		<link rel="stylesheet" type="text/css" href="{$wdb:edocBaseURL}/resources/css/common.css" />
		<link rel="stylesheet" type="text/css" href="{$wdb:edocBaseURL}/resources/scripts/jquery-ui/jquery-ui.min.css" />
		{wdb:getProjectFiles($node, $model, 'css')}
		<script src="{$wdb:edocBaseURL}/resources/scripts/jquery.min.js" />
		<script src="{$wdb:edocBaseURL}/resources/scripts/jquery-ui/jquery-ui.min.js" />
		<script src="{$wdb:edocBaseURL}/resources/scripts/js.cookie.js" />
		<script src="{$wdb:edocBaseURL}/resources/scripts/function.js" />
		{wdb:getProjectFiles($node, $model, 'js')}
	</head>
};

(:~
 : Try ro load project specific XQuery to import CSS and JS
 : @created 2018-02-02 DK
 :)
declare function wdb:getProjectFiles ( $node as node(), $model as map(*), $type as xs:string ) as node()* {
	let $files := if (wdb:findProjectFunction($model, 'getProjectFiles', 1))
		then util:eval("wdbPF:getProjectFiles($model)", false(), (xs:QName('map'), $model)) 
		else
			(: no specific function available, so we assume standards :)
			(
				<link rel="stylesheet" type="text/css" href="{$wdb:edocBaseURL}/{$model('ed')}/scripts/project.css" />,
				<script src="{$wdb:edocBaseURL}/{$model('ed')}/scripts/project.js" />
			)
		
	return if ($type = 'css')
		then $files[self::*:link]
		else $files[self::*:script]
};

(:~
 : return the header - if there is a project specific function, use it
 :)
declare function wdb:getHeader ( $node as node(), $model as map(*) ) {
	let $functionAvailable := if (wdb:findProjectFunction($model, 'getHeader', 1))
    	then system:function-available(xs:QName("wdbPF:getHeader"), 1)
    	else false()
    
    return
    	<header>{
    		if ($functionAvailable = true())
    			then util:eval("wdbPF:getHeader($model)", false(), (xs:QName('map'), $model))
    			else
    				<h1>{$model("title")}</h1>
    		}
    		<span class="dispOpts">[<a id="searchLink" href="search.html?ed={$model("ed")}">Suche</a>]</span>
    		<span class="dispOpts">[<a id="showNavLink" href="javascript:toggleNavigation();">Navigation
					einblenden</a>]</span>
    		<hr/>
    		<nav style="display:none;" />
    	</header>
};

(:~
 : return the body
 :)
declare function wdb:getContent($node as node(), $model as map(*)) {
	(: von populateModel wird jetzt der komplette Pfad übergeben; 2017-05-22 DK :)
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
		catch * { (console:log(
			<report>
				<file>{$file}</file>
				<xslt>{$xslt}</xslt>
				{$params}
				{$attr}
				<error>{$err:code || ': ' || $err:description}</error>
				<error>{$err:module || '@' || $err:line-number ||':'||$err:column-number}</error>
				<additional>{$err:additional}</additional>
			</report>),
			wdbErr:error(map{"code" := "wdbErr:wdb1001", "model" := $model, "additional" := $params}))
		}
	
	return 
		<div id="wdbContent">
			{$re}
			{wdb:getFooter($file, $xslt)}
		</div>
};

(: Finden der korrekten behavior
 : $test: zu bewertende mets:behavior
 : $seqStruct: sequence von mets:div/@ID, spezifischste zuletzt
 : $type: gesuchter Ausgabetyp
 : returns: einen gewichteten Wert für den Rang der behavior :)
declare %private function local:val($test, $seqStruct, $type) {
    let $vIDt := for $s at $i in $seqStruct
        return if (matches($test/@STRUCTID, concat('(^| )', $s, '( |$)')))
            then math:exp10($i)
            else 0
    let $vID := fn:max($vIDt)
    let $vS := if ($test[@BTYPE = $type])
        then 5
        else if ($test[@LABEL = $type])
        then 3
        else if ($test[@ID = $type])
        then 1
        else 0
    
    return $vS + $vID
};

declare function wdb:pageTitle($node as node(), $model as map(*)) {
	let $ti := $model("title")
	return <title>{normalize-space($wdb:configFile//main:short)} – {$ti}</title>
};

(: Den Instanznamen ausgeben :)
declare function wdb:getInstanceName($node as node(), $model as map(*)) {
	<h1>{normalize-space(doc('../config.xml')//main:meta/main:name)}</h1>
};

(: Den Kurznamen ausgeben :)
declare function wdb:getInstanceShort($node as node(), $model as map(*)) {
	<span>{normalize-space(doc('../config.xml')//main:meta/main:short)}</span>
};

(: die vollständige URL zu einer Resource auslesen :)
declare function wdb:getUrl ( $path as xs:string ) as xs:string {
	$wdb:edocBaseURL || substring-after($path, $wdb:edocBaseDB)
};

declare %private function local:getXslFromMets ($metsLoc, $id, $ed) {
	(: Das XSLT finden :)
	(: Die Ausgabe sollte hier in Dokumentreihenfolge erfolgen und innerhalb der sequence stabil sein;
	 : damit ist die »spezifischste« ID immer die letzte :)
	let $mets := doc($metsLoc)
	let $metsfile := $mets//mets:file[@ID=$id]
	let $structs := $mets//mets:div[mets:fptr[@FILEID=$id]]/ancestor-or-self::mets:div/@ID
	(: Die behavior stehen hier in einer nicht definierten Reihenfolge (idR Dokumentreihenfolge, aber nicht zwingend) :)
	let $be := for $s in $structs
		return $mets//mets:behavior[matches(@STRUCTID, concat('(^| )', $s, '( |$)'))]
	let $behavior := for $b in $be
		order by local:val($b, $structs, 'HTML')
		return $b
	let $trans := $behavior[position() = last()]/mets:mechanism/@xlink:href
	return concat($wdb:edocBaseDB, '/', $ed, '/', $trans)
};

(:~
 : Evaluate wdbmeta.xml to get the process used for transformation
 :
 : @param $ed The (relative) path to the project
 : @param $id The ID of the file to be processed
 : @param $target The processing target to be used
 :
 : @returns The path to the XSLT
:)
declare %private function local:getXslFromWdbMeta($ed as xs:string, $id as xs:string, $target as xs:string) {
	let $metaFile := $wdb:edocBaseDB || '/' || $ed || '/wdbmeta.xml'
	let $fil := doc($metaFile)
	
	let $process := if (not(doc($metaFile)//meta:process[@target = $target]))
		then
			(: no process for this target: use first process :)
			doc($metaFile)//meta:process[1]
		else doc($metaFile)//meta:process[@target = $target]
	
	let $sel := for $c in $process/meta:command
		return if ($c/@refs)
			then
				(: if a list of IDREFS is given, this command matches if $id is part of that list :)
				let $map := tokenize($c/@refs, ' ')
				return if ($map = $id)
					then $c
					else ()
			else if ($c/@regex and matches($id, $c/@regex))
				(: if a regex is given and $id matches that regex, the command matches :)
				then $c
			else if (not($c/@refs or $c/@regex))
				(: if no selection method is given, the command is considered the default :)
				then $c
				else () (: neither refs nor regex match and no default given :)
	
	(: As we check from most specific to default, the first command in the sequence is the right one :)
	return $sel[1]/text()
};

(:~
	: Return the (relative) path to the project
	:
	: @param $path a path to a file within the project, usually wdbmeta.xml or mets.xml
	: @param $absolute (optional) if true(), return an absolute URL
	:
	: @returns the path (relative) to the app root
	:)
declare function wdb:getEdPath($path as xs:string, $absolute as xs:boolean) as xs:string {
	let $tok := tokenize(xstring:substring-after($path, $wdb:edocBaseDB||'/'), '/')
	
	let $pa := for $i in 1 to count($tok)
		let $t := $wdb:edocBaseDB || '.*' || string-join ($tok[position() < $i+1], '/')
		return xmldb:match-collection($t)
	
	let $path := if (count($pa) = 0) then wdbErr:error(map{"code" := "wdbErr:wdb2001", "additional" := <additional><path>{$path}</path></additional>})
	else for $p in $pa
		order by string-length($p) descending
		let $p1 := $p || '/wdbmeta.xml'
		let $p2 := $p || '/mets.xml'
		return if (doc-available($p1) or doc-available($p2)) then $p else ()
	
	return if ($absolute)
		then $path[1]
		else substring-after($path[1], $wdb:edocBaseDB||'/')
};

(:~
	: Return the relative path to the project
	:
	: @param $path a path to a file within the project, usually wdbmeta.xml or mets.xml
	: @return the path relative to the app root
	:)
declare function wdb:getEdPath($path as xs:string) as xs:string {
	wdb:getEdPath($path, false())
};

declare function wdb:getFooter($xm as xs:string, $xs as xs:string) {
	let $xml := if (starts-with($xm, 'http'))
		then $xm
		else wdb:getUrl($xm)
	let $xsl := if (starts-with($xs, 'http'))
		then $xs
		else wdb:getUrl($xs)
	
	return
		<footer>
			<span>XML: <a href="{$xml}">{$xml}</a></span>
			<span>XSL: <a href="{$xsl}">{$xsl}</a></span>
		</footer>
};

(:~
 : Try to get the data collection. Documentation explicitly tells users to have a wdbmeta.xml
 : in the Collection that contains all projects
 :)
declare function wdb:getDataCollection () {
	let $editionsW := collection($wdb:edocBaseDB)//meta:projectMD
	
	let $paths := for $f in $editionsW
    	let $path := base-uri($f)
    	where contains($path, '.xml')
    	order by string-length($path)
    	return $path
    
    return replace(xstring:substring-before-last($paths[1], '/'), '//', '/')
};

(:~ 
 : Look up $function the given project's project.xqm if it exists
 : This involves registering the module: if the function is available, it can
 : immediately be used by the calling script if this lookup is within the caller's scope
 : The scope is the project as given in $model("pathToEd")
 : 
 : @param $model a map of parameters that conforms to the global structure
 : @param $name the (local) name of the function to be looked for
 : @param $arity the arity (i.e. number of arguments) of said function
 : @return true() if project.xqm exists for the project and contains a function
 : with the given parameters; else() otherwise.
 :)
declare function wdb:findProjectFunction ($model as map(*), $name as xs:string, $arity as xs:integer) as xs:boolean {
	let $location := $model("pathToEd") || '/project.xqm'
	
	return if (not(util:binary-doc-available($location)))
		then false()
		else
			let $module := util:import-module(xs:anyURI("https://github.com/dariok/wdbplus/projectFiles"), 'wdbPF', $location)
			return system:function-available(xs:QName("wdbPF:" || $name), $arity)
};

(:~
 : Return the full URI to the (edition) XML file with the given ID
 : The scope is the whole data collection; documentation states in several places that file IDs need to be unique
 :
 : @param $id as xs:string: the file ID
 : @return xs:string the full URI to the file within the database
 :)
declare function wdb:getFilePath($id as xs:string) as xs:string {
(: Wegen des Aufrufs aus pquery nur mit Nr. hier prüfen; 2017-03-27 DK :)
		(: Das wird vmtl. verändert werden müssen. Ggf. auslagern für queries :)
		let $files := collection($wdb:edocBaseDB)/id($id)
		
		let $pathToFile := if (count($files) = 0)
			then fn:error(fn:QName('https://github.com/dariok/wdbErr', 'wdb0000'))
			else if (count($files[not(namespace-uri() = "https://github.com/dariok/wdbplus/wdbmeta")]) > 1)
			then fn:error(fn:QName('https://github.com/dariok/wdbErr', 'wdb0001'))
			else if (count($files[not(namespace-uri() = "https://github.com/dariok/wdbplus/wdbmeta")]) = 1)
			then base-uri($files[not(namespace-uri() = "https://github.com/dariok/wdbplus/wdbmeta")])
			else if (count($files[namespace-uri() = "https://github.com/dariok/wdbplus/wdbmeta"]) = 1)
			(: do we need to add a check and error if the xml:id is found twice in wdbmeta.xml? :)
			then
				let $p := base-uri($files[1])
				return substring-before($p, 'wdbmeta.xml') || $files[1]/@path
			else fn:error(fn:QName('https://github.com/dariok/wdbErr', 'wdb0000'), "no file with given @xml:id and no fallback")
			
		return $pathToFile
};