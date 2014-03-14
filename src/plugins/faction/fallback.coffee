plugin = 

    test: (item) ->

        return false if not FactionUtil.isCallingBot item

        return -1

    process: (item, callback) ->

        r = FactionUtil.parseCallingBody item

        if /(不要|禁止|不许|别)再?卖萌/.test r.body

            template = [
                ['@{player} 哼 ']
                ['{smily:掀桌}']
            ]

        else if /卖.*?萌/.test r.body

            template = [
                ['@{player} ']
                [
                    '{smily:happy}'
                    '{smily:喵}'
                    '{smily:shy}'
                ]
            ]

        else

            template = [
                ['@{player} ']
                [
                    '呵呵'
                    '嗯?'
                    '{smily:surprise}'
                ]
            ]

        FactionUtil.send Bot.getTemplate(template).fillPlayer(r.player).fillSmily().toString()

        callback()

module.exports = plugin