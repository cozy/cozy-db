should = require 'should'
CozyAdapter = require('../src/index')
Client = require("request-json").JsonClient
client = new Client "http://localhost:9101/"
process.env.NAME = "test"
process.env.TOKEN = "token"
client.setBasicAuth "test", "token"


describe "API Functions", ->

    userID = null
    instanceID = null

    before (done) ->
        user =
            docType: "user"
            email: 'test@cozycloud.cc'
            password: 'password'
            timezone: 'Europe/Paris'
            tags: ['A', 'B']

        client.post '/data/', user, (err, res, created) ->
            return done err if err
            userID = created._id
            done null

    after (done) ->
        client.del "/data/#{userID}/", done


    before (done) ->

        instance =
            domain: "testuser.cozycloud.cc"
            locale: "fr"
            docType: "cozyinstance"
            tags: ['B', 'C']

        client.post '/data/', instance, (err, res, created) ->
            return done err if err
            instanceID = created._id
            done null

    after (done) ->
        client.del "/data/#{instanceID}/", done

    before (done) ->
        CozyAdapter.configure __dirname, null, done


    describe "getCozyInstance", ->

        it 'should return the instance', (done) ->

            CozyAdapter.api.getCozyInstance (err, instance) ->
                return done err if err
                instance.should.have.property 'domain', 'testuser.cozycloud.cc'
                done null

    describe "getCozyUser", ->

        it 'should return the user', (done) ->

            CozyAdapter.api.getCozyUser (err, user) ->
                return done err if err
                user.should.have.property 'email', 'test@cozycloud.cc'
                done null


    describe 'getCozyDomain', ->

        it 'should return the domain', (done) ->

            CozyAdapter.api.getCozyDomain (err, domain) ->
                return done err if err
                domain.should.equal 'https://testuser.cozycloud.cc/'
                done null

    describe 'getCozyLocale', ->

        it 'should return the locale', (done) ->

            CozyAdapter.api.getCozyLocale (err, locale) ->
                return done err if err
                locale.should.equal 'fr'
                done null

    describe 'getCozyTimezone', ->

        it 'should return the timezone', (done) ->

            CozyAdapter.api.getCozyTimezone (err, tz) ->
                return done err if err
                tz.should.equal 'Europe/Paris'
                done null


    describe 'getCozyOwnerEmail', ->

        it 'should return the owner email', (done) ->

            CozyAdapter.api.getCozyOwnerEmail (err, email) ->
                return done err if err
                email.should.equal 'test@cozycloud.cc'
                done null

    describe 'getCozyTags', ->

        it 'should return the dedup tags', (done) ->

            CozyAdapter.api.getCozyTags (err, tags) ->
                return done err if err
                tags.should.be.an.Array
                tags.should.have.property 'length', 3
                done null

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