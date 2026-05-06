---@class ChaosMod -- Global mod object main data structure
---@field mapLoaded boolean -- If map/world was loaded in this session
---@field enabled boolean -- If mod is currently enabled
---@field modId string -- Internal mod ID
---@field modData ChooseGameInfo.Mod? -- Internal mod data such as ID, version, etc.
---@field lastTimeTickMs integer -- Last time tick milliseconds
---@field wallhack boolean -- If wallhack is enabled
---@field specialAnimalsFollowers table<integer, SpecialAnimal>
ChaosMod = ChaosMod or {
    mapLoaded = false,
    enabled = false,
    modId = "ChaosMod",
    modData = nil,
    lastTimeTickMs = 0,
    wallhack = false,
    specialAnimalsFollowers = {}
}

local LoadSpawnPointFromModData
local SaveSpawnPointIfMissing

function ChaosMod.StartMod()
    -- Return early if mod is already enabled
    if ChaosMod.enabled == true then
        return
    end
    -- Return early if trying to start mod before map is loaded
    if ChaosMod.mapLoaded == false then
        print("[ChaosMod] Map not loaded")
        return
    end
    -- Update internal mod data such as ID and version from mod.info file
    ChaosUtils.updateModId()
    -- Load config.json file from disk
    ChaosConfig.LoadConfigFromDisk()
    -- Reload localization files for configured language
    ChaosLocalization.ReloadLanguages()
    ChaosUIManager.hud:OnLanguageLoaded()
    -- Load effects.json file from disk
    ChaosEffectsRegistry.Initialize()
    -- Clear position history so it starts fresh from this session
    ChaosUtils.playerPositionHistory = {}
    ChaosUtils.positionSampleMs = 0
    ChaosMod.specialAnimalsFollowers = {}
    -- Load last sleep position from global mod data
    ChaosUtils.LoadSleepData()
    -- Save spawn point when enabling the mod the first time for this save
    if SaveSpawnPointIfMissing then
        SaveSpawnPointIfMissing()
    end
    -- Set mod enabled flag to true
    ChaosMod.enabled = true;
    -- Set last time tick milliseconds to current time for next tick function call
    ChaosMod.lastTimeTickMs = getTimestampMs()
    -- Start global effects countdown timer if effects are enabled
    if ChaosConfig.IsEffectsEnabled() then
        ChaosEffectsManager.StartGlobalTimer()
    end
    print("[ChaosMod] Mod started")
    local modVersion = "0"
    -- Update internal mod version string
    if ChaosMod.modData then
        modVersion = ChaosMod.modData:getModVersion() or "0"
    end
    local newMainString = string.format("ChaosMod v%s enabled. %d effects enabled", modVersion,
        ChaosEffectsRegistry.effectsEnabledCount)
    -- Set main text for UI
    ChaosUIManager:SetMainText(newMainString)
    -- Update UI elements status based on mod enabled flag
    ChaosUIManager.hud:OnModStatusChanged(true)
    ChaosUIManager:ShowEffectsUI()
    -- Load zombie nicknames from disk first time if enabled
    if ChaosConfig.IsZombieNicknamesEnabled() then
        ChaosNicknames.LoadNicknamesFromDisk()
    end

    if ChaosConfig.streamer_mode and ChaosConfig.streamer_mode.streamer_mode_enabled == true then
        local ts = tostring(getTimestampMs())
        ChaosEffectsManager.iterationIndex = 0
        ChaosEffectsManager.syncTimestamp = ts
        ChaosEffectsManager.lastVotingActive = 0
        ChaosFileReader.WriteSyncFile(ts, 0, 0)
    end

    ChaosUIManager.hud:AddMessage("Chaos Mod started")
    ChaosUtils.PlayUISound("UIPauseMenuEnter")
end

