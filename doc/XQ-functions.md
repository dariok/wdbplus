## List of XQuery functions for use in custom functions

The following is an (incomplete) list of the public functions declared within the app.
These might be helpful for your own scripts.
A more detailed description is available in eXist's function documentation.
If it has been properly generated, it should also provide content completion in eXide.

### app.xql

|function|use|
|--|--|
|`wdb:populateModel($id, $view, $model)`|Add more information to `$model` for use in other functions.|
|`wdb:getUrl($path)`|Return a full URL for a relative DB path.|
|`wdb:getEdPath($path, $absolute)`|Return the (relative or absolute) path to a resource.|
|`wdb:findProjectFunction($model, $name, $arity)`|Returns true if the project with the path given in `$model("pathToEd")` has a [[project.xqm]] which declares a public function `$name` (the name is to be the local name only) with `$arity` parameters.|
|`wdb:eval($function)`|Calls `util:eval($function)` and is subject to the same constraints (especially, the function name needs to be prefixed here; for project specifics: “wdbPF”); as this is within the scope of `app.xql`, it works immediately after calling `wdb:findProjectFunction` and also from another XQuery (while calling `util:eval` from another file will not work as the import is out of scope).|