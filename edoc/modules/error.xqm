xquery version "3.1";

module namespace wdbErr    = "https://github.com/dariok/wdbplus/errors";

import module namespace templates = "http://exist-db.org/xquery/templates";
import module namespace console   = "http://exist-db.org/xquery/console";

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
    case "wdbErr:wdb0004"
    case "wdb0004" return "The requested file is not readable by the current user."
    case "wdbErr:wdb0200"
    case "wdb0200" return "Project not found."
    case "wdbErr:wdb1001"
    case "wdb1001" return "An error occurred while applying the transformation."
    case "wdbErr:wdb2001" return "Module not found."
    case "wdbErr:wdb2002" return "Error executing wdbq:query($map as map(*))"
    case "wdbErr:wdb2101" return "Module not found for addin."
    case "wdbErr:wdb2102" return "Error executing wdbadd:main($map as map(*))"
    case "wdbErr:wdb3001" return "Error creating model in function.xqm"
    default return "An unknown error has occurred: " || $data("code")

  let $content :=
    <div id="content" data-template="templates:surround" data-template-with="templates/error.html" data-template-at="container">
      <h1>Something has gone wrong...</h1>
        <p>{$error}</p>
        {wdbErr:get($data, '')}
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
    <link rel="stylesheet" type="text/css" href="resources/css/wdb.css" />
    <link rel="stylesheet" type="text/css" href="resources/css/function.css" />
    <!-- this one is being called from app root, so no ..! -->
    <script src="https://code.jquery.com/jquery-3.4.1.min.js" />
    <script src="resources/scripts/function.js"/>
  </head>,
  templates:process($content, $data("model"))
  )
};

declare function wdbErr:get($map as map(*), $prefix as xs:string) {
  for $key in map:keys($map)
      let $pr := if ($prefix = "") then $key else $prefix || ' → ' || $key
    return try {
      let $s := map:size($map($key))
      return wdbErr:get($map($key), $pr)
    } catch * {
      let $value := try { xs:string($map($key)) } catch * { "err" }
      return <p><b>{$pr}: </b> {$value}</p>
    }
};