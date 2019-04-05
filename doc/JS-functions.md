## Files declaring JavaScript functions

| file | used for |
|--|--|
| resources/scripts/admin.js | in admin functions|
| resources/scripts/annotate.js| user annotations in texts|
| resources/scripts/function.js| main functionality|

## functions declared for common use

### annotate.js
|function|use|
|--|--|
|anno()|prompt for simple annotation text and forward text and IDs to `insert.xql`|
|$(document).ready()|load annotations from `return.xql`|

### function.js
|function|use|
|--|--|
|$(document).ready()| evaluate **&l=from-to** and highlight elements with ID from, to and all in between|
|loadTargetImage()| load the image for the page where #target is located – calls _displayImage(href)_|
|marginPos(), positionMarginalia (index, element)| position marginalia within a `div class="#marginalia_container`|
|getPosition(el)| get the (absolute) vertical position of _el_|
|mouseIn(event)| load a note into _#ann_ – contains legacy code for hovering boxes|
|mouseOut(event)| remove legacy hovering box after timeout|
|show_annotation(dir, xml, xsl, ref, height, width)| show info from `entity.html` in _#ann_|
|clear(id)|close _#id_ or all info displayed in _#ann_|
|commonAncestor(e1, e2)|find the common ancestor for _#e1_ and _#e2_|
|sprung(event)|highlight a section defined by 'targ' und 'targe'|
|highlightAll(startMarker, endMarker, color, alt)|highligh _#startMarker_, _#endMarker_, and all elements in between with $color and optionally display $alt as text|
|toggleNavigation()|display/hide _#nav_|
|getUniqueId()|return an ID that is unique at runtime|
|doLogout()|log out|
|displayImage(href)|actually display href in _#facsimile_|
|toggleRightside()|adjust width of _#wdbContent_ to 75% or back to 50%|
|close()|hide the facsimile|