plugin = 

    test: (item) ->

        return false if not FactionUtil.isCallingBot item

        r = FactionUtil.parseCallingBody item
        return true if /(hi|hello|你好)/i.test r.body

        return false

    process: (item, callback) ->

        r = FactionUtil.parseCallingBody item
        
        FactionUtil.send Bot.getTemplate([
            ['@{player} ']
            [
                '你好~ '
                'Hello~ '
                'Hi! '
            ]
            ['{smily:smile}']
        ]).fillPlayer(r.player).fillSmily().toString(), r.body

        callback()

module.exports = plugin