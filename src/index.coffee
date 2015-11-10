log = require('printit')
    date: true
    prefix: 'Cozy DB'

fs = require 'fs'
async = require 'async'

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


module.exports.getModel = (name, schema) ->

    # Internal: Generated Class from getModel
    klass = class ClassFromGetModel extends CozyModel
        @schema: schema

    klass.displayName = klass.name = name
    klass.toString = -> "#{name}Constructor"
    klass.docType = name

    return klass

module.exports.api = api = require './api'


maybeSetupPouch = (options) ->
    # if we are given a db or dbName options
    # or env variable is set
    # the app is meant to be used standalone
    if process.env.RUN_STANDALONE or options.db or options.dbName
        Pouch = require 'pouchdb'
        PouchModel = require './pouchmodel'
        module.exports.CozyModel = CozyModel = PouchModel
        if options.db
            PouchModel.db = options.db
        else
            options.dbName ?= process.env.POUCHDB_NAME or 'cozy'
            PouchModel.db = new Pouch options.dbName

getRequests = (root) ->
    modelPath = "#{root}/server/models/"
    requestFile = modelPath + "requests"
    # get the requests file
    try requests = require requestFile
    catch err
        console.log "Could not load #{requestFile}"
        requests = {}

    requestsToSave = []
    models = []

    # get all indexes defined in models into an array
    modelFiles =
    for file in fs.readdirSync modelPath
        try
            model = require modelPath + file
            if model?.prototype instanceof CozyModel
                models.push model

    # get all requests from the request file into an array
    for docType, requestDefinitions of requests
        model = require modelPath + docType

        for requestName, requestDefinition of requestDefinitions
            requestsToSave.push {model, requestName, requestDefinition}

    # add all request for cozyinstance & user
    requestsToSave.push
        model: api.CozyInstance
        optional: true
        requestName: 'all'
        requestDefinition: defaultRequests.all

    requestsToSave.push
        model: api.CozyUser
        optional: true
        requestName: 'all'
        requestDefinition: defaultRequests.all

    return {models, requestsToSave}

defineRequests = (requestsToSave, callback) ->
    async.eachSeries requestsToSave, (request, next) ->
        {model, requestName, requestDefinition, optional} = request
        log.info "#{model.getDocType()} - #{requestName} request creation..."
        model.defineRequest requestName, requestDefinition, (err) ->
            if err and not optional
                log.raw err
                log.error """
                    A request creation failed, abandon. Are you sure the DS is
                    started ?
                """
                next err
            else
                log.info "succeeded"
                next null

    , callback

defineIndexes = (models, callback) ->
    async.eachSeries models, (model, next) ->
        log.info "#{model.getDocType()} - define indexes..."
        model.registerIndexDefinition callback
    , callback

requestsIndexingProgress = 0
requestsIndexingTotal = 1
requestsIndexingCallbacks = []

module.exports.getRequestsReindexingProgress = ->
    log.warn "#{requestsIndexingProgress} / #{requestsIndexingTotal}"
    requestsIndexingProgress / requestsIndexingTotal

module.exports.waitReindexing = (callback) ->
    if requestsIndexingTotal is requestsIndexingProgress
        callback null
    else
        requestsIndexingCallbacks.push callback

forceIndexRequests = (requestsToSave, callback, i = 0) ->
    {model, requestName} = requestsToSave[i]
    requestsIndexingTotal = requestsToSave.length
    log.info "#{model.getDocType()} - #{requestName} reindexing " +
        "#{requestsIndexingProgress}/#{requestsIndexingTotal}"
    model.rawRequest requestName, limit: 1, (err) ->
        if err and err.code is 'ECONNRESET'
            log.info " Timedout"
            setTimeout ->
                forceIndexRequests requestsToSave, callback, i
            , 4000 # wait 4s, the request is timing out, probably reindex

        else if i + 1 >= requestsToSave.length
            requestsIndexingProgress++
            log.info " requests reindexing complete"
            callback null
            cb null for cb in requestsIndexingCallbacks
        else
            requestsIndexingProgress++
            log.info " succeeded"
            forceIndexRequests requestsToSave, callback, i + 1


# to use cozydb as an americano module
# Plugin configuration: run through models/requests.(coffee|js) and save
# them all in the Cozy Data System.
module.exports.configure = (options, app, callback) ->
    callback ?= ->
    if typeof options is 'string'
        options = root: options

    try maybeSetupPouch(options)
    catch err
        console.log "Fail to init pouchdb, did you install it ?"
        console.log err.stack
        return callback err

    api.setupModels()

    try {requestsToSave, models} = getRequests options.root
    catch err
        log.raw err.stack
        log.error "Failed to load requests file."
        return callback err

    defineRequests requestsToSave, (err) ->
        return callback err if err

        defineIndexes models, (err) ->
            return callback err if err

            reindex = forceIndexRequests.bind null, requestsToSave
            module.exports.forceReindexing = reindex

            callback null
