{NotFound, DSError} = require './utils/errors'

# Public: minimalist convenience controller
class Controller

    # Public: create a new controller from a model and params
    #
    # options - {Object} options
    #       :model - {String} model to be used
    #       :reqParamID - {String} name of the req param for model id
    #       :reqProp - {String} name of the req property
    #                  where the model will be placed
    #
    # Returns null
    #
    # Examples
    #
    #  Note = cozydb.getModel 'Note', SCHEMA
    #  baseController = cozydb.SimpleController
    #       model: Note
    #       reqProp: 'note'
    #       reqParamID: 'noteid'
    constructor: (options) ->
        @model = options.model or throw 'model needed'
        @reqProp = options.reqProp or @model.getDocType().toLowerCase()
        @reqParamID = options.reqParamID or @reqProp + 'id'



    # Public: express handler to be link a model to the request
    # set a req[@reqProp] with the model found from the param id.
    # You should use this or {::find} but not both
    #
    # Returns null
    #
    # Examples
    #
    #  app.param 'noteid', baseController.fetch
    fetch: (req, res, next, id) =>
        @model.find id, (err, found) =>
            return next err if err
            return next NotFound "#{@reqProp}##{id}" if not found
            req[@reqProp] = found
            next()

    # Public: express handler to link a model to the request
    # set a req[@reqProp] with the model found from the param @reqParamID
    # You should use this or {::fetch} but not both
    #
    # Returns null
    #
    # Examples
    #
    #  app.get '/note/:noteid', [
    #       baseController.fetch,
    #       baseController.send
    #  ]
    find: (req, res, next) =>
        id = req.params[@reqParamID]
        @model.find id, (err, found) =>
            return next err if err
            return next NotFound "#{@reqProp}##{id}" unless found
            req[@reqProp] = found
            next()

    # Public: express handler to send the result of request 'all'
    #
    # Returns null
    #
    # Examples
    #
    #  app.get '/notes/', baseController.listAll
    listAll: (req, res, next) =>
        @model.all (err, items) =>
            return next err if err
            res.send 200, items

    # Public: express handler to send the @reqProp model
    #
    #
    # Returns null
    send: (req, res, next) =>
        res.send 200, req[@reqProp]

    # Public: express handler to update the @reqParamID model with request body
    # (dont get the model before update)
    #
    # Returns null
    #
    # Examples
    #
    #  app.put 'note/:noteid', baseController.update
    update: (req, res, next) =>
        id = req.params[@reqParamID]
        changes = req.body
        @model.updateAttributes id, req.body, (err, updated) =>
            return next err if err
            res.send 200, updated
            next()

    # Public: express handler to destroy the @reqParamID model
    # (dont get the model before destroy)
    #
    # Returns null
    #
    # Examples
    #
    #  app.del 'note/:noteid', baseController.destroy
    destroy: (req, res, next) =>
        id = req.params[@reqParamID]
        @model.destroy id, (err) =>
            return next err if err
            res.send 204, 'Deleted'
            next()


    # Private: utility function to pipe file from ds to client
    copySafeHeaders = (dsres, myres) ->

        console.log 'this called'
        # copy headers from ds response to my response
        for header, value of dsres.headers
            myres.setHeader header, value

        # protect from XSS typed files
        XSSmimeTypes = ['text/html', 'image/svg+xml']
        if myres.getHeader('Content-Type') in XSSmimeTypes
            myres.setHeader 'content-type', 'text/plain'


    # Private: utility function to get which file to download
    getFileName = (options, req) ->

        if options.filename and not options.reqParamFilename
            return options.filename

        if options.reqParamFilename and not options.filename
            return req.params[options.reqParamFilename]

        throw new Error """
                You should set only one of reqParamFilename or filename
                """

    # Public: express handler to send a file
    # (no need for a {::find} or {::fetch} before)
    #
    # options -
    #       :reqParamFilename - get the filename to send from this req.param
    #       :filename - set the filename
    #       :download - force download (content-disposition attachment)
    #
    # Examples
    #  handler = baseController.sendAttachment filename: 'picture'
    #  app.get 'contact/:contactid.jpg',
    sendAttachment: (options = {}) =>
        return handler = (req, res, next) =>
            name = getFileName options
            id = req.params[@reqParamID]
            stream = @model.getFile id, name, (err) -> next err if err
            stream.pipefilter = copySafeHeaders
            req.on 'close', -> stream.abort()
            stream.pipe res

    # Public: express handler to send a file
    # (no need for a {::find} or {::fetch} before)
    #
    # options -
    #       :reqParamFilename - get the filename to send from this req.param
    #       :filename - set the filename
    #
    # Examples
    #  handler = baseController.sendAttachment filename: 'picture'
    #  app.get 'contact/:contactid.jpg',
    sendBinary: (options = {})->
        return handler = (req, res, next) =>
            name = getFileName options
            id = req.params[@reqParamID]
            stream = @model.getBinary id, name, (err) -> next err if err
            stream.pipefilter = copySafeHeaders
            req.on 'close', -> stream.abort()
            stream.pipe res



module.exports = Controller
