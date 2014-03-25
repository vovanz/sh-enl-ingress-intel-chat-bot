storage = require(LIB_DIR + '/storage.js')('plugin.auth')

randomstring = require 'randomstring'
async = require 'async'

requestEntries = []

plugin = 

    name: 'auth'

    init: (callback) ->

        helper.get '/manage/auth/whitelist', 'List acceptable players', (req, res) ->

            response = []

            async.eachSeries storage.acceptedAgents, (agent, callback) ->
                
                s =
                    player: agent
                    valid:  false

                Database.db.collection('Bot.Auth.Token').findOne
                    player: agent
                    valid:  true
                , (err, result) ->
                    s.valid = true if result
                    response.push s
                    callback()

            , ->

                res.json response


        helper.put '/manage/auth/whitelist/:player', 'Add an acceptable player', (req, res) ->

            player = req.params.player

            if storage.acceptedAgents.indexOf(player) is -1
                logger.info '[Auth] Added acceptable player: %s', player
                storage.acceptedAgents.push player
                storage.save() if not argv.debug

            res.json storage.acceptedAgents

        helper.delete '/manage/auth/whitelist/:player', 'Remove an acceptable player', (req, res) ->

            player = req.params.player

            pos = storage.acceptedAgents.indexOf(player)
            if pos isnt -1
                storage.acceptedAgents.splice pos, 1
                storage.save() if not argv.debug
                Database.db.collection('Bot.Auth.Token').remove
                    player: player
                , noop

            res.json storage.acceptedAgents

        helper.get '/auth/help', 'Show help messages', (req, res) ->

            res.json requestEntries

        helper.post '/auth/token/:player', 'Generate new access token', (req, res) ->

            player = req.params.player

            if storage.acceptedAgents.indexOf(player) is -1
                return res.json
                    error: 'Not in acceptable list'

            token = randomstring.generate()

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

        helper.get '/auth/token/:token', 'Check validation status of the token', (req, res) ->

            token = req.params.token

            Database.db.collection('Bot.Auth.Token').findOne
                
                token: token

            , (err, result) ->

                if err or not result
                    return res.json
                        token: token
                        valid: false

                res.json
                    token: token
                    valid: result.valid

        storage.fetch
            acceptedAgents: []
        , callback

    checkToken: (token, player, callback) ->

        async.series [

            (callback) ->

                Database.db.collection('Bot.Auth.Token').findOne
                    
                    token:  token
                    player: player
                    valid:  false

                , (err, result) ->

                    return callback 'No token available' if err or not result

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

                logger.info '[Auth] Successfully validated player %s [token=%s]', player, token
                callback()

        ], callback

helper = {}

['get', 'post', 'put', 'delete'].forEach (method) ->

    helper[method] = (path, desc, callback) ->

        requestEntries.push
            method: method
            path:   path
            desc:   desc
        Bot.Server.app[method] path, callback

module.exports = plugin