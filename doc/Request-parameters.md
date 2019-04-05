##Common parameters
The following [[main HTML files|main-html-files]]

- `.../edoc/view.html?`
- `.../edoc/query.html?`
- `.../edoc/search.html?`
- `.../edoc/start.html?`

all use the the `id` parameter to identify a project or file.

Some pages and functions may support the `ed` parameter that supplies a relative path to a project. As of March 2019, though, this parameter is deprecated and is likely to be removed. If both `ed` and `id` are present, the `id` parameter will take precedence. To avoid surprises, you should ensure that only one is used in any page call, though.

##Additional parameters
Some function pages (e. g. `query.html`) support and additional parameters `p`. It MUST have the form of a JSON object
and will be parsed as a `map(*)` in `$model("p").