PublicListener = GLOBAL.PublicListener =
    
    init: (callback) ->

        callback()

    start: ->

        Bot.exec '--broadcasts --noplayerinfo', Config.Public.MaxTimeout, (err) ->

            if err
                logger.error '[Public] Error: %s', err.message

            setTimeout PublicListener.start, Config.Public.FetchInterval