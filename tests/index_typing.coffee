Model = require '../src/model'
{getIndexOptions} = require '../src/utils/index_typing'
equals = require 'lodash.isequal'
should = require 'should'

someDate = new Date()

class SubModel extends Model
    @schema:
        subModelString: String
        subModelNumber: Number

    @indexType: 'string'
    @indexTransform: (data) -> data.subModelNumber + data.subModelString


class TestModel extends Model
    @schema:
        aString: String
        aNonIndexedString: String
        aNumber: Number
        aDate: Date
        aSubObject: SubModel
        aObject: Object
        aArrayOfString: [String]
        aArrayOfSubmodel: [SubModel]

    @indexedFields: [
        'aString', 'aNumber', 'aDate', 'aSubObject',
        'aArrayOfString', 'aArrayOfSubmodel'
    ]

describe 'when all is ok', ->

    it 'generates a proper DS indexer options', ->

        value =
            aString: 'hello'
            aNumber: 36
            aDate: someDate
            aSubObject:
                subModelString: 'world'
                subModelNumber: 42
            aObject:
                a: 'b'
                c: 'd'
                e: f: 'g'
            aArrayOfString: ['tag1', 'tag2']
            aArrayOfSubmodel: [
                {subModelString: 'world2', subModelNumber: 43}
                {subModelString: 'world3', subModelNumber: 44}
            ]

        options = getIndexOptions TestModel, value


        equals(options.fields, TestModel.indexedFields).should.be.true

        expected =
            aString: 'string'
            aNumber: 'number'
            aDate: 'date'
            aSubObject: 'string'
            aArrayOfString: 'string'
            aArrayOfSubmodel: 'string'

        equals(options.fieldsType, expected).should.be.true

        expected =
            aSubObject: '42world'
            aArrayOfString: 'tag1 tag2'
            aArrayOfSubmodel: '43world2 44world3'

        equals(options.mappedValues, expected).should.be.true
