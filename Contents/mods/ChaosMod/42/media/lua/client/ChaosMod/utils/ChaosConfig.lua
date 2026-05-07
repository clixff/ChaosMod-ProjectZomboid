---@class DonatePriceGroup
---@field group integer
---@field price number

---@class ChaosConfigStreamerMode
---@field streamer_mode_enabled boolean -- if streamer mode is enabled
---@field voting_enabled boolean -- If voting is enabled
---@field voting_mode number
---@field type string -- Streamer mode type (twitch or ...)
---@field use_localhost_ip boolean
---@field advanced_voting_numbers boolean
---@field say_killed_zombie_name boolean
---@field zombie_nicknames_buffer number
---@field use_zombie_nicknames boolean
---@field enable_donate boolean
---@field donate_providers table<integer, string>
---@field donate_price_groups DonatePriceGroup[]
---@field allow_vote_command boolean
---@field hide_votes boolean
---@field render_chat_messages boolean
---@field use_animals_nicknames boolean

---@class ChaosConfigUI
---@field progress_bar_color string
---@field progress_bar_opacity number
---@field progress_bar_text_color string
---@field progress_bar_height number
---@field effect_progress_color string
---@field effect_progress_text_color string
---@field effects_default_x number
---@field effects_default_y number
---@field effects_from_bottom_to_top boolean
---@field effects_anchor_right boolean
---@field progress_bar_rgb {r: number, g: number, b: number}
---@field progress_bar_text_rgb {r: number, g: number, b: number}
---@field effect_progress_rgb {r: number, g: number, b: number}
---@field effect_progress_text_rgb {r: number, g: number, b: number}
---@field progress_bar_voting_color string -- progress bar color when voting is active
---@field progress_bar_voting_rgb {r: number, g: number, b: number}
---@field vote_background_color string
---@field vote_background_rgb {r: number, g: number, b: number}

---@class ChaosConfig
---@field lang string -- Language code (e.g. "en", "fr")
---@field effects_interval_enabled boolean -- Disabling this will not start any effect, but streamer mode will work
---@field effects_interval number
---@field vote_start_time number
---@field hide_progress_bar boolean
---@field use_voting_progress_bar_color boolean
---@field ui ChaosConfigUI
---@field ui_sounds_enabled boolean
---@field ignore_effect_chances boolean -- If true, all effects have equal chance 1 during selection
---@field streamer_mode ChaosConfigStreamerMode
ChaosConfig = ChaosConfig or {
    lang = "en",
    effects_interval_enabled = true,
    effects_interval = 45,
    vote_start_time = 15,
    hide_progress_bar = false,
    use_voting_progress_bar_color = false,
    ui = {
        progress_bar_color         = "9f211f",
        progress_bar_opacity       = 0.9,
        progress_bar_text_color    = "ffffff",
        progress_bar_height        = 22,
        effect_progress_color      = "9f211f",
        effect_progress_text_color = "ffffff",
        effects_default_x          = 1620,
        effects_default_y          = 720,
        effects_from_bottom_to_top = true,
        effects_anchor_right       = true,
        progress_bar_rgb           = { r = 159 / 255, g = 33 / 255, b = 31 / 255 },
        progress_bar_text_rgb      = { r = 1, g = 1, b = 1 },
        effect_progress_rgb        = { r = 159 / 255, g = 33 / 255, b = 31 / 255 },
        effect_progress_text_rgb   = { r = 1, g = 1, b = 1 },
        progress_bar_voting_color  = "3b8eea",
        progress_bar_voting_rgb    = { r = 17 / 255, g = 168 / 255, b = 205 / 255 },
        vote_background_color      = "9f211f",
        vote_background_rgb        = { r = 159 / 255, g = 33 / 255, b = 31 / 255 },
    },
    ui_sounds_enabled = true,
    ignore_effect_chances = false,
    streamer_mode = {
        streamer_mode_enabled = false,
        voting_enabled = false,
        voting_mode = 0,
        type = "twitch",
        use_localhost_ip = true,
        advanced_voting_numbers = false,
        say_killed_zombie_name = true,
        zombie_nicknames_buffer = 150,
        use_zombie_nicknames = true,
        enable_donate = false,
        donate_providers = {},
        donate_price_groups = {
            { group = 1, price = 1.0 },
            { group = 2, price = 2.0 },
            { group = 3, price = 4.0 },
            { group = 4, price = 5.0 },
            { group = 5, price = 7.5 },
            { group = 6, price = 10.0 },
        },
        vote_start_time = 15,
        allow_vote_command = true,
        hide_votes = false,
        render_chat_messages = true,
        use_animals_nicknames = true,
    }
}

