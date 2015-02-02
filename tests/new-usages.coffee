
adapter = require('../src/index')
fs = require 'fs'
path = require 'path'
should = require 'should'

TESTFILENAME = 'test.png'
TESTFILE = path.join __dirname, TESTFILENAME
TESTFILEOUT = path.join __dirname, 'test-get.png'

Client = require("request-json").JsonClient
client = new Client "http://localhost:9101/"
client.setBasicAuth "test", "apptoken"

Note = null

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

    it "so does the ", ->
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

    describe "Add an attachment", ->

        it "When I add an attachment", (done) ->
            @note.attachBinary TESTFILE, (err) =>
                @err = err
                done()

        it "Then no error is returned", ->
            should.not.exist @err

    describe "Retrieve an attachment", ->

        it "When I claim this attachment", (done) ->
            @timeout 10000
            stream = @note.getBinary TESTFILENAME, -> done()
            stream.pipe fs.createWriteStream(TESTFILEOUT)

        it "Then I got the same file I attached before", ->
            fileStats = fs.statSync(TESTFILE)
            resultStats = fs.statSync(TESTFILEOUT)
            resultStats.size.should.equal fileStats.size

    describe "Remove an attachment", ->

        it "When I remove this attachment", (done) ->
            @note.removeBinary TESTFILENAME, (err) =>
                @err = err
                done()

        it "Then no error is returned", ->
            should.not.exist @err

        it "When I claim this attachment", (done) ->
            stream = @note.getBinary TESTFILENAME, (err) =>
                @err = err
                done()
            stream.pipe fs.createWriteStream(TESTFILEOUT)


        it "Then I got an error", ->
            should.exist @err