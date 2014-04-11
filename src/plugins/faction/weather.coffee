_ = require 'underscore'
request = require 'request'
async = require 'async'
cheerio = require 'cheerio'
lru = require 'lru-cache'
cache = lru
    max:    500
    maxAge: 30 * 60 * 1000

# preprocess data

alterCitycodes =
    '魔都': '上海'
    '帝都': '北京'
    '哏都': '天津'
    '妖都': '广州'
    '霸都': '合肥'
    '神都': '洛阳'
    '小魔都': '南京'
    '旧都': '南京'

getCSV = (file) ->

    fs = require 'fs'
    s = fs.readFileSync file
    
    result = []

    rows = s.toString().split '\n';
    for row in rows
        continue if row.trim().length is 0
        cols = row.split ','
        result.push cols

    result

_provinces = getCSV ROOT_DIR + '/res/province.csv'
_provinceId2P = {}
_provinceId2P[p[0]] = p for p in _provinces
_cities = getCSV ROOT_DIR + '/res/city.csv'
cities = []
for c in _cities

    if _provinceId2P[c[4]]?[1] is c[1]
        #省份名
        tags = [c[1], c[2]]
        factor = 11
    else
        #不是省份名
        province = _provinceId2P[c[4]]
        if c[1].indexOf('(') > -1
            tags = [c[1].replace(/\(.*?\)/, ''), /\((.*?)\)/.exec(c[1])[1], c[2], province[1], province[2]]
        else
            tags = [c[1], c[2], province[1], province[2]]

        tags = _.uniq tags

        factor = 10

    cities.push
        reqName: c[1]
        tags:    tags
        factor:  factor

# release memory
_provinces = null
_provinceId2P = null
_cities = null

plugin = 

    test: (item) ->

        return false if not FactionUtil.isCallingBot item

        r = FactionUtil.parseCallingBody item
        return true if r.body.toLowerCase() is 'tq'
        return true if /(天气|tian\s*?qi|weather)/i.test r.body

        return false

    parseRequestCity: (body) ->

        # default value
        if /^(天气|tian\s*?qi|weather|tq)$/i.test body
            return '上海'
        
        escapedBody = body.toLowerCase()
        escapedBody = escapedBody.replace /\s/g, ''
        escapedBody = escapedBody.replace /(天气|tianqi|weather)/g, ''

        maxFactor = 0
        maxFactorName = null

        # 计算命中最高的城市
        for city in cities
            f = 0
            for tag in city.tags
                if escapedBody.indexOf(tag) > -1
                    f += city.factor * tag.length
            if f > maxFactor
                maxFactor = f
                maxFactorName = city.reqName

        # 检查别名
        if maxFactorName is null
            for alterCityname, realCityname of alterCitycodes
                if escapedBody.indexOf(alterCityname) > -1
                    maxFactorName = realCityname
                    break

        return maxFactorName

    getWeather: (cityCode, callback) ->

        return callback 'Invalid city code' if cityCode is null

        w = cache.get cityCode
        return callback null, w if w?

        async.waterfall [

            (callback) ->

                request.get 'http://weather.51juzhai.com/data/getHttpUrl?cityName=' + encodeURIComponent(cityCode), (err, response, body) ->

                    if err
                        return callback err

                    try
                        obj = JSON.parse body
                    catch err
                        return callback err

                    if not obj.result?
                        return callback 'Invalid response body'

                    callback null, obj.result

            , (url, callback) ->

                request.get url, (err, response, xml) ->

                    if err
                        return callback err

                    callback null, cheerio.load(xml)
                    #parseString xml, callback

            , ($, callback) ->

                weather = {}

                weather.city = $('ct').attr 'nm'
                weather.data = []

                $d = $('dt')
                $d.each ->
                    day = $(this)
                    weather.data.push
                        date:       day.attr 'date'
                        weather:    day.attr 'hwd'
                        templow:    day.attr 'ltmp'
                        temphigh:   day.attr 'htmp'
                        notice:     day.attr 'newkn'

                $d = $('air')
                if $d.length > 0
                    weather.air =
                        avgname: $d.attr 'cityaveragename'
                        pm2:     $d.attr 'pmtwoaqi'
                        pm10:    $d.attr 'pmtenaqi'
                        grade:   $d.attr 'aqigrade'
                        pubtime: new Date($d.attr 'ptime')
                
                cache.set cityCode, weather

                callback null, weather

        ], callback

    process: (item, callback) ->

        r = FactionUtil.parseCallingBody item
        city = plugin.parseRequestCity r.body

        if argv.debug
            FactionUtil.send Bot.generateTemplate('@{player} ## weather of {city} ##').fillPlayer(r.player).fill({city: city}).toString(), r.body
            return callback()

        plugin.getWeather city, (err, weather) ->

            if err
                FactionUtil.send Bot.generateTemplate('@{player} 不会自己查啊 {smily:掀桌}').fillPlayer(r.player).fillSmily().toString(), r.body
                return callback()

            if weather.air?
                template = Bot.getTemplate 'weather.air'
            else
                template = Bot.getTemplate 'weather'

            template = template.fill
                city:               weather.city
                today_weather:      weather.data[0].weather
                today_ltmp:         weather.data[0].templow
                today_htmp:         weather.data[0].temphigh
                today_notice:       weather.data[0].notice
                tomorrow_weather:   weather.data[1].weather
                tomorrow_ltmp:      weather.data[1].templow
                tomorrow_htmp:      weather.data[1].temphigh
                tomorrow_notice:    weather.data[1].notice
            if weather.air?
                template = template.fill
                    air_avgname:        weather.air?.avgname
                    air_grade:          weather.air?.grade
                    air_pm2:            weather.air?.pm2
                    air_pm10:           weather.air?.pm10
                    air_time:           weather.air?.pubtime.getHours() + '时'

            template = template.fillPlayer r.player

            FactionUtil.send template.toString(), r.body
            callback()

module.exports = plugin


###
weather.test '天气'
weather.test 'tq'
weather.test 'weather'
weather.test '上海天气'
weather.test '上海'
weather.test 'shanghai'
weather.test 'shanghaitianqi'
weather.test 'shang hai tian qi'
weather.test 'shang hai tianqi'
weather.test 'shanghai tian qi'
weather.test 'shanghai weather'
weather.test '宝山天气'
weather.test 'baoshan tianqi'
weather.test '上海宝山天气'
weather.test 'shanghai bao shan tianqi'
weather.test '崇明县天气'
weather.test '上海崇明天气'
weather.test 'chongming weather'
weather.test 'chongming tianqi'
weather.test '通州天气'
weather.test '北京的通州天气'
weather.test 'tongzhou tianqi'
weather.test 'tongzhou,beijing weather'
weather.test '南通通州 天气'
weather.test '江苏通州天气'
weather.test 'jiang su tongzhou tianqi'
weather.test 'beijing tianqi'
weather.test '北京天气'
weather.test '海淀区天气'
weather.test '北京海淀区天气'
weather.test 'haidianqutianqi'
weather.test '华盛顿天气'
weather.test '迈阿密天气'
weather.test 'luoma tianqi'
weather.test 'milantianqi'
weather.test '台北市天气'
###