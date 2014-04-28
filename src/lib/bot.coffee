o3o = require 'o3o'

child_process = require 'child_process'
path = require 'path'
fs = require 'fs'

readline = require 'readline'

express = require 'express'
app = express()

async = require 'async'

exporterBaseDir = ROOT_DIR + '/ingress-exporter'

######################
# Get plugins
_plugins = require('require-all')
    dirname: PLUGINS_DIR + '/server'
    filter : /(.+)\.js$/,

serverPluginList = []
serverPluginList.push plugin for pname, plugin of _plugins
serverPlugins = {}
serverPlugins[plugin.name] = plugin for plugin in serverPluginList

_plugins = null
######################

class FormatableTemplate

    constructor: (string) ->

        @value = string

    fillPlayer: (player) ->

        @value = @value.replace /\{([^{}]+)\}/g, (match, key) ->
            if key is 'player'
                return player
            else
                return '{' + key + '}'

        @

    fillSmily: ->

        @value = @value.replace /\{([^{}]+)\}/g, (match, key) ->
            if key.indexOf('smily') is 0
                return o3o key.substr(6)
            else
                return '{' + key + '}'

        @

    fill: (arr) ->

        @value = @value.replace /\{([^{}]+)\}/g, (match, key) ->
            if arr[key]?
                return arr[key]
            else
                return '{' + key + '}'

        @

    toString: ->

        @value

GLOBAL.AccessLevel = 

    LEVEL_UNKNOWN:      -1
    LEVEL_GUEST:        0
    LEVEL_VALIDATED:    10
    LEVEL_TRUSTED:      100
    LEVEL_CORE:         1000
    LEVEL_ROOT:         9999

    stringify: (v) ->

        return 'LEVEL_GUEST'        if v is AccessLevel.LEVEL_GUEST
        return 'LEVEL_VALIDATED'    if v is AccessLevel.LEVEL_VALIDATED
        return 'LEVEL_TRUSTED'      if v is AccessLevel.LEVEL_TRUSTED
        return 'LEVEL_CORE'         if v is AccessLevel.LEVEL_CORE
        return 'LEVEL_ROOT'         if v is AccessLevel.LEVEL_ROOT
        
        'LEVEL_UNKNOWN'

    parse: (v) ->

        return AccessLevel.LEVEL_GUEST      if v is 'LEVEL_GUEST'
        return AccessLevel.LEVEL_VALIDATED  if v is 'LEVEL_VALIDATED'
        return AccessLevel.LEVEL_TRUSTED    if v is 'LEVEL_TRUSTED'
        return AccessLevel.LEVEL_CORE       if v is 'LEVEL_CORE'
        return AccessLevel.LEVEL_ROOT       if v is 'LEVEL_ROOT'
        
        AccessLevel.LEVEL_UNKNOWN

    isValid: (v) ->

        return false if AccessLevel.stringify(v) is 'LEVEL_UNKNOWN'

        true

Bot = GLOBAL.Bot =
    
    Server:

        app: app

        plugins: serverPlugins

        routeEntries: []

        start: (callback) ->

            app.listen Config.Server.Port, ->

                logger.info '[Server] Started @ port %d', Config.Server.Port
                callback()

        bootstrap: (callback) ->

            app.use require 'compression'
            app.use require 'method-override'
            app.use require 'body-parser'

            async.eachSeries serverPluginList, (plugin, callback) ->
                if plugin.bootstrap?
                    plugin.bootstrap callback
                else
                    callback()
            , callback

        init: (callback) ->

            async.eachSeries serverPluginList, (plugin, callback) ->
                if plugin.init?
                    plugin.init callback
                else
                    callback()
            , callback

    init: (callback) ->

        async.series [
            Bot.Server.bootstrap
            Bot.Server.init
        ], callback

    exec: (options, callback) ->

        parameters = options.argv
        timeout    = options.timeout
        output     = options.output

        argv = [
            path.join(exporterBaseDir, 'build/app.js')
            '--raw'
            '--detect'
            'false'
            '--cookie'
            Config.Auth.CookieRaw
        ].concat parameters

        process = child_process.spawn 'node', argv, 
            cwd: exporterBaseDir

        stdout = ''
        stderr = ''

        ex = null
        timer = null

        exithandler = (code, signal) ->

            if timer
                clearTimeout timer
                timer = null

            if not ex and code is 0 and signal is null
                return callback null, stdout, stderr

            if not ex
                ex = new Error 'Command failed: ' + stderr
                ex.code = code
                ex.signal = signal

            callback ex, stdout, stderr

        errorhandler = (e) ->

            ex = e
            process.stdout.destroy()
            process.stderr.destroy()
            exithandler()

        kill = ->

            process.stdout.destroy();
            process.stderr.destroy();

            try
                process.kill()
            catch e
                ex = e
                exithandler()

        pipeLog = (line) ->

            p = line.indexOf ':'
            
            if p is -1
                logger.info line
                return

            type = line.substr 0, p
            if ['info', 'error', 'warn'].indexOf(type) isnt -1
                logger[type] line.substr p + 2
            else
                logger.info line

        if timeout
            timer = setTimeout ->
                kill()
                timer = null
            , timeout

        process.stderr.setEncoding 'utf8'
        process.stdout.setEncoding 'utf8'

        readline.createInterface
            input:      process.stdout
            terminal:   false
        .on 'line', (line) ->
            stdout += line + '\n'
            pipeLog line

        readline.createInterface
            input:      process.stderr
            terminal:   false
        .on 'line', (line) ->
            stderr += line + '\n'
            pipeLog line

        process.on 'error', errorhandler

        process.on 'close', exithandler
    
    removePunc: (str) ->

        str.replace(/[\.,-\/#!$%\^&\*;:{}=\-_`~()]/g, '').trim()

    getTemplate: (file) ->

        templates = require(TEMPLATE_DIR + '/' + file + '.json')
        Bot.getTemplateObj templates

    getTemplateObj: (templates) ->

        s = ''
        for arr in templates
            s += Bot.getRandomInArray arr

        return new FormatableTemplate s

    generateTemplate: (templateString) ->

        return new FormatableTemplate templateString

    getRandomInArray: (arr) ->

        r = Math.floor Math.random() * arr.length
        return arr[r]

['get', 'post', 'put', 'delete'].forEach (method) ->

    Bot.Server[method] = (path, min_access_level, desc, callback) ->

        Bot.Server.routeEntries.push
            method:             method
            path:               path
            desciption:         desc
            min_access_level:   AccessLevel.stringify min_access_level

        app[method] path, (req, res) ->

            if argv.auth is 'false' or min_access_level <= AccessLevel.LEVEL_GUEST
                return callback req, res

            if req._check_token?
                req._check_token min_access_level, req.query.token, (ok) ->

                    return callback req, res if ok

                    res.json
                        error: "No permission. Required access-level: #{AccessLevel.stringify(min_access_level)}"
            else
                callback req, res
            
module.exports = plugin