function ChaosMod.StopMod()
    ChaosEffectsManager.StopAllEffects()
    ChaosEffectsManager.ClearGlobalTimer()
    ChaosMod.enabled = false;
    ChaosUIManager.hud:AddMessage("ChaosMod stopped")
    print("[ChaosMod] Mod stopped")
    -- Set main text for UI
    ChaosUIManager:SetMainText("ChaosMod disabled")
    -- Update UI elements status based on mod enabled flag
    ChaosUIManager.hud:OnModStatusChanged(false)
    ChaosUIManager:HideEffectsUI()
    ChaosEffectsManager.iterationIndex = 0
    ChaosEffectsManager.syncTimestamp = "0"
    ChaosEffectsManager.lastVotingActive = 0
    ChaosEffectsManager.pendingVoteReadMs = -1
    ChaosMod.specialAnimalsFollowers = {}
    ChaosFileReader.WriteSyncFile("0", 0, 0)
end

---@param key integer
function ChaosMod.OnKeyPressed(key)
    if key == 53 then
        local player = getPlayer()
        if player then
            print("Drop item in hand")
            player:dropHandItems()
        end
    elseif key == 51 then
        local player = getPlayer()
        if player then
            player:getInventory()
            print("Dress in random outfit")
            ChaosPlayer.DropAllItemsOnGround(player, false)
            player:dressInRandomOutfit()
        end
    end
end

local SPAWN_POINT_MOD_DATA_KEY = "ChaosMod_SpawnPoint"

LoadSpawnPointFromModData = function()
    local md = ModData.getOrCreate(SPAWN_POINT_MOD_DATA_KEY)
    if not (md["x"] and md["y"] and md["z"]) then
        return false
    end

    ChaosUtils.playerSpawnPoint = {
        x = md["x"] --[[@as number]],
        y = md["y"] --[[@as number]],
        z = md["z"] --[[@as number]]
    }
    print(string.format("[ChaosMod] Loaded spawn point: %.1f, %.1f, %.1f", md["x"], md["y"], md["z"]))
    return true
end

SaveSpawnPointIfMissing = function()
    if LoadSpawnPointFromModData() then
        return true
    end

    local player = getPlayer()
    if not player then
        return false
    end

    local x, y, z = player:getX(), player:getY(), player:getZ()
    ChaosUtils.playerSpawnPoint = { x = x, y = y, z = z }

    local md = ModData.getOrCreate(SPAWN_POINT_MOD_DATA_KEY)
    md["x"] = x
    md["y"] = y
    md["z"] = z
    ModData.transmit(SPAWN_POINT_MOD_DATA_KEY)
    print(string.format("[ChaosMod] Saved spawn point: %.1f, %.1f, %.1f", x, y, z))
    return true
end

-- When world loads first time per session
function ChaosMod.OnInitWorld()
    print("[ChaosMod] OnInitWorld")
    ChaosMod.mapLoaded = true;
    ChaosMod.specialAnimalsFollowers = {}
    ChaosEffectsManager.iterationIndex = 0
    ChaosEffectsManager.syncTimestamp = "0"
    ChaosEffectsManager.lastVotingActive = 0
    ChaosEffectsManager.pendingVoteReadMs = -1
    ChaosFileReader.WriteSyncFile("0", 0, 0)

    ChaosUtils.playerPreviousPositionsSampleMs = 0
    ChaosUtils.playerPreviousPositions = {}

    LoadSpawnPointFromModData()
end

---@param attacker IsoGameCharacter
---@param target IsoGameCharacter
---@param weapon HandWeapon
---@param damage number
function ChaosMod.OnWeaponHitCharacter(attacker, target, weapon, damage)

end

function ChaosMod.OnGameStart()
    print("[ChaosMod] OnGameStart")
    ChaosUIManager:Init()
    -- Updates internal mod data such as ID, version from mod.info file
    ChaosUtils.updateModId()
    -- Load config.json file from disk
    ChaosConfig.LoadConfigFromDisk()
    -- Reload localization files for configured language
    ChaosLocalization.ReloadLanguages()
    ChaosUIManager.hud:OnLanguageLoaded()
    -- Load effects.json file from disk
    ChaosEffectsRegistry.Initialize()

    -- Custom fix for fishing equip event
    -- By default it runs even if zombie equips a weapon
    -- We need to prevent this from happening
    if Fishing and Fishing.Handler and Fishing.Handler.onEquipPrimary then
        Events.OnEquipPrimary.Remove(Fishing.Handler.onEquipPrimary)
        Events.OnEquipPrimary.Add(ChaosMod.CustomFishingEquipEvent)
    end
