## Changes from jugglingdb, jugglingdb-cozy-adapter and americano-cozy

### .api

Expose utility functions for accessing some cozy informations.
[all available functions](http://cozy.github.io/cozy-db/doc/classes/Api.html)

```coffeescript
require('cozydb').api.getCozyLocale (err, locale) ->
```

Warning: You still need to ask the proper permissions in package.json

### subclassing

Model and CozyBackedModel are simple Coffeescript class, you can easily extends
them :

```coffeescript
class Note extends cozydb.CozyModel
class MagickNote extends Note
```

### Model.first

Get the first instance of a Model, or null if none exists


## v0.0.3

- Support for pouchdb & cozy-light :Simply pass a db or dbname option to
americano start method.
- Better documentation