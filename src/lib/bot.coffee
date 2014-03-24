o3o = require 'o3o'

child_process = require 'child_process'
path = require 'path'
fs = require 'fs'

readline = require 'readline'

express = require 'express'
app = express()

async = require 'async'

exporterBaseDir = ROOT_DIR + '/ingress-exporter'

serverPlugins = require('require-all')
    dirname: PLUGINS_DIR + '/server'
    filter : /(.+)\.js$/,

serverPluginList = []
serverPluginList.push plugin for pname, plugin of serverPlugins

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
                return o3o.fetch key.substr(6)
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

Bot = GLOBAL.Bot =
    
    Server:

        app: app

        start: (callback) ->

            app.listen Config.Server.Port, ->

                logger.info '[Server] Started @ port %d', Config.Server.Port
                callback()

        init: (callback) ->

            async.eachSeries serverPluginList, (plugin, callback) ->
                if plugin.init?
                    plugin.init callback
                else
                    callback()
            , callback

    init: (callback) ->

        async.series [
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
                callback null, stdout, stderr
                return

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

    getTemplate: (templates) ->

        s = ''
        for arr in templates
            s += Bot.getRandomInArray arr

        return new FormatableTemplate s

    generateTemplate: (templateString) ->

        return new FormatableTemplate templateString

    getRandomInArray: (arr) ->

        r = Math.floor Math.random() * arr.length
        return arr[r]
