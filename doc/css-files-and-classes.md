## global CSS files

All these files define global CSS rules. While it is possible to change them directly, the preferred way to go is via [[project specific files|project-specifics]] as these global files may be replaced during an update or upgrade.

|file|rules|
|--|--|
|[[resources/css/common.css\|css-files-and-classes#commoncss]]| basic layout of any main page|
|[[resources/css/footnotes.css\|css-files-and-classes#footnotescss]]| additional layout for footnotes|
|[[resources/css/function.css\|#function]]| additional layout for function pages (e.g. search)|
|[[resources/css/index.css\|#index]]| additional layout for `index.html` and other wide pages – includes `common.css`|
|[[resources/css/main.css\|css-files-and-classes#maincss]]| main layout file for _header_, _nav_, _main_ and _aside_ in an HTML page|
|[[resources/css/start.css\|#start]]| additional layout for `start.html` – includes `common.css`|

## overview of classes
### common.css
|class / rule / id|intended for|
|--|--|
|a.upRef|link back to top|
|:target|target of a link|
|[lang=grc], [lang=he], [lang=he]|text in foreign language|
|p.editors|editors etc. of a text|
|.info|iformation displayed in aside or hovering|
|#wip|“work in progress” information|
|.footer|footer in an HTML generated from XML|
|table.noborder|table without visible border|
|span.infoContainer|container for .info|
|div.ccsec|license information|
|img.ccimg|image for .ccsec|
|.subscript|subscript|
|.superscript|superscript (size adjusted)|
|.blockquote|long citations|
|p.content|main text content|
|span.orig|original text (e.g. for critical footnotes)|
|span.nameSC|name in small caps|
|#rDis|central div with » or «|
|#auth|login containter|
|#ann|annotation display within/on top of _aside_|
|.start|container on the right hand side of a `start.html`|

### footnotes.css
|class / rule / id|intended for|
|--|--|
|div.footnotes|container for all footnotes|
|#kritApp, #FußnotenApparat, #critApp, #apparatus|one group of notes|
|hr.fnRule|footnote rule (above)|
|a.fn_number|footnotes's identifier in the main text| 
|.fn_number_app|footnotes's identifier within the footnote|
|span.footnoteText|footnote's text (usually after the identifier)|

### main.css
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

### start.css
|class / rule / id|intended for|
|--|--|
|#toc_title|title for the table of contents|
|div.startImage|an image to be displayed on the right|