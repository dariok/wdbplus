By default, `start.html` is contructed as follows:

- the header uses the applicatio title as specified in `wdbmeta.xml` (or `mets.xml` as fallback)
- the left is a navigation the generation of which can be changed by [[Project-specifics]]
- the right is a generic display of text and images

It is possible to overwrite the default behaviour in 2 ways:
- Use HTML templates in the project's `resoucres` folder (this means: `${directoryOfProject.xqm}/resources`) named
`startHeader.html`, `startLeft.html`, and/or `startRight.html` respectively; if used, it should contain the contents to be displayed in a div
- Use [[Project-specifics]] by implementing `wdbPF:getStartHeader()`, `wdbPF:getStartLeft()`, and/or `wdbPF:getStart()`, respectively.

You can mix-and-match all three approaches. The order is 1. HTML, 2. wdbPF, 3. generic.

Similar to the mechanism in [[Project-specifics]], after the global scripts are loaded, `projectStart.css` and `projectStart.js` are being searched for in `${directoryOfProject.xqm}/resources/`. You can create one or both and overwrite any settings/functions you like to style `starthtml` to your needs.