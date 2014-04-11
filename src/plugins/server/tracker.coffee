async = require 'async'

plugin = 

    name: 'tracker'

    init: (callback) ->

        Bot.Server.get '/tracker/:player/:page', AccessLevel.LEVEL_TRUSTED, 'Track a player', (req, res) ->

            player = req.params.player
            page = parseInt req.params.page

            async.series [

                # update to correct letter-case
                (callback) ->

                    Database.db.collection('Agent').findOne
                        _id: new RegExp('^' + player + '$', 'i')
                    , (err, agent) ->

                        return callback() if err or not agent
                        player = agent._id
                        callback()

                (callback) ->

                    Database.db.collection('Chat.Public').find
                        'markup.PLAYER1.plain': player
                    .sort
                        time: -1
                    .skip   (page - 1) * Config.Tracker.PageSize
                    .limit  Config.Tracker.PageSize
                    .toArray (err, records) ->

                        res.json records

            ]

        callback()

module.exports = plugin