(:~
 : MODEL.XQM
 :
 : Create the global map(*) for $model
 :
 : 2025-02-03 — dario.kampkaspar@tu-darmstadt.de — Created from functions previously contained in app.xqm and function.xqm
 :)

xquery version "3.1";

module namespace wdbm = "https://github.com/dariok/wdbplus/model";

import module namespace config   = "https://github.com/dariok/wdbplus/config" at "wdb-config.xqm";
import module namespace wdb      = "https://github.com/dariok/wdbplus/wdb"    at "app.xqm";
import module namespace wdbFiles = "https://github.com/dariok/wdbplus/files"  at "wdb-files.xqm";

declare namespace meta    = "https://github.com/dariok/wdbplus/wdbmeta";
declare namespace request = "http://exist-db.org/xquery/request";
declare namespace sm      = "http://exist-db.org/xquery/securitymanager";
declare namespace tei     = "http://www.tei-c.org/ns/1.0";

(:~
 : Populate the model with the most important global settings when displaying a file
 : 
 : @param $id the id for the file to be displayed
 : @param $view a string to be passed to the processing XSLT
 : @param $model the pre-generated (empty) model
 : @param $p general parameter to be passed to the processing XSLT
 : @return a map; in case of error, an HTML file
 :)
 declare function wdbm:populateModel ( $id as xs:string, $ed as xs:string,
                                       $view as xs:string, $p as xs:string, $q as xs:string ) as item()* {
  try {
    let $filePathInfo := if ( $ed = "" and $id = "" )
          then
            map {
              "projectPath": $config:data,
              "collectionPath": $config:data,
              "fileName": $config:data || "/wdbmeta.xml",
              "mainProject": $config:data
            }
          else
            wdbFiles:getFullPath( ($id, $ed)[1] )    (: $id and $ed should never be present at the same time :)
      , $pathToFile := if ( map:keys($filePathInfo) = 'fileURL' ) (: fileURL: URL to a file located on a peer :)
          then $filePathInfo?fileURL
          else $filePathInfo?collectionPath || '/' || $filePathInfo?fileName
    
    (: URI-endcoded JSON parameter :)
    let $parsedParam := try {
        parse-json($p)
      } catch * {
        normalize-space($p)
      }
    
    (: the project in question; if $ed is given, this has to be the right one; else get it from the path info;
      in case of conflict, $ed will win but this should not happen :)
    let $projectID := if ( $ed != "" )
          then $ed
          else string(doc($filePathInfo?projectPath || '/wdbmeta.xml')/meta:projectMD/@xml:id)
      , $projectFile := if ( $projectID != "data" )
          then $filePathInfo?mainProject || "/project.xqm"
          else ""

    let $projectFunctions := for $function in doc($filePathInfo?mainProject || "project-functions.xml")//function
          return $function/@name || '#' || count($function/argument)
      , $instanceFunctions := for $function in doc($config:data || "/instance-functions.xml")//function
          return $function/@name || '#' || count($function/argument)
    
    let $xsl := if ( $filePathInfo?fileName = "wdbmeta.xml" )
      then
        (: TODO get path to XSL via function – unify with REST function (rest-files) :)
        xs:anyURI($config:data || '/resources/nav.xsl')
      else
        wdb:getXslFromWdbMeta($filePathInfo?projectPath || '/wdbmeta.xml', $id, 'html')
    
    let $xslt := if ( doc-available($xsl) )
      then $xsl
      else if ( doc-available($filePathInfo?projectPath || '/' || $xsl) )
      then $filePathInfo?projectPath || '/' || $xsl
      else ""
      
    let $doc := doc($pathToFile)
      , $title := if ( $id != "" )
          then normalize-space(($doc//tei:title)[1])
          else normalize-space($doc//meta:title[1])
      , $language := if ( $id != "" )
          then normalize-space($doc//tei:langUsage/tei:language[1]/@ident)
          else normalize-space($doc//meta:language[1])
    
    let $requestHeaders := if ( request:exists() )
          then map:merge( for $header in request:get-header-names() return map:entry($header, request:get-header($header)) )
          else ()
      , $requestUrl := if ( request:exists() )
          then request:get-url()
          else ()
      
    (: TODO read global parameters from config.xml and store as a map :)
    return map {
      "auth":             sm:id()/sm:id,
      "ed":               $projectID,
      "fileLoc":          $pathToFile,
      "filePathInfo":     $filePathInfo,
      "functions":        map { "project": $projectFunctions, "instance": $instanceFunctions }, 
      "header":           $requestHeaders,
      "id":               $id,
      "infoFileLoc":      $filePathInfo?projectPath || '/wdbmeta.xml',
      "language":         $language,
      "mainEd":           $filePathInfo?mainProject,
      "p":                $parsedParam,
      "pathToEd":         $filePathInfo?projectPath,
      "projectFile":      $projectFile,
      "projectResources": $filePathInfo?mainProject || "/resources/",
      "q":                $q,
      "requestUrl":       $requestUrl,
      "title":            $title,
      "view":             $view,
      "xslt":             $xslt
    }
  } catch *:wdb0000 {                       (: wdb-files.xqm: no file with ID :)
    error(
      xs:QName("wdbErr:wdb0200"),
      "file or project not found",
      map {
        "code":        "wdbErr:wdb0000",
        "id":          $id,
        "ed":          $ed,
        "p":           $p,
        "q":           $q,
        "wdb:data":    $config:data,
        "request":     if ( request:exists() ) then request:get-url() else ""
      }
    )
  } catch * {                                   (: TODO: add more descriptions:)
    error(
      xs:QName("wdbErr:wdb3001"),
      "error creating map",
      map {
        "code":        "wdbErr:wdb3001",
        "id":          $id,
        "ed":          $ed,
        "p":           $p,
        "q":           $q,
        "wdb:data":    $config:data,
        "errC":        $err:code,
        "errA":        $err:additional,
        "errM":        $err:description,
        "errLocation": $err:module || '@' || $err:line-number || ':' || $err:column-number,
        "request":     request:get-url()
      }
    )
  }
};
