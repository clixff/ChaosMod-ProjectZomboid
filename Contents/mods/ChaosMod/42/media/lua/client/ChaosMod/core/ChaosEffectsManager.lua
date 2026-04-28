---@class ChaosEffectsManager
---@field activeEffects table<integer, ChaosEffectBase>
---@field globalTimerMs number -- current elapsed ms, counts 0 → globalTimerMaxMs
---@field globalTimerMaxMs number -- effects_interval in ms
---@field iterationIndex integer -- increments each time globalTimer fires
---@field lastVotingActive integer -- last written voting active value (0 or 1)
---@field votingSyncCheckMs number -- accumulator for 1-second voting poll
---@field syncTimestamp string -- line1 value of last written sync file
---@field pendingVoteReadMs number -- countdown ms until effect_votes.txt is read; -1 = inactive
---@field externalEffectsCheckMs number -- accumulator for donate effects poll (every 3 s)
ChaosEffectsManager = ChaosEffectsManager or {
    activeEffects = {},
    globalTimerMs = 0,
    globalTimerMaxMs = 0,
    iterationIndex = 0,
    lastVotingActive = 0,
    votingSyncCheckMs = 0,
    syncTimestamp = "0",
    pendingVoteReadMs = -1,
    externalEffectsCheckMs = 0,
}

function ChaosEffectsManager.StartGlobalTimer()
    ChaosEffectsManager.globalTimerMaxMs = math.floor(ChaosConfig.effects_interval * 1000)
    ChaosEffectsManager.globalTimerMs = 0
    ChaosEffectsManager.votingSyncCheckMs = 0
end

function ChaosEffectsManager.ClearGlobalTimer()
    ChaosEffectsManager.globalTimerMs = 0
    ChaosEffectsManager.globalTimerMaxMs = 0
end

---@return integer
function ChaosEffectsManager.ComputeVotingActive()
    local sm = ChaosConfig.streamer_mode
    if not sm or sm.streamer_mode_enabled ~= true or sm.voting_enabled ~= true then
        return 0
    end
    local voteStartMs = (ChaosConfig.vote_start_time or 0) * 1000
    return ChaosEffectsManager.globalTimerMs >= voteStartMs and 1 or 0
end

function ChaosEffectsManager.OnGlobalEffectsTimerEnd()
    if not ChaosConfig.IsEffectsEnabled() then return end
    local sm = ChaosConfig.streamer_mode
    if not sm or sm.streamer_mode_enabled == false or sm.voting_enabled == false then
        local effectIds = ChaosEffectsRegistry.GetRandomEffects(1, "default")
        if effectIds and effectIds[1] then
            ChaosEffectsManager.StartEffect(effectIds[1])
        end
    end
    if sm and sm.streamer_mode_enabled == true then
        ChaosEffectsManager.iterationIndex = ChaosEffectsManager.iterationIndex + 1
        local ts = tostring(getTimestampMs())
        ChaosEffectsManager.syncTimestamp = ts
        ChaosEffectsManager.lastVotingActive = 0
        ChaosFileReader.WriteSyncFile(ts, ChaosEffectsManager.iterationIndex, 0)
        if sm.voting_enabled == true then
            ChaosEffectsManager.pendingVoteReadMs = 250
        end
    end
end

function ChaosEffectsManager.HandleVoteRead()
    local reader = getFileReader("ChaosMod/effect_votes.txt", false)
    if not reader then
        ChaosEffectsManager.pendingVoteReadMs = 250
        return
    end
    local effectId = reader:readLine()
    print("[ChaosEffectsManager] Effect ID from vote: " .. tostring(effectId))
    reader:close()
    local writer = getFileWriter("ChaosMod/effect_votes.txt", true, false)
    if writer then
        writer:write("")
        writer:close()
    end
    if effectId and effectId ~= "" then
        ChaosEffectsManager.StartEffect(effectId)
    else
        ChaosEffectsManager.pendingVoteReadMs = 250
    end
end

function ChaosEffectsManager.HandleExternalEffectsRead()
    local reader = getFileReader("ChaosMod/effects_external.txt", false)
    if not reader then return end

    ---@type table<integer, {effectId: string, nickname: string}>
    local entries = {}
    while true do
        local line = reader:readLine()
        if line == nil then break end
        if line ~= "" then
            local slashPos = string.find(line, "/", 1, true)
            if slashPos then
                local nickname = string.sub(line, 1, slashPos - 1)
                local effectId = string.sub(line, slashPos + 1)
                if effectId ~= "" then
                    if nickname == "" then nickname = "Anonymous" end
                    table.insert(entries, { effectId = effectId, nickname = nickname })
                end
            end
        end
    end
    reader:close()

    local writer = getFileWriter("ChaosMod/effects_external.txt", true, false)
    if writer then
        writer:write("")
        writer:close()
    end

    for _, entry in ipairs(entries) do
        ChaosEffectsManager.StartEffect(entry.effectId)
        ChaosUIManager.onDonateEffectActivated(entry.nickname, entry.effectId)
    end
end