---@param hex string
---@return {r: number, g: number, b: number} | nil
function ChaosConfig.HexToRGB(hex)
    if type(hex) ~= "string" or #hex ~= 6 or not hex:match("^[0-9a-fA-F]+$") then
        return nil
    end
    return {
        r = (tonumber(hex:sub(1, 2), 16) or 0) / 255,
        g = (tonumber(hex:sub(3, 4), 16) or 0) / 255,
        b = (tonumber(hex:sub(5, 6), 16) or 0) / 255,
    }
end

---@param existing any
---@param defaults any
---@return any, boolean -- merged value, true if any keys were added
local function mergeMissingKeys(existing, defaults)
    if type(defaults) ~= "table" or type(existing) ~= "table" then
        return existing, false
    end

    -- Treat arrays as opaque values; do not merge their elements
    local function isArr(t)
        if type(t) ~= "table" then return false end
        local count = 0
        for _ in pairs(t) do count = count + 1 end
        if count == 0 then return true end
        for i = 1, count do
            if t[i] == nil then return false end
        end
        return true
    end

    if isArr(defaults) or isArr(existing) then
        return existing, false
    end

    local changed = false
    for key, defValue in pairs(defaults) do
        if existing[key] == nil then
            existing[key] = defValue
            changed = true
        else
            local merged, subChanged = mergeMissingKeys(existing[key], defValue)
            existing[key] = merged
            if subChanged then changed = true end
        end
    end
    return existing, changed
end

ChaosConfig._mergeMissingKeys = mergeMissingKeys

