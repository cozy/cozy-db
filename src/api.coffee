client = require './utils/client'
cozydb = require './index'

CozyInstance = null
CozyUser = null

# Public models
module.exports.setupModels = setupModels = ->
    module.exports.CozyInstance = CozyInstance =
      cozydb.getModel 'CozyInstance', cozydb.NoSchema
    module.exports.CozyUser = CozyUser =
      cozydb.getModel 'User', cozydb.NoSchema
    return

setupModels()


# Public: kitchen sink class for various convenience methods
#
# Examples
#   require('cozydb').api.getCozyInstance (err, instance) ->
class Api


    # Public: Retrieve the CozyInstance object
    # Warning: Your app need to ask the CozyInstance permission
    #
    # callback - {Function}({Error} err, {CozyInstance} instance)
    #
    # Returns null
    getCozyInstance: (callback) ->
        CozyInstance.first callback


    # Public: Retrieve the CozyUser object
    # Warning: Your app need to ask the User permission
    #
    # callback - {Function}({Error} err, {CozyUser} instance)
    #
    # Returns null
    getCozyUser: (callback) ->
        CozyUser.first callback


    # Public: Retrieve the Cozy domain set at the instance level.
    # Warning: Your app need to ask the CozyInstance permission
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


    # Public: Retrieve the locale set at the instance level.
    # Warning: Your app need to ask the CozyInstance permission
    #
    # callback - {Function}({Error} err, {String} locale)
    #
    # Returns null
    getCozyLocale: (callback) ->
        api.getCozyInstance (err, instance) ->
            callback err, instance?.locale or 'en'


    # Public: Retrieve the timezone set at the user level.
    # Warning: Your app need to ask the User permission
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


    # Public: Retrieve the Cozy owner's email.
    # Warning: Your app need to ask the User permission
    #
    # callback - {Function}({Error} err, {String} email)
    #
    # Returns null
    getCozyOwnerEmail: (callback) ->
        api.getCozyUser (err, user) ->
            return callback err if err
            email = user?.email

            if email then callback null, email
            else callback new Error 'No user set'


    # Public: Retrieve all existing tags in the cozy.
    #
    # callback - {Function}({Error} err, [{String}] tags)
    #
    # Returns null
    getCozyTags: (callback) ->
        client.get 'tags', (err, response, body) ->
            callback err, body


    # Public: Send an email
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
        client.post "mail/", data, (error, response, body) ->
            if body.error?
                if body.error.code? and body.error.code is 'postfix_unavailable'
                    callback new Error "postfix-#{body.error.message}"
                else
                    callback body.error
            else if response.statusCode is 400
                callback new Error 'Body has not all necessary attributes'
            else if response.statusCode is 500
                callback new Error "Server error occured."
            else
                callback()


    # Public: Send an email to the cozy owner.
    # Warning: Your app need to ask the "send mail to user" permission
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
        client.post "mail/to-user/", data, (error, response, body) ->
            if body.error?
                if body.error.code? and body.error.code is 'postfix_unavailable'
                    callback new Error "postfix-#{body.error.message}"
                else
                    callback body.error
            else if response.statusCode is 400
                callback new Error 'Body has not all necessary attributes'
            else if response.statusCode is 500
                callback new Error "Server error occured."
            else
                callback()


    # Public: Send an email from the cozy owner.
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
        client.post "mail/from-user/", data, (error, response, body) ->
            if body.error?
                if body.error.code? and body.error.code is 'postfix_unavailable'
                    callback new Error "postfix-#{body.error.message}"
                else
                    callback body.error
            else if response.statusCode is 400
                callback new Error 'Body has not all necessary attributes'
            else if response.statusCode is 500
                callback new Error "Server error occured."
            else
                callback()


    # Public: Create a Sharing and send request to all the targets
    # Warning : Your app need to ask the 'Sharing' permission
    # data - {Object}
    #   :rules - [rule], composed of id and docType fields
    #   :targets - [target], composed of recipientUrl fields
    #   :continuous - {boolean}, sync sharing
    #   :desc - {String}, human-readable description
    # callback - {Function}({Error} err)
    #
    # Returns null
    createSharing: (data, callback) ->
        client.post "services/sharing/", data, (err, res, body) ->
            callback err, body


    # Public: Answer a Sharing request
    # Warning : Your app need to ask the 'Sharing' permission
    # data - {Object}
    #   :id - {String}, id of the recipient's Sharing document
    #   :accepted - {boolean}
    # callback - {Function}({Error} err)
    #
    # Returns null
    answerSharing: (data, callback) ->
        client.post "services/sharing/sendAnswer", data, (err, res, body) ->
            callback err, body


    # Public: Revoke a Sharing from the sharer side
    # Warning : Your app need to ask the 'Sharing' permission
    # id - {String}, id of the sharer's Sharing document, also called shareID
    # callback - {Function}({Error} err)
    #
    # Returns null
    revokeSharingFromSharer: (id, callback) ->
        path = "services/sharing/sharer/#{id}/"
        client.post path, {}, (err, res, body) ->
            callback err, body


    # Public: Revoke a target from the sharer side
    # Warning : Your app need to ask the 'Sharing' permission
    # id - {String}, id of the sharer's Sharing document, also called shareID
    # target - {String}, url of the target
    # callback - {Function}({Error} err)
    #
    # Returns null
    revokeSharingTargetFromSharer: (id, target, callback) ->
        path = "services/sharing/sharer/#{id}/#{target}/"
        client.post path, {}, (err, res, body) ->
            callback err, body


    # Public: Revoke a Sharing from the recipient side
    # Warning : Your app need to ask the 'Sharing' permission
    # id - {String}, id of the recipient's Sharing document
    # callback - {Function}({Error} err)
    #
    # Returns null
    revokeSharingFromRecipient: (id, callback) ->
        path = "services/sharing/target/#{id}/"
        client.post path, {}, (err, res, body) ->
            callback err, body


module.exports = api = new Api()
module.exports.setupModels = setupModels
module.exports.CozyInstance = CozyInstance
module.exports.CozyUser = CozyUser

