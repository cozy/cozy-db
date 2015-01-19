client = require './utils/client'
cozydb = require './index'

# Public: CozyInstance model
class CozyInstance extends cozydb.CozyModel
    @docType: 'CozyInstance'
    @schema: cozydb.NoSchema

# Public: User model
class CozyUser extends cozydb.CozyModel
    @docType: 'User'
    @schema: cozydb.NoSchema

# Public: kitchen sink class for various convenience methods
#
# Examples
#   require('cozydb').api.getCozyInstance (err, instance) ->
class Api


    # Public: get the CozyInstance object
    # Warning : Your app need to ask the CozyInstance permission
    #
    # callback - {Function}({Error} err, {CozyInstance} instance)
    #
    # Returns null
    getCozyInstance: (callback) ->
        CozyInstance.first callback

    # Public: get the CozyUser object
    # Warning : Your app need to ask the User permission
    #
    # callback - {Function}({Error} err, {CozyUser} instance)
    #
    # Returns null
    getCozyUser: (callback) ->
        CozyUser.first callback

    # Public: get the Cozy domain
    # Warning : Your app need to ask the CozyInstance permission
    # domain is normalized with https and trailing /
    #
    # callback - {Function}({Error} err, {String} domain)
    #
    # Returns null
    getCozyDomain: (callback) ->
        api.getCozyInstance (err, instance) ->
            return callback err if err
            url = instance?.domain?.replace('http://', '')
                .replace('https://', '')

            if url then callback null, "https://#{url}/"
            else callback new Error 'No instance domain set'

    # Public: get the Cozy locale
    # Warning : Your app need to ask the CozyInstance permission
    #
    # callback - {Function}({Error} err, {String} locale)
    #
    # Returns null
    getCozyLocale: (callback) ->
        api.getCozyInstance (err, instance) ->
            callback err, instance?.locale or 'en'

    # Public: get the Cozy timezone
    # Warning : Your app need to ask the User permission
    #
    # callback - {Function}({Error} err, {String} timezone)
    #
    # Returns null
    getCozyTimezone: (callback) ->
        api.getCozyUser (err, user) ->
            return callback err if err
            tz = user?.timezone

            if tz then callback null, tz
            else callback new Error 'No user set'

    # Public: get the Cozy owner's email
    # Warning : Your app need to ask the User permission
    #
    # callback - {Function}({Error} err, {String} email)
    #
    # Returns null
    getCozyOwnerEmail: (callback) ->
        api.getCozyUser (err, user) ->
            return callback err if err
            email = user?.email

            if email then callback null, tz
            else callback new Error 'No user set'

    # Public: get all existing tags in the cozy
    #
    # callback - {Function}({Error} err, [{String}] tags)
    #
    # Returns null
    getCozyTags: (callback) ->
        client.get 'tags', (err, response, body) ->
            callback err, body


    # Public: send an email
    # Warning : Your app need to ask the "send mail" permission
    #
    # data - {Object}
    #   :to
    #   :from
    #   :subject
    #   :cc
    #   :bcc
    #   :replyTo
    #   :inReplyTo
    #   :references
    #   :headers
    #   :alternatives
    #   :envelope
    #   :messageId
    #   :date
    #   :encoding
    #   :text
    #   :html
    # callback - {Function}({Error} err)
    #
    # Returns null
    sendMail: (data, callback) ->
        client.post "mail/", data, (error, response, body) =>
            if body.error
                callback body.error
            else if response.statusCode is 400
                callback new Error 'Body has not all necessary attributes'
            else if response.statusCode is 500
                callback new Error "Server error occured."
            else
                callback()

    # Public: send an email to the cozy owner
    # Warning : Your app need to ask the "send mail to user" permission
    #
    # data - {Object}
    #   :to
    #   :subject
    #   :text
    #   :html
    # callback - {Function}({Error} err)
    #
    # Returns null
    sendMailToUser: (data, callback) ->
        client.post "mail/to-user/", data, (error, response, body) =>
            if body.error
                callback body.error
            else if response.statusCode is 400
                callback new Error 'Body has not all necessary attributes'
            else if response.statusCode is 500
                callback new Error "Server error occured."
            else
                callback()

    # Public: send an email from the cozy owner
    # Warning : Your app need to ask the "send mail from user" permission
    #
    # data - {Object}
    #   :to
    #   :subject
    #   :text
    #   :html
    # callback - {Function}({Error} err)
    #
    # Returns null
    sendMailFromUser: (data, callback) ->
        client.post "mail/from-user/", data, (error, response, body) =>
            if body.error?
                callback body.error
            else if response.statusCode is 400
                callback new Error 'Body has not all necessary attributes'
            else if response.statusCode is 500
                callback new Error "Server error occured."
            else
                callback()



module.exports = api = new Api()