
CozyAdapter = require('../src/index')
Client = require("request-json").JsonClient
client = new Client "http://localhost:9101/"


describe "API Functions", ->

    before: (done) ->
        client.put ""

    describe "Send common mail", ->

        it "When I send the mail", (done) ->
            data =
                to: "test@cozycloud.cc"
                from: "Cozy-test <test@cozycloud.cc>"
                subject: "Test jugglingdb"
                content: "Content of mail"
            CozyAdapter.api.sendMail data, (err) =>
                @err = err
                done()

        it "Then no error is returned", ->
            should.not.exist @err

    describe "Send mail to user", ->

        it "When I send the mail", (done) ->
            data =
                from: "Cozy-test <test@cozycloud.cc>"
                subject: "Test jugglingdb"
                content: "Content of mail"
            CozyAdapter.api.sendMailToUser data, (err) =>
                @err = err
                done()

        it "Then no error is returned", ->
            should.not.exist @err

    describe "Send mail from user", ->

        it "When I send the mail", (done) ->
            data =
                to: "test@cozycloud.cc"
                subject: "Test jugglingdb"
                content: "Content of mail"
            CozyAdapter.api.sendMailFromUser data, (err) =>
                @err = err
                done()

        it "Then no error is returned", ->
            should.not.exist @err