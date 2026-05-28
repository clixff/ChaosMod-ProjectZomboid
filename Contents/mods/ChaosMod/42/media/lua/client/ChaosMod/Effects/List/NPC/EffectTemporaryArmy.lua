---@class EffectTemporaryArmy : ChaosEffectBase
---@field npcs ChaosNPC[]
---@field brainTimer ChaosManualTimer
EffectTemporaryArmy = ChaosEffectBase:derive("EffectTemporaryArmy", "temporary_army")

local ARMY_COUNT = 30
local BRAIN_THROTTLE_MS = 500

---@param enemy IsoGameCharacter?
---@return boolean
local function isValidEnemy(enemy)
    if not enemy then return false end
    if enemy:isDead() then return false end
    return true
end

function EffectTemporaryArmy:OnStart()
    ChaosEffectBase:OnStart()

    self.npcs = {}
    self.brainTimer = ChaosManualTimer.new(BRAIN_THROTTLE_MS)

    local player = getPlayer()
    if not player then return end

    for _ = 1, ARMY_COUNT do
        local square = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, 3, 8, 50, true, true, false)
        if square then
            local newZombies = ChaosZombie.SpawnZombieAt(
                square:getX(), square:getY(), square:getZ(), 1, "Naked", 50)
            local zombie = newZombies and newZombies:getFirst() or nil
            if zombie then
                local npc = ChaosNPC:new(zombie)
                -- zombie:dressInRandomOutfit()
                npc:initializeHuman()
                npc.canBePanicked = false
                npc.canGiftItems = false
                npc.npcGroup = ChaosNPCGroupID.COMPANIONS
                npc:AddTag("no_betray")

                ChaosZombie.AddZombieClothesBatch(zombie, {
                    { type = "Base.Shoes_ArmyBootsDesert" },
                    { type = "Base.Vest_DefaultTEXTURE" },
                    { type = "Base.Trousers_CamoGreen" },
                })
                table.insert(self.npcs, npc)
            end
        end
    end
end

---@param deltaMs integer
function EffectTemporaryArmy:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)

    local player = getPlayer()
    if not player then return end

    local px = player:getX()
    local py = player:getY()
    local pz = player:getZ()

    renderLine(px, py, pz + 0.5, px, py + 3, pz + 0.2, 1.0, 0.0, 0.0, 1.0)

    if not self.npcs then return end

    self.brainTimer:add(deltaMs)
    if not self.brainTimer:isEnded() then return end
    self.brainTimer:reset()

    -- Shared brain: an idle army member borrows a target from a fighting member.
    for _, npc in ipairs(self.npcs) do
        if npc and npc.zombie and npc.zombie:isAlive() and not isValidEnemy(npc.enemy) then
            for _, other in ipairs(self.npcs) do
                if other ~= npc and other.zombie and other.zombie:isAlive() and isValidEnemy(other.enemy) and other.enemy ~= nil then
                    npc:SetAsTargetEnemy(other.enemy)
                    break
                end
            end
        end
    end
end

function EffectTemporaryArmy:OnEnd()
    ChaosEffectBase:OnEnd()

    if self.npcs then
        for _, npc in ipairs(self.npcs) do
            if npc and npc.zombie then
                npc:Destroy(true)
            end
        end
        self.npcs = nil
    end
end
