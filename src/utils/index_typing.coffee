
# Get the index rule for a cozydb type
#
# Returns an index rule with
#    :indexType {String} - the data-indexer type for this field
#    :indexTransform {Function} - the transform to apply to the value before
getIndexType = (type) ->

    # Support for both styles
    #   field: String
    #   field: SubModel
    #   field: {type: String, indexTransform: parseInt, indexType: 'number'}
    if type.type and not type.indexType
        type = type.type

    if type.indexTransform and type.indexType
        indexType: type.indexType
        indexTransform: type.indexTransform

    else if type is String
        indexType: 'string'
        indexTransform: null

    else if type is Date
        indexType: 'date'
        indexTransform: null

    else if type is Number
        indexType: 'number'
        indexTransform: null

    else if type is Boolean
        indexType: 'boolean'
        indexTransform: null

    # case where the type is an array like [String], [SubModel]
    else if Array.isArray(type) and type.length is 1

        itemIndexRule = getIndexType(type[0])
        if itemIndexRule?.indexType is 'string'

            indexTransform = if itemIndexRule.indexTransform
            then (data) -> data.map(itemIndexRule.indexTransform).join ' '
            else (data) -> data.join ' '

            indexType: 'string'
            indexTransform: indexTransform


        else
            # for now, we only support array of string or toStringable
            undefined
    else
        undefined

# Compute and memoize the indexer options
#
# Returns indexerOptions
#     :fieldsType - An {Object} mapping field to type
#     :transformers - An {Object} mapping field to transform function
getIndexerOptions = (Model) ->

    return Model.__indexerOptions if Model.__indexerOptions

    fieldsType = {}
    transformers = {}

    for field in Model.indexedFields
        rule = getIndexType Model.schema[field]
        unless rule
            throw new Error "dont know how to index field #{field}"
        fieldsType[field] = rule.indexType
        transformers[field] = rule.indexTransform if rule.indexTransform


    return Model.__indexerOptions = {fieldsType, transformers}

# For a given Model and data, compute the mappedValues and returns
# the object to pass to the data-system
exports.getIndexOptions = (Model, data) ->

    indexerOptions = getIndexerOptions Model

    mappedValues = {}

    for field, transform of indexerOptions.transformers
        mappedValues[field] = transform(data[field])

    for key, definition of Model.computedIndexes or {}
        fieldsType[key] = definition.indexType
        mappedValues[key] = definition.indexTransform(data)

    return options =
        fields: Model.indexedFields
        fieldsType: indexerOptions.fieldsType
        mappedValues: mappedValues
