Model = require './model'

fs = require 'fs'
pathHelpers = require 'path'
async = require 'async'
mkdirp = require 'mkdirp'
uuid = require 'node-uuid'
pouch = require 'pouchdb'


pouchdbDataAdapter =

    # Check existence of model in the data system.
    exists: (id, callback) ->
        id = id + '' # cast to string
        PouchdbBackedModel.db.get id, (err, doc) ->
            if err and not err.status is 404
                callback err
            else if err?.status is 404
                callback null, false
            else
                callback null, true

    find: (id, callback) ->
        id = id + '' # cast to string
        PouchdbBackedModel.db.get id, (err, doc) ->
            if err
                callback err
            else if not doc?
                callback null, null
            else
                callback null, doc

    create: (attributes, callback) ->
        if attributes.id? or attributes._id?
            attributes.id = attributes._id unless attributes.id
            attributes._id = attributes.id unless attributes._id
            func = 'put'
        else
            attributes._id = attributes.id = uuid.v4().split('-').join('')
            func = 'post'

        PouchdbBackedModel.db[func] attributes, (err, response) ->
            if err
                callback err
            else if not response.ok
                callback new Error 'An error occured while creating document.'
            else
                callback null, {id: response.id}

    save: (id, attributes, callback) ->
        attributes.docType = @getDocType()
        PouchdbBackedModel.db.get id, (err, doc) =>
            if err
                callback err
            else if not doc?
                callback new Error 'document does not exist'
            else if doc.docType.toLowerCase() isnt @getDocType().toLowerCase()
                callback new Error 'document does not exist'
            else
                attributes._id = attributes.id
                attributes._rev = doc._rev
                PouchdbBackedModel.db.put attributes, (err, response) ->
                    if err
                        callback err
                    if not response.ok
                        callback new Error """
                            An error occured while saving document.'
                        """
                    else
                        callback null, attributes

    updateAttributes: (id, attributes, callback) ->
        docType = @getDocType()
        PouchdbBackedModel.db.get id, (err, doc) ->
            if err
                callback err
            else if not doc?
                callback new Error 'document does not exist'
            else if doc.docType.toLowerCase() isnt docType.toLowerCase()
                callback new Error 'document does not exist'
            else
                for own key, value of attributes
                    throw new Error("NOW") if key is '0'
                    doc[key] = value
                PouchdbBackedModel.db.put doc, (err, response) ->
                    if err
                        callback err
                    if not response.ok
                        callback new Error """
                            An error occured while updating document.'
                        """
                    else
                        callback null, doc

    destroy: (id, callback) ->
        PouchdbBackedModel.db.get id, (err, doc) ->
            if err
                callback err
            else
                PouchdbBackedModel.db.remove doc, callback

# @todo implement me using pouchdb-quick-search
pouchdbIndexAdapter =

    search: (query, callback) ->
        callback null, []

    index: (id, fields, callback) ->
        callback null

    registerIndexDefinition: (callback) ->
        callback null


pouchdbFileAdapter =

    attach: (id, path, data, callback) ->
        [data, callback] = [null, data] if typeof(data) is "function"
        folder = pathHelpers.join "attachments", id
        mkdirp folder, (err) ->
            if err then callback err
            else
                filename = pathHelpers.basename path
                filepath = pathHelpers.join folder, filename
                source = fs.createReadStream path
                target = fs.createWriteStream filepath
                source.on 'error', callback
                source.on 'end', callback
                source.pipe target

    get: (id, filename, callback) ->
        folder = pathHelpers.join "attachments", id
        filename = pathHelpers.basename filename
        filepath = pathHelpers.join folder, filename
        source = fs.createReadStream filepath
        source.on 'error', callback
        source.on 'end', callback
        source

    remove: (id, filename, callback) ->
        folder = pathHelpers.join "attachments", id
        filepath = pathHelpers.join folder, filename
        fs.unlink filepath, callback

