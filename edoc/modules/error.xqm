xquery version "3.1";

module namespace wdbErr = "https://github.com/dariok/wdbplus/errors";

import module namespace templates = "http://exist-db.org/xquery/html-templating" at "/db/system/repo/templating-1.0.2/content/templates.xqm";
import module namespace response  = "http://exist-db.org/xquery/response"        at "java:org.exist.xquery.functions.response.ResponseModule";
import module namespace map       = "http://www.w3.org/2005/xpath-functions/map" at "java:org.exist.xquery.functions.map.MapModule";
import module namespace console   = "http://exist-db.org/xquery/console";
import module namespace functx    = "http://www.functx.com"                      at "/db/system/repo/functx-1.0.1/functx/functx.xq";


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

  return (
    console:log($error),
    response:set-status-code(418),
    <head>
      <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
      <meta name="wdb-template" content="(error page)" />
      <title>ERROR</title>
      <link rel="stylesheet" type="text/css" href="$shared/css/wdb.css" />
      <link rel="stylesheet" type="text/css" href="$shared/css/function.css" />
      <script src="https://code.jquery.com/jquery-3.5.1.min.js" />
      <script src="resources/scripts/function.js"/>
    </head>,
    <body>
      <div>
        <h1>Something has gone wrong...</h1>
        <p>{$error}</p>
        { wdbErr:get(map:merge(($data, map:entry("user", sm:id()))), '') }
      </div>
    </body>
  )
};

declare function wdbErr:get ( $test as item()*, $prefix as xs:string* ) {
  typeswitch ($test)
    case array(*) return
      for $n in (1 to array:size($test)) return
        wdbErr:get($test($n), $prefix || ' → [' || $n || ']')
    case map(*) return
      for $key in map:keys($test) return
      try {  
        if ($test($key) instance of map(*))
          then wdbErr:get($test($key), string-join(($prefix, $key), ' → '))
        else if ($test($key) instance of function(*))
          then (<dt>{string-join(($prefix, $key), ' → ')}</dt>, <dd>{function-name($test($key))}#{function-arity($test($key))}</dd>)
        else if ($test($key) instance of xs:string or $test($key) instance of xs:boolean)
          then wdbErr:get($test($key), string-join(($prefix, $key), ' → '))
        else (<dt>{string-join(($prefix, $key), ' → ')}</dt>, <dd>{functx:atomic-type($test($key))}</dd>)
      } catch * {
        functx:atomic-type($key) || " - " || functx:atomic-type($prefix)
      }
    case element(*) return
      (<dt>{string-join(($prefix, "element(" || local-name($test) || ")"), ' → ')}</dt>, <dd>{normalize-space($test)}</dd>)
    default return (<dt>{$prefix}</dt>, <dd>{$test}</dd>)
};
