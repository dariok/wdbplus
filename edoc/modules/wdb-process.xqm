xquery version "3.1";

module namespace wdbProc = "https://github.com/dariok/wdbplus/Process";

import module namespace wdb = "https://github.com/dariok/wdbplus/wdb" at "app.xqm";

declare namespace meta = "https://github.com/dariok/wdbplus/wdbmeta";

declare function wdbProc:getContent ( $id as xs:string, $process as element(), $view as xs:string, $model as map(*) ) as map(*) {
  let $effectiveModel := map:merge((
        map:remove($model, ("id", "process", "view", "xslt")),
        map {
          "id": ($model?id, $id)[1],
          "process": ($model?process, $process)[1],
          "view": ($model?view, $view)[1],
          "xslt": ($model?xslt, $process)[1]
        }
      ))

  (: TODO if multiple commands are defined, check that one is actually applicable – #395 :)
  (: TODO pass the position of this command on to the processing function or pass target and view on :)
  (: TODO once dev on wdbmeta, -- steps -- is done, implement these here – #394:)
  return switch ( $process[1]/meta:command/@type )
    case "xsl" return
      let $content := wdbProc:processXSL($effectiveModel)
      return map { "status": $content?status, "content": $content?content }
    case "xquery" return
      let $content := wdbProc:processXQuery($effectiveModel)
      return map { "status": $content?status, "content": $content?content }
    default return
      map { "status": 500, "content": "Invalid command type " || ($process[1]/meta:command/@type, '?')[1] }
};

(: TODO: use parameter list as defined in app.xqm :)
(: TODO: inject additional parameters? :)
declare function wdbProc:processXSL ( $model as map(*) ) as map(*) {
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
            if ( $model?view != '' )
              then <param name="view" value="{$model?view}" />
              else ()
          }
          {
            if ($model?p != '')
              then <param name="p" value="{$model?p}" />
              else ()
          }
          <param name="xml" value="{$file}" />
          <param name="xsl" value="{normalize-space(($model?xslt)/meta:command)}" />
        </parameters>
      
  (: TODO: for multiple commands, we need recursion here :)
  return if ( not(sm:has-access($file, 'r')) )
    then map { "status": 403, "content": "File " || $file || " is not readable" }
    else map {
      "status": 200,
      "content": transform:transform(
          doc($file),
          doc(normalize-space(($model?xslt)/meta:command)),
          $params,
          $attr,
          ""
        )
    }
};

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
