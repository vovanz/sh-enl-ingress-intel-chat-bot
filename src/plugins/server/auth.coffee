randomstring = require 'randomstring'
async = require 'async'

requestEntries = []

plugin = 

    name: 'auth'

    bootstrap: (callback) ->

        Bot.Server.app.use (req, res, next) ->

            req._check_token = plugin.checkTokenAccessable
            next()

        callback()

    init: (callback) ->

        Bot.Server.get '/manage/auth/tokens', AccessLevel.LEVEL_ROOT, 'List all tokens', (req, res) ->

            Database.db.collection('Bot.Auth.Token').find
                aclv:
                    $gte:   AccessLevel.LEVEL_VALIDATED
            .toArray (err, ts) ->
                
                tokens = []

                for token in ts
                    tokens.push
                        player:         token.player
                        token:          token.token
                        access_level:   AccessLevel.stringify(token.aclv)

                res.jsonp tokens

        Bot.Server.put '/manage/auth/:player/:level', AccessLevel.LEVEL_ROOT, 'Set access-level of all tokens of an agent', (req, res) ->

            player = req.params.player
            level = AccessLevel.parse(req.params.level)

            if level is AccessLevel.LEVEL_UNKNOWN
                return res.jsonp
                    error: 'Invalid access-level'

            Database.db.collection('Bot.Auth.Token').update
                player:         player
                aclv:
                    $gte:       AccessLevel.LEVEL_VALIDATED
            ,
                $set:
                    aclv: level
            ,
                multi: true
            , (err, affected) ->
                logger.info '[Auth] Updated access-level of %s to %s', player, AccessLevel.stringify(level)
                res.jsonp
                    updated_tokens: affected

        Bot.Server.post '/auth/token/:player', AccessLevel.LEVEL_GUEST, 'Generate a new token', (req, res) ->

            player = req.params.player
            token = randomstring.generate()

            Database.db.collection('Bot.Auth.Token').insert
                
                token:  token
                player: player
                ip:     req.connection.remoteAddress
                time:   Date.now()
                aclv:   AccessLevel.LEVEL_GUEST

            , (err) ->

                res.jsonp
                    token:  token
                    player: player

        Bot.Server.get '/auth/token/:token', AccessLevel.LEVEL_GUEST, 'Get detail of a token', (req, res) ->

            token = req.params.token

            Database.db.collection('Bot.Auth.Token').findOne
                
                token: token

            , (err, result) ->

                if err or not result
                    return res.jsonp
                        token:          token
                        access_level:   AccessLevel.stringify(AccessLevel.LEVEL_GUEST)

                res.jsonp
                    token:          token
                    access_level:   AccessLevel.stringify(result.aclv)

        callback()

    checkToken: (token, player, callback) ->

        async.series [

            (callback) ->

                Database.db.collection('Bot.Auth.Token').findOne
                    
                    token:  token
                    player: player
                    aclv:   AccessLevel.LEVEL_GUEST

                , (err, result) ->

                    if err or not result
                        callback 'No token available'
                        return

                    callback()

            (callback) ->

                Database.db.collection('Bot.Auth.Token').update
                    token:  token
                    player: player
                    aclv:   AccessLevel.LEVEL_GUEST
                ,
                    $set:
                        aclv:   AccessLevel.LEVEL_VALIDATED
                , callback

            (callback) ->

                logger.info '[Auth] Successfully validated player %s [token=%s]', player, token
                callback()

        ], callback

    checkTokenAccessable: (access_level, token, callback) ->

        return callback false if not token
        
        Database.db.collection('Bot.Auth.Token').findOne
            
            token: token
            aclv:
                $gte: access_level

        , (err, result) ->

            if err or not result
                callback false
            else
                callback true

module.exports = plugin