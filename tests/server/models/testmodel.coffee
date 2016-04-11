cozydb = require '../../../src/index'
module.exports = class TestModel extends cozydb.CozyModel
    @schema:
        title: String
        content: String
        author: String

    @fullTextIndex:
        title:
            nGramLength: {gte: 1, lte: 2},
            stemming: true, weight: 5, fieldedSearch: true
        content:
            nGramLength: 1,
            stemming: true, weight: 1, fieldedSearch: true