util = require 'util'
fs = require 'fs'

deprecated = ->
    if process.env.NODE_ENV not in ['test', 'production']
        console.log new Error('deprecated').stack

_wrapCallback = (that, changes, callback) ->
    (err, data) ->
        return callback err if err
        if data?.success
            that[key] = value for key, value of changes
        else
            that[key] = value for key, value of data
        callback null, that

{NotOnNewModel} = require './utils/errors'


# Public: the model class
class Model

    # STATIC FUNCTIONS
    # Private: get the Model's docType
    #
    # Returns {String} the model docType
    @getDocType: -> this.docType?.toLowerCase() or this.name.toLowerCase()

    # Public: check if a model with given Id exists.
    #
    #
    # id - {String}, id of the model we are looking for
    # callback - Function({Error} err, Boolean exists)
    #
    # Returns null
    @exists: (id, callback) ->
        @adapter.exists id, callback

    # Public: find a model by its Id (GET)
    #
    # id - {String}, id of the model we are looking for
    # callback - Function({Error} err, Model result)
    #
    # Returns null
    @find: (id, callback) ->
        @adapter.find id, (err, attributes) =>

            if err
                return callback err

            else if attributes?.docType?.toLowerCase() isnt @getDocType()
                return callback null, null

            else
                return callback null, new this(attributes)

    # Public: create a new instance of this model (POST)
    #
    # data - Object, arguments for the new model
    # callback - Function({Error} err, {Model} created)
    #
    # Returns null
    @create: (data, callback) ->
        data.docType = @getDocType()
        data = @cast data
        @adapter.create data, (err, attributes) =>
            return callback err if err
            data[k] = v for k,v of attributes
            callback null, new (this)(data)

    # Public: save (create or update) a model whole state (PUT)
    #
    # id - {String}, id of the model to update
    # data - Object, new attributes for the model
    # callback - Function({Error} err, {Model} updated)
    #
    # Returns null
    @save: (id, data, callback) ->
        @adapter.save id, data, (err, attributes) =>
            callback null, new this(attributes)

    # Public: change some attributes of the model (PATCH)
    #
    # id - {String}, id of the model to update
    # data - Object, changed attributes for the model
    # callback - Function({Error} err, Model updated)
    #
    # Returns null
    @updateAttributes: (id, data, callback) ->
        @adapter.updateAttributes id, data, (err, updated) =>
            callback null, new this(updated)


    # Public: delete a model by its Id
    #
    # id - {String}, id of the model to delete
    # callback - Function({Error} err)
    #
    # Returns null
    @destroy: (id, callback) ->
        @adapter.destroy id, callback

    # Public: find docs by FTS
    #
    # query - {String}, string to search
    # callback - Function({Error} err, [{Model}] results)
    #
    # Returns null
    @search: (query, callback) ->
        @indexAdapter.search.call @, query, (err, objects) =>
            return callback err if err
            callback null, objects.map (row) => new this row


    # methods that are both static and instance
    @index: (id, fields, callback) ->
        @indexAdapter.index.call @, id, fields, callback


    # FILES & BINARIES FUNCTIONS

    # Public: attach a file to the object
    #
    # id - {String}, id of the model to update
    # path - {String} path or [Buffer](http://nodejs.org/api/buffer.html) or
    #        [Stream](http://nodejs.org/api/stream.html)
    # data - Object options linked with upload
    #        :filename - {String} Name of the file
    # callback - Function({Error} err)
    #
    # Returns null
    @attachFile: (id, path, data, callback) ->
        @fileAdapter.attach id, path, data, callback


    # Public: get an attached file as a stream
    #
    # id - {String}, id of the model to update
    # path - {String}, path or [Buffer](http://nodejs.org/api/buffer.html) or
    #        [Stream](http://nodejs.org/api/stream.html)
    # data - Obejct options linked with upload
    #        :filename - {String} Name of the file
    # callback - Function({Error} err,
    #               [Stream](http://nodejs.org/api/stream.html) stream})
    #
    # Returns a [Stream](http://nodejs.org/api/stream.html) for the model
    @getFile: (id, path, callback) ->
        @fileAdapter.get id, path, callback


    # Public: [DEPRECATED] save an attached file to disk
    #
    # id - {String}, id of the model to update
    # path - {String}, Name of the attachment
    # filePath - {String}, path to save to
    # callback - Function({Error} err)
    #
    # Returns null
    @saveFile: (id, path, filePath, callback) ->
        deprecated()
        @fileAdapter.get id, path, filePath, (err, res) ->
            return callback err if err
            res.pipe writeStream = fs.createWriteStream filePath
            writeStream.on 'finish', -> callback null, res


    # Public: remove an attached file
    #
    # id - {String}, id of the model to update
    # path - {String}, Name of the attachment
    # callback - Function({Error} err)
    #
    # Returns null
    @removeFile: (id, path, callback) ->
        @fileAdapter.remove id, path, callback

    # Public: attach a file to the object
    #
    # id - {String}, id of the model to update
    # path - {String}, path or [Buffer](http://nodejs.org/api/buffer.html) or
    #       [Stream](http://nodejs.org/api/stream.html)
    # data - Obejct options linked with upload
    #        :filename - {String} Name of the file
    # callback - Function({Error} err)
    #
    # Returns null
    @attachBinary: (id, path, data, callback) ->
        [data, callback] = [null, data] if typeof(data) is "function"
        @binaryAdapter.attach id, path, data, callback

    # Public: get an attached file as a stream
    #
    # id - {String}, id of the model to update
    # path - {String}, path or [Buffer](http://nodejs.org/api/buffer.html) or
    #        [Stream](http://nodejs.org/api/stream.html)
    # data - Obejct options linked with upload
    #        :filename - {String} Name of the file
    # callback - Function({Error} err,
    #               [Stream](http://nodejs.org/api/stream.html) file)
    #
    # Returns a {LaterStream} for the file
    @getBinary: (id, path, callback) ->
        @binaryAdapter.get id, path, callback


    # Public: [DEPRECATED] save an attached file to disk
    #
    # id - {String}, id of the model to update
    # path - {String}, Name of the attachment
    # filePath - {String}, path to save to
    # callback - Function({Error} err)
    #
    # Returns null
    @saveBinary: (id, path, filePath, callback) ->
        deprecated()
        @binaryAdapter.get id, path, filePath, (err, res) ->
            return callback err if err
            res.pipe writeStream = fs.createWriteStream filePath
            writeStream.on 'finish', -> callback null, res

    # Public: remove an attached file
    #
    # id - {String}, id of the model to update
    # path - {String}, Name of the attachment
    # callback - Function({Error} err)
    #
    # Returns null
    @removeBinary: (id, path, callback) ->
        @binaryAdapter.remove id, path, callback

    # REQUESTS FUNCTION


    # Public: Define a map/reduce request for this model
    #
    # name - {String}, name of the request
    # request - a single {Function} (map only) *OR* an object with properties
    #        :map - {Function}
    #        :reduce -  {Function}
    # callback - Function({Error} err)
    #
    # Returns null
    @defineRequest: (name, request, callback) ->

        if typeof(request) is "function" or typeof(request) is 'string'
            map = request
        else
            map = request.map
            reduce = request.reduce

        @requestsAdapter.define.call this, name, {map, reduce}, callback


    # Public: Get results for defined request for this model
    #
    # name - {String}, name of the request
    # request - Couchdb query params
    # callback - Function({Error} err, [{Model}] results)
    #
    # Returns null
    @request: (name, params, callback) ->
        [params, callback] = [{}, params] if typeof(params) is "function"
        @rawRequest name, params, (err, results) =>
            return callback err if err
            callback null, results.map (row) => new this row.value


    # Public: Get results for defined request for this model
    # pass the results as an array of object with id, key, value properties
    #
    # name - {String}, name of the request
    # request - Couchdb query params
    # callback - Function({Error} err, )
    #
    # Returns null
    @rawRequest: (name, params, callback) ->
        [params, callback] = [{}, params] if typeof(params) is "function"
        @requestsAdapter.run.call this, name, params, callback


    # Public: remove a Request
    #
    # name - {String}, name of the request
    # callback - Function({Error} err)
    #
    # Returns null
    @removeRequest: (name, callback) ->
        @requestsAdapter.remove.call this, name, callback


    # Public: Destroy results for defined request for this model
    #
    # name - {String}, name of the request
    # request - Couchdb query params
    # callback - Function({Error} err)
    #
    # Returns null
    @requestDestroy: (name, params, callback) ->
        [params, callback] = [{}, params] if typeof(params) is "function"
        params.limit ?= 100
        @requestsAdapter.requestDestroy.call this, name, params, callback


    # Public: List all instance of a model
    # assume the model has an "all" request
    #
    # params - optional {Object} requests params (see couchdb doc)
    # callback - Function({Error} err, [{Model}] results)
    #
    # Returns null
    @all: (params, callback) ->
        [params, callback] = [{}, params] if typeof(params) is "function"
        @request 'all', params, callback

    # Public: Find the first item of this kind
    # useful for singleton type Model
    #
    # callback - Function({Error} err, {Model} found or null)
    #
    # Returns null
    @first: (callback) ->
        @all (err, items) ->
            callback err, items?[0] or null


    # Public: cast a POJO using this model schema
    #
    # attributes - {Object} to cast
    # target - optional {Object} that will be filled with cast properties
    #
    # Returns {Object} target
    @cast: (attributes, target = {}) ->
        castObject attributes, @schema, target, @name


    @destroyAll: (params, callback) ->
        [params, callback] = [{}, params] if typeof(params) is "function"
        @requestDestroy 'all', params, callback


    # instance methods

    # Public: constructor
    #
    # attributes - Object, attributes of the model
    #
    # Returns a {Model} instance
    constructor: (attributes) ->

        attributes ?= {}
        @constructor.cast attributes, this
        @id ?= attributes._id if attributes._id

    # Public: [DEPRECATED] save
    #
    # update or create a model
    #
    # callback - Function({Error} err, {Model} updated)
    #
    # Returns null
    save: (callback) ->
        cb = _wrapCallback @, {}, callback
        if @id
            @constructor.adapter.save
            .call @constructor, @id, @getAttributes(), cb
        else
            @constructor.adapter.create.call @constructor, @getAttributes(), cb

    # Public: updateAttributes
    #
    # apply changes to model (dont change other fields)
    #
    # attributes - Object changes to apply
    # callback - Function({Error} err, {Model} updated)
    #
    # Returns null
    updateAttributes: (attributes, callback) ->
        return callback NotOnNewModel() unless @id
        cb = _wrapCallback @, attributes, callback
        @constructor.adapter.updateAttributes
        .call @constructor, @id, attributes, cb


    # Public: desttroy
    #
    # Remove the model from the DB
    #
    # callback - Function ({Error} err)
    #
    # Returns null
    destroy: (callback) ->
        return callback NotOnNewModel() unless @id
        @constructor.destroy.call @constructor, @id, callback


    # Public: index
    #
    # Index some fields on this model
    #
    # fields - [{String}] fields to index
    # callback - Function ({Error} err)
    #
    # Returns null
    index: (fields, callback) ->
        return callback NotOnNewModel() unless @id
        @constructor.indexAdapter.index.call @constructor, @id, fields, callback

    # Public: attach a file to the object
    #
    # Instance version of {.attachFile}
    attachFile: (path, data, callback) ->
        return callback NotOnNewModel() unless @id
        @constructor.attachFile.call @constructor, @id, path, data, callback


    # Public: get an attached file as a stream
    #
    # Instance version of {.getFile}
    getFile: (path, callback) ->
        return callback NotOnNewModel() unless @id
        @constructor.getFile.call @constructor, @id, path, callback


    # Public: [DEPRECATED] save an attached file to disk
    #
    # Instance version of {.saveFile}
    saveFile: (path, filePath, callback) ->
        return callback NotOnNewModel() unless @id
        @constructor.saveFile.call @constructor, @id, path, filePath, callback

    # Public: remove an attached file
    #
    # Instance version of {.removeFile}
    removeFile: (path, callback) ->
        return callback NotOnNewModel() unless @id
        @constructor.removeFile.call @constructor, @id, path, callback


    # Public: attach a file to the object
    #
    # Instance version of {.attachBinary}
    attachBinary: (path, data, callback) ->
        return callback NotOnNewModel() unless @id
        @constructor.attachBinary.call @constructor, @id, path, data, callback

    # Public: get an attached file as a stream
    #
    # Instance version of {.getBinary}
    getBinary: (path, callback) ->
        return callback NotOnNewModel() unless @id
        @constructor.getBinary.call @constructor, @id, path, callback


    # Public: [DEPRECATED] save an attached file to disk
    #
    # Instance version of {.saveBinary}
    saveBinary: (path, filePath, callback) ->
        return callback NotOnNewModel() unless @id
        @constructor.saveBinary.call @constructor, @id, path, filePath, callback

    # Public: remove an attached file
    #
    # Instance version of {.removeBinary}
    removeBinary: (path, callback) ->
        return callback NotOnNewModel() unless @id
        @constructor.removeBinary.call @constructor, @id, path, callback



    # Public: getAttributes
    #
    # Returns this model attributes as a POJO
    #
    # Returns Object
    getAttributes: ->
        out = {}
        for own key, value of this
            out[key] = value
        return out

    toJSON: -> @getAttributes()
    toObject: -> @getAttributes()
    toString: -> @constructor.getDocType() + JSON.stringify @toJSON()

module.exports = Model
{castObject} = require './utils/type_checking'
