==============================
Installation and Configuration
==============================

You need a working instance of eXist (4.0 or later).
It is recommended that you use the default software selection during installation.
The default memory settings usually work very well but you can, of course, always give eXist a little more RAM.

Using the .xar package
======================

#. Clone this repo including its submodules (xstring, wdbmeta) 
#. ``cd edoc``
#. run ``ant``
#. install the ``.xar`` file created in ``edoc/build/`` using eXist's dashboard

The app will be installed into ``/db/apps/edoc``.

eXgit
=====
Additionally, it is possible to use `eXgit <https://github.com/dariok/exgit>`_ to clone the current version directly into a running eXist instance.

#. Install eXgit as stated in the repo.
#. create a user ``wdb`` and a group ``wdbusers`` for the framework and log in under that name –– CAVEAT: this user, at least for the duration of the installation, **needs to be** in the **dba** group!
#. create the target collection (default would be ``/db/apps/edoc``) as this user
#. open eXide from eXist's Dashboard
#. paste:

   .. code-block:: xquery

       xquery version "3.1";
    
       import module namespace exgit="http://exist-db.org/xquery/exgit" at "java:org.exist.xquery.modules.exgit.Exgit";
    
       let $whereToClone := "/home/user/git/wdbplus"
       let $targetCollection := "/db/apps/edoc"
    
       let $cl := exgit:clone("https://github.com/dariok/wdbplus", $whereToClone)
       let $ie := exgit:import($whereToClone || "/edoc", $targetCollection)
       let $ic := exgit:import($whereToClone || "/edoc/config", "/db/system/config/db/apps")

#. replace the value of ``$whereToClone`` with the full target directory on your file system where the app shall be cloned into
#. if you do not want to install into ``/db/apps/edoc``, change the value of ``$targetCollection`` to the full DB path
#. run the script
#. open ``post-install.xql`` in your target collection
#. if you did not install into ``/db/apps/edoc``, change ``$targetCollection`` accordingly
#. run ``post-install.xql`` to set rights and index configuration


Manual Installation
===================

#. clone this repo including its submodules
#. put folder ``edoc`` anywhere you want in your eXist; the default would be ``/db/apps/edoc``; you can also rename it to your needs (in this case, you have to adjust the paths in the next steps!).
#. import the index configuration files – i.e. the contents of the ``config`` directory – into ``/db/system/config/db/apps`` (see the wiki if you change the destination)
#. run ``edoc/post-install.xql`` to set execution rights and apply the index configuration (if you change the destination, adjust your paths).

Initial configuration
=====================

Set the name for the instance and other settings in ``edoc/config.xml`` or using the form under ``edoc/admin/admin.html``.

Creating and uploading projects
===============================

While many different ways of putting data into the application are possible, the standard way is to have one collection under data for each project.
It is possible to create an initial setup using ``admin/admin.html``.
The following describes a manual installation and assumes that you work with a standard setup, i.e. have installed the app into ``/db/apps/edoc`` and want to put your projects into ``/db/apps/edoc/data/yourproject``.

#. create ``wdbmeta.xml`` in ``/db/apps/edoc/data/yourproject``, either by copying, pasting and editing the example below or by using ``admin/admin.html`` for the basic settings (it also creates the collection) and adding the other settings.

    .. code-block:: xml

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

    You have to set at least one ``process``; the example above points to a standard XSLT provided by wdb+.
#. add project's XML/XSLT etc. files to your projects, e.g. into a subcollection ``/db/apps/edoc/data/yourproject/texts``
#. add a ``<file>`` entry to ``wdbmeta.xlm`` for each file to be displayed; you MUST give it an ``xml:id`` which SHOULD be the same as that file’s ``/*/@xml:id``
#. The file is now available to view under ``http://yourserver:8080/exist/apps/edoc/view.html?id=xml-id``

Usage and Configuration
=======================

Global configuration options, i.e. those that concern options for the whole instance, have to be set in ``config.xml`` (e.g. the instance's name).
Settings for a project are set in the project's ``wdbmeta.xml``.
See the Wiki for details!

Global Configuration
====================

All global configuration options, i.e. those that affect how the app works, are set in ``$approot/config.xml``.
If you use the [[default setup|basic-collection-structure#default-structure]], ``$approot := /db/apps/edoc``.

Settings in ``config.xml``
~~~~~~~~~~~~~~~~~~~~~~~~~~

meta
````
- ``name`` – a long title for this instance of the app
- ``short`` – a short title, e.g. to be used in ``html:title``

role
````
- ``type`` – the [[role|server-roles]] of this instance
- ``peer`` – for a _workbench_, this points to the House of Lords, i.e. the _publication_ instance

See the documentation of the [[server roles|server-roles]] for more detail.

params
``````
- ``param`` – a key-value pair for global parameters that are available in all scripts and will be passed on to the model.

Not really implemented yet but planned for version 2.0.

server
``````
A full URL, reachable from the outside, to be used if the automatic resolution in ``app.xql`` does not work or needs to be overwritten. This needs to point to the collection containg ``config.xml`` (thus, the standard setting would be ``http://yourexist.tld/exist/apps/edoc/``)– a setting here overwrites the automatic processing and will be globally available as ``$wdb:edocBaseURL``, the server's name (or IP) as ``$wdb:server``.
While all standard scripts should be able to figure this out correctly, certain setups may cause problems.

Scripts invoked via RESTXQ will not be able to use automatic resolution – if you need the base URL from within a RESTXQ endpoint (e.g. for the IIIF image descriptor), you MUST set this option.

rest
````
A full URL which is the base for REST calls. This will be used by JavaScript functions, e.g. to load navigation or to insert/retrieve annotations. This must be set if the rest endpoint is not available under the usual location (i.e. ``http://yourexist.tld/exist/restxq/edoc/`` for the standard setup). This might be the case if you hid parts of the standard path by eXist's configuration or reverse proxying.

.. note::
    this needs to include the ``edoc/`` part

Projects
~~~~~~~~
In order to create a project, you have to create a collection for it and make the most important settings in ``wdbmeta.xml``. The initial settings can be done using ``admin/admin.html`` (New Project).
After that, you have to add at least one view and an entry for every file you want to access.
