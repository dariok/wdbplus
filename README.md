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
1. put folder `edoc` anywhere you want in your eXist; the default would be `/db/apps/edoc`; you can also rename it to your needs (in this case, you have to adjust the paths in the next steps!).
1. import the index configuration files – i.e. the contents of the `config` directory – into `/db/system/config/db/apps` (see the wiki if you change the destination)
1. run `edoc/post-install.xql` to set execution rights and apply the index configuration (if you change the destination, adjust your paths).

## Creating and uploading projects
1) add project's XML/XSLT etc. files into a subcollection of `/db/apps/edoc/data`
2) create a file `wdbmeta.xml` in that collection (you can also use `admin/admin.html` for the basic settings)
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
            <command type="xsl">/db/apps/edoc/resources/xsl/tei-transcript.xsl</command>
        </process>
        <struct label="1722" order="1722">
            <view file="xml-id" label="Title of File" />
        </struct>
    </projectMD>
```
You have to set at least one `process`; the example above points to a standard XSLT provided by wdb+.
3) The file is now available to view under `http://yourserver:8080/exist/apps/edoc/view.html?id=xml-id`

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
