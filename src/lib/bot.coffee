o3o = require 'o3o'

exec = require('child_process').exec
path = require 'path'
fs = require 'fs'

exporterBaseDir = fs.realpathSync 'ingress-exporter'

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
    
    exec: (parameters, timeout, callback) ->

        exec 'node ' + path.join(exporterBaseDir, 'build/app.js') + ' --mungedetect false --playerdetect false ' + parameters,
            cwd:     exporterBaseDir
            timeout: timeout
        , callback

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
