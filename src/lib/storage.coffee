class Storage

    constructor: (storageKey) ->

        Object.defineProperty @, '_storageKey',
            enumerable:     false
            configurable:   false
            writable:       false
            value:          storageKey

        Object.defineProperty @, '_updateTimer',
            enumerable:     false
            configurable:   false
            writable:       true
            value:          null

    fetch: (defaultValue, callback) =>

        Database.db.collection('Bot.Storage').findById @_storageKey, (err, record) =>
            
            if record?.data
                @setRawData record.data
                return callback()

            @setRawData defaultValue
            callback()

    setRawData: (data) =>

        for key, value of data

            Object.defineProperty @, key,
                enumerable:     true
                configurable:   true
                writable:       true
                value:          value

        @getRawData()

    getRawData: =>

        data = {}
        for key, value of @
            data[key] = value if (@hasOwnProperty key) and (typeof value isnt 'function')

        data

    save: =>

        @_updateTimer = setTimeout @_save, 1000 if not @_updateTimer?

    _save: =>

        Database.db.collection('Bot.Storage').updateById @_storageKey
        ,
            $set:
                data: @getRawData()
        ,
            upsert: true
        , noop

        @_updateTimer = null

module.exports = (storageKey) ->

    new Storage storageKey