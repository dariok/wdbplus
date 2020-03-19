# What scripts need to do
Currently, `XSLT` is the only type script that is well-supported by the app. XQuery and others might follow if the need arises.

As the app already provides an HTML frame (by means of eXist’s templating system, see [[Main-HTML-files]]), any script generating HTML output does not need to concern itself with the HTML header, the head portion or the display area for annotations and images on the right. Instead, all that needs to be done is generate a (series of) div(s) that will live inside the `html:main` displayed on the left.

# How to specify which script to use
The script to use is best specified within [[wdbmeta.xml]]. It is possible to supply a parameter `view` that will be passed to the script as a paramter `$view`.