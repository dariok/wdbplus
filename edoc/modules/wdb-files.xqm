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

import module namespace wdb = "https://github.com/dariok/wdbplus/wdb" at "app.xqm";

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
 : @param $id         the ID value to be used
 : @return xs:string* the paths to the files as stored in the meta data files
 :)
 declare function wdbFiles:getFilePaths ( $id ) as xs:string* {
  (
    collection($wdb:data)//meta:file[@xml:id = $id]/@path,
    collection($wdb:data)//meta:file[@ID = $id]/mets:FLocat/@xlink:href
  )
};