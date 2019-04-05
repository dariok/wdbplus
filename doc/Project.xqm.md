## General
`project.xqm` is the central file controlling how a project is displayed. By implementing the functions described below, you can load special JavaScript and CSS files (useful if your needs can't be met by simple project.css/project.js), adapt how the title is displayed (in the HTML `header`), or adjust the project's start page (as displayed by `start.html`).
To help maintaining a clean structure and a common page layout, `project.xqm` is cascading: if none is present in a project's collection, the search continues upwards. If all of your projects share the settings available here, you might be able to just have one `project.xqm` in your data collection.

## Functions in project.xqm
While none of these functions has to be implemented, at least `wdbPF:getHeader` should be present to display a meaningful head.
See also [[project specific layout and functions|project-specifics]].

### wdbPF:getProjectFiles($model)
return `html:link` and `html:script` elements to be included in the `html:head`.

### wdbPF:getHeader($model)
return the content for `html:header`: one `html:h1`, one `html:h2` and 0+ `html:span` with class 'dispOpts' for links used all over the project.

### wdbPF:getImages($id, $page)
return the full path for the image of $page in document $id – used in the creation of an IIIF manifest.

### wdbPF:getStart($model)
return a sequence of nodes that will be the right hand side of `start.html`.

### wdbPF:getNavXSLT()
return an `xs:anyURI` pointing to the XSLT that should be used to transform the response of `nav.xql` for displaying the navigation. This is only necessary if there is no `vav.xsl` present in the project collection and you don't want to use the global stylesheet ad `wdb:edocBaseDB/resources/nav.xsl`.