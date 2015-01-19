
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