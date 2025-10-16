DiscordWebhook = {
    ['trunk']            = "",
    ['glovebox']         = "",
    ['stash']            = "",
    ['drop']             = "",
    ['give']             = "",
    ['additem']          = "",
    ['player']           = "",
    ['shop']             = "",
    ['cheater']          = "",
    ['checkserveritems'] = "",
    ['duplicateitems']   = ""
}

local Colors = {
    ['default'] = 14423100,
    ['blue'] = 255,
    ['red'] = 16711680,
    ['green'] = 65280,
    ['white'] = 16777215,
    ['black'] = 0,
    ['orange'] = 16744192,
    ['yellow'] = 16776960,
    ['pink'] = 16761035,
    ["lightgreen"] = 65309,
}

RegisterNetEvent('codem-inventory:CreateLog', function(title, color, message, source, webhooktype)
    if not Config.UseDiscordWebhooks then return end
    local logQueue = {}
    if not webhooktype then webhooktype = "additem" end
    local webHook = DiscordWebhook[webhooktype]
    if not source then source = "Unknown" end
    local info = message.info and message.info.series or nil
    local description = ""
    if message and info then
        description = "Player: **" .. message.playername .. "**\n"
        description = description .. "Item: **" .. message.itemname .. "**\n"
        description = description .. "Miktar: **" .. message.amount .. "**\n"
        description = description .. "Konum : **" .. message.reason .. "**\n"
        description = description .. "Series : **" .. info .. "**\n"
    else
        description = "Player: **" .. message.playername .. "**\n"
        description = description .. "Item: **" .. message.itemname .. "**\n"
        description = description .. "Miktar: **" .. message.amount .. "**\n"
        description = description .. "Konum : **" .. message.reason .. "**\n"
    end

    local embedData = {
        {
            ['title'] = title or "Envanter Log",
            ['color'] = Colors[color] or Colors['default'] or 14423100,
            ['footer'] = {
                ['text'] = os.date('%Y-%m-%d %H:%M:%S') or false,
            },
            ['description'] = description,
            ['author'] = {
                ['name'] = 'Codem Inventory Logs',
                ['icon_url'] =
                'https://cdn.discordapp.com/attachments/1063175024992858253/1149113090382762126/c298422238593b82857b5dc916dce30ba6483031.png?ex=64fa5276&is=64f900f6&hm=6bb8b4a0daf6dfcaf61cb55b153db06929b449ef8646d9b1e5990098bf95b9bd&',
            },
        }
    }
    logQueue = { webhook = webHook, data = embedData }
    local postData = { username = 'Codem Inventory Log', embeds = embedData }
    PerformHttpRequest(webHook, function(err, text, headers) end, 'POST', json.encode(postData),
        { ['Content-Type'] = 'application/json' })
end)


RegisterNetEvent('codem-inventory:cheaterlogs', function(logdata)
    local description = ""


    description = "Oyuncu: **" .. logdata.playername .. "**\n"
    description = description .. "Event: **" .. logdata.event .. "**\n"
    local embedData = {
        {
            ['title'] = "Cheater Log",
            ['color'] = 14423100,
            ['footer'] = {
                ['text'] = os.date('%Y-%m-%d %H:%M:%S') or false,
            },
            ['description'] = description,
            ['author'] = {
                ['name'] = 'Codem Inventory Logs',
                ['icon_url'] =
                'https://cdn.discordapp.com/attachments/1063175024992858253/1149113090382762126/c298422238593b82857b5dc916dce30ba6483031.png?ex=64fa5276&is=64f900f6&hm=6bb8b4a0daf6dfcaf61cb55b153db06929b449ef8646d9b1e5990098bf95b9bd&',
            },
        }
    }
    local postData = { username = 'Codem Inventory Log', embeds = embedData }
    PerformHttpRequest(DiscordWebhook['cheater'], function(err, text, headers) end, 'POST', json.encode(postData),
        { ['Content-Type'] = 'application/json' })
end)
