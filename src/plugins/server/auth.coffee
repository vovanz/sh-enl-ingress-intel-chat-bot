requestEntries = []

plugin = 

    init: (callback) ->

        f.get '/auth/help', 'Show help messages', (req, res) ->

            res.json requestEntries

        callback()

f = {}

['get', 'post'].forEach (method) ->

    f[method] = (path, desc, callback) ->

        requestEntries.push
            method: method
            path:   path
            desc:   desc
        Bot.Server.app[method] path, callback

module.exports = plugin