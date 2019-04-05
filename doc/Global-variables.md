# Global variables
## $model

In several instances, most prominently in `app.xqm`, a parameter called `$model` is passed to functions.
This is part of eXist's templating system and has been used in several locations to allow for uniform distribution of common parameters.

`$model` always is a `map(*)`. The most important parameters MUST be the same in all instances. This means:

| parameter | contents |
|--|--|
| `id` | a file's ID (e.g. file to be displayed) |
| `title` | the title of the file or project |
| `ed` | the ID of the project (= `@xml:id` of `meta:projectMD` or `mets:mets`) |
| `pathToEd` | the full DB-Path to the project |
| `fileLoc` | full path to the current file |
| `infoFileLoc` | full path to `wdbmeta.xml` or `mets.xml` |
| `xslt` (app.xqm only) | full path to the XSLT to be used for transformation |
| `view` (app.xqm only) | the `view` query parameter as pass in the call to `view.html` |
| `p` (function.xml only) | all values from `p` query parameter parsed into a `map(*)` |

## parameters in `wdb` namespace
The [[wdb namespace|list-of-namespaces]] contains several global parameters that can be accessed from every script that imports `app.xql`:

|name|contents|
|--|--|
|`$wdb:edocBaseDB`| same as `$config:root` – the path to where the application is installed within `/db/`.|
|`$wdb:configFile`| the (parsed) config file (`{$wdb:edocBaseDB}/config.xml`).|
|`wdb:data`| the path to the data collection. It is assumed that this is the top collection with a `wdbmeta.xml` file.|
|`wdb:server`| the server's address including protocol and port – if automatic resolution does not work, set it manually in [[config.xml\|global-configuration]].|
|`$wdb:edocBaseURL`| the full URL to the app's root or the current subcollection.|
|`$wdb:role`| the [[role\|server-roles]] of this instance.|
|`$wdb:peer`| this instance's peer, if it is a workbench.|
