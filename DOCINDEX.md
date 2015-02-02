## [Cozy](http://cozy.io) ORM

Replacement of jugglingdb for cozy application.

## Exports

This module exports several things
- cozydb.[CozyModel](./classes/CozyBackedModel.html) is the class your
models should inherit from. It is an implementation of the
[Model](./classes/Model.html) interface.

- cozydb.[api](./classes/Api.html) expose various function to access data
from the cozy (such as locale, timezone, owner email ...)

- cozydb.[SimpleController](./classes/Controller.html) is a controller which
expose express middlewares to easily work with cozydb Models.
```


## Usage

```coffeescript
# Existence
Note.exists 123, (err, isExist) ->
    console.log isExist

# Find
Note.find 321, (err, note) ->
    console.log note

# Create
Note.create { "content":"created value"}, (err, note) ->
    console.log note.id # 321

# Update attributes
Note.updateAttributes "321", title: "my new title", (err) ->

# Delete
Note.destroy "321", (err) ->

# you can also call the function on model instances
note.updateAttributes title: "my new title", (err) ->
    console.log err
note.destroy (err) ->
    console.log err
```


### Indexation

```coffeescript
# Index document fields
note.index ["title", "content"], (err) ->
    console.log err
Note.index "321", ["title", "content"], (err) ->

# Search through indexes
Note.search "dragons", (err, notes) ->
    console.log notes
```


### Files

```coffeescript
# Attach file
note.attachFile "./test.png", (err) ->
    console.log err

# Get file
stream = @note.getFile "test.png", (err) ->
     console.log err
stream.pipe fs.createWriteStream('./test-get.png')
```

## Use with [Americano](https://github.com/cozy/americano)

Simply add `cozydb` to the americano plugin list in server/config.
The americano plugin will fetch `./models/requests.coffee`
and register the requests on the data-system.

If you dont use americano, you can manually create your requests with
[defineRequest](./classes/Model.html#defineRequest-class)
