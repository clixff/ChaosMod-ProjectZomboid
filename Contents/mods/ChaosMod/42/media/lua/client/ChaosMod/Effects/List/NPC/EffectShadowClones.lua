---@class EffectShadowClones : ChaosEffectBase
---@field npcs ChaosNPC[]
EffectShadowClones = ChaosEffectBase:derive("EffectShadowClones", "shadow_clones")

local CLONE_COUNT = 3
local CLONE_ALPHA = 0.5
local DAMAGE_MULTIPLIER = 1.25

function EffectShadowClones:OnStart()
    ChaosEffectBase:OnStart()

    self.npcs = {}

    local player = getPlayer()
    if not player then return end

    local femaleChance = player:isFemale() and 100 or 0

    for _ = 1, CLONE_COUNT do
        local randomSquare = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, 2, 3, 50, true, true, false)
        if randomSquare then
            local newZombies = ChaosZombie.SpawnZombieAt(
                randomSquare:getX(),
                randomSquare:getY(),
                randomSquare:getZ(),
                1,
                "Tourist",
                femaleChance
            )

            local zombie = newZombies and newZombies:getFirst() or nil
            if zombie then
                local npc = ChaosNPC:new(zombie, self.effectNickname)
                npc:initializeHuman()
                ChaosZombie.CopyCharacterVisualsAndClothes(player, zombie)
                npc.npcGroup = ChaosNPCGroupID.COMPANIONS
                npc.DamageMultiplier = DAMAGE_MULTIPLIER
                npc.canBePanicked = false

                npc.maxHealth = 5.0
                zombie:setHealth(npc.maxHealth)

                npc:AddTag("shadow_clone")

                table.insert(self.npcs, npc)
            end
        end
    end
end

---@param deltaMs integer
function EffectShadowClones:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)

    if not self.npcs then return end

    for _, npc in ipairs(self.npcs) do
        if npc and npc.zombie then
            npc.zombie:setAlphaAndTarget(CLONE_ALPHA)
        end
    end
end

function EffectShadowClones:OnEnd()
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
