plugin = 

    test: (item) ->

        return false if not FactionUtil.isCallingBot item

        r = FactionUtil.parseCallingBody item
        return true if /^\[validate\]/i.test r.body

        return false

    process: (item, callback) ->

        r = FactionUtil.parseCallingBody item

        token = r.body.replace '[validate]', ''
        token = token.trim()
        player = r.player
        
        Bot.Server.plugins.auth.checkToken token, player
        
        callback()

module.exports = plugin