## global CSS files

All these files define global CSS rules. While it is possible to change them
directly, the preferred way to go is via
[[project specific files|project-specifics]] as these global files may be
replaced during an update or upgrade.

|file|rules|
|--|--|
|resources/css/wdb.css|basic layout of any page – this one is loaded first by all pages in the templating system|
|resources/css/function.css| basic layout for function pages (small aside left, wide main right)|
|[[resources/css/view.css\|css-files-and-classes#viewcss]]| main layout file for _header_, _nav_, _main_ and _aside_ in of view.html|
|resources/css/search.css|additional layout for search page and results|
|[[resources/css/start.css\|css-files-and-classes#startcss]]| additional layout for `start.html`|
|[[resources/css/footnotes.css\|css-files-and-classes#footnotescss]]| additional layout for footnotes|

## overview of classes
### view.css
|class / rule / id|intended for|
|--|--|
|header|the horizontal header at the top|
|main|main text area to the left|
|nav|(global) navigation|
|#wdbRight|the right hand side|
|#fac|container for facsimile (on the right)|
|#facsimile|iframe to load facsimiles|
|#wdbShowHide|central vertical bar to adjust size|
|#wdbContent|container for text in _main_|
|footer|the footer below a text (container)|
|span.dispOpts|options in the header (usually to the right)|
|#marginalia_container|container for marginalia|

### footnotes.css
|class / rule / id|intended for|
|--|--|
|div.footnotes|container for all footnotes|
|#kritApp, #FußnotenApparat, #critApp, #apparatus|one group of notes|
|hr.fnRule|footnote rule (above)|
|a.fn_number|footnotes's identifier in the main text| 
|.fn_number_app|footnotes's identifier within the footnote|
|span.footnoteText|footnote's text (usually after the identifier)|


### start.css
|class / rule / id|intended for|
|--|--|
|#toc_title|title for the table of contents|
|div.startImage|an image to be displayed on the right|