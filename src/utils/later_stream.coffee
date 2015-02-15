EventEmitter = require('events').EventEmitter


drainStream = (stream, cb) ->
    body = ''
    stream.on 'data', (chunk) -> body += chunk if cb
    stream.on 'end', -> cb? body


# Public: former API returned the mikeal/request object from getBinary
# this is a fake similar object with pipe & abort
module.exports = class LaterStream extends EventEmitter


    constructor: (@callback) ->
        super
        @pipeDests = []
        @aborted = false
        @callbackCalled = false
        @trueStream = null


    _onStreamingDone: (err) =>
        unless @callbackCalled
            @callbackCalled = true
            @callback err


    abort: =>
        if @trueStream
            @trueStream.req.abort()
        else
            @aborted = true


    pipe: (dest) =>
        if @trueStream
            @pipefilter? @trueStream, dest
            @trueStream.pipe dest
        else
            @pipeDests.push dest


    onReadableReady: (error, stream) =>

        if error
            drainStream stream
            @_onStreamingDone error

        else if stream?.statusCode isnt 200
            drainStream stream, (body) =>
                error = new Error "Error code #{stream?.statusCode} - #{body}"
                error.status = stream?.statusCode or 500
                @_onStreamingDone error

        else if @aborted
            stream.req.abort()
            drainStream stream
        else
            @trueStream = stream
            @emit 'ready', @trueStream
            @trueStream.on 'error', @_onStreamingDone
            @trueStream.on 'end', @_onStreamingDone

            for dest in @pipeDests
                @pipefilter? @trueStream, dest
                @trueStream.pipe dest
