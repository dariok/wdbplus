# Main files

This list the main (non-HTML-)files that you should know about.
These are usually meant to be adapted to your needs and play a special role for customization.

## `project.css` and `project.js`
See [[project specifics|project-specifics]] for information about how to use these files.

## wdbmeta.xml
This is the central information file for your project.
It was developed from the METS standard and is (planned to be) transformable into a standard `mets.xml`.
However, the focus was on easy editing, high flexibility and the possibility to automatically enter new files.
The schema with basic documentation of this file is available under `{$approot}/includes/wdbmeta`.
A more detailed discussion of the options and the file's processing can be found under [[wdbmeta.xml]].

## project.xqm
This files contains several XQuery functions you can use to load [[project specific layout and functions|project-specifics]], define information for the HTML-header etc.
A more detailed discussion of this file is available under [[project.xqm]].