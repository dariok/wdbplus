# Main HTML files

## files in `$approot`

### entity.html
This file will be included via AJAX if additional information for an “entity” is to be displayed.
Here, entity is to be understood as ”POKb” (German: _Personen, Orte, Körperschaften, bibliographische Angaben_ – “persons, places, organizations, bibliographic data”) for which additional information is supplied from an index file or external source.

_Template:_ `page2.html`

### index.html
Serves as the main point of entry by displaying an inventory of all projects currently present in the instance. It is assumed, that every project uses a `wdbmeta.xml` and that every `wdbmeta.xml` describes a project. Thus, subprojects are recognized.
Projects that solely rely on a `mets.xml` will be recognized and displayed, too. Subporjects for a METS-project are not supported, though.

_Template:_ `page2.html`

### query.html
A wrapper page for XQuery scripts that should display their input or result via the templating system. See [[the page on project specific setting||project-specifics#queries]] for more detail on how to use this.

_Template:_ `function.html`

### search.html
Does roughly the same as query.html but is made especially for search pages. It wraps input/output for full text searches and includes some help.

_Template:_ `function.html`

### start.html
This file is to be called with an ID parameter pointing to the project: `{$edocBaseURL}/start.html?id=projectID`. It will display a start page for that project. By default, this will be the navigation as defined by `wdbmeta.xml` or `mets.xml` and optionally additional content created by `start.xml`, possibly a local `start.xsl` (if none exists, a global stylesheet will be used) and a local `start.css` (a global CSS will be loaded first).

To customize it, you can either create HTML fragments called `startHeader.html`, `startLeft.html`,  or `startRight.html` or implement functions in `project.xqm` (`wdbPF:getStartHeader`, `wdbPF:getStartLeft`, `wdb:getStart`). HTML files will take precedence over functions which will take precedence over the generic function.

_Template:_ `function.html`

### view.html
The main entry point to display an HTML representation of an XML file in any project.

_Template:_ `layout.html`
