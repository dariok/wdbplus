xquery version "3.1";

module namespace wdbanno = "https://github.com/dariok/wdbplus/anno";

import module namespace wdb = "https://github.com/dariok/wdbplus/wdb" at "app.xqm";

(:~
 : return the annotation file for the given user on the given file.
 : If no user is given, the public annotation file is returned.
 :
 : @param $file as xs:anyURI: the full URI to the edition file
 : @param $username as xs:string: the user for whom the annotations are to be returned
 : @return node(): the annotation file 
 :)
declare function wdbanno:getAnnoFile($file as xs:anyURI, $username as xs:string) as node() {
	let $annotationCollectionName := substring-before(substring-after($file, $wdb:data), '.xml')
	let $annotationCollectionBase := $wdb:edocBaseDB || '/annotations/'
	let $annotationCollection := if (xmldb:collection-available($annotationCollectionBase || $annotationCollectionName))
			then $annotationCollectionBase || $annotationCollectionName
			else if (sm:has-access($annotationCollectionBase, 'w'))
			then xmldb:create-collection($annotationCollectionBase, $annotationCollectionName)
			else ""
	
	let $fileName := if ($username = "")
		then "anno.xml"							(: public annotations :)
		else $username || '.xml'		(: private or special annotations :)
	
	let $annotationFile := if (doc-available($annotationCollection || '/' || $fileName))
		then $annotationCollection || '/' || $fileName
		else if (sm:has-access($annotationCollection, 'w'))
		then
			let $annotationContent := <anno xmlns="https://github.com/dariok/wdbplus/annotations"/>
			let $fileStored := xmldb:store($annotationCollection, $fileName, $annotationContent)
			let $changes := if ($fileName = 'anno.xml')
				then (sm:chgrp($fileStored, 'wdbusers'), sm:chmod($fileStored, 'rw-rw-r--'))
				else (sm:chgrp($fileStored, 'wdb'), sm:chmod($fileStored, 'rw-rw----'), sm:chown($fileStored, $username))
			return $fileStored
		else ""
	
	return if ($annotationCollection != "" and $annotationFile != "")
		then doc($annotationFile)
		else <error>Collection or file not found for user {sm:id()//sm:real/sm:username/text()}</error>
};