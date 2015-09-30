log = require('printit')
    prefix: 'Cozy DB'

_toString = (x) -> Object.prototype.toString.call x
_isArray = Array.isArray or (x) -> '[object Array]' is _toString x
_isMap = (x) -> '[object Object]' is _toString x
_default = (value, defaultValue, lastDefault) ->
    if value isnt undefined then value
    else if defaultValue isnt undefined then defaultValue
    else lastDefault

{WrongShemaError} = require './errors'

exports.NoSchema = NoSchema = {symbol: 'NoSchema'}

exports.castValue = castValue = (value, typeOrOptions) ->

    # each prop can either be just the type (msg: String)
    # or an option hash (msg: type: String, default: 'yolo')
    if typeOrOptions.type
        {type} = typeOrOptions
        defaultValue = typeOrOptions['default']
    else
        type = typeOrOptions
        defaultValue = undefined


    if value is undefined or value is null
        if _isArray type then return []
        else return defaultValue

    if type is NoSchema
        out = value

    # type Date cast to a Date object
    else if type is Date
        value = _default value, defaultValue, undefined
        out = new Date value

    # type String get casted to Number
    else if type is String
        value = _default value, defaultValue, undefined
        out = String value

    # type Boolean get casted Boolean
    else if type is Boolean
        value = _default value, defaultValue, undefined
        out = Boolean value

    # type Number get casted to Number
    else if type is Number
        value = _default value, defaultValue, undefined
        out = Number value

    # type Object are swallow cloned
    else if type is Object
        out = {}
        out[key] = pvalue for own key, pvalue of value

    # a model can be used as type
    # it gets casted following its schema
    else if type.prototype instanceof Model
        out = type.cast value

    # support for typed array tags: [String]
    # default to empty array
    else if _isArray type
        throw WrongShemaError 'empty array' unless type[0]
        value = _default value, defaultValue, []
        arrayType = type[0]
        result = []
        if value? and typeof value isnt 'string'
            for item in value
                result.push castValue item, arrayType
        return result

    # support for (x) -> x use everywhere in cozy apps
    else if typeof type is 'function'
        return type(value)

    # unknown type throw
    else throw WrongShemaError "unsuported type ", type

    return out



reportCastIgnore = process.env.NODE_ENV not in ['production', 'test'] or
                   process.end.NO_CAST_WARNING

exports.castObject = castObject = (raw, schema, target = {}) ->

    handled = []

    if schema is NoSchema
        target[prop] = value for prop, value of raw
        return target

    for own prop, typeOrOptions of schema
        target[prop] = castValue raw[prop], typeOrOptions
        handled.push prop if reportCastIgnore

    if reportCastIgnore
        for own prop, value of raw when prop not in handled
            log.warn "Warning : cast ignored property '#{prop}'"

    return target


# import late because circular dependency
Model = require '../model'
