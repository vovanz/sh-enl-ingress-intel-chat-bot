plugin = 

    test: (item) ->

        return false if not FactionUtil.isCallingBot item

        r = FactionUtil.parseCallingBody item
        return true if r.body.indexOf('多哥') > -1

        return false

    process: (item, callback) ->

        r = FactionUtil.parseCallingBody item
        
        FactionUtil.send Bot.generateTemplate('@{player} 为了多哥！@xmorose {smily:evil}').fillPlayer(r.player).fillSmily().toString(), r.body

        callback()

module.exports = plugin