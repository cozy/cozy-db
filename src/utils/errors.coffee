
exports.NotFound = (what) ->
    msg = "#{what} not found"
    err = new Error msg
    err.status = 404
    return err

exports.DSError = (originalErr) ->
    msg = "DSError : " + originalErr.message
    err = new Error msg
    err.stack = originalErr.stack
    err.status = 500
    return err

exports.WrongShemaError = (msg) ->
    msg = "WrongShemaError: " + msg
    err = new Error msg
    return err

exports.NotOnNewModel = ->
    return new Error """
        Wrong Usage : you attempted to call an instance method on a model
        without id.
    """
