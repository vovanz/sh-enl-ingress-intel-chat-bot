plugin = 

    test: (item) ->

        return false if not FactionUtil.isCallingBot item

        r = FactionUtil.parseCallingBody item
        return true if r.body.toLowerCase().indexOf('ping') > -1

        return false

    process: (item, callback) ->

        r = FactionUtil.parseCallingBody item
        
        FactionUtil.send Bot.getTemplate('ping').fillPlayer(r.player).fillSmily().toString(), r.body

        callback()

module.exports = plugin