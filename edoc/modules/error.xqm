xquery version "3.1";

module namespace wdbErr		= "https://github.com/dariok/wdbplus/errors";

import module namespace templates	= "http://exist-db.org/xquery/templates";
import module namespace console 	= "http://exist-db.org/xquery/console";

declare function wdbErr:error ($data as map (*)) {
	let $error := switch (xs:string($data("code")))
		case "wdbErr:wdb0000"
		case "wdb0000" return "No file could be found for the ID supplied in the request."
		case "wdbErr:wdb0001"
		case "wdb0001" return "Multiple files were found for the ID supplied. Unable to determine which one to display."
		case "wdbErr:wdb0002"
		case "wdb0002" return "No transformation was found to display the file."
		case "wdbErr:wdb0003"
		case "wdb0003" return "No metadata file could be found for the project."
		case "wdbErr:wdb1001"
		case "wdb1001" return "An error occurred while applying the transformation."
		default return "An unknown error has occurred: " || $data("code")

	let $content :=
		<div id="content" data-template="templates:surround" data-template-with="templates/error.html" data-template-at="container">
			<h1>Something has gone wrong...</h1>
		    <p>{$error}</p>
		    <p>{$data("additional")}</p>
		    <p>{$data("pathToEd")}</p>
		    {
		    let $model := $data('model')
		    return for-each(map:keys($model), function($key) {
		            <p><b>{$key}:</b> {$data($key)}</p>
		        })
		    }
		    <p><b>{$data("value")//label}:</b> {$data('value')//item}</p>
		</div>
	
	let $lookup := function($functionName as xs:string, $arity as xs:int) {
	    try {
	        function-lookup(xs:QName($functionName), $arity)
	    } catch * {
	        ()
	    }
	}
	
	let $t := console:log($error)
	
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