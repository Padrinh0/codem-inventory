local ShopItems = {
    ["1"] = { name = "sandwich", price = 80 },
    ["2"] = { name = "tosti", price = 80 },
    ["3"] = { name = "kurkakola", price = 80 },
    ["4"] = { name = "twerks_candy", price = 80 },
    ["5"] = { name = "water_bottle", price = 80 },
    ["6"] = { name = "beer", price = 80 },
    ["7"] = { name = "lighter", price = 80 },
    ["8"] = { name = "rolling_paper", price = 80 },
}


Config.Shops = {
    ["policeshop"] = {
        label = "Police Shop",
        Blip = {
            enable = true, -- show blip = true  -- hide blip false
            id = 1,
            scale = 0.5,
            color = 5,
        },
        job = {
            ["police"] = {
                [1] = true,
                [2] = true,
                [3] = true
            }
        },
        items = {
            ["1"] = { name = "weapon_pistol", price = 10, grade = 5 },
            ["2"] = { name = "weapon_flashlight", price = 10, grade = 4 },
            ["3"] = { name = "handcuffs", price = 10, grade = 6 },
            ["4"] = { name = "weapon_stungun", price = 10, },
            ["5"] = { name = "weapon_assaultsmg", price = 10, },
            ["6"] = { name = "weapon_smg", price = 10, },
            ["7"] = { name = "weapon_pistol50", price = 10, },
            ["8"] = { name = "bandage", price = 10, },
            ["9"] = { name = "pistol_ammo", price = 10, },
            ["10"] = { name = "smg_ammo", price = 10, },
        },
        coords = vector3(458.02, -979.17, 30.69)
    },
    ["market"] = {
        label = "Market",
        job = 'all',
        items = ShopItems,
        coords = vector3(25.65, -1346.6, 29.5),
        Blip = {
            enable = true, -- show blip = true  -- hide blip false
            id = 52,
            scale = 0.5,
            color = 5,
        },
    },
    ["market2"] = {
        label = "Market",
        job = 'all',
        items = ShopItems,
        coords = vector3(547.85, 2670.77, 42.16),
        Blip = {
            enable = true, -- show blip = true  -- hide blip false
            id = 52,
            scale = 0.5,
            color = 5,
        },
    },
    ["market3"] = {
        label = "Market",
        job = 'all',
        items = ShopItems,
        coords = vector3(1960.94, 3741.09, 32.34),
        Blip = {
            enable = true, -- show blip = true  -- hide blip false
            id = 52,
            scale = 0.5,
            color = 5,
        },
    },
    ["market4"] = {
        label = "Market",
        job = 'all',
        items = ShopItems,
        coords = vector3(-3040.04, 585.45, 7.91),
        Blip = {
            enable = true, -- show blip = true  -- hide blip false
            id = 52,
            scale = 0.5,
            color = 5,
        },
    },
    ["market5"] = {
        label = "Market",
        job = 'all',
        items = ShopItems,
        coords = vector3(-3242.85, 1001.27, 12.83),
        Blip = {
            enable = true, -- show blip = true  -- hide blip false
            id = 52,
            scale = 0.5,
            color = 5,
        },
    },
    ["market6"] = {
        label = "Market",
        job = 'all',
        items = ShopItems,
        coords = vector3(-2967.84, 391.34, 15.04),
        Blip = {
            enable = true, -- show blip = true  -- hide blip false
            id = 52,
            scale = 0.5,
            color = 5,
        },
    },
    ["market7"] = {
        label = "Market",
        job = 'all',
        items = ShopItems,
        coords = vector3(-1487.53, -378.72, 40.16),
        Blip = {
            enable = true, -- show blip = true  -- hide blip false
            id = 52,
            scale = 0.5,
            color = 5,
        },
    },
    ["market8"] = {
        label = "Market",
        job = 'all',
        items = ShopItems,
        coords = vector3(-707.36, -913.96, 19.22),
        Blip = {
            enable = true, -- show blip = true  -- hide blip false
            id = 52,
            scale = 0.5,
            color = 5,
        },
    },
    ["market9"] = {
        label = "Market",
        job = 'all',
        items = ShopItems,
        coords = vector3(-47.94, -1757.37, 29.42),
        Blip = {
            enable = true, -- show blip = true  -- hide blip false
            id = 52,
            scale = 0.5,
            color = 5,
        },
    },
    ["market10"] = {
        label = "Market",
        job = 'all',
        items = ShopItems,
        coords = vector3(1163.46, -323.09, 69.21),
        Blip = {
            enable = true, -- show blip = true  -- hide blip false
            id = 52,
            scale = 0.5,
            color = 5,
        },
    },
    ["market11"] = {
        label = "Market",
        job = 'all',
        items = ShopItems,
        coords = vector3(373.95, 326.73, 103.57),
        Blip = {
            enable = true, -- show blip = true  -- hide blip false
            id = 52,
            scale = 0.5,
            color = 5,
        },
    },
    ["market12"] = {
        label = "Market",
        job = 'all',
        items = ShopItems,
        coords = vector3(375.3, 325.79, 103.57),
        Blip = {
            enable = true, -- show blip = true  -- hide blip false
            id = 52,
            scale = 0.5,
            color = 5,
        },
    }
}
