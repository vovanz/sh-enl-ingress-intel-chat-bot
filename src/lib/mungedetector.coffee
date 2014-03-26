async = require 'async'
requestFactory = require LIB_DIR + '/requestfactory.js'
request = requestFactory()

NemesisMethodName = null

Munges = GLOBAL.Munges =
    Failed:    false
    Data:      null
    ActiveSet: 0
    NormalizeParamCount:
        func: (a) -> a
        body: 'function(a){return a;}'

MungeDetector = GLOBAL.MungeDetector = 
    
    start: (delay) ->

        delay = 0.5 * 60 * 1000 if not delay?
        
        setTimeout ->

            MungeDetector.detect (err) ->

                if err
                    logger.info '[MungeDetector] Retry in 5 seconds'
                    MungeDetector.start 5000
                else
                    MungeDetector.start()

        , delay

    detect: (callback) ->

        async.series [

            (callback) ->

                # 0. retrive munge data from database

                Database.db.collection('MungeData').findOne {_id: 'munge'}, (err, record) ->

                    if err
                        logger.error '[MungeDetector] Failed to read mungedata from database: %s', err.message
                        return callback err

                    if record?
                        Munges.Data = record.data
                        Munges.ActiveSet = record.index
                        Munges.NormalizeParamCount.body = record.func
                        Munges.NormalizeParamCount.func = Utils.createNormalizeFunction(record.func)

                    callback()

            (callback) ->

                # 1. test by internal munge-set

                # No munges in database: skip this step
                if Munges.Data is null
                    callback()
                    return

                tryMungeSet (err) ->

                    if not err?
                        callback 'done'
                        return

                    logger.warn '[MungeDetector] Failed.'
                    callback()

            (callback) ->

                # 2. extract munge data from Ingress.com/intel

                logger.info '[MungeDetector] Trying to extract munge data from ingress.com/intel.'

                extractMunge (err) ->

                    if not err?
                        callback 'new'
                        return

                    logger.warn '[MungeDetector] Failed.'
                    callback()

            (callback) ->

                # :( no useable munge-set

                callback 'fail'

        ], (err) ->

            if err is 'done' or err is 'new'
                
                Munges.Failed = false

                if err is 'new'

                    Database.db.collection('MungeData').update {_id: 'munge'},
                        $set:
                            data:  Munges.Data
                            index: Munges.ActiveSet
                            func:  Munges.NormalizeParamCount.body
                    , {upsert: true}
                    , (err) ->
                        
                        # ignore error

                        if err
                            logger.error '[MungeDetector] Failed to save mungedata: %s', err.message
                        
                        callback && callback()
                        return

                else

                    callback && callback()
                    return

            else

                Munges.Failed = true

                logger.error '[MungeDetector] Failed to detect munge data.'
                callback new Error('Munge detection failed')

tryMungeSet = (tryCallback) ->

    request.push
        action: 'getGameScore'
        data:   {}
        onSuccess: (response, callback) ->

            if not response?.result?.resistanceScore?
                
                callback()
                tryCallback && tryCallback err

            else

                callback()
                tryCallback && tryCallback()

        onError: (err, callback) ->

            callback()
            tryCallback && tryCallback err

extractMunge = (callback) ->

    request.get '/jsc/gen_dashboard.js', (error, response, body) ->
        
        if error
            callback 'fail'
            return

        body = body.toString()

        # some hacks
        export_obj = {}
        google =
            maps:
                OverlayView: ->
                    null

        try
            eval body + ';export_obj.nemesis = nemesis;'
            result = Utils.extractMungeFromStock export_obj.nemesis
        catch err
            callback 'fail'
            return

        Munges.Data      = [result]
        Munges.ActiveSet = 0
        Munges.NormalizeParamCount.body = Utils.extractNormalizeFunction export_obj.nemesis
        Munges.NormalizeParamCount.func = Utils.createNormalizeFunction Munges.NormalizeParamCount.body

        # test it
        tryMungeSet (err) ->

            if not err?
                callback()
                return

            callback 'fail'
