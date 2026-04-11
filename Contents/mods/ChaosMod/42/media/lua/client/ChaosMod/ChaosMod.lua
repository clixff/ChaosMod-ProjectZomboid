---@class ChaosMod -- Global mod object main data structure
---@field mapLoaded boolean -- If map/world was loaded in this session
---@field enabled boolean -- If mod is currently enabled
---@field modId string -- Internal mod ID
---@field modData ChooseGameInfo.Mod? -- Internal mod data such as ID, version, etc.
---@field lastTimeTickMs integer -- Last time tick milliseconds
---@field wallhack boolean -- If wallhack is enabled
ChaosMod = ChaosMod or {
    mapLoaded = false,
    enabled = false,
    modId = "ChaosMod",
    modData = nil,
    lastTimeTickMs = 0,
    wallhack = false
}

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
    -- Load effects.json file from disk
    ChaosEffectsRegistry.Initialize()
    -- Clear position history so it starts fresh from this session
    ChaosUtils.playerPositionHistory = {}
    ChaosUtils.positionSampleMs = 0
    -- Load last sleep position from global mod data
    ChaosUtils.LoadSleepData()
    -- Set mod enabled flag to true
    ChaosMod.enabled = true;
    -- Set last time tick milliseconds to current time for next tick function call
    ChaosMod.lastTimeTickMs = getTimestampMs()
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
    -- Load zombie nicknames from disk first time if enabled
    if ChaosConfig.IsZombieNicknamesEnabled() then
        ChaosNicknames.LoadNicknamesFromDisk()
    end

    ChaosUtils.PlayUISound("UIPauseMenuEnter")
end

function ChaosMod.StopMod()
    ChaosEffectsManager.StopAllEffects()
    -- Set mod enabled flag to false
    ChaosMod.enabled = false;
    print("[ChaosMod] Mod stopped")
    -- Set main text for UI
    ChaosUIManager:SetMainText("ChaosMod disabled")
    -- Update UI elements status based on mod enabled flag
    ChaosUIManager.hud:OnModStatusChanged(false)
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

-- When world loads first time per session
function ChaosMod.OnInitWorld()
    print("[ChaosMod] OnInitWorld")
    ChaosMod.mapLoaded = true;
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
            if npc then
                local deltaMs = ChaosMod.lastTimeTickMs - npc.lastTimeUpdateMs
                npc:update(deltaMs)
                npc.lastTimeUpdateMs = ChaosMod.lastTimeTickMs
            else
                zombie:setHealth(0)
                ---@diagnostic disable-next-line: param-type-mismatch
                zombie:DoDeath(nil, nil)
                md[CHAOS_NPC_MOD_DATA_KEY] = nil
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
        ChaosUtils.sleepHandleTick()
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
Events.OnZombieDead.Add(ChaosMod.OnZombieDead)
Events.OnEnterVehicle.Add(ChaosMod.OnEnterVehicle)

return ChaosMod
