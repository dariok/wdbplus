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

import module namespace functx = "http://www.functx.com" at "/db/system/repo/functx-1.0.1/functx/functx.xq";

declare namespace meta   = "https://github.com/dariok/wdbplus/wdbmeta";
declare namespace wdbErr = "https://github.com/dariok/wdbplus/errors";

(:~
 : Return the path to all Resources with a given ID
 :
 : This function looks within a project’s metadata file, i.e. wdbmeta.xml, and returns all paths found. If a file has no
 : xml:id or has an xml:id but is not “registered” with its project’s metadata, it wont’t be returned. Also, this
 : function will return all files with a given ID; it is up to the caller to act upon this accordingly.
 :
 : @param $collection as xs:string: ID of the collection in which to search
 : @param $id as xs:string: the ID value to be used
 : @return attribute()* the path attributes to the files as stored in the meta data files
 :)
 declare function wdbFiles:getFilePaths ( $collection, $id ) as attribute()* {
  let $candidates := collection($collection)//id($id)

  return (
    $candidates[self::meta:file]/@path,
    $candidates[self::meta:struct]/@xml:id
  )
};

(:~
 : Return the absolute Path to the file identified by the path attribute
 : 
 : @param $path as attribute() an attribute node from wdbmeta
 : @return xs:anyURI
 :)
declare function wdbFiles:getAbsolutePath ( $path as attribute() ) {
  let $base := functx:substring-before-last(base-uri($path), '/')
    , $val := string($path)
  
  return if ( starts-with($val, $base) )
    then xs:anyURI($val)
    else xs:anyURI($base || '/' || $val)
};

(:~
: return a map with the path to a file split into its parent collection (which may be different from the
: project collection) and its file name
:
: @param $id as xs:string: the ID of the file (which should be unique)
: @return map(string, string) with "collectionPath", "fileName"
:)
declare function wdbFiles:getFullPath ( $id as xs:string ) as map( xs:string, xs:string )? {
  (: Admins are advised by the documentation they REALLY SHOULD NOT have more than one entry for every ID
   : if there are multiple files, this will throw an error :)
  for $file in collection("/db")/id($id)[not(self::meta:file or self::meta:struct)]
    let $path := base-uri($file)
    return map{ "collectionPath": functx:substring-before-last($path, '/') , "fileName": functx:substring-after-last($path, '/') }
};

(:~
 : Check whether the current user has the right to access the file with the given mode
 : 
 : @param $collection: the collection in which to search for the ID
 : @param $id as xs:string: the ID value to be used
 : @param $mode as xs:string: the access mode
 : @return false() if access is not possible, xs:anyURI (full path) otherwise
 :)
declare function wdbFiles:hasAccess ( $collection as xs:string, $id as xs:string, $mode as xs:string ) {
  let $file := wdbFiles:getFilePaths($collection, $id)

  return if (count($file) = 0)
  then error(xs:QName("wdbErr:wdb0000"))
  else if (count($file) = 1)
  then
    let $path := wdbFiles:getAbsolutePath($file[1])
    return if (sm:has-access($path, $mode)) then $path else false()
  else error(xs:QName("wdbErr:wdb0001"))
};

(:~
 : Return the modification date adjusted to GMT, without milliseconds
 :
 : @param $collectionPath xs:string path to the base collection
 : @param $id xs:string ID of the file
 : @return xs:dateTime
 :)
declare function wdbFiles:getModificationDate ( $id as xs:string ) as xs:dateTime {
  let $path := wdbFiles:getFullPath($id)
  
  return wdbFiles:getModificationDate($path?collectionPath, $path?fileName)
};

(:~
 : Return the modification date adjusted to GMT, without milliseconds
 :
 : @param $collectionPath xs:string path to the base collection
 : @param $fileName xs:string the name of the file
 : @return xs:dateTime
 :)
declare function wdbFiles:getModificationDate ( $collectionPath as xs:string, $fileName as xs:string ) as xs:dateTime {
  let $dateTime := xmldb:last-modified($collectionPath, $fileName)
    , $adjusted := adjust-dateTime-to-timezone($dateTime,"-PT0H0M")
    
  return xs:dateTime(format-dateTime($adjusted, "[Y]-[M01]-[D01]T[H01]:[m]:[s]Z"))
};

declare function wdbFiles:evaluateIfModifiedSince ( $id as xs:string, $requestedModified as xs:string+ ) as xs:double {
  let $path := wdbFiles:getFullPath($id)

  return wdbFiles:evaluateIfModifiedSince($path?collectionPath, $path?fileName, $requestedModified)
};

(:~
 : evaluate If-Modified-Since and return either 200 or 304
 :)
declare function wdbFiles:evaluateIfModifiedSince ( $collectionPath as xs:string, $fileName as xs:string, $requestedModified as xs:string+ ) as xs:double {
  let $modifiedWithoutMillisecs := wdbFiles:getModificationDate($collectionPath, $fileName)
    , $requestedModifiedParsed := parse-ietf-date(string-join($requestedModified))
  
  return if ( $requestedModifiedParsed lt $modifiedWithoutMillisecs )
    then 200
    else 304
};

(:~
 : format da given datetime as IETF date
 :
 : @param gmtDateTime an xs:dataTime adjust to GMT
 : @returns xs:string formated as an IETF date
 :)
declare function wdbFiles:ietfDate ( $gmtDateTime as xs:dateTime ) as xs:string {
  format-dateTime($gmtDateTime, "[FNn,3-3], [D00] [MNn,3-3] [Y] [H01]:[m]:[s] GMT")
};
