# W. Digitale Bibliothek (wdbplus)

An extensible framework for digital Editions for the [eXist XML database](https://github.com/eXist-db).

This framework still lacks a good name. If you have an idea, please let me know!

## Incompatible changes

Release 24Q2 dropped functions `wdb:getEdPath( $ed as xs:string , $absolute as xs:boolean() )` and
`wdb:getEdPath( $ed as xs:string )`. These queries can be replaced by `(wdbFile:getFullPath($id))` which returns a map
with `projectPath` (the path to the project, i.e. the collection where `project.xqm` is stored), `collectionPath` (for
the subcollection where a file is actually located), and `fileName`.

Release 24Q1 dropped support for METS-based projects. As METS files can have a number of very different ways of encoding
information, especially when it comes to behaviours, native support is hard to achieve. At the same time, most
installations use wdb+’s native wdbmeta system as this is what the admin functions work with.
If you require METS support, please open an issue and provide an example of your METS files. We will then try to create
import and export functions.

Release 24Q1 introduced changes to the transformation: previously, XIncludes were not expanded before the XSLT was
applied to a file. This has now been dropped meaning that XIncludes will always be expanded. This is most likely the
expected behaviour. If you want to ignore XInclude, you can add this as a global setting in eXist: in
`${eXist-dir}/etc/conf.xml` set `serializer/@enable-xinclude` to `no`.

## Installation
You need a working instance of eXist (4.0 or later). It is recommended that you use the default software selection 
during installation. The default memory settings usually work very well but you can, of course, always give eXist a
little more RAM.
### Using the .xar package
1. Clone this repo including its submodules (xstring, wdbmeta) 
1. `cd edoc`
1. run `ant`
1. install the `.xar` file created in `edoc/build/` using eXist's dashboard or (https://github.com/eXist-db/xst)[XST]

The app will be installed into `/db/apps/edoc`.

### manual installation
1. clone this repo including its submodules
1. put folder `edoc` anywhere you want in your eXist; the default would be `/db/apps/edoc`; you can also rename it to your needs (in this case, you have to adjust the paths in the next steps!).
1. import the index configuration files – i.e. the contents of the `config` directory – into `/db/system/config/db/apps` (see the wiki if you change the destination)
1. run `edoc/post-install.xql` to set execution rights and apply the index configuration (if you change the destination, adjust your paths).

## Initial configuration
Set the name for the instance and other settings in `edoc/config.xml` or using the form under `edoc/admin/admin.html`.

## Creating and uploading projects
While many different ways of putting data into the application are possible, the standard way is to have one collection
under data for each project.

### Using admin functions
It is possible to create an initial setup using `admin/admin.html`. After creating a project, you can immediately start
uploading files using the upload form. wdb+ will take care of creating meta data entries.

### Manual approach
The following describes a manual installation and assumes that you work with a standard setup, i.e. have installed the app
into `/db/apps/edoc` and want to put your projects into `/db/apps/edoc/data/yourproject`.

1. create `wdbmeta.xml` in `/db/apps/edoc/data/yourproject`, either by copying, pasting and editing the example below or by using
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
1. add project's XML/XSLT etc. files to your projects, e.g. into a subcollection `/db/apps/edoc/data/yourproject/texts`
1. add a `<file>` entry to `wdbmeta.xlm` for each file to be displayed; you MUST give it an `xml:id` which SHOULD be the same as that file’s `/*/@xml:id`
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
* ULB Darmstadt

If you use wdbplus for your editions, please drop me a message so I can add you to this list.
