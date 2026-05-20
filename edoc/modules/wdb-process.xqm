xquery version "3.1";

module namespace wdbProc = "https://github.com/dariok/wdbplus/Process";

import module namespace wdb = "https://github.com/dariok/wdbplus/wdb" at "app.xqm";

declare namespace meta = "https://github.com/dariok/wdbplus/wdbmeta";
declare namespace xsl  = "http://www.w3.org/1999/XSL/Transform";

declare function wdbProc:process ( $input as node(), $commands as element(meta:command)+, $params as element(parameters) ) as map(*) {
  fold-left(
    $commands,
    $input,
    function ( $accumulator as node(), $command as element(meta:command) ) {
      switch ( $command/@type )
        case "xsl" return wdbProc:processXSL($accumulator, doc(normalize-space($command))/*, $params)
        (: TODO case "xquery" :)
        default
          return map { "status": 500, "content": "Invalid command type " || ($command/@type, '?')[1] }
    }
  )
};

declare function wdbProc:getContent ( $model as map(*) ) as map(*) {
  if ( not(sm:has-access($model?fileLoc, 'r')) ) then
    map { "status": 403, "content": "File " || $model?fileLoc || " is not readable" }
  else
    (: this is necessary to catch meta:struct with IDs (for a sub-corpus) :)
    let $file := if ( ends-with($model?fileLoc, 'wdbmeta.xml') )
          then $model?fileLoc || '#' || $model?id
          else $model?fileLoc
      , $input := doc($file)
      , $params :=
          <parameters>
            <param name="exist:stop-on-warn" value="no" />
            <param name="exist:stop-on-error" value="yes" />
            <param name="projectDir" value="{ $model?pathToEd }" />
            <param name="ed" value="{ $model?ed }" />
            {
              if ( exists($model?view) and $model?view != '' )
                then <param name="view" value="{ $model?view }" />
                else ()
            }
            {
              if ( exists($model?p) and $model?p != '' )
                then <param name="p" value="{ $model?p }" />
                else ()
            }
            <param name="xml" value="{ $file }" />
          </parameters>

    return try {
      let $content := wdbProc:process($input, $model?process/*, $params)
      return map { "status": $content?status, "content": $content?content }
    } catch * {
      map { "status": 500, "content": $err:description }
    }
  (: TODO if multiple commands are defined, check that one is actually applicable – #395 :)

};

(: TODO: use parameter list as defined in app.xqm :)
(: TODO: inject additional parameters? :)
declare function wdbProc:processXSL ( $node as node(), $xslt as element(xsl:stylesheet), $params as element(parameters) ) as map(*) {
  map {
    "status": 200,
    "content": transform:transform(
        $node,
        $xslt,
        $params,
        <attributes>
          <attr name="http://saxon.sf.net/feature/recoveryPolicyName" value="recoverSilently" />
        </attributes>,
        ""
      )
  }
};

(: TODO: this needs to be rewritten as wdbProc:process will not hand over a model :)
declare function wdbProc:processXQuery ( $model as map(*) ) as map(*) {
  let $function := $model?process/meta:command/text()

  return if ( starts-with($function, 'http') or starts-with($function, '/') )
    then () (: TODO :)
    else if ( wdb:findProjectFunction($model, $function, 2) ) then
      try {
        map {
          "status": 200,
          "content": wdb:eval($function || "($id, $process)", false(), (xs:QName("id"), $model?id, xs:QName("process"), $model?process))
        }
      } catch * {
        map { "status": 500, "content": $err:description }
      }
    else
      map { "status": 500, "content": "function " || $function || " not found" }
};
