xquery version "3.0";

module namespace wdbPL = "https://github.com/dariok/wdbplus/ProjectList";

import module namespace config   = "https://github.com/dariok/wdbplus/config" at "../modules/wdb-config.xqm";
import module namespace sm       = "http://exist-db.org/xquery/securitymanager";
import module namespace wdbFiles = "https://github.com/dariok/wdbplus/files"  at "../modules/wdb-files.xqm";
import module namespace wdbs     = "https://github.com/dariok/wdbplus/stats"  at "../modules/stats.xqm";
import module namespace xstring  = "https://github.com/dariok/XStringUtils"   at "../include/xstring/string-pack.xql";

declare namespace meta   = "https://github.com/dariok/wdbplus/wdbmeta";
declare namespace tei    = "http://www.tei-c.org/ns/1.0";

declare function wdbPL:pageTitle ( $node as node(), $model as map(*) ) as element(title) {
  <title>{ normalize-space($config:configFile//config:short) } – Admin</title>
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
          return wdbPL:getFileStat($model , $file)
        
        case 'uuid' return
          let $ins := attribute uuid {util:uuid($xml)}
          let $up1 := if ($fileEntry/@uuid)
            then update replace $fileEntry/@uuid with $ins
            else update insert $ins into $fileEntry
          return wdbPL:getFileStat($model, $file)
        
        case 'pid' return
          let $ins := attribute pid { string($xml//tei:publicationStmt/tei:idno[@type = 'URI']) }
          let $up1 := if ($fileEntry/@pid)
            then update replace $fileEntry/@pid with $ins
            else update insert $ins into $fileEntry
          return wdbPL:getFileStat($model, $file)
        
        case 'date' return
          let $ins := attribute date {xmldb:last-modified($subColl, $resource)}
          let $up1 := if ($fileEntry/@date)
            then update replace $fileEntry/@date with $ins
            else update insert $ins into $fileEntry
          return wdbPL:getFileStat($model, $file)
        
        case 'id' return
          let $ins := attribute xml:id {normalize-space($xml/tei:TEI/@xml:id)}
          let $upd1 := if ($fileEntry/@xml:id)
            then update replace $fileEntry/@xml:id with $ins
            else update insert $ins/@xml:id into $fileEntry
          return wdbPL:getFileStat($model, $file)
        
        case 'private' return
          let $id := normalize-space($xml/tei:TEI/@xml:id)
          let $view := ($metaFile//meta:view[@file = $id])[1]
          let $upd := if ($view/@private = 'true')
            then update value $view/@private with 'false'
            else if ($view/@private = 'false')
              then update value $view/@private with 'true'
              else update insert attribute private {'true'} into $view
          return wdbPL:getFileStat($model, $file)
        
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
      wdbPL:getFileStat($model, $file)
};

declare function local:getFiles($model) {
  let $infoFile := doc($model?infoFileLoc)
    , $filesInEd := $infoFile//meta:file
  
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
              let $info := if ( $doc[self::meta:file] )
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
                else ()
              
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
                  <td><a href="?ed={$model?ed}&amp;file={$info[1]}">anzeigen</a></td>
                </tr>
          }
        </tbody>
      </table>
    </div>
};

declare
  %private
function wdbPL:getFileStat( $model as map(*), $id as xs:string ) as element(div) {
  let $fullPath := wdbFiles:getFullPath($id)
    , $filePath := $fullPath?collectionPath || "/" || $fullPath?fileName
    , $doc := doc($filePath)
    , $metaFile := doc($fullPath?projectPath || "/wdbmeta.xml")
    , $entry := $metaFile/id($id)
    , $uuid := util:uuid($doc)
    , $pid := $entry/@pid
    , $date := xmldb:last-modified($fullPath?collectionPath, $fullPath?fileName)
  
  return
    <div id="data">
      <div style="width: 100%;">
        <h3>{ $id }</h3>
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
                else <td>fehlt <a href="javascript:job('add', '{$id}')">hinzufügen</a></td>
              }
            </tr>
            {if ($entry/@path != '')
              then (
                <tr>
                  <td style="border-top: 1px solid black;">UUID in wdbMeta</td>
                  {if ($entry/@uuid = $uuid)
                    then <td>OK: {$uuid}</td>
                    else <td>{normalize-space($entry/@uuid)}<br/><a href="javascript:job('uuid', '{$id}')">UUID aktualisieren</a></td>
                  }
                </tr>,
                <tr>
                  <td>externe PID</td>
                  <td>{if ($entry/@pid = $pid)
                    then "OK: " || string($entry/@pid)
                    else <a href="javascript:job('pid', '{$id}'">PID aus Datei übernehmen</a>
                  }</td>
                </tr>,
                <tr>
                  <td>Timestamp in wdbMeta</td>
                  {if ($entry/@date = $date)
                    then <td>OK: {$date}</td>
                    else <td>{normalize-space($entry/@date)}<br/><a href="javascript:job('date', '{$id}')">Timestamp aktualisieren</a></td>
                  }
                </tr>,
                <tr>
                  <td><code>@xml:id</code> in wdbMeta</td>
                  {if ($entry/@xml:id = $doc/tei:TEI/@xml:id)
                    then <td>OK: {$entry/@xml:id/string()}</td>
                    else <td>{normalize-space($entry/@xml:id)}<br/><a href="javascript:job('id', '{$id}')">ID aktualisieren</a></td>
                  }
                </tr>
              )
              else ()
            }
          </tbody>
        </table>
        {
          (: if ( $config:role = 'workbench' ) then
            let $remoteMetaFilePath := $config:peer || '/' || substring-after($model?pathToEd, $config:data) || '/wdbmeta.xml'
            let $remoteMetaFile := try {
               doc($remoteMetaFilePath)
            } catch * {
              util:log("error", "Peer meta file not found: " || $remoteMetaFilePath ||
                'e: ' ||  $err:code || ': ' || $err:description || ' @ ' || $err:line-number ||':'||$err:column-number || '
                c: ' || $err:value || ' in ' || $err:module || '
                a: ' || $err:additional)
            }
            let $remoteEntry := $remoteMetaFile//meta:file[@xml:id = $id]
            
            return (
              <h3>Peer Info</h3>,
              <table style="width: 100%;">
                <tbody>
                  <tr>
                    <td>Peer Server</td>
                    <td>{ $config:peer }</td>
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
                        {if ($remoteEntry/@xml:id = $id)
                          then <td>OK: { $id }</td>
                          else <td>Diff: {normalize-space($remoteEntry/@xml:id)}</td>
                        }
                      </tr>
                    )
                    else ()
                  }
                </tbody>
              </table>
            )
          else () :)
        }
        {
          if ( $config:role = 'standalone' ) then
            let $status := if ($metaFile//meta:view[@file = $id])
              then
                let $view := ($metaFile//meta:view[@file = $id])[1]
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
                        let $link := <a href="javascript:job('private', '{ $id }')">umschalten</a>
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