# W. Digitale Bibliothek (wdbplus)

An extensible framework for digital Editions for the [eXist XML database](https://github.com/eXist-db).

This framework still lacks a good name. If you have an idea, please let me know!

## Installation
1. Clone
1. `cd edoc`
1. run `ant`
1. install the `.xar` file in `edoc/build/` using eXist's dashboard

The app will be installed into `/db/apps/edoc`.

### eXgit
Additionally, it is possible to use [eXgit](https://github.com/dariok/exgit) to clone the current version directly into a running eXist instance.

1. Install eXgit as stated in the repo.
1. (optional) create a user for the framework and log in under that name –– CAVEAT: this user, at least for the duration of the installation, **needs to be** in the **dba** group!
1. (optional) create the target collection as this user
1. open eXide from eXist's Dashboard and paste:

```
xquery version "3.1";

import module namespace exgit="http://exist-db.org/xquery/exgit" at "java:org.exist.xquery.modules.exgit.Exgit";

let $whereToClone := "~/git/"

let $cl := exgit:clone("https://github.com/dariok/wdbplus", $whereToClone)
let $ie := exgit:import($whereToClone || "/wdbplus/edoc", "/db/apps/edoc")
let $ic := exgit:import($whereToClone || "/wdbplus/config", "/db/system/config/db/apps")

let $chmod := (sm:chmod(xs:anyURI('/db/apps/edoc/controller.xql'), 'r-xr-xr-x'),
    sm:chmod(xs:anyURI('/db/apps/edoc/modules/view.xql'), 'r-xr-xr-x'),
    sm:chmod(xs:anyURI('/db/apps/edoc/rest/rest-anno.xql'), 'r-xr-xr-x'),
    sm:chmod(xs:anyURI('/db/apps/edoc/rest/rest-coll.xql'), 'r-xr-xr-x'),
    sm:chmod(xs:anyURI('/db/apps/edoc/rest/rest-entity.xql'), 'r-xr-xr-x'),
    sm:chmod(xs:anyURI('/db/apps/edoc/rest/rest-files.xql'), 'r-xr-xr-x'),
    sm:chmod(xs:anyURI('/db/apps/edoc/rest/rest-search.xql'), 'r-xr-xr-x'),
    sm:chmod(xs:anyURI('/db/apps/edoc/rest/rest-test.xql'), 'r-xr-xr-x')
)
let $chown := sm:chown(xs:anyURI('/db/apps/edoc/annotations'), 'wdb')
let $chgrp := sm:chgrp(xs:anyURI('/db/apps/edoc/annotations'), 'wdbusers')
let $reindex := xmldb:reindex('/db/apps/edoc/data')

return ($cl, $ie, $ic, $chmod, $chown, $chgrp, $reindex)
```
1. adjust `$whereToClone` to point to a directory on your file system where the app shall be cloned into.
1. run the script

### manual installation
1. clone this repo including its submodules
1. put folder `edoc` anywhere you want in your eXist; the default would be `/db/apps/edoc`; you can also rename it to your needs (in this case, you have to adjust the paths in the next steps!).
1. import the index configuration files – i.e. the contents of the `config` directory – into `/db/system/config/db/apps` (see the wiki if you change the destination)
1. run `edoc/post-install.xql` to set execution rights and apply the index configuration (if you change the destination, adjust your paths).

## Initial configuration
Set the name for the instance and other settings in `edoc/config.xml`.

## Creating and uploading projects
While many different ways of putting data into the application are possible, the stanard way is to have one collection
under data for each project. It is possible to create an ninitial setup using `admin/admin.html`. The following describes a manual installation and assumes that you work with a standard setup, i.e. have installed the app
into `/db/apps/edoc` and want to put your projects into `/db/apps/edoc/data/*`.

1. create `wdbmeta.xml` in that collection, either by copying, pasting and editing the example or by using
`admin/admin.html` for the basic settings (it also creates the collection) and adding the other settings.
```XML
<projectMD xmlns="https://github.com/dariok/wdbplus/wdbmeta"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xsi:schemaLocation="https://github.com/dariok/wdbplus/wdbmeta https://raw.githubusercontent.com/dariok/wdbmeta/master/wdbmeta.xsd"
  xml:id="yourProjectID">
    <projectID>yourProjectID</projectID>
    <titleData>
        <title>Project Title</title>
    </titleData>
    <files>
        <file path="pathTo.xml" xml:id="xml-id" />
    </files>
    <process target="html">
        <command type="xsl">/db/apps/edoc/resources/xsl/tei-transcript.xsl</command>
    </process>
    <struct label="1722" order="1722">
        <view file="xml-id" label="Title of File" />
    </struct>
</projectMD>
```
You have to set at least one `process`; the example above points to a standard XSLT provided by wdb+.
1. add project's XML/XSLT etc. files to your projects, e.g. into a subcollection `/db/apps/edoc/data/yourporject/texts`
1. add a `<file>` entry to `wdbmeta.xlm` for each file to be displayed; you MUST give it an `xml:id`
1. The file is now available to view under `http://yourserver:8080/exist/apps/edoc/view.html?id=xml-id`

### Usage and Configuration
Global configuration options, i.e. those that concern options for the whole instance, have to be set in `config.xml` (e.g. the instance's name).
Settings for a project are set in the project's `wdbmeta.xml`.

See the Wiki for details!

----

## Currently used in these projects:

* HAB Wolfenbüttel
  * Editionsprojekt Karlstadt
* ACDH Wien
  * Wien[n]erisches Diarium Digital
  * Repertotium frühneuzeitlicher Rechtsquellen
  * Protokolle der Sitzungen der Gesamtakadmie
* Akademie der Wissenschaften, Heidelberg
    * Theologenbriefwechsel

If you use wdbplus for your editions, please drop me a message so I can add you to this list.
