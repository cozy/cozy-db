
# Public: the Model constructor
module.exports.Model = Model = require './model'

# Public: the CozyModel constructor
module.exports.CozyModel = CozyModel = require './cozymodel'

module.exports.SimpleController = Controller = require './controller'

{NoSchema} = require './utils/type_checking'
module.exports.NoSchema = NoSchema

# jshint
emit = ->

module.exports.defaultRequests = defaultRequests =
    all: (doc) -> emit doc._id, doc
    tags: (doc) -> emit(tag, doc) for tag in doc.tags or []
    by: (field) ->
        ((doc) -> emit doc.FIELD, doc).toString().replace 'FIELD', field


module.exports.api = api = require './api'

module.exports.getModel = (name, schema) ->

    # Internal: Generated Class from getModel
    klass = class ClassFromGetModel extends CozyModel
        @schema: schema

    klass.displayName = klass.name = name
    klass.toString = -> "#{name}Constructor"
    klass.docType = name

    return klass

log = ->
    return null if process.env.NODE_ENV is 'test'
    console.log.apply console, arguments

# to use cozydb as an americano module
# Plugin configuration: run through models/requests.(coffee|js) and save
# them all in the Cozy Data System.
module.exports.configure = (options, app, callback) ->

    callback ?= ->
    if typeof options is 'string'
        options = root: options

    # if we are given a db or dbName options
    # the app is meant to be used standalone
    if options.db or options.dbName
        try
            Pouch = require 'pouchdb'
            PouchModel = require './pouchmodel'
            module.exports.CozyModel = CozyModel = PouchModel
            if options.db
                PouchModel.db = options.db
            else
                options.dbName ?= process.env.POUCHDB_NAME or 'cozy'
                PouchModel.db = new Pouch options.dbName

        catch err
            console.log err
            return callback err

    modelPath = "#{options.root}/server/models/"


    # get the requests file
    try requests = require modelPath + "requests"
    catch err
        log "failed to load requests file", err
        return callback err


    # get all requests from the request file into an array
    requestsToSave = []
    for docType, requestDefinitions of requests
        model = require modelPath + docType

        for requestName, requestDefinition of requestDefinitions
            requestsToSave.push {model, requestName, requestDefinition}

    # add all request for cozyinstance & user
    requestsToSave.push
        model: api.CozyInstance
        requestName: 'all'
        requestDefinition: defaultRequests.all

    requestsToSave.push
        model: api.CozyUser
        requestName: 'all'
        requestDefinition: defaultRequests.all

    step = (i = 0) ->
        {model, requestName, requestDefinition} = requestsToSave[i]
        log "#{model.getDocType()} - #{requestName} request creation..."
        model.defineRequest requestName, requestDefinition, (err) ->
            if err
                log "failed", err
                log "A request creation failed, abandon."
                callback err

            else if i + 1 >= requestsToSave.length
                log "requests creation complete"
                callback null

            else
                log "succeeded"
                step i + 1
    # loop over them asynchroniously
    step 0