
adapter = require('../src/index')


describe "Allow subclassing of Models", ->

    Note = MagicNote = mn = null
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