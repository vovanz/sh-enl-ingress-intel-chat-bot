plugin = 

    test: (item) ->

        return false if not FactionUtil.isCallingBot item

        return -1

    process: (item, callback) ->

        r = FactionUtil.parseCallingBody item

        if /^来?卖个?萌吧?$/.test r.body

            template = [
                ['@{player} 才不卖萌 ']
                [
                    '{smily:喵}'
                    '{smily:shy}'
                ]
            ]

        else if /(不要|禁止|不许|别)再?卖萌/.test r.body

            template = [
                ['@{player} 哼 ']
                [
                    '{smily:掀桌}'
                    '{smily:angry}'
                ]
            ]

        else if /(萌|乖)/.test r.body

            template = [
                ['@{player} ']
                [
                    '{smily:happy}'
                    '{smily:喵}'
                    '{smily:shy}'
                ]
            ]

        else if /(好|真)(屌|叼|吊|厉害)/.test r.body

            template = [
                ['@{player} 那当然~ ']
                [
                    '{smily:happy}'
                    '{smily:shy}'
                ]
            ]

        else if /笨|不聪明/.test r.body

            template = [
                ['@{player} ']
                ['{smily:sad}']
            ]

        else if /(吗|么|了没)/.test r.body

            template = [
                ['@{player} ']
                ['不知道 {smily:surprise}']
            ]

        else

            template = [
                ['@{player} ']
                [
                    '呵呵'
                    '嗯?'
                    #'{smily:surprise}'
                ]
            ]

        FactionUtil.send Bot.getTemplateObj(template).fillPlayer(r.player).fillSmily().toString(), r.body

        callback()

module.exports = plugin