function ChaosConfig.LoadConfigFromDisk()
    ---@type table | nil
    local defaultConfig = ChaosFileReader.ReadJsonFile("default_config.json")
    if not defaultConfig then
        print("[ChaosConfig] Failed to load default_config.json")
    end

    ---@type ChaosConfig | nil
    local configData = ChaosFileReader.ReadJsonFromCache("ChaosMod/config.json")
    if not configData then
        if defaultConfig then
            print("[ChaosConfig] config.json not found in user folder; copying default_config.json")
            ChaosFileReader.WriteJsonToCache("ChaosMod/config.json", defaultConfig)
            configData = defaultConfig
        end
    elseif defaultConfig then
        local _, changed = mergeMissingKeys(configData, defaultConfig)
        if changed then
            print("[ChaosConfig] Added missing keys from default_config.json; saving config.json")
            ChaosFileReader.WriteJsonToCache("ChaosMod/config.json", configData)
        end
    end

    if not configData then
        print("[ChaosConfig] Failed to load config from disk")
        return
    end

    if type(configData.lang) == "string" and configData.lang ~= "" then
        ChaosConfig.lang = configData.lang
    end

    if type(configData.effects_interval_enabled) == "boolean" then
        ChaosConfig.effects_interval_enabled = configData.effects_interval_enabled
    end

    if type(configData.effects_interval) == "number" then
        ChaosConfig.effects_interval = configData.effects_interval
    end

    if type(configData.vote_start_time) == "number" then
        ChaosConfig.vote_start_time = configData.vote_start_time
    end

    if type(configData.hide_progress_bar) == "boolean" then
        ChaosConfig.hide_progress_bar = configData.hide_progress_bar
    end

    if type(configData.use_voting_progress_bar_color) == "boolean" then
        ChaosConfig.use_voting_progress_bar_color = configData.use_voting_progress_bar_color
    end

    if configData.ui then
        local src = configData.ui
        local dst = ChaosConfig.ui

        local pbRgb = ChaosConfig.HexToRGB(src.progress_bar_color)
        if pbRgb then
            dst.progress_bar_color = src.progress_bar_color
            dst.progress_bar_rgb = pbRgb
        end

        if type(src.progress_bar_opacity) == "number" and src.progress_bar_opacity >= 0 and src.progress_bar_opacity <= 1 then
            dst.progress_bar_opacity = src.progress_bar_opacity
        end

        local pbtRgb = ChaosConfig.HexToRGB(src.progress_bar_text_color)
        if pbtRgb then
            dst.progress_bar_text_color = src.progress_bar_text_color
            dst.progress_bar_text_rgb = pbtRgb
        end

        if type(src.progress_bar_height) == "number" and src.progress_bar_height > 0 then
            dst.progress_bar_height = src.progress_bar_height
        end

        local epRgb = ChaosConfig.HexToRGB(src.effect_progress_color)
        if epRgb then
            dst.effect_progress_color = src.effect_progress_color
            dst.effect_progress_rgb = epRgb
        end

        local eptRgb = ChaosConfig.HexToRGB(src.effect_progress_text_color)
        if eptRgb then
            dst.effect_progress_text_color = src.effect_progress_text_color
            dst.effect_progress_text_rgb = eptRgb
        end

        if type(src.effects_default_x) == "number" and src.effects_default_x >= 0 and src.effects_default_x <= 1920 then
            dst.effects_default_x = src.effects_default_x
        end

        if type(src.effects_default_y) == "number" and src.effects_default_y >= 0 and src.effects_default_y <= 1080 then
            dst.effects_default_y = src.effects_default_y
        end

        if type(src.effects_from_bottom_to_top) == "boolean" then
            dst.effects_from_bottom_to_top = src.effects_from_bottom_to_top
        end

        if type(src.effects_anchor_right) == "boolean" then
            dst.effects_anchor_right = src.effects_anchor_right
        end

        local pbvRgb = ChaosConfig.HexToRGB(src.progress_bar_voting_color)
        if pbvRgb then
            dst.progress_bar_voting_color = src.progress_bar_voting_color
            dst.progress_bar_voting_rgb = pbvRgb
        end

        local vbRgb = ChaosConfig.HexToRGB(src.vote_background_color)
        if vbRgb then
            dst.vote_background_color = src.vote_background_color
            dst.vote_background_rgb = vbRgb
        end
    end

    if type(configData.ui_sounds_enabled) == "boolean" then
        ChaosConfig.ui_sounds_enabled = configData.ui_sounds_enabled
    end

    if type(configData.ignore_effect_chances) == "boolean" then
        ChaosConfig.ignore_effect_chances = configData.ignore_effect_chances
    end

    if configData.streamer_mode then
        -- If streamer mode enabled
        if type(configData.streamer_mode.streamer_mode_enabled) == "boolean" then
            ChaosConfig.streamer_mode.streamer_mode_enabled = configData.streamer_mode.streamer_mode_enabled
        end

        -- If voting is enabled
        if type(configData.streamer_mode.voting_enabled) == "boolean" then
            ChaosConfig.streamer_mode.voting_enabled = configData.streamer_mode.voting_enabled
        end

        -- Streamer mode type (twitch or ...)
        if type(configData.streamer_mode.type) == "string" then
            ChaosConfig.streamer_mode.type = configData.streamer_mode.type
        end

        -- Voting mode
        if type(configData.streamer_mode.voting_mode) == "number" then
            ChaosConfig.streamer_mode.voting_mode = configData.streamer_mode.voting_mode
        end

        -- If should use localhost IP for voting
        if type(configData.streamer_mode.use_localhost_ip) == "boolean" then
            ChaosConfig.streamer_mode.use_localhost_ip = configData.streamer_mode.use_localhost_ip
        end
        -- If should use advanced voting numbers
        if type(configData.streamer_mode.advanced_voting_numbers) == "boolean" then
            ChaosConfig.streamer_mode.advanced_voting_numbers = configData.streamer_mode.advanced_voting_numbers
        end
        -- If should say killed zombie name
        if type(configData.streamer_mode.say_killed_zombie_name) == "boolean" then
            ChaosConfig.streamer_mode.say_killed_zombie_name = configData.streamer_mode.say_killed_zombie_name
        end
        -- Zombie nicknames buffer size
        if type(configData.streamer_mode.zombie_nicknames_buffer) == "number" then
            ChaosConfig.streamer_mode.zombie_nicknames_buffer = configData.streamer_mode.zombie_nicknames_buffer
        end
        -- If should use zombie nicknames
        if type(configData.streamer_mode.use_zombie_nicknames) == "boolean" then
            ChaosConfig.streamer_mode.use_zombie_nicknames = configData.streamer_mode.use_zombie_nicknames
        end
        -- If donate is enabled
        if type(configData.streamer_mode.enable_donate) == "boolean" then
            ChaosConfig.streamer_mode.enable_donate = configData.streamer_mode.enable_donate
        end
        -- Donate providers list
        if type(configData.streamer_mode.donate_providers) == "table" then
            ChaosConfig.streamer_mode.donate_providers = configData.streamer_mode.donate_providers
        end
        -- If chat vote command (!vote) is allowed
        if type(configData.streamer_mode.allow_vote_command) == "boolean" then
            ChaosConfig.streamer_mode.allow_vote_command = configData.streamer_mode.allow_vote_command
        end
        -- If vote counts are hidden from viewers
        if type(configData.streamer_mode.hide_votes) == "boolean" then
            ChaosConfig.streamer_mode.hide_votes = configData.streamer_mode.hide_votes
        end
        -- If zombie chat messages should be rendered above zombies
        if type(configData.streamer_mode.render_chat_messages) == "boolean" then
            ChaosConfig.streamer_mode.render_chat_messages = configData.streamer_mode.render_chat_messages
        end
        -- If animal nicknames should be displayed above follower animals
        if type(configData.streamer_mode.use_animals_nicknames) == "boolean" then
            ChaosConfig.streamer_mode.use_animals_nicknames = configData.streamer_mode.use_animals_nicknames
        end
        -- Donate price groups
        if type(configData.streamer_mode.donate_price_groups) == "table" then
            local groups = {}
            for _, entry in ipairs(configData.streamer_mode.donate_price_groups) do
                if type(entry) == "table" and type(entry.group) == "number" and type(entry.price) == "number" then
                    table.insert(groups, { group = entry.group, price = entry.price })
                end
            end
            if #groups > 0 then
                ChaosConfig.streamer_mode.donate_price_groups = groups
            end
        end
    end

    print("[ChaosMod] Config effects_interval_enabled: " .. tostring(ChaosConfig.effects_interval_enabled))
    print("[ChaosMod] Config streamer_mode.streamer_mode_enabled: " ..
        tostring(ChaosConfig.streamer_mode.streamer_mode_enabled))
    print("[ChaosMod] Config streamer_mode.use_zombie_nicknames: " ..
        tostring(ChaosConfig.streamer_mode.use_zombie_nicknames))
    print("[ChaosMod] Config streamer_mode.say_killed_zombie_name: " ..
        tostring(ChaosConfig.streamer_mode.say_killed_zombie_name))
