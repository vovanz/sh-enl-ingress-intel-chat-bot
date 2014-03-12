plugin = 

    test: (item) ->

        return false if not FactionUtil.isCallingBot item

        return -1

    process: (item, callback) ->

        r = FactionUtil.parseCallingBody item
        
        FactionUtil.send Bot.generateTemplate('@{player} {smily:surprise}').fillPlayer(r.player).fillSmily().toString()

        callback()

module.exports = plugin