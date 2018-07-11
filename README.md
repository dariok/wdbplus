# W. Digitale Bibliothek (wdbplus)

An extensible framework for digital Editions for the [eXist XML database](https://github.com/eXist-db).

This framework still lacks a good name. If you have an idea, please let me know!

## Installation
The final version will be available as an installable .xar package for eXist.

### eXgit
Additionally, it is possible to use [eXgit](https://github.com/dariok/exgit) to clone the current version directly into a running eXist instance.

1. Install eXgit as stated in the repo.
1. (optional) create a user for the framework and log in under that name
1. (optional) create the target collection as this user
1. run the following XQuery:

    xquery version "3.1";
    
    import module namespace exgit="http://exist-db.org/xquery/exgit" at "java:org.exist.xquery.modules.exgit.Exgit";
    
    let $cl := exgit:clone("https://github.com/dariok/wdbplus", "/home/dario/test/wdbplus")
    let $ie := exgit:import("/home/dario/test/wdbplus/edoc", "/db/apps/edoc")
    let $ic := exgit:import("/home/dario/test/wdbplus/config", "/db/system/config/db/apps")
    
    let $chmod := (sm:chmod(xs:anyURI('/db/apps/edoc/controller.xql'), 'r-xr-xr-x'), sm:chmod(xs:anyURI('/db/apps/edoc/insert.xql'), 'r-xr-xr-x'),
            sm:chmod(xs:anyURI('/db/apps/edoc/return.xql'), 'r-xr-xr-x'), sm:chmod(xs:anyURI('/db/apps/edoc/modules/app.xql'), 'r-xr-xr-x'),
            sm:chmod(xs:anyURI('/db/apps/edoc/modules/nav.xql'), 'r-xr-xr-x'), sm:chmod(xs:anyURI('/db/apps/edoc/modules/start.xql'), 'r-xr-xr-x'),
            sm:chmod(xs:anyURI('/db/apps/edoc/modules/view.xql'), 'r-xr-xr-x'))
    
    return ($cl, $ie, $ic, $chmod)

### manual installation
1. clone this repo
1. put folder `edoc` anywhere you want in your eXist; the default would be `/db/apps/edoc`
1. Set execute rights on .xql files
1. add project's XML/XSLT etc. files into a subcollection of `/db/apps/edoc/data`
1. create a file `wdbmeta.xml` in that directory:

    <projectMD xmlns="https://github.com/dariok/wdbplus/wdbmeta" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="https://github.com/dariok/wdbplus/wdbmeta https://raw.githubusercontent.com/dariok/wdbmeta/master/wdbmeta.xsd"
    xml:id="yourProjectID">
        <projectID>yourProjectID</projectID>
        <titleData>
            <title>Project Title</title>
        </titleData>
        <files>
            <file path="pathTo.xml" xml:id="xml-id" />
        </files>
        <process target="html">
            <command type="xsl">/db/apps/edoc/data/yourProject/yourXSL.xsl</command>
        </process>
        <struct label="1722" order="1722">
            <view file="xml-id" label="Title of File" />
        </struct>
    </projectMD>

1. The file is now available to view under `http://yourserver/exist/apps/edoc/view.html?id=xml-id`

----

Currently used in these projects:

* HAB Wolfenbüttel
  * Editionsprojekt Karlstadt
* ACDH Wien
  * Wien[n]erisches Diarium Digital
  * Repertotium frühneuzeitlicher Rechtsquellen
* Akademie der Wissenschaften, Heidelberg
    * Theologenbriefwechsel

If you use wdbplus for your editions, please drop me a message so I can add you to this list.