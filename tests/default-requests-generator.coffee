adapter = require '../src/index'

describe "Default requests generator", ->

    describe "all", ->
        it "should return the correct map function to list all documents", ->
            adapter.defaultRequests.all.toString().should.equal """
function (doc) {
      return emit(doc._id, doc);
    }
            """

    describe "by(string)", ->
        it "should return a map function with one parameter for emit", ->
            console.log adapter.defaultRequests.by('aField')
            adapter.defaultRequests.by('aField').should.equal """
function (doc) {
        return emit(doc.aField, doc);
      }
            """

    describe "by(string, string)", ->
        it "should return a map function with an array of parameters for emit", ->
            adapter.defaultRequests.by('aField', 'bField').should.equal """
function (doc) {
        return emit([doc.aField, doc.bField], doc);
      }
            """

    describe "by(no parameter)", ->
        it "should throw", ->
            func = adapter.defaultRequests.by
            func.should.throw('There should be at least one parameter')
