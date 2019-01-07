xquery version "3.1";

module namespace wdbanno = "https://github.com/dariok/wdbplus/anno";

import module namespace wdb = "https://github.com/dariok/wdbplus/wdb" at "app.xql";

(:~
 : return the annotation file for the given user on the given file.
 : If no user is given, the public annotation file is returned.
 :
 : @param $file as xs:string: the full URI to the edition file
 : @param $username as xs:string: the user for whom the annotations are to be returned
 : @return node(): the annotation file 
 :)
declare function wdbanno:getAnnoFile($file as xs:string, $username as xs:string) as node() {
	let $annotationCollectionName := substring-before(substring-after($file, $wdb:data), '.xml')
	let $annotationCollection := if (xmldb:collection-available($wdb:edocBaseDB || '/annotations/'
		|| $annotationCollectionName))
			then $wdb:edocBaseDB || '/annotations/' || $annotationCollectionName
			else xmldb:create-collection($wdb:edocBaseDB || '/annotations', $annotationCollectionName)
	
	let $fileName := if ($username = "")
		then "anno.xml"							(: public annotations :)
		else $username || '.xml'		(: private or special annotations :)
	
	let $annotationFile := if (doc-available($annotationCollection || '/' || $fileName))
		then $annotationCollection || '/' || $fileName
		else
			let $annotationContent := <anno xmlns="https://github.com/dariok/wdbplus/annotations"/>
			let $fileStored := xmldb:store($annotationCollection, $fileName, $annotationContent)
			let $changes := if ($fileName = 'anno.xml')
				then (sm:chgrp($fileStored, 'wdbusers'), sm:chmod($fileStored, 'rw-rw-r--'))
				else (sm:chgrp($fileStored, 'wdb'), sm:chmod($fileStored, 'rw-rw----'), sm:chown($fileStored, $username))
			return $fileStored
	
	return doc($annotationFile)
};