---@param effectId string
---@return ChaosEffectBase | nil
function ChaosEffectsManager.StartEffect(effectId)
    if not effectId or effectId == "" then
        print("[ChaosEffectsManager] Effect ID is required")
        return
    end

    local effectData = ChaosEffectsRegistry.effects[effectId]
    if not effectData then
        print("[ChaosEffectsManager] Effect not found")
        return
    end

    if not effectData.class then
        print("[ChaosEffectsManager] Effect class not found")
        return
    end

    if effectData.disableEffects and #effectData.disableEffects > 0 then
        ChaosEffectsManager.DisableSpecificEffects(effectData.disableEffects)
    end

    local effectClass = effectData.class
    local newEffect = effectClass:new(effectId, effectData.name, effectData.duration, effectData.withDuration)
    if not newEffect then return end

    newEffect:OnStart()
    ChaosUtils.PlayUISound("UIPauseMenuEnter")

    local msNow = getTimestampMs()

    newEffect.activationTimeMs = msNow
    newEffect.ticksActiveTime = 0
    newEffect.maxTicks = math.floor(newEffect.duration * 1000)

    if newEffect.withDuration == false then
        newEffect.maxTicks = 15 * 1000
    end

    table.insert(ChaosEffectsManager.activeEffects, newEffect)
    return newEffect
end

---@param deltaMs integer
function ChaosEffectsManager.OnTick(deltaMs)
    if ChaosMod.enabled and ChaosConfig.IsEffectsEnabled() then
        ChaosEffectsManager.globalTimerMs = ChaosEffectsManager.globalTimerMs + deltaMs
        if ChaosEffectsManager.globalTimerMs >= ChaosEffectsManager.globalTimerMaxMs then
            ChaosEffectsManager.OnGlobalEffectsTimerEnd()
            ChaosEffectsManager.globalTimerMs = 0
        end
    end

    if ChaosMod.enabled then
        ChaosEffectsManager.votingSyncCheckMs = ChaosEffectsManager.votingSyncCheckMs + deltaMs
        if ChaosEffectsManager.votingSyncCheckMs >= 1000 then
            ChaosEffectsManager.votingSyncCheckMs = 0
            local votingActive = ChaosEffectsManager.ComputeVotingActive()
            if votingActive ~= ChaosEffectsManager.lastVotingActive then
                ChaosEffectsManager.lastVotingActive = votingActive
                ChaosFileReader.WriteSyncFile(ChaosEffectsManager.syncTimestamp, ChaosEffectsManager.iterationIndex,
                    votingActive)
            end
        end

        if ChaosEffectsManager.pendingVoteReadMs >= 0 then
            ChaosEffectsManager.pendingVoteReadMs = ChaosEffectsManager.pendingVoteReadMs - deltaMs
            if ChaosEffectsManager.pendingVoteReadMs <= 0 then
                ChaosEffectsManager.pendingVoteReadMs = -1
                ChaosEffectsManager.HandleVoteRead()
            end
        end

        local sm = ChaosConfig.streamer_mode
        if sm and sm.streamer_mode_enabled == true and sm.enable_donate == true then
            ChaosEffectsManager.externalEffectsCheckMs = ChaosEffectsManager.externalEffectsCheckMs + deltaMs
            if ChaosEffectsManager.externalEffectsCheckMs >= 3000 then
                ChaosEffectsManager.externalEffectsCheckMs = 0
                ChaosEffectsManager.HandleExternalEffectsRead()
            end
        end
    end

    -- Backward loop to avoid issues with removing items from the table while iterating
    for i = #ChaosEffectsManager.activeEffects, 1, -1 do
        local shouldRemove = false
        local effect = ChaosEffectsManager.activeEffects[i]
        if not effect then
            shouldRemove = true
        else
            if effect.withDuration then
                effect:OnTick(deltaMs)
            end

            effect.ticksActiveTime = effect.ticksActiveTime + deltaMs
            if effect.ticksActiveTime >= effect.maxTicks then
                effect:OnEnd()
                shouldRemove = true
            end
        end

        if shouldRemove then
            table.remove(ChaosEffectsManager.activeEffects, i)
        end
    end
end

---@param effectIds table<integer, string>
function ChaosEffectsManager.DisableSpecificEffects(effectIds)
    if not effectIds or #effectIds == 0 then
        return
    end

    ---@type table<string, boolean>
    local effectIdsToDisableMap = {}

    for _, effectId in ipairs(effectIds) do
        effectIdsToDisableMap[effectId] = true
    end

    -- Backward loop in activeEffects table to avoid issues
    for i = #ChaosEffectsManager.activeEffects, 1, -1 do
        local effect = ChaosEffectsManager.activeEffects[i]
        if effect then
            local activeEffectId = effect.effectId
            -- If effectID is found in map of effects to disable
            if effectIdsToDisableMap[activeEffectId] then
                -- Call method that will clean up the effect
                effect:OnEnd()
                -- Remove effect from activeEffects table
                table.remove(ChaosEffectsManager.activeEffects, i)
            end
        end
    end
end

function ChaosEffectsManager.StopAllEffects()
    for i = #ChaosEffectsManager.activeEffects, 1, -1 do
        local effect = ChaosEffectsManager.activeEffects[i]
        if effect then
            effect:OnEnd()
            table.remove(ChaosEffectsManager.activeEffects, i)
        end
    end
end
