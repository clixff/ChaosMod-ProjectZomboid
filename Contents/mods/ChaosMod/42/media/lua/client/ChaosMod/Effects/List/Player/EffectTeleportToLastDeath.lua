---@class EffectTeleportToLastDeathZombieData
---@field wasUseless boolean

---@class EffectTeleportToLastDeath : ChaosEffectBase
EffectTeleportToLastDeath = ChaosEffectBase:derive("EffectTeleportToLastDeath", "teleport_to_last_death")

local RADIUS = 30
local MAX_DURATION = 8000
local DISABLE_AI_EFFECT_ID = "teleport_to_last_death"

---@param deltaMs integer
---@param data { elapsedMs: integer, affectedZombies: table<IsoZombie, EffectTeleportToLastDeathZombieData>, affectedNPCs: table<IsoZombie, boolean> }
local function TeleportToLastDeathTick(deltaMs, data)
    local bar = UIManager.getProgressBar(0)
    data.elapsedMs = data.elapsedMs + deltaMs
    local progress = data.elapsedMs / MAX_DURATION
    bar:setValue(progress)

    local player = getPlayer()
    if not player then return end

    local px = player:getX()
    local py = player:getY()

    ChaosZombie.ForEachZombieInRange(px, py, RADIUS, function(zombie)
        if not zombie or zombie:isDead() then return end

        if ChaosNPCUtils.IsNPC(zombie) then
            if data.affectedNPCs[zombie] == nil then
                local npc = ChaosNPCUtils.GetNPCFromZombie(zombie)
                if npc then
                    npc:AddDisableAiEffect(DISABLE_AI_EFFECT_ID)
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

---@param data { affectedZombies: table<IsoZombie, EffectTeleportToLastDeathZombieData>, affectedNPCs: table<IsoZombie, boolean> }
local function TeleportToLastDeathEnd(data)
    for zombie, zdata in pairs(data.affectedZombies) do
        if zombie and zombie:isAlive() then
            zombie:setUseless(zdata.wasUseless)
        end
    end

    for zombie in pairs(data.affectedNPCs) do
        if zombie and zombie:isAlive() then
            local npc = ChaosNPCUtils.GetNPCFromZombie(zombie)
            if npc then
                npc:RemoveDisableAiEffect(DISABLE_AI_EFFECT_ID)
            end
        end
    end
end

function EffectTeleportToLastDeath:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    local x, y, z = ChaosUtils.GetLatestDeathPosition()
    if not (x and y and z) then
        ChaosPlayer.SayLineByColor(player,
            ChaosLocalization.GetString("misc", "failed_to_find_last_death"),
            ChaosPlayerChatColors.red)
        return
    end

    ChaosVehicle.ExitVehicle(player)
    player:teleportTo(math.floor(x --[[@as number]]), math.floor(y --[[@as number]]), math.floor(z --[[@as number]]))

    ChaosSpecialAction.AddNewAction(
        { elapsedMs = 0, affectedZombies = {}, affectedNPCs = {} },
        MAX_DURATION,
        TeleportToLastDeathTick,
        TeleportToLastDeathEnd,
        TeleportToLastDeathEnd
    )
end

function EffectTeleportToLastDeath:OnEnd()
    ChaosEffectBase:OnEnd()
end