end

---@return boolean
function ChaosConfig.IsZombieNicknamesEnabled()
    if not ChaosConfig.streamer_mode then
        return false
    end

    if ChaosConfig.streamer_mode.streamer_mode_enabled == false then
        return false
    end

    return ChaosConfig.streamer_mode.use_zombie_nicknames == true
end

---@return boolean
function ChaosConfig.IsAnimalsNicknamesEnabled()
    if not ChaosConfig.streamer_mode then
        return false
    end

    if ChaosConfig.streamer_mode.streamer_mode_enabled == false then
        return false
    end

    return ChaosConfig.streamer_mode.use_animals_nicknames == true
end

---@return boolean
function ChaosConfig.IsKilledZombieNameEnabled()
    if not ChaosConfig.streamer_mode then
        return false
    end

    if ChaosConfig.streamer_mode.streamer_mode_enabled == false then
        return false
    end

    if ChaosConfig.streamer_mode.use_zombie_nicknames == false then
        return false
    end

    return ChaosConfig.streamer_mode.say_killed_zombie_name == true
end

---@return boolean
function ChaosConfig.IsStreamerVotingEnabled()
    if not ChaosConfig.streamer_mode then
        return false
    end

    if ChaosConfig.effects_interval_enabled == false then
        return false
    end

    if ChaosConfig.streamer_mode.streamer_mode_enabled == false then
        return false
    end

    return ChaosConfig.streamer_mode.voting_enabled == true
end

---@return boolean
function ChaosConfig.IsEffectsEnabled()
    return ChaosConfig.effects_interval_enabled == true
end

---@return boolean
function ChaosConfig.IsUISoundsEnabled()
    return ChaosConfig.ui_sounds_enabled == true
end
