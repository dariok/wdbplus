xquery version "3.0";

module namespace wdbPL = "https://github.com/dariok/wdbplus/ProjectList";

import module namespace sm      = "http://exist-db.org/xquery/securitymanager";
import module namespace wdb     = "https://github.com/dariok/wdbplus/wdb"    at "../modules/app.xqm";
import module namespace wdbs    = "https://github.com/dariok/wdbplus/stats"  at "../modules/stats.xqm";
import module namespace xstring = "https://github.com/dariok/XStringUtils"   at "../include/xstring/string-pack.xql";

declare namespace config = "https://github.com/dariok/wdbplus/config";
declare namespace meta   = "https://github.com/dariok/wdbplus/wdbmeta";
declare namespace mets   = "http://www.loc.gov/METS/";
declare namespace tei    = "http://www.tei-c.org/ns/1.0";

declare function wdbPL:pageTitle ($node as node(), $model as map(*)) {
  let $t := $wdb:configFile//config:short
  
  return <title>{normalize-space($t)} – Admin</title>
};

declare function wdbPL:body ( $node as node(), $model as map(*) ) {
  let $file := request:get-parameter('file', '')
  let $job := request:get-parameter('job', '')
  let $user := sm:id()
  
  return
    if (not($user//sm:group = 'dba'))
      then <p>Diese Seite ist nur für Administratoren zugänglich!</p>
    else if ($job != '') then
      let $editionID := $model?id
      let $metaPath := $model?infoFileLoc
      let $metaFile := doc($metaPath)
      
      let $relativePath := substring-after($file, $model?pathToEd || '/')
      let $subColl := xstring:substring-before-last($file, '/')
      let $resource := xstring:substring-after-last($file, '/')
      let $fileEntry := $metaFile//meta:file[@path = $relativePath]
      let $xml := doc($file)
      
      return switch ($job)
        case 'add' return
          let $ins := <file xmlns="https://github.com/dariok/wdbplus/wdbmeta" path="{$relativePath}" uuid="{util:uuid($xml)}" 
            date="{xmldb:last-modified(xstring:substring-before-last($file, '/'), xstring:substring-after-last($file, '/'))}"
            xml:id="{$xml/tei:TEI/@xml:id}" />
          let $up1 := update insert $ins into $metaFile//meta:files
          return local:getFileStat($model , $file)
        
        case 'uuid' return
          let $ins := attribute uuid {util:uuid($xml)}
          let $up1 := if ($fileEntry/@uuid)
            then update replace $fileEntry/@uuid with $ins
            else update insert $ins into $fileEntry
          return local:getFileStat($model, $file)
        
        case 'pid' return
          let $ins := attribute pid { string($xml//tei:publicationStmt/tei:idno[@type = 'URI']) }
          let $up1 := if ($fileEntry/@pid)
            then update replace $fileEntry/@pid with $ins
            else update insert $ins into $fileEntry
          return local:getFileStat($model, $file)
        
        case 'date' return
          let $ins := attribute date {xmldb:last-modified($subColl, $resource)}
          let $up1 := if ($fileEntry/@date)
            then update replace $fileEntry/@date with $ins
            else update insert $ins into $fileEntry
          return local:getFileStat($model, $file)
        
        case 'id' return
          let $ins := attribute xml:id {normalize-space($xml/tei:TEI/@xml:id)}
          let $upd1 := if ($fileEntry/@xml:id)
            then update replace $fileEntry/@xml:id with $ins
            else update insert $ins/@xml:id into $fileEntry
          return local:getFileStat($model, $file)
        
        case 'private' return
          let $id := normalize-space($xml/tei:TEI/@xml:id)
          let $view := ($metaFile//meta:view[@file = $id])[1]
          let $upd := if ($view/@private = 'true')
            then update value $view/@private with 'false'
            else if ($view/@private = 'false')
              then update value $view/@private with 'true'
              else update insert attribute private {'true'} into $view
          return local:getFileStat($model, $file)
        
        default return
          <div id="data"><div><h3>Strange Error</h3></div></div>
    (: no job given :)
    else if ( ($model?ed = 'data' or $model?ed = '') and $file = '' ) then (
      <h3>Liste der Projekte</h3>,
      wdbs:projectList(true(), '')
    )
    else if ($model?ed != 'data' and $model?ed != ''and $file = '') then
      local:getFiles($model)
    else
      local:getFileStat($model, $file)
};

declare function local:getFiles($model) {
  let $infoFile := doc($model?infoFileLoc)
  let $filesInEd := (
    $infoFile//meta:file,
    $infoFile//mets:file
  )
  
  return 
    <div id="content">
      <h1>Insgesamt {count($filesInEd)} Texte</h1>
      <table class="noborder">
        <tbody>
          <tr>
            <th>Nr.</th>
            <th>Pfad</th>
            <th>Titel</th>
            <th>Status</th>
          </tr>
          {
            for $doc in $filesInEd
              let $info := if ($doc[self::meta:file])
                then
                  let $id := $doc/@xml:id
                  let $view := $infoFile//meta:view[@file = $id]
                  return (
                    $id,
                    if ($view/@order castable as xs:int)
                      then number($infoFile//meta:view[@file = $id]/@order)
                      else "",
                    $model?pathToEd || "/" || $doc/@path,
                    $view/@label
                  )
                else
                  let $id := $doc/@ID
                  let $struct := $infoFile//mets:fptr[@FILEID = $id]/parent::tei:div
                  return (
                    $id,
                    if ($struct/@ORDERLABEL castable as xs:int)
                      then number($struct/@ORDERLABEL)
                      else string($struct/@ORDERLABEL),
                    $model?pathToEd || "/" || $doc/mets:FLocat/@*:href,
                    $struct/@LABEL
                  )
              
              order by $info[3]
              return
                <tr>
                  <td>{$info[2]}</td>
                  <td>{$info[3]}</td>
                  <td>
                    <a href="../view.html?id={$info[1]}">
                      {substring($info[4], 1, 100)}
                    </a>
                  </td>
                  <td><a href="javascript:show('{$model?ed}', '{$info[1]}')">anzeigen</a></td>
                </tr>
          }
        </tbody>
      </table>
    </div>
};

declare function local:getFileStat($model, $file) {
  let $filePath := wdb:getFilePath($file)
  let $doc := doc($filePath)
  let $metaFile := doc($model?infoFileLoc)
  let $entry := $metaFile/id($file)
  let $uuid := util:uuid($doc)
  let $pid := $entry/@pid
  let $date := xmldb:last-modified(xstring:substring-before-last($filePath, "/"),
      xstring:substring-after-last($filePath, "/"))
  
  return
    <div id="data">
      <div style="width: 100%;">
        <h3>{$file}</h3>
        <hr />
        <table style="width: 100%;">
          <tbody>
            {
              for $title in $doc//tei:teiHeader/tei:title
                return <tr><td>Titel</td><td>{$title}</td></tr>
            }
            <tr>
              <td>UUID v3</td>
              <td>{$uuid}</td>
            </tr>
            <tr>
              <td>externe PID</td>
              <td>{$pid}</td>
            </tr>
            <tr>
              <td>Timestamp</td>
              <td>{$date}</td>
            </tr>
            <tr>
              <td>Metadaten-Datei</td>
              <td>{$model?infoFileLoc}</td>
            </tr>
            <tr>
              <td>relativer Pfad zur Datei</td>
              <td>{string($entry/@path)}</td>
            </tr>
            <tr>
              <td>Eintrag in <i>wdbmeta.xml</i> vorhanden?</td>
              {if ($entry/@path != '')
                then <td>OK</td>
                else <td>fehlt <a href="javascript:job('add', '{$file}')">hinzufügen</a></td>
              }
            </tr>
            {if ($entry/@path != '')
              then (
                <tr>
                  <td style="border-top: 1px solid black;">UUID in wdbMeta</td>
                  {if ($entry/@uuid = $uuid)
                    then <td>OK: {$uuid}</td>
                    else <td>{normalize-space($entry/@uuid)}<br/><a href="javascript:job('uuid', '{$file}')">UUID aktualisieren</a></td>
                  }
                </tr>,
                <tr>
                  <td>externe PID</td>
                  <td>{if ($entry/@pid = $pid)
                    then "OK: " || string($entry/@pid)
                    else <a href="javascript:job('pid', '{$file}'">PID aus Datei übernehmen</a>
                  }</td>
                </tr>,
                <tr>
                  <td>Timestamp in wdbMeta</td>
                  {if ($entry/@date = $date)
                    then <td>OK: {$date}</td>
                    else <td>{normalize-space($entry/@date)}<br/><a href="javascript:job('date', '{$file}')">Timestamp aktualisieren</a></td>
                  }
                </tr>,
                <tr>
                  <td><code>@xml:id</code> in wdbMeta</td>
                  {if ($entry/@xml:id = $doc/tei:TEI/@xml:id)
                    then <td>OK: {$entry/@xml:id/string()}</td>
                    else <td>{normalize-space($entry/@xml:id)}<br/><a href="javascript:job('id', '{$file}')">ID aktualisieren</a></td>
                  }
                </tr>
              )
              else ()
            }
          </tbody>
        </table>
        {
          if ($wdb:role = 'workbench') then
            let $remoteMetaFilePath := $wdb:peer || '/' || substring-after($model?pathToEd, $wdb:data) || '/wdbmeta.xml'
            let $remoteMetaFile := try {
               doc($remoteMetaFilePath)
            } catch * {
              util:log("error", "Peer meta file not found: " || $remoteMetaFilePath ||
                'e: ' ||  $err:code || ': ' || $err:description || ' @ ' || $err:line-number ||':'||$err:column-number || '
                c: ' || $err:value || ' in ' || $err:module || '
                a: ' || $err:additional)
            }
            let $remoteEntry := $remoteMetaFile//meta:file[@xml:id = $file]
            
            return (
              <h3>Peer Info</h3>,
              <table style="width: 100%;">
                <tbody>
                  <tr>
                    <td>Peer Server</td>
                    <td>{$wdb:peer}</td>
                  </tr>
                  <tr>
                    <td>Eintrag in <i>wdbmeta.xml</i> vorhanden?</td>
                    {if ($remoteEntry/@path != '')
                      then <td>OK</td>
                      else <td>fehlt</td>
                    }
                  </tr>
                  {if ($remoteEntry/@path != '')
                    then (
                      <tr>
                        <td>UUID in wdbMeta</td>
                        {if ($remoteEntry/@uuid = $uuid)
                          then <td>OK: {$uuid}</td>
                          else <td>Diff: {normalize-space($remoteEntry/@uuid)}</td>
                        }
                      </tr>,
                      <tr>
                        <td>Timestamp in wdbMeta</td>
                        {if ($remoteEntry/@date = $date)
                          then <td>OK: {$date}</td>
                          else <td>Diff: {normalize-space($remoteEntry/@date)}</td>
                        }
                      </tr>,
                      <tr>
                        <td><code>@xml:id</code> in wdbMeta</td>
                        {if ($remoteEntry/@xml:id = $file)
                          then <td>OK: {$file}</td>
                          else <td>Diff: {normalize-space($remoteEntry/@xml:id)}</td>
                        }
                      </tr>
                    )
                    else ()
                  }
                </tbody>
              </table>
            )
          else ()
        }
        {
          if ($wdb:role = 'standalone') then
            let $status := if ($metaFile//meta:view[@file = $file])
              then
                let $view := ($metaFile//meta:view[@file = $file])[1]
                return if ($view/@private = true())
                  then 'intern'
                  else 'sichtbar'
              else 'Kein Struktureintrag'
            return (
              <h3>Verwaltung</h3>,
              <table>
                <tbody>
                  <tr>
                    <td>Status</td>
                    <td>{
                      if ($status = 'Kein Struktureintrag') then
                        $status
                      else
                        let $link := <a href="javascript:job('private', '{$file}')">umschalten</a>
                        return ($status, <br/>, $link)
                    }</td>
                  </tr>
                </tbody>
              </table>
            )
          else ()
        }
      </div>
    </div>
};