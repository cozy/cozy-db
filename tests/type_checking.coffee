Model = require '../src/model'
{castObject} = require '../src/utils/type_checking'
equals = require 'lodash.isequal'
should = require 'should'


class SubModel extends Model
    @schema:
        subModelString: String
        subModelNumber: Number

SCHEMA =
    aString: String
    aNumber: Number
    aDate: Date
    aSubObject: SubModel
    aObject: Object
    aArrayOfString: [String]

someDate = new Date()


describe 'when all is ok', ->

    it 'cast a correct complete object', ->

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

        result = castObject value, SCHEMA
        equals(result, value).should.be.ok

    it 'dont cast more values', ->

        value =
            aString: 'hello'
            aNumber: 36
            thisFieldIsntInTheSchema: true
            aDate: someDate
            aSubObject:
                subModelString: 'world'
                subModelNumber: 42
            aObject:
                a: 'b'
                c: 'd'
                e: f: 'g'
            aArrayOfString: ['tag1', 'tag2']

        result = castObject value, SCHEMA
        equals(result, value).should.be.false
        should.not.exist result.thisFieldIsntInTheSchema
        delete value.thisFieldIsntInTheSchema
        equals(result, value).should.be.true