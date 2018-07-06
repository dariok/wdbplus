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