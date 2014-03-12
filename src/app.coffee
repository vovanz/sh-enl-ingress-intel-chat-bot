logger = GLOBAL.logger = require 'winston'
logger.exitOnError = false
logger.remove logger.transports.Console
logger.add logger.transports.Console,
    colorize:   true
    timestamp:  true
logger.add logger.transports.File,
    filename:   'bot.log'

noop = GLOBAL.noop = ->
    null

require './config.js'

require './lib/bot.js'
require './lib/leaflet.js'
require './lib/utils.js'
require './lib/database.js'
require './lib/mungedetector.js'
require './lib/accountinfo.js'
require './lib/public.js'
require './lib/faction.js'

async = require 'async'

async.series [

    (callback) ->

        # raise error here
        logger.info '[MungeDetector] Detecting munge set...'
        MungeDetector.detect callback

    , (callback) ->
        
        # raise error here
        AccountInfo.fetch callback

    , (callback) ->

        PublicListener.init callback
    
    , (callback) ->

        FactionListener.init callback

    , (callback) ->

        logger.info '[Bot] started'
        MungeDetector.start()
        PublicListener.start()
        FactionListener.start()
        callback()

], (err) ->

    Database.db.close() if err