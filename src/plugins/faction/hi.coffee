plugin = 

    test: (item) ->

        return false if not FactionUtil.isCallingBot item

        r = FactionUtil.parseCallingBody item
        return true if /(hi|hello|你好)/i.test r.body

        return false

    process: (item, callback) ->

        r = FactionUtil.parseCallingBody item
        
        FactionUtil.send item.text, Bot.getTemplate([
            ['@{player} ']
            [
                '你好~ '
                'Hello~ '
                'Hi! '
            ]
            ['{smily:smile}']
        ]).fillPlayer(r.player).fillSmily().toString()

        callback()

module.exports = plugin