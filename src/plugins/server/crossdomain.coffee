plugin = 

    name: 'help'

    bootstrap: (callback) ->

        Bot.Server.app.all '/', (req, res, next) ->

            res.header 'Access-Control-Allow-Origin', '*'
            res.header 'Access-Control-Allow-Headers', 'X-Requested-With'
            next()

        callback()

module.exports = plugin