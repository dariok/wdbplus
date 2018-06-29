xquery version "3.1";

module namespace wdbErr		= "https://github.com/dariok/wdbErr";

import module namespace templates	= "http://exist-db.org/xquery/templates"		at "templates.xql";
import module namespace wdb			= "https://github.com/dariok/wdbplus/wdb"		at "app.xql";

declare function wdbErr:error ($data as map (*)) {
	let $error := switch (xs:string($data("code")))
		case "wdbErr:wdb0000" return "Keine Datei zu dieser ID gefunden"
		case "wdbErr:wdb0001" return "Zu viele Dateien zu dieser ID gefunden"
		default return "Ein unbekannter Fehler ist aufgetreten: " || $data("code")

	let $content :=
			<div id="content" data-template="templates:surround" data-template-with="templates/error.html" data-template-at="container">
				<h1>Es ist leider ein Fehler aufgetreten</h1>
			    <p>{$error}</p>
			    <p>{$data("additional")}</p>
			    <p>{$data("pathToEd")}</p>
			</div>  
	
	let $lookup := function($functionName as xs:string, $arity as xs:int) {
	    try {
	        function-lookup(xs:QName($functionName), $arity)
	    } catch * {
	        ()
	    }
	}
	
	return (
	<head>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
		<meta name="wdb-template" content="(error page)" />
		<title>ERROR</title>
		<link rel="stylesheet" type="text/css" href="resources/css/main.css" />
		<!-- this one is being called from app root, so no ..! -->
		<script src="resources/scripts/jquery.min.js"/>
		<script src="resources/scripts/function.js"/>
	</head>,
	templates:process($content, $data("model"))
	)
};