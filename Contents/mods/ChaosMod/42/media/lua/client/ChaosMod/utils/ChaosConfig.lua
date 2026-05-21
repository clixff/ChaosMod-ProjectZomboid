---@class DonatePriceGroup
---@field group string
---@field price number

---@class ChaosConfigStreamerMode
---@field streamer_mode_enabled boolean -- if streamer mode is enabled
---@field voting_enabled boolean -- If voting is enabled
---@field voting_mode number
---@field voting_options_number number
---@field use_localhost_ip boolean
---@field say_killed_zombie_name boolean
---@field zombie_nicknames_buffer number
---@field use_zombie_nicknames boolean
---@field enable_donate boolean
---@field donation_systems table -- opaque, owned by StreamerMode app; Lua only round-trips it through save
---@field donate_price_groups DonatePriceGroup[]
---@field allow_vote_command boolean
---@field hide_votes boolean
---@field render_chat_messages boolean
---@field use_animals_nicknames boolean
---@field random_effect_in_vote boolean -- if true, one of the vote options is a hidden "Random" effect

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
---@field effects_duration_multiplier number -- multiplier applied to every effect's duration
---@field recent_effects_block_buffer number -- size of the recently-used effects blocklist
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
    effects_duration_multiplier = 1.0,
    recent_effects_block_buffer = 90,
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
        voting_options_number = 4,
        use_localhost_ip = true,
        say_killed_zombie_name = true,
        zombie_nicknames_buffer = 150,
        use_zombie_nicknames = true,
        enable_donate = false,
        donation_systems = {
            donationalerts = { enabled = false, app_id = "", currency = "" },
            twitch_bits = { enabled = false, price_multiplier = 100.0 },
        },
        donate_price_groups = {
            { group = "positive_1", price = 1 },
            { group = "positive_2", price = 2.5 },
            { group = "positive_3", price = 5 },
            { group = "positive_4", price = 7 },
            { group = "positive_5", price = 8 },
            { group = "positive_6", price = 10 },
            { group = "negative_1", price = 1 },
            { group = "negative_2", price = 2.5 },
            { group = "negative_3", price = 5 },
            { group = "negative_4", price = 7 },
            { group = "negative_5", price = 8 },
            { group = "negative_6", price = 10 },
            { group = "neutral_1",  price = 1 },
            { group = "neutral_2",  price = 2.5 },
            { group = "neutral_3",  price = 4.5 },
            { group = "neutral_4",  price = 7 },
            { group = "neutral_5",  price = 8 },
            { group = "neutral_6",  price = 10 },
        },
        vote_start_time = 15,
        allow_vote_command = true,
        hide_votes = false,
        render_chat_messages = true,
        use_animals_nicknames = true,
        random_effect_in_vote = true,
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

    if configData.lang and type(configData.lang) == "string" and configData.lang ~= "" then
        ---@diagnostic disable-next-line: assign-type-mismatch
        ---@type string
        local lang = configData.lang
        ChaosConfig.lang = lang
    end

    if type(configData.effects_interval_enabled) == "boolean" then
        ChaosConfig.effects_interval_enabled = configData.effects_interval_enabled
    end

    if type(configData.effects_interval) == "number" then
        ChaosConfig.effects_interval = configData.effects_interval
    end

    if type(configData.effects_duration_multiplier) == "number" and configData.effects_duration_multiplier > 0 then
        ChaosConfig.effects_duration_multiplier = configData.effects_duration_multiplier
    end

    if type(configData.recent_effects_block_buffer) == "number" and configData.recent_effects_block_buffer >= 0 then
        ChaosConfig.recent_effects_block_buffer = math.floor(configData.recent_effects_block_buffer)
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

        -- Voting mode
        if type(configData.streamer_mode.voting_mode) == "number" then
            ChaosConfig.streamer_mode.voting_mode = configData.streamer_mode.voting_mode
        end

        -- Number of voting options (clamped to 4-8)
        if type(configData.streamer_mode.voting_options_number) == "number" then
            local n = math.floor(configData.streamer_mode.voting_options_number)
            if n < 4 then n = 4 end
            if n > 8 then n = 8 end
            ChaosConfig.streamer_mode.voting_options_number = n
        end

        -- If should use localhost IP for voting
        if type(configData.streamer_mode.use_localhost_ip) == "boolean" then
            ChaosConfig.streamer_mode.use_localhost_ip = configData.streamer_mode.use_localhost_ip
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
        -- Donation systems (opaque blob owned by StreamerMode app)
        if type(configData.streamer_mode.donation_systems) == "table" then
            ChaosConfig.streamer_mode.donation_systems = configData.streamer_mode.donation_systems
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
        -- If one of the vote options is a hidden "Random" effect
        if type(configData.streamer_mode.random_effect_in_vote) == "boolean" then
            ChaosConfig.streamer_mode.random_effect_in_vote = configData.streamer_mode.random_effect_in_vote
        end
        -- Donate price groups
        if type(configData.streamer_mode.donate_price_groups) == "table" then
            local groups = {}
            for _, entry in ipairs(configData.streamer_mode.donate_price_groups) do
                if type(entry) == "table"
                    and (type(entry.group) == "string" or type(entry.group) == "number")
                    and type(entry.price) == "number" then
                    table.insert(groups, { group = tostring(entry.group), price = entry.price })
                end
            end
            ChaosConfig.streamer_mode.donate_price_groups = groups
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

