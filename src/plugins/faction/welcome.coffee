storage = require(LIB_DIR + '/storage.js')('plugin.welcome')

plugin = 

    init: (callback) ->

        storage.fetch
            welcomedAgents: {}
        , ->

            if argv.debug
                storage.welcomedAgents = {}

            callback()

    test: (item) ->

        return true if item.markup?.TEXT1?.plain is 'has completed training.'
        return true if item.markup?.TEXT2?.plain is ' captured their first Portal.'
        return true if item.markup?.TEXT2?.plain is ' created their first Link.'

        return false

    process: (item, callback) ->

        if item.markup?.TEXT1?.plain is 'has completed training.'

            player = item.markup.SENDER1.plain
            player = player.substr 0, player.length - 2
            if storage.welcomedAgents[player.toLowerCase()]?
                plugin.sayHelloJoke player
            else
                plugin.sayHello player

        else

            plugin.sayHello item.markup.PLAYER1.plain

        callback()

    sayHelloJoke: (player) ->

        FactionUtil.send Bot.getTemplate('welcome.joke').fillPlayer(player).fillSmily().toString()

    sayHello: (player) ->

        return if storage.welcomedAgents[player.toLowerCase()]?
        storage.welcomedAgents[player.toLowerCase()] = true
        storage.save() if not argv.debug

        FactionUtil.send Bot.getTemplate('welcome').fillPlayer(player).fillSmily().toString()

module.exports = plugin