# Global variables
## $model

In several instances, most prominently in `app.xql`, a parameter called `$model` is passed to functions.
This is part of eXist's templating system and has been used in several locations to allow for uniform distribution of common parameters.

`$model` always is a `map(*)`. The most important parameters MUST be the same in all instances. This means:

| parameter | contents |
|--|--|
| `id` | a file's ID (e.g. file to be displayed) |
| `title` | the title of the file or project |
| `ed` | the document within the local structure, i.e. relative to `$wdb:data`|
| `pathToEd` | the full DB-Path to the project's collection|
| `fileLoc` | full path to the current file|
| `infoFileLoc` | full path to `wdbmeta.xml` or `mets.xml`|

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
