# W. Digitale Bibliothek (wdbplus)

An extensible framework for digital Editions for the [eXist XML database](https://github.com/eXist-db).

This framework still lacks a good name. If you have an idea, please let me know!

## Installation
The final version will be available as an installable .xar package for eXist.

### eXgit
Additionally, it is possible to use [eXgit](https://github.com/dariok/exgit) to clone the current version directly into a running eXist instance.

1. Install eXgit as stated in the repo.
1. (optional) create a user for the framework and log in under that name –– CAVEAT: this user, at least for the duration of the installation, **needs to be** in the **dba** group!
1. (optional) create the target collection as this user
1. in `install.xql`, set `$whereToClone` to a path on your file system where you want to clone
1. if you do not want to install into `/db/apps/edoc`, adjust the paths in `install.xql` so they point to the desired destination
1. copy the contents of the cloned `wdbplus/install.xql` into eXide and run

### manual installation
1. clone this repo including its submodules
1. put folder `edoc` anywhere you want in your eXist; the default would be `/db/apps/edoc`
1. import the configuration files into `/db/system/config/db/apps/edoc` or the config folder corresponding to the collection you chose
1. apply the configuration
1. Set execute rights on .xql files (start out from `edoc/post-install.xql`; if not installing into `/db/apps/edoc`, adjust your paths.

## Creating and uploading projects
1) add project's XML/XSLT etc. files into a subcollection of `/db/apps/edoc/data`
2) create a file `wdbmeta.xml` in that collection:
```XML
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
```
3) The file is now available to view under `http://yourserver:8080/exist/apps/edoc/view.html?id=xml-id`

### Usage and Configuration
See the Wiki!

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
