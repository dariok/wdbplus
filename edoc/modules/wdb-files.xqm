(:~
 : WDB-FILES.XQM
 : 
 : basic functions dealling with the availability and permissions of resources
 : 
 : functio creata PRID KAL APR MMXX
 : 
 : Vienna, Dario Kampkaspar – dario.kampkaspar(at)ulb.tu-darmstadt.de
 :)

xquery version "3.1";

module namespace wdbFiles = "https://github.com/dariok/wdbplus/files";

import module namespace functx = "http://www.functx.com"                    at "/db/system/repo/functx-1.0.1/functx/functx.xq";
import module namespace wdbErr = "https://github.com/dariok/wdbplus/errors" at "error.xqm";

declare namespace meta   = "https://github.com/dariok/wdbplus/wdbmeta";
declare namespace mets   = "http://www.loc.gov/METS/";
declare namespace xlink  = "http://www.w3.org/1999/xlink";

(:~
 : Return the path to all Resources with a given ID
 :
 : This function looks within metadata files, i.e. wdbmeta.xml and mets.xml, and return all paths found. If a file has
 : an xml:id but is not “registered” with its project’s metadata, it wont’t be returned. Also, this function will
 : return all files; it is up to the caller to act upon this accordingly.
 :
 : @param $collection as xs:string: ID of the collection in which to search
 : @param $id as xs:string: the ID value to be used
 : @return attribute()* the path attributes to the files as stored in the meta data files
 :)
 declare function wdbFiles:getFilePaths ( $collection, $id ) as attribute()* {
  (
    collection($collection)//meta:file[@xml:id = $id]/@path,
    collection($collection)//mets:file[@ID = $id]/mets:FLocat/@xlink:href
  )
};

(:~
 : Return the absolute Path to the file identified by the path attribute
 : 
 : @param $path as attribute() an attribute node from wdbmeta or METS
 : @return xs:anyURI
 :)
declare function wdbFiles:getAbsolutePath ( $path as attribute() ) {
  let $base :=functx:substring-before-last(base-uri($path), '/')
  let $val := string($path)
  
  return if (starts-with($val, $base))
    then xs:anyURI($val)
    else xs:anyURI($base || '/' || $val)
};

(:~
 : Check whether the current user has the right to access the file with the given mode
 : 
 : @param $collection: the collection in which to search for the ID
 : @param $id as xs:string: the ID value to be used
 : @param $mode as xs:string: the access mode
 : @return xs:boolean
 :)
declare function wdbFiles:hasAccess ( $collection as xs:string, $id as xs:string, $mode as xs:string ) {
  let $file := wdbFiles:getFilePaths($collection, $id)
  
  return if (count($file) = 0)
  then wdbErr:error(map { "code": "wdbErr:wdb0000", "id": $id, "collection": $collection })
  else if (count($file) = 1)
  then
    let $path := wdbFiles:getAbsolutePath($file[1])
    return (sm:has-access($path, $mode), $path)
  else wdbErr:error(map { "code": "wdbErr:wdb0001", "id": $id, "collection": $collection })
};