---@return table
function ChaosConfig.BuildJsonSnapshot()
    local ui = ChaosConfig.ui or {}
    local sm = ChaosConfig.streamer_mode or {}
    local groups = {}
    if type(sm.donate_price_groups) == "table" then
        for _, g in ipairs(sm.donate_price_groups) do
            if type(g) == "table" then
                table.insert(groups, { group = tostring(g.group or ""), price = tonumber(g.price) or 0 })
            end
        end
    end
    return {
        lang = ChaosConfig.lang,
        effects_interval_enabled = ChaosConfig.effects_interval_enabled,
        effects_interval = ChaosConfig.effects_interval,
        effects_duration_multiplier = ChaosConfig.effects_duration_multiplier,
        recent_effects_block_buffer = ChaosConfig.recent_effects_block_buffer,
        vote_start_time = ChaosConfig.vote_start_time,
        hide_progress_bar = ChaosConfig.hide_progress_bar,
        use_voting_progress_bar_color = ChaosConfig.use_voting_progress_bar_color,
        ui = {
            progress_bar_color = ui.progress_bar_color,
            progress_bar_opacity = ui.progress_bar_opacity,
            progress_bar_text_color = ui.progress_bar_text_color,
            progress_bar_height = ui.progress_bar_height,
            effect_progress_color = ui.effect_progress_color,
            effect_progress_text_color = ui.effect_progress_text_color,
            effects_default_x = ui.effects_default_x,
            effects_default_y = ui.effects_default_y,
            effects_from_bottom_to_top = ui.effects_from_bottom_to_top,
            progress_bar_voting_color = ui.progress_bar_voting_color,
            vote_background_color = ui.vote_background_color,
        },
        ui_sounds_enabled = ChaosConfig.ui_sounds_enabled,
        ignore_effect_chances = ChaosConfig.ignore_effect_chances,
        streamer_mode = {
            streamer_mode_enabled = sm.streamer_mode_enabled,
            voting_enabled = sm.voting_enabled,
            voting_mode = sm.voting_mode,
            voting_options_number = sm.voting_options_number,
            use_localhost_ip = sm.use_localhost_ip,
            use_zombie_nicknames = sm.use_zombie_nicknames,
            use_animals_nicknames = sm.use_animals_nicknames,
            render_chat_messages = sm.render_chat_messages,
            say_killed_zombie_name = sm.say_killed_zombie_name,
            zombie_nicknames_buffer = sm.zombie_nicknames_buffer,
            enable_donate = sm.enable_donate,
            donation_systems = sm.donation_systems or {},
            donate_price_groups = groups,
            allow_vote_command = sm.allow_vote_command,
            hide_votes = sm.hide_votes,
            random_effect_in_vote = sm.random_effect_in_vote,
        },
    }
end

---@return boolean
function ChaosConfig.SaveConfigToDisk()
    local snapshot = ChaosConfig.BuildJsonSnapshot()
    local ok = ChaosFileReader.WriteJsonToCache("ChaosMod/config.json", snapshot)
    if ok then
        print("[ChaosConfig] Saved config.json")
    else
        print("[ChaosConfig] Failed to save config.json")
    end
    return ok
end

---@return boolean
function ChaosConfig.ResetToDefaults()
    local defaults = ChaosFileReader.ReadJsonFile("default_config.json")
    if not defaults then
        print("[ChaosConfig] Cannot reset: default_config.json not found")
        return false
    end
    if not ChaosFileReader.WriteJsonToCache("ChaosMod/config.json", defaults) then
        print("[ChaosConfig] Failed to write defaults to user config.json")
        return false
    end
    ChaosConfig.LoadConfigFromDisk()
    print("[ChaosConfig] Reset to defaults complete")
    return true
end
