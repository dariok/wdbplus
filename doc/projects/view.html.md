# view.html
By using standard [[project-specifics]], the functions and styling of any resource displayed via `view.html` can be changed to  a project’s needs.
There are 2 more options to extend `view.html`:

1. a file `projectFooter.html` in the project’s resource collection or a function `wdbPF:getProjectFooter` will be included as a footer below the text content on the left (and similarly in all pages created by using the function.html template);
1. a file `projectRightFooter.html` in the project’s resource collection or a function `wdbPF:getProjectRightFooter` will be included on the right (after `#fac`); this can e.g. be used to attach a viewer.

If both an HTML file and a function are present, the HTML file will take precedence.
