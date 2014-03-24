PublicListener = GLOBAL.PublicListener =
    
    init: (callback) ->

        callback()

    fetch: (callback) ->

        if argv.debug
            tracedays = Config.Faction.TraceDaysDebug
        else
            tracedays = Config.Faction.TraceDays

        Bot.exec
            argv:       ['--broadcasts', '--tracedays', tracedays]
            output:     true
        , callback

    start: ->

        Bot.exec
            argv:       ['--broadcasts']
            timeout:    Config.Public.MaxTimeout
            output:     true
        , (err) ->

            #if err
            #    logger.error '[Public] Error: %s', err.message

            setTimeout PublicListener.start, Config.Public.FetchInterval