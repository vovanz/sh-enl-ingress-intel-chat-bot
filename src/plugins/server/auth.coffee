randomstring = require 'randomstring'
async = require 'async'

requestEntries = []

plugin = 

    name: 'auth'

    init: (callback) ->

        helper.get '/auth/help', 'Show help messages', (req, res) ->

            res.json requestEntries

        helper.get '/auth/token/new/:player', 'Generate new access token', (req, res) ->

            token = randomstring.generate()
            player = req.params.player

            Database.db.collection('Bot.Auth.Token').insert
                
                token:  token
                player: player
                ip:     req.connection.remoteAddress
                valid:  false
                time:   Date.now()

            , (err) ->

                res.json
                    token:  token
                    player: player

        helper.get '/auth/token/status/:token', 'Check validation status of the token', (req, res) ->

            token = req.params.token

            Database.db.collection('Bot.Auth.Token').findOne
                
                token: token

            , (err, result) ->

                if err or not result?
                    return res.json
                        token: token
                        valid: false

                res.json
                    token: token
                    valid: result.valid

        callback()

    checkToken: (token, player, callback) ->

        async.series [

            (callback) ->

                Database.db.collection('Bot.Auth.Token').findOne
                    
                    token:  token
                    player: player
                    valid:  false

                , (err, result) ->

                    if err or not result?
                        return callback false

                    callback()

            (callback) ->

                Database.db.collection('Bot.Auth.Token').update
                    token:  token
                    player: player
                ,
                    $set:
                        valid: true
                , callback

            (callback) ->

                logger.info '[Auth] Successfully validated player %s [token: %s]', player, token
                callback()

        ], callback

helper = {}

['get', 'post'].forEach (method) ->

    helper[method] = (path, desc, callback) ->

        requestEntries.push
            method: method
            path:   path
            desc:   desc
        Bot.Server.app[method] path, callback

module.exports = plugin