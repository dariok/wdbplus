**This is a documentation of what’s to come! The endpoints as described here are currently under development and may not yet be available or may still contain bugs!**

The base URL for these endpoints is `{$server}/restxq/edoc/`.

# rest-coll.xql
|Endpoint|Method|Data Type|Data schema|action|
|--|--|--|--|--|
|**collection**|GET|XML, JSON|-|get a list of all projects (as defined by a collection with a `wdbmeta.xml`) and their subprojects – the IDs are those available for calls to `collection/${id}`. The data type is XML by default and subject to content negotiation|
|**collection.xml**|GET|XML|-| ––"–– |
|**collection.json**|GET|JSON|-| ––"–– |
|**collection/${id}/wdbmeta.xml**|GET|XML|wdbmeta:projectMD|returns the project’s meta data file ; a project is identified by `wdbmeta:projectMD/@xml:id`|
|**collection/${id}**|GET|XML, JSON|list|use content negotiation to get the result of the next 2|
|**collection/${id}/resources.xml**|GET|XML|list|get a list of all collections and resources with an ID in the project identified by `$id`|
|**collection/${id}/resources.json**|GET|JSON|list|get a list of all collections and resources with an ID in the project identified by `$id`|
|**collection/${id}/nav.xml**|GET|XML|wdbmeta:struct|return the navigation for the given project. All children structs are returned and for all other projects, their hierarchy|
|**collection/${id}/nav.html**|GET|HTML|html:ul|the result of the former transformed by either a project specific or a generic XSLT|

# rest-files.xql
|Endpoint|Method|Data Type|Data schema|action|
|--|--|--|--|--|
|**resource/${id}**|GET|-|-|return the file identified by `$id` in whatever datatype it is present in the DB. A file’s ID is listed in `wdbmeta.xml` (or for TEI files, in `/tei:TEI/@xml:id`)|
|**resource/${id}/views**|GET|XML, JSON|(list)|-|return a list of views that are available for this file (e.g., „HTML“) – this is given by the processes defined in `wdbmeta.xml`|
|**resource/${id}/${fragment}**|GET|-|-|return whatever is identified by $fragment in $id (as above). In most cases, this will be an element with an `@xml:id` in an XML file (but it can be anything that is by a schema defined as an ID)|
|**resource/${id}.${view}**|GET|-|-|return the result of applying the process identified by $view to the file identified by $id|
|**resource/iiif/${id}.json**|GET|JSON|IIIF manifest|return a IIIF manifest for this file if it is an edition file|
|**resource/iiif/${id}/${image}.json**|GET|JSON|IIIF image descriptor|return a IIIF image descriptor for the image identified by $image in the edition file identified by $id|

# rest-search.xql
|Endpoint|Method|Data Type|Data schema|action|
|--|--|--|--|--|
|**search/collection/{$id}.xml**|GET|XML|results/result|full text search of the collection with the given ID. The search string is to be sent URL encoded in parameter `q`; an offset can be given in parameter `start`; additional parameters can be passed as a simple map in `p`.|
|**search/collection/{$id}.html**|GET|HTML|ul|full text search of the collection with the given ID. The search string is to be sent URL encoded in parameter `q`; an offset can be given in parameter `start`; additional parameters can be passed as a simple map in `p`. Results are produced by a (probably project specific) search.xsl |
|**search/file/{$id}.xml**|GET|XML|results/result|full text search in the resource with the given ID. The search string is to be sent URL encoded in parameter `q`; an offset can be given in parameter `start`; additional parameters can be passed as a simple map in `p`.|
|**search/file/{$id}.html**|GET|HTML|ul|full text search of the resource with the given ID. The search string is to be sent URL encoded in parameter `q`; an offset can be given in parameter `start`; additional parameters can be passed as a simple map in `p`. Results are produced by a (probably project specific) search.xsl |

# rest-anno.xql
|Endpoint|Method|Data Type|Data schema|action|
|--|--|--|--|--|
|**anno/{$fileID}**|GET|JSON| - |get all private annotations for the currently logged in user and all public annotations for the file identified by `$fileID`.|
|**anno/{$fileID}** | POST | JSON | array: **from**, to, **text** | post one full text annotation for the file identified by `$fileID`.|
|**anno/{$fileID}/word**|POST|JSON|array: **ID**, **job**, **text**|change the token with the given ID. job may be one of `edit`|