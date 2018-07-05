# Global Configuration

All global configuration options, i.e. those that affect how the app works, are set in `$approot/config.xml`.
If you use the [[default setup|basic-collection-structure#default-structure]], `$approot` is `/db/apps/edoc`.

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
A complete URL to be used if the automatic resolution in `app.xql` does not work. This needs to point to the collection containg `config.xml` – a setting here overwrites the automatic processing and will be globally available as `$wdb:edocBaseURL`.