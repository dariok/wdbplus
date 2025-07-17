xquery version "3.1";

module namespace wdbProc = "https://github.com/dariok/wdbplus/Process";

import module namespace wdb = "https://github.com/dariok/wdbplus/wdb" at "app.xqm";

declare namespace meta = "https://github.com/dariok/wdbplus/wdbmeta";

declare function wdbProc:getContent($id as xs:string, $process as element(), $view as xs:string, $model as map(*)) as item()* {
  (: TODO if multiple commands are defined, check that one is actually applicable – #395 :)
  (: TODO pass the position of this command on to the processing function or pass target and view on :)
  (: TODO once dev on wdbmeta, -- steps -- is done, implement these here – #394:)
  (: TODO this should be moved to a more generic location (e.g. common.xq) as it is also used in app.xqm :)
  let $type := $process[1]/meta:command/@type
  return if ($type = "xsl")
    then wdbProc:processXSL($id, $process, $model, $view)
    else if ($type = "xquery")
    then wdbProc:processXQuery($id, $process, $model)
    else (500, "Invalid command type " || $type)
};

(: TODO: move this functions to a more generic location (e.g. common.xq) as is should also be used from app.xqm :)
(: TODO: use parameter list as defined in app.xqm :)
(: TODO: inject additional parameters? :)
(: TODO: move this to a more generic location (e.g. common.xq) as it is also used in app.xqm :)
declare function wdbProc:processXSL( $id as xs:string, $process as element(), $model as map(*), $view as xs:string ) as item()* {
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
      ("error",
        $err:description,
        util:log("error", "Processing " || $id || ": " || $err:description))
    }
  
  return if ($content[1] = "error")
    then (500, $content[2])
    else (200, $content)
};

(: TODO: move this to a more generic location (e.g. common.xq) as it is also used in app.xqm :)
declare function wdbProc:processXQuery($id as xs:string, $process as element(), $model as map(*)) as item()* {
  let $function := $process/meta:command/text()
  return if (starts-with($function, 'http') or starts-with($function, '/'))
  then () (: TODO :)
  else
    let $fn := wdb:findProjectFunction($model, $function, 2)
    return if ($fn) then try {
      (200, wdb:eval($function || "($id, $process)", false(), (xs:QName("id"), $id, xs:QName("process"), $process)))
    } catch * {
      (500, $err:description)
    }
    else (500, "function " || $function || " not found")
};
