(This information is correct for version 2.0 – 22Q1)

## How to customize

By default, `start.html` is contructed as follows:

- the header uses the application title as specified in `wdbmeta.xml`
- the left is a navigation the generation of which can be changed by [[Project-specifics]]
- the right is a generic display of text and images which can also be adapted as needed

It is possible to overwrite the default behaviour in several ways:
- By default, the contents on the right are created from `wdbmeta.xml` by a generic XSLT,
  `{$edocBaseDB}/resources/start.xsl`. This can be overridden or extended (via `xsl:import`) by an instance specific
  global XSLT, `{$wdb:data}/resources/start.xsl`.
- Use HTML templates in the project's `resoucres` folder (see [[Project-specifics]] for details) named
  `startHeader.html`, `startLeft.html`, and/or `startRight.html` respectively; if used, each file should contain the
  contents to be displayed in a single `html:div`.
- Use [[Project-specifics]] by implementing `wdbPF:getStartHeader()`, `wdbPF:getStartLeft()`, and/or `wdbPF:getStart()`.

The preferred mechanism is to write a global extension to `start.xsl` as this maintains consistency across all projects
  and requires the meta data in `wdbmeta.xml` to be up-to-date.
  
If you really want to adjust `start.html` on a by-project basis, all three approaches. The order is 1. project specific
  HTML; 2. functions `wdbPF:*()` in `project.xqm`; 3. `{$wdb:data}/resources/start.xsl` for the right hand side; 4.
  `{$wdb:edocBaseDB}/resources/start.xsl` for the right hand side.

Similar to the mechanism in [[Project-specifics]], after the generic and global `start.css` and `function.js` are
  loaded, `projectStart.css` and `projectStart.js` are being searched for in `{$pathToEd}/resources/`. You can create
  one or both and overwrite any settings/functions you like to style `starthtml` to your needs.
  
## A word on images

Images are loaded from the URLs given in `//meta:coverImages/meta:image/@href`. It is possible to have multiple images
  in here. The CSS is prepared in such a way that all images `.slideImage` will be centered within `.slideContainer`.
  However, there is no further styling (esp. no animation) as these will differ between projects and e.g. the number of
  images included. To facilitate e.g. a simple slider, though, the images are `position: absolute` within the container.
  A `max-height: 40vh` and `max-width: 40%` should take care of most needs for animations etc. but you can of course
  use any setting you may need in a global `start.css` or `projectStart.css`.