pouchdbBinaryAdapter =

    attach: (id, path, data, callback) ->
        [data, callback] = [null, data] if typeof(data) is "function"
        writeStream = (filepath, source, callback) ->
            target = fs.createWriteStream filepath
            source.on 'error', callback
            source.on 'end', callback
            source.pipe target

        folder = pathHelpers.join "attachments", id
        mkdirp folder, (err) ->
            if err then callback err
            else if typeof(path) is 'string'
                filename = pathHelpers.basename path
                filepath = pathHelpers.join folder, filename
                source = fs.createReadStream path
                writeStream filepath, source, callback

            else if path instanceof Buffer
                filename = data?.name or 'file'
                filepath = pathHelpers.join folder, filename
                buffer = path
                fs.writeFile filepath, buffer, callback

            else # path is a stream
                filename = data?.name or 'file'
                filepath = pathHelpers.join folder, filename
                source = path
                writeStream filepath, source, callback

    get: (id, filename, callback) ->
        folder = pathHelpers.join "attachments", id
        filename = pathHelpers.basename filename
        filepath = pathHelpers.join folder, filename
        source = fs.createReadStream filepath
        source.on 'error', callback
        source.on 'end', callback
        source

    remove: (id, filename, callback) ->
        folder = pathHelpers.join "attachments", id
        filepath = pathHelpers.join folder, filename
        fs.unlink filepath, callback

pouchdbRequestsAdapter =

    define: (name, request, callback) ->
        docType = @getDocType()
        {map, reduce} = request

        qs = map.toString()
        qs = qs.substring qs.indexOf '{'
        qs = qs.substring 0, (qs.length - 1)
        stringquery = "if (doc.docType.toLowerCase() === " + \
                      "\"#{docType}\") #{qs.toString()}};"
        stringquery = stringquery.replace '\n', ''

        ### jshint ignore: start ###
        # Function is dangerous, check if we can remove it
        try
            map = new Function "doc", stringquery
        catch error
            callback new Error "Error when parsing request's body: #{error}"
        ### jshint ignore: end ###
        view = map: map.toString()
        view.reduce = reduce.toString() if reduce?

        viewName = "_design/#{docType.toLowerCase()}"
        PouchdbBackedModel.db.get viewName, (err, designDoc) ->
            unless designDoc?
                designDoc =
                    _id: viewName
                    views: {}
            unless designDoc.views?
                designDoc.views = {}
            designDoc.views[name.toLowerCase()] = view
            PouchdbBackedModel.db.put designDoc, (err, designDoc) ->
                callback(err)

    run: (name, params, callback) ->
        [params, callback] = [{}, params] if typeof(params) is "function"
        docType = @getDocType()

        viewName = "#{docType.toLowerCase()}/#{name.toLowerCase()}"
        PouchdbBackedModel.db.query viewName, params, (err, body) ->
            if err
                callback err
            else
                callback null, body.rows

    remove: (name, callback) ->
        docType = @getDocType()
        name = '_design/' + docType.toLowerCase()
        PouchdbBackedModel.db.get name, (err, designDoc) ->
            if err
                callback err
            else
                delete designDoc.views[name.toLowerCase()]
                PouchdbBackedModel.db.put designDoc, (err, designDoc) ->
                    callback err

    requestDestroy: (name, params, callback) ->
        [params, callback] = [{}, params] if typeof(params) is "function"
        params.limit ?= 100
        @request name, params, (err, docs) ->
            if err
                callback err
            else
                async.eachSeries docs, (doc, cb) ->
                    doc.destroy cb
                , (err) ->
                    callback err


# Public: a model backed by the pouchdb data-system
#    expose the complete {Model} interface
module.exports = class PouchdbBackedModel extends Model
    @adapter         : pouchdbDataAdapter
    @indexAdapter    : pouchdbIndexAdapter
    @fileAdapter     : pouchdbFileAdapter
    @binaryAdapter   : pouchdbBinaryAdapter
    @requestsAdapter : pouchdbRequestsAdapter

    @cast: ->
        unless @__addedToSchema
            @__addedToSchema = true
            @schema._id = String
            @schema._attachments = Object
            @schema._rev = String
            @schema.id = String
            @schema.docType = String
            @schema.binaries = Object
        super
