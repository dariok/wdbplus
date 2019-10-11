# Global Configuration

All global configuration options, i.e. those that affect how the app works, are set in `$approot/config.xml`.
If you use the [[default setup|basic-collection-structure#default-structure]], `$approot := /db/apps/edoc`.

## Settings in `config.xml`
### meta
- `name` – a long title for this instance of the app
- `short` – a short title, e.g. to be used in `html:title`

### role
- `type` – the [[role|server-roles]] of this instance
- `peer` – for a _workbench_, this points to the House of Lords, i.e. the _publication_ instance

See the documentation of the [[server roles|server-roles]] for more detail.

### params
- `param` – a key-value pair for global parameters that are available in all scripts and will be passed on to the model.

Not really implemented yet but planned for version 2.0.

### server
A full URL, reachable from the outside, to be used if the automatic resolution in `app.xql` does not work or needs to be overwritten. This needs to point to the collection containg `config.xml` (thus, the standard setting would be `http://yourexist.tld/exist/apps/edoc/`)– a setting here overwrites the automatic processing and will be globally available as `$wdb:edocBaseURL`, the server's name (or IP) as `$wdb:server`.
While all standard scripts should be able to figure this out correctly, certain setups may cause problems.

Scripts invoked via RESTXQ will not be able to use automatic resolution – if you need the base URL from within a RESTXQ endpoint (e.g. for the IIIF image descriptor), you MUST set this option.

### rest
A full URL which is the base for REST calls. This will be used by JavaScript functions, e.g. to load navigation or to insert/retrieve annotations. This must be set if the rest endpoint is not available under the usual location (i.e. `http://yourexist.tld/exist/restxq/edoc/` for the standard setup). This might be the case if you hid parts of the standard path by eXist's configuration or reverse proxying.

NB: this needs to include the “edoc/” part

## Projects
In order to create a project, you have to create a collection for it and make the most important settings in `wdbmeta.xml`. The initial settings can be done using `admin/admin.html` (New Project).
After that, you have to add at least one view and an entry for every file you want to access.