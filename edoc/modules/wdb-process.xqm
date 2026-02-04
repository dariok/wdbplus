xquery version "3.1";

module namespace wdbProc = "https://github.com/dariok/wdbplus/Process";

import module namespace wdb = "https://github.com/dariok/wdbplus/wdb" at "app.xqm";

declare namespace meta = "https://github.com/dariok/wdbplus/wdbmeta";

declare function wdbProc:getContent ( $id as xs:string, $process as element(), $view as xs:string, $model as map(*) ) as map(*) {
  (: TODO if multiple commands are defined, check that one is actually applicable – #395 :)
  (: TODO pass the position of this command on to the processing function or pass target and view on :)
  (: TODO once dev on wdbmeta, -- steps -- is done, implement these here – #394:)
  switch ( $process[1]/meta:command/@type )
    case "xsl" return
      let $content := wdbProc:processXSL($id, $process, $model, $view)
      return map { "status": $content?status, "content": $content?content }
    case "xquery" return
      let $content := wdbProc:processXQuery($id, $process, $model)
      return map { "status": $content?status, "content": $content?content }
    default return
      map { "status": 500, "content": "Invalid command type " || ($process[1]/meta:command/@type, '?')[1] }
};

(: TODO: use parameter list as defined in app.xqm :)
(: TODO: inject additional parameters? :)
declare function wdbProc:processXSL ( $id as xs:string, $process as element(), $model as map(*), $view as xs:string ) as map(*) {
  let $content := try {
    (: this is necessary to catch meta:struct with IDs (for a sub-corpus) :)
    let $file := if ( ends-with($model?fileLoc, 'wdbmeta.xml') )
      then $model?fileLoc || '#' || $model?id
      else $model?fileLoc

    (: do not stop transformation on ambiguous rule match and similar warnings :)
    let $attr :=
        <attributes>
          <attr name="http://saxon.sf.net/feature/recoveryPolicyName" value="recoverSilently" />
        </attributes>
      , $params :=
          <parameters>
            <param name="exist:stop-on-warn" value="no" />
            <param name="exist:stop-on-error" value="no" />
            <param name="projectDir" value="{$model?pathToEd}" />
            <param name="ed" value="{$model?ed}" />
            {
              if ( $view != '' )
                then <param name="view" value="{$view}" />
                else ()
            }
            {
              if ($model?p != '')
                then <param name="p" value="{$model?p}" />
                else ()
            }
            <param name="xml" value="{$file}" />
            <param name="xsl" value="{normalize-space($process/meta:command)}" />
          </parameters>
      
      (: TODO: for multiple commands, we need recursion here :)
      return transform:transform(doc($file),
          doc(normalize-space($process/meta:command)),
          $params,
          $attr,
          ""
        )
  } catch * {
    (
      500,
      $err:description,
      util:log("error", "Processing " || $id || ": " || $err:description)
    )
  }
  
  return if ( $content[1] = "error" )
    then map { "status": $content[1], "content": $content[2] }
    else map { "status": 200, "content": $content }
};

declare function wdbProc:processXQuery ( $id as xs:string, $process as element(), $model as map(*) ) as map(*) {
  let $function := $process/meta:command/text()

  return if ( starts-with($function, 'http') or starts-with($function, '/') )
    then () (: TODO :)
    else if ( wdb:findProjectFunction($model, $function, 2) ) then
      try {
        map {
          "status": 200,
          "content": wdb:eval($function || "($id, $process)", false(), (xs:QName("id"), $id, xs:QName("process"), $process))
        }
      } catch * {
        map { "status": 500, "content": $err:description }
      }
    else
      map { "status": 500, "content": "function " || $function || " not found" }
};
