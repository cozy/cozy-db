
# Public: the Model constructor
module.exports.Model = Model = require './model'

# Public: the CozyModel constructor
module.exports.CozyModel = CozyModel = require './cozymodel'

module.exports.SimpleController = Controller = require './controller'

{NoSchema} = require './utils/type_checking'
module.exports.NoSchema = NoSchema


module.exports.defaultRequests =
    all: (doc) -> emit doc._id, doc
    tags: (doc) -> emit(tag, doc) for tag in doc.tags or []
    by: (field) ->
        ((doc) -> emit doc.FIELD, doc).toString().replace 'FIELD', field


api = require './api'
module.exports[key] = value for key, value of api


module.exports.getModel = (name, schema) ->

    klass = class ClassFromGetModel extends CozyModel
        @schema: schema

    klass.displayName = klass.name = name
    klass.toString = -> "#{name}Constructor"
    klass.docType = name

    return klass

# to use cozydb as an americano module
# Plugin configuration: run through models/requests.(coffee|js) and save
# them all in the Cozy Data System.
module.exports.configure = (options, app, callback) ->

    callback ?= ->
    root = if typeof options is 'string' then options else options.root
    modelPath = "#{root}/server/models/"

    log = ->
        return null if process.env.NODE_ENV is 'test'
        console.log.apply console, arguments

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

    # loop over them asynchroniously
    do step = (i = 0) ->
        {model, requestName, requestDefinition} = requestsToSave[i]
        log "#{docType} - #{requestName} request creation..."
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