end

---@param player IsoGameCharacter
---@param item HandWeapon
function ChaosMod.CustomFishingEquipEvent(player, item)
    if player and instanceof(player, "IsoPlayer") then
        Fishing.Handler.onEquipPrimary(player, item)
    end
end

---@param zombie IsoGameCharacter
function ChaosMod.OnZombieUpdate(zombie)
    if ChaosMod.enabled == false then
        return
    end

    ChaosNPCUtils.OnZombieUpdateForNPC(zombie)

    -- Render zombie nickname if enabled
    if ChaosConfig.IsZombieNicknamesEnabled() then
        ChaosNicknames.RenderNickname(zombie)
    end

    local md = zombie:getModData()
    if md then
        if md[CHAOS_NPC_MOD_DATA_KEY] then
            ---@type ChaosNPC
            local npc = md[CHAOS_NPC_MOD_DATA_KEY_2]

            if npc and getmetatable(npc) == ChaosNPC then
                local deltaMs = ChaosMod.lastTimeTickMs - npc.lastTimeUpdateMs
                npc:update(deltaMs)
                npc.lastTimeUpdateMs = ChaosMod.lastTimeTickMs
            else
                zombie:setHealth(0)
                ---@diagnostic disable-next-line: param-type-mismatch
                zombie:DoDeath(nil, nil)
                md[CHAOS_NPC_MOD_DATA_KEY] = nil
                md[CHAOS_NPC_MOD_DATA_KEY_2] = nil
            end
        end
    end
end

function ChaosMod.OnTick()
    -- Get current timestamp in milliseconds
    local msNow = getTimestampMs()
    -- Calculate delta time in milliseconds since last tick
    local deltaMs = msNow - ChaosMod.lastTimeTickMs
    ChaosMod.lastTimeTickMs = msNow
    -- Tick all active effects
    ChaosEffectsManager.OnTick(deltaMs)
    -- Tick zombie nicknames if enabled
    if ChaosMod.enabled and ChaosConfig.IsZombieNicknamesEnabled() then
        ChaosNicknames.OnTick(deltaMs)
    end

    if ChaosMod.enabled then
        ChaosUtils.AdjustVisibleZombiesForNPCs()
        ChaosUtils.TrackPlayerPosition(deltaMs)
        ChaosUtils.TrackPlayerPreviousPositions(deltaMs)
        ChaosUtils.sleepHandleTick()
        ChaosNPCUtils.OnTick(deltaMs)
    end
end

function ChaosMod.OnSpecialAnimalsTick()
    if ChaosMod.enabled == false then
        return
    end

    for i = #ChaosMod.specialAnimalsFollowers, 1, -1 do
        local specialAnimal = ChaosMod.specialAnimalsFollowers[i]
        if not specialAnimal or specialAnimal:isDead() then
            table.remove(ChaosMod.specialAnimalsFollowers, i)
        else
            specialAnimal:tick()
        end
    end
end

---@param zombie IsoZombie
function ChaosMod.OnZombieDead(zombie)
    ChaosZombie.OnZombieDead(zombie)
end

---@param character IsoGameCharacter
function ChaosMod.OnEnterVehicle(character)
    if not character then return end
    if not instanceof(character, "IsoPlayer") then return end
    local vehicle = character:getVehicle()
    if not vehicle then return end
    ChaosUtils.lastUsedVehicle = vehicle
end

Events.OnKeyPressed.Add(ChaosMod.OnKeyPressed)
Events.OnInitWorld.Add(ChaosMod.OnInitWorld)
Events.OnWeaponHitCharacter.Add(ChaosMod.OnWeaponHitCharacter)
Events.OnGameStart.Add(ChaosMod.OnGameStart)
Events.OnZombieUpdate.Add(ChaosMod.OnZombieUpdate)
Events.OnTick.Add(ChaosMod.OnTick)
Events.OnTick.Add(ChaosMod.OnSpecialAnimalsTick)
Events.OnZombieDead.Add(ChaosMod.OnZombieDead)
Events.OnEnterVehicle.Add(ChaosMod.OnEnterVehicle)

return ChaosMod
