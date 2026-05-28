---@class EffectFakeTeleport : ChaosEffectBase
---@field originalX number
---@field originalY number
---@field originalZ number
EffectFakeTeleport = ChaosEffectBase:derive("EffectFakeTeleport", "fake_teleport")

local TELEPORT_TIME_BACK_MS = 15000
local DISABLE_NPC_AI_ID = "fake_teleport"

---@class EffectTeleportZombieData
---@field wasUseless boolean

---@param deltaMs integer
---@param data { elapsedMs: integer, affectedZombies: table<IsoZombie, EffectTeleportToLastDeathZombieData>, affectedNPCs: table<IsoZombie, boolean> }
local function TeleportTick(deltaMs, data)
    local player = getPlayer()
    if not player then return end

    local px = player:getX()
    local py = player:getY()

    ChaosZombie.ForEachZombieInRange(px, py, 2, function(zombie)
        if not zombie or zombie:isDead() then return end

        if ChaosNPCUtils.IsNPC(zombie) then
            if data.affectedNPCs[zombie] == nil then
                local npc = ChaosNPCUtils.GetNPCFromZombie(zombie)
                if npc then
                    npc:AddDisableAiEffect(DISABLE_NPC_AI_ID)
                    data.affectedNPCs[zombie] = true
                end
            end
        else
            if data.affectedZombies[zombie] == nil then
                data.affectedZombies[zombie] = { wasUseless = zombie:isUseless() }
            end
            zombie:setUseless(true)
        end
    end, false, nil)
end

---@param data { affectedZombies: table<IsoZombie, EffectTeleportToLastDeathZombieData>, affectedNPCs: table<IsoZombie, boolean>, originalXYZ: { x: number, y: number, z: number } }
local function TeleportBack(data)
    local player = getPlayer()
    if not player then return end

    for zombie, zdata in pairs(data.affectedZombies) do
        if zombie and zombie:isAlive() then
            zombie:setUseless(zdata.wasUseless)
        end
    end

    for zombie in pairs(data.affectedNPCs) do
        if zombie and zombie:isAlive() then
            local npc = ChaosNPCUtils.GetNPCFromZombie(zombie)
            if npc then
                npc:RemoveDisableAiEffect(DISABLE_NPC_AI_ID)
            end
        end
    end

    player:teleportTo(data.originalXYZ.x, data.originalXYZ.y, math.floor(data.originalXYZ.z))

    local stringFallback = "Fake Teleport"

    local str = ChaosLocalization.GetString("effects", "fake_teleport")

    ChaosPlayer.SayLineByColor(player, str, ChaosPlayerChatColors.green)
end


function EffectFakeTeleport:OnStart()
    ChaosEffectBase:OnStart()

    self.fakeEffectNameId = "teleport_to_last_used_bed"

    local player = getPlayer()
    if not player then return end

    local loc = ChaosUtils.sleepWorldLocation or ChaosUtils.playerSpawnPoint
    if not loc then
        player:Say(ChaosLocalization.GetString("misc", "no_sleep_location"))
        return
    end

    self.originalX = player:getX()
    self.originalY = player:getY()
    self.originalZ = player:getZ()

    ChaosVehicle.ExitVehicle(player)

    local x = math.floor(loc.x)
    local y = math.floor(loc.y)
    local z = math.floor(loc.z)

    player:teleportTo(x, y, z)

    print(string.format("[EffectTeleportToLastUsedBed] Teleported to %.1f, %.1f, %.1f", loc.x, loc.y, loc.z))

    ChaosSpecialAction.AddNewAction(
        { elapsedMs = 0, affectedZombies = {}, affectedNPCs = {}, originalXYZ = { x = self.originalX, y = self.originalY, z = self.originalZ } },
        TELEPORT_TIME_BACK_MS,
        TeleportTick,
        TeleportBack,
        TeleportBack
    )
end

function EffectFakeTeleport:OnEnd()
    ChaosEffectBase:OnEnd()
end
