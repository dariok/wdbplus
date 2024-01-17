## Introduction to wdbmeta.xml

A fully detailed description of `wdbmeta.xml` is available in the XML Schema available in `{$approot}/include/wdbmeta`.
This documentation will cover the most important parts and how the file is evaluated in the app.

Evey project should have a `wdbmeta.xml` file. This is also true about the main data collection.
`wdbmeta.xml` is intended to replace `mets.xml` with a less verbose format while maintaining its functionality as a table of contents for a project.
Since v 3.0, `wdbmeta.xml` is the only format available as METS support has been dropped. If METS are required, the way
to achieve this is via an XSLT-based import and export of the METS data into `wdbmeta.xml`.

The files main element in `projectMD` in the namespace `https://github.com/dariok/wdbplus/wdbmeta`.

## Main settings
|element|max. allowed|usage|
|--|--|--|
|projectID|1|A globally unique ID for this project. While it is not a requirement, this value should equal `/projectMD/@xml:id` unless the difference has some meaning within the current instance of the app.|
|titleData|1|Groups together the main information about the original text(s) contained in the project.|
|titleData/title|+|The main title for this (sub-)project.|
|titleData/date|* |A date that refers to the creation of the texts, e.g. 'from' and 'to'.|
|titleData/place|* |A place relevant for the original texts, e.g. place of creation.|
|titleData/language|* |An ISO 639-code for the languages (and scripts) used in the texts.|
|titleData/type|1|A short documentation of the type(s) of text contained in the project.|
|metaData|1|Groups together the meta data for the project|
|metaData/contentGroup|1|Groups the types of content the project has|
|metaData/contentGroup/content|+|A description of one type of content. `@xml:id` is mandatory.|
|metaData/involvement|1|Groups information about all parties involved in the project|
|metaData/involvement/org|* |Information about one organisation. Should contain `@contribution` with reference to a `content` element describing to which types of content the org contributed to.|
|metaData/involvement/person|* |Information about one person. Should contain `@contribution` with reference to a `content` element describing to which types of content the person contributed to.|
|metaData/legal|1|Groups licencing information.|
|metaData/legal/licence|+|Contains info about a licence, a link to the full text and references to `content` elements in `@content`.|
|files|1|Groups metadate about all files containted within the project.|
|files/fileGroup|* |Groups file elements together for purposes of processing or simply clarity of organisation.|
|files/file|+|Information about one file. Must have an `@xml:id` and `@path` and should have a `@uuid` and `@date`.|
|process|+|Groups instructions how files are to be processed. Should have `@target` to specify the target format.|
|process/command|+|Command point to scripts etc. that are to be executed with a file as input. Commands may have an attribute to specify which files are to be processed by this command. The first matching command is executed, while the last in the list is always the default.|
|struct|1|Groups together files in a TOC.|
|struct/import|1|Import another wdbmeta, ussually of the parent, to generate several levels of a TOC.|
|struct/struct|+|Additional levels to the TOC.|
|struct/view|+|One TOC entry; needs `@file` to point to a `file` and a `@label`.|