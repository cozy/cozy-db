
adapter = require('../src/index')
fs = require 'fs'
path = require 'path'
should = require 'should'
helpers = require './helpers'

TESTFILENAME = 'test.png'
TESTFILE = path.join __dirname, TESTFILENAME
TESTFILEOUT = path.join __dirname, 'test-get.png'

Client = require("request-json").JsonClient
client = new Client "http://localhost:9101/"
client.setBasicAuth "test", "apptoken"

Note = TestModel = null

describe "Allow subclassing of Models", ->

    MagicNote = mn = null
    ref = 0

    it "i can subclass once", ->

        class Note extends adapter.CozyModel
            @schema:
                title: String
                content: String
                author: String

    it "i can subclass twice", ->

        class MagicNote extends Note
            doTheMagick: -> ref++

    it "normal method work", (done) ->

        data =
            title: 'this note is magick'
        MagicNote.create data, (err, created) ->
            mn = created
            done(err)

    it "so does the subclassed methods", ->
        mn.doTheMagick()
        ref.should.equal 1


### Binaries ###

describe "Binaries", ->

    before (done) ->
        @note = new Note id: 321
        data =
            title: "my note"
            content: "my content"
            docType: "Note"

        try fs.unlinkSync TESTFILEOUT
        catch err then console.log err

        client.post 'data/321/', data, (error, response, body) ->
            done()


    after (done) ->
        client.del "data/321/", (error, response, body) ->
            done()

    describe "Add a binary", ->

        it "When I add a binary", (done) ->
            @note.attachBinary TESTFILE, (err) =>
                @err = err
                done()

        it "Then no error is returned", ->
            should.not.exist @err

    describe "Retrieve a binary", ->

        it "When I claim this binary", (done) ->
            @timeout 10000
            stream = @note.getBinary TESTFILENAME, ->
            ws = fs.createWriteStream(TESTFILEOUT)
            ws.on 'finish', done
            ws.on 'error', done
            stream.pipe ws

        it "Then I got the same file I attached before", ->
            fileStats = fs.statSync(TESTFILE)
            resultStats = fs.statSync(TESTFILEOUT)
            resultStats.size.should.equal fileStats.size

    describe "Remove a binary", ->

        it "When I remove this binary", (done) ->
            @note.removeBinary TESTFILENAME, (err) =>
                @err = err
                done()

        it "Then no error is returned", ->
            should.not.exist @err

        it "When I claim this binary", (done) ->
            stream = @note.getBinary TESTFILENAME, (err) =>
                @err = err
                done()
            stream.pipe fs.createWriteStream(TESTFILEOUT)


        it "Then I got an error", ->
            should.exist @err


describe "Binaries, from a Buffer", ->

    before (done) ->
        @note = new Note id: 321
        data =
            title: "my note"
            content: "my content"
            docType: "Note"
        client.post 'data/321/', data, (error, response, body) ->
            done()

    after (done) ->
        client.del "data/321/", (error, response, body) ->
            done()

    describe "Add a binary", ->

        it "When I add a binary from a buffer", (done) ->
            buffer = fs.readFileSync TESTFILE
            Buffer.isBuffer(buffer).should.be.ok
            @note.attachBinary buffer, name: TESTFILENAME, (err) =>
                @err = err
                done()

        it "Then no error is returned", ->
            should.not.exist @err

        it "And I can remove this binary", (done) ->
            @timeout 5000
            @note.removeBinary TESTFILENAME, (err) ->
                should.not.exist err
                done()


### INDEX DEFINTION ###
describe "Index definition (nopouch)", ->

    before helpers.clearDocType 'indexdefinition'
    before helpers.clearDocType 'note'
    before helpers.clearDocType 'testmodel'
    before (done) ->
        client.del "data/index/clear-all/", done

    it "When the adapter configure", (done) ->
        adapter = require('../src/index')
        adapter.configure __dirname, null, done

    it "Then an index definition has been registered in the DS", (done) ->
        url = 'request/indexdefinition/all/'
        options = include_docs: true
        client.post url, options, (err, res, body) ->
            for row in body when row.doc.targetDocType is 'testmodel'
                return done null

            return done new Error 'no indexdefinition for testmodel'

    it "And wait a few seconds", (done) ->
        @timeout 4000
        setTimeout done, 3000

    it "And I can use it to search (create note)", (done) ->
        TestModel = require './server/models/testmodel'
        data = title: 'Hello world', content: 'A cool testcase'
        TestModel.create data, (err, created) =>
            @id = created.id
            return done err if err
            setTimeout done, 100

    it "And I can use it to search (search note)", (done) ->
        TestModel.search 'hello', (err, result) =>
            return done err if err
            result[0].id.should.equal @id
            done null

    it "I can also register an index manually (no americano) ", (done) ->

        class Note extends adapter.CozyModel
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


        Note.registerIndexDefinition done
