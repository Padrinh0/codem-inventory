Config                                = {}
Locales                               = Locales or {}
Config.Framework                      = "esx"       -- esx, oldesx, qb, oldqb
Config.Language                       = 'pt'       -- Check locales folder for available languages
Config.SQL                            = "oxmysql"  -- oxmysql, ghmattimysql, mysql-async
Config.InteractionHandler             = "drawtext" -- drawtext , qb-target , ox-target
Config.ServerLogo                     =
"https://cdn.discordapp.com/attachments/1025789416456867961/1106324039808594011/512x512_Logo.png?ex=6605d98d&is=65f3648d&hm=4c50c51ca9daaa45ef0bd4e7e4db0a76877a42a8f35e572830fa6e3b1bd8c5ca&"

Config.MaxWeight                      = 100000 -- Max weight that player can carry 100 kg
Config.MaxSlots                       = 35     -- Max slots that player can carry
Config.GroundSlots                    = 50     -- Max slots ground
Config.ItemClothingSystem             = true   -- If you want to use clothing system, set this to true or false
Config.CashItem                       = false  -- If you want to use cash item, set this to true or false
Config.DurabilitySystem               = true   -- If you want to use durability system, set this to true or false
Config.UseDiscordWebhooks             = false   -- If you want to use discord webhooks, set this to true or false
Config.DebugPrint                     = false  -- If you want to see debug prints, set this to true or false
Config.RealisticObjectDrop            = false  -- If you want to use realistic object drop, set this to true or false
Config.ThrowablesSystem               = false   -- If you want to use throwables system, set this to true or false
Config.SlingWeapon                    = false   -- If you want to use sling weapon system, set this to true or false
Config.DiePlayerRemoveHandsWeaponItem = false  -- If you want to remove weapon item when player die, set this to true or false
Config.MaxBackPackItem                = 1
Config.Cheaterlogs                    = true
Config.VersionChecker                 = false
Config.CraftSystem                    = true

Config.KeyBinds                       = {
    Inventory = 'F2',
    HotBar = 'TAB',
    ThrowWeapon = 'E'
}


Config.NotDeleteItemWhenPlayerDie = {
    ["id_card"] = true,
    ["driver_license"] = true,

    --- do not delete
    ["tshirt_1"] = true,
    ["torso_1"] = true,
    ["arms"] = true,
    ["pants_1"] = true,
    ["shoes_1"] = true,
    ["mask_1"] = true,
    ["bproof_1"] = true,
    ["chain_1"] = true,
    ["helmet_1"] = true,
    ["glasses_1"] = true,
    ["watches_1"] = true,
    ["bracelets_1"] = true,
    ["bags_1"] = true,

}
---for items that you don't want to be dragged during player rob
Config.NotRobItem = {
    ['id_card'] = true,
    ['lockpick'] = true
}
--- for jobs that you don't want to be robbed
Config.NotRobJob = {
    ['police'] = true,
    ['ambulance'] = true
}



Config.AnimPlayer = {
    ['openinventory'] = true,
    ['drop'] = true,
    ['giveitemplayer'] = true,
    ['opentrunk'] = true,
    ['closetrunk'] = true,

}


Config.Commands = {
    ['giveitem'] = "giveitem", -- giveitem command
    ['clearinv'] = "clearinv", -- clearinv command
    ['robplayer'] = "rob",     -- rob player
    ['deathrob'] = "deathrob", -- deathrob command
    ['closeinv'] = "closeinv",
    ['openinv'] = "openinv",
    ['hotbar'] = "hotbar",
    ['openinventoryplayer'] = "openinventoryplayer",
    ['openstash'] = "openstash",                             -- openstash command  /openstash stashid
    ['checkserveronlineitems'] = "checkserveronlineitems",   --- only cmd
    ['checkserverofflineitems'] = "checkserverofflineitems", -- only cmd
    ['slingweapon'] = "slingweapon"
}

Config.ContextMenuData = {
    { name = 'use',  label = 'Use Item',  icon = 'useitemicon' },
    { name = 'give', label = 'Give Item', icon = 'giveitemicon' },
    { name = 'drop', label = 'Drop Item', icon = 'dropitemicon' },
}
Config.AdjustmentsData = {
    { name = 'soundfx',      label = 'Sound FX',       value = true },
    { name = 'hoverinfo',    label = 'Hover Info',     value = true },
    { name = 'infoonbottom', label = 'Info on Bottom', value = true },
    { name = 'lights',       label = 'Lights',         value = true },
}

Config.Category = {
    { name = 'all',       label = 'All Items', icon = 'allitemsicon' },
    { name = 'weapon',    label = 'Weapons',   icon = 'weaponicon' },
    { name = 'food',      label = 'Foods',     icon = 'foodicon' },
    { name = 'craftable', label = 'Craftable', icon = 'craftableicon' },
    { name = 'clothes',   label = 'Clothes',   icon = 'clothesicon' }
}

