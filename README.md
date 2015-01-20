## [Cozy](http://cozy.io) ORM

Replacement of jugglingdb for cozy application. The base class is the
[Model](http://aenario.github.io/cozydb/doc/classes/Model.html). The
[CozyModel](http://aenario.github.io/cozydb/doc/classes/CozyBackedModel.html)
is a subclass of a Model to use with the cozy-data-system.

## Use with [Americano](https://github.com/cozy/americano)

Simply add `'cozydb'` to the americano plugin list in server/config.
This will automatically declare your model's requests to the data-system.

## Changes from jugglingdb, jugglingdb-cozy-adapter and americano-cozy

### .api

Expose utility functions for accessing some cozy informations.
[all available functions](http://aenario.github.io/cozydb/doc/classes/Api.html)

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

## Contribution

You can contribute to the Cozy Data System in many ways:

* Pick up an [issue](https://github.com/aenario/cozydb/issues?state=open) and solve it.
* Write new tests.

## Tests

[![Build
Status](https://travis-ci.org/aenario/cozydb.png?branch=master)](https://travis-ci.org/aenario/cozydb)

Run tests with following commmand

    npm test


## Before submitting a pull request

Make sure you have build & linted your code with

    npm run prepublish



## License

Cozydb is developed by Cozy Cloud and distributed under the AGPL v3 license.

## What is Cozy?

![Cozy Logo](https://raw.github.com/mycozycloud/cozy-setup/gh-pages/assets/images/happycloud.png)

[Cozy](http://cozy.io) is a platform that brings all your web services in the
same private space.  With it, your web apps and your devices can share data
easily, providing you
with a new experience. You can install Cozy on your own hardware where no one
profiles you.

## Community

You can reach the Cozy Community by:

* Chatting with us on IRC #cozycloud on irc.freenode.net
* Posting on our [Forum](https://groups.google.com/forum/?fromgroups#!forum/cozy-cloud)
* Posting issues on the [Github repos](https://github.com/mycozycloud/)
* Mentioning us on [Twitter](http://twitter.com/mycozycloud)
