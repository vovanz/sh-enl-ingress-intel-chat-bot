plugin = 

    name: 'help'

    init: (callback) ->

        Bot.Server.get '/help', AccessLevel.LEVEL_GUEST, 'Show help messages', (req, res) ->

            res.jsonp Bot.Server.routeEntries

        callback()

module.exports = plugin