Config.Stashs = {
    ["policestash"] = {
        label = "Police",
        maxweight = 35000,
        slot = 40,
        job = {
            ["police"] = {
                [1] = true,
                [2] = true,
                [3] = true
            }
        },
        gang = {
            ["ballas"] = {
                [1] = true,
                [2] = true,
                [3] = true
            },
            ["vagos"] = {
                [1] = true,
                [2] = true,
                [3] = true
            }
        },
        coords = vector3(461.87, -982.59, 30.69)
    },
    ["personelstash"] = {
        label = "Personel",
        maxweight = 35000,
        slot = 40,
        job = 'all',
        coords = vector3(457.07, -988.58, 30.69)
    },
}

Config.AddonVehicleTrunkOrGlovebox = {
    ['nkbuffalos'] = {
        ['trunk'] = {
            maxweight = 5000,
            slots = 5
        },
        ['glovebox'] = {
            maxweight = 10000,
            slots = 4
        }

    }
}


Config.BackEngineVehicles = {
    [`ninef`] = true,
    [`adder`] = true,
    [`vagner`] = true,
    [`t20`] = true,
    [`infernus`] = true,
    [`zentorno`] = true,
    [`reaper`] = true,
    [`comet2`] = true,
    [`comet3`] = true,
    [`jester`] = true,
    [`jester2`] = true,
    [`cheetah`] = true,
    [`cheetah2`] = true,
    [`prototipo`] = true,
    [`turismor`] = true,
    [`pfister811`] = true,
    [`ardent`] = true,
    [`nero`] = true,
    [`nero2`] = true,
    [`tempesta`] = true,
    [`vacca`] = true,
    [`bullet`] = true,
    [`osiris`] = true,
    [`entityxf`] = true,
    [`turismo2`] = true,
    [`fmj`] = true,
    [`re7b`] = true,
    [`tyrus`] = true,
    [`italigtb`] = true,
    [`penetrator`] = true,
    [`monroe`] = true,
    [`ninef2`] = true,
    [`stingergt`] = true,
    [`surfer`] = true,
    [`surfer2`] = true,
    [`gp1`] = true,
    [`autarch`] = true,
    [`tyrant`] = true
}
Citizen.CreateThread(function()
    function customToLower(str)
        str = str:gsub("İ", "i")
        str = str:gsub("I", "i")
        return str:lower()
    end
end)

Config.TrunkAndGloveboxWeight = {
    ["trunk"] = {
        [0] = {
            maxweight = 38000,
            slots = 30
        },
        [1] = {
            maxweight = 50000,
            slots = 40
        },
        [2] = {
            maxweight = 75000,
            slots = 50
        },
        [3] = {
            maxweight = 42000,
            slots = 35
        },
        [4] = {
            maxweight = 38000,
            slots = 30
        },
        [5] = {
            maxweight = 30000,
            slots = 25
        },
        [6] = {
            maxweight = 30000,
            slots = 25
        },
        [7] = {
            maxweight = 30000,
            slots = 25
        },
        [8] = {
            maxweight = 15000,
            slots = 15
        },
        [9] = {
            maxweight = 60000,
            slots = 35
        },
        [12] = {
            maxweight = 120000,
            slots = 25
        },
        [13] = {
            maxweight = 0,
            slots = 0
        },
        [14] = {
            maxweight = 120000,
            slots = 50
        },
        [15] = {
            maxweight = 120000,
            slots = 50
        },
        [16] = {
            maxweight = 120000,
            slots = 50
        }
    },
    ["glovebox"] = {
        [0] = {
            maxweight = 10000,
            slots = 6
        },
        [1] = {
            maxweight = 10000,
            slots = 6
        },
        [2] = {
            maxweight = 10000,
            slots = 6
        },
        [3] = {
            maxweight = 10000,
            slots = 6
        },
        [4] = {
            maxweight = 10000,
            slots = 6
        },
        [5] = {
            maxweight = 10000,
            slots = 6
        },
        [6] = {
            maxweight = 10000,
            slots = 6
        },
        [7] = {
            maxweight = 10000,
            slots = 6
        },
        [8] = {
            maxweight = 10000,
            slots = 6
        },
        [9] = {
            maxweight = 10000,
            slots = 6
        },
        [12] = {
            maxweight = 10000,
            slots = 6
        },
        [13] = {
            maxweight = 10000,
            slots = 6
        },
        [14] = {
            maxweight = 10000,
            slots = 6
        },
        [15] = {
            maxweight = 10000,
            slots = 6
        },
        [16] = {
            maxweight = 10000,
            slots = 6
        }
    }

}

Config.Notification = function(message, type, isServer, src) -- You can change here events for notifications
    if isServer then
        if Config.Framework == "esx" then
            TriggerClientEvent("esx:showNotification", src, message)
        else
            TriggerClientEvent('QBCore:Notify', src, message, type, 1500)
        end
    else
        if Config.Framework == "esx" then
            TriggerEvent("esx:showNotification", message)
        else
            TriggerEvent('QBCore:Notify', message, type, 1500)
        end
    end
end
