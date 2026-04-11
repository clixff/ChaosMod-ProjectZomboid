---@class ChaosConfigStreamerMode
---@field streamer_mode_enabled boolean -- if streamer mode is enabled
---@field voting_enabled boolean -- If voting is enabled
---@field type string -- Streamer mode type (twitch or ...)
---@field voting_duration number
---@field use_localhost_ip boolean
---@field advanced_voting_numbers boolean
---@field say_killed_zombie_name boolean
---@field zombie_nicknames_buffer number
---@field use_zombie_nicknames boolean

---@class ChaosConfig
---@field effects_enabled boolean -- Disabling this will not start any effect, but streamer mode will work
---@field effects_interval number
---@field ui_sounds_enabled boolean
---@field streamer_mode ChaosConfigStreamerMode
ChaosConfig = ChaosConfig or {
    effects_enabled = true,
    effects_interval = 45,
    ui_sounds_enabled = true,
    streamer_mode = {
        streamer_mode_enabled = false,
        voting_enabled = false,
        type = "twitch",
        voting_duration = 25,
        use_localhost_ip = true,
        advanced_voting_numbers = false,
        say_killed_zombie_name = true,
        zombie_nicknames_buffer = 150,
        use_zombie_nicknames = true,
    }
}

function ChaosConfig.LoadConfigFromDisk()
    ---@type ChaosConfig | nil
    local configData = ChaosFileReader.ReadJsonFile("config.json")
    if not configData then
        print("[ChaosConfig] Failed to load config from disk")
        return
    end

    if type(configData.effects_enabled) == "boolean" then
        ChaosConfig.effects_enabled = configData.effects_enabled
    end

    if type(configData.effects_interval) == "number" then
        ChaosConfig.effects_interval = configData.effects_interval
    end

    if type(configData.ui_sounds_enabled) == "boolean" then
        ChaosConfig.ui_sounds_enabled = configData.ui_sounds_enabled
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

        -- Voting duration in seconds
        if type(configData.streamer_mode.voting_duration) == "number" then
            ChaosConfig.streamer_mode.voting_duration = configData.streamer_mode.voting_duration
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
    end

    print("[ChaosMod] Config effects_enabled: " .. tostring(ChaosConfig.effects_enabled))
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

    if ChaosConfig.effects_enabled == false then
        return false
    end

    if ChaosConfig.streamer_mode.streamer_mode_enabled == false then
        return false
    end

    return ChaosConfig.streamer_mode.voting_enabled == true
end

---@return boolean
function ChaosConfig.IsEffectsEnabled()
    return ChaosConfig.effects_enabled == true
end

---@return boolean
function ChaosConfig.IsUISoundsEnabled()
    return ChaosConfig.ui_sounds_enabled == true
end
