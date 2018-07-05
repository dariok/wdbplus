# Main files

This list the main (non-HTML-)files that you should know about.
These are usually meant to be adapted to your needs and play a special role for customization.

## `project.css` and `project.js`
See [[project specifics|project-specifics]] for information about how to use these files.

## `start.xml`
If you call a project's `start.html` – be that directly or via the `?ed`-parameter – a generic start page is generated to the project.
It features a table of contents on the left – generated from `[[wdbmeta.xml|#wdbmeta.xml]]` or a `mets.xml` – and an empty right hand side.
To fill this, you can create a basic TEI file called `start.xml` which will be transformed by the global `{$approot}/resources/start.xsl` and displayed on the right.
If you want more control over how the result looks, you can provide a `start.css` and/or `start.xsl` to adjust this to your needs.

## wdbmeta.xml
This is the central information file for your project.
It was developed from the METS standard and is (planned to) be transformable into a standard `mets.xml`.
However, the focus way on easy editing, high flexibility and the possibility to automatically enter new files.
The schema with basic documentation of this faile is available under `{$approot}/includes/wdbmeta`.
A more detailed discussion of the options and the file's processing can be found under [[wdbmeta.xml]].

## project.xqm
This files contains several XQuery functions you can use to load [[project specific layout and functions|project-specifics]], define information for the HTML-header etc.
A more detailed discussion of this file is available under [[project.xqm]].