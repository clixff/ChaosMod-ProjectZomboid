---@class EffectHireMercenaries : ChaosEffectBase
---@field npcs ChaosNPC[]
EffectHireMercenaries = ChaosEffectBase:derive("EffectHireMercenaries", "hire_mercenaries")

local MERCENARY_COUNT = 3
local MERCENARY_HEALTH = 10.0
local HELI_SOUND_DURATION_MS = 9000

local function noop() end

---@param data { heliEmitter: FMODSoundEmitter, heliSound: integer }
local function HeliSoundEnd(data)
    if data.heliEmitter and data.heliSound then
        data.heliEmitter:stopSound(data.heliSound)
    end
    data.heliEmitter = nil
    data.heliSound = nil
end

function EffectHireMercenaries:OnStart()
    ChaosEffectBase:OnStart()

    self.npcs = {}

    local player = getPlayer()
    if not player then return end

    local playerSquare = player:getSquare()

    local world = getWorld()
    if world and playerSquare then
        local heliEmitter = world:getFreeEmitter(playerSquare:getX(), playerSquare:getY(), playerSquare:getZ())
        if heliEmitter then
            local heliSound = heliEmitter:playSound("Helicopter")
            ChaosSpecialAction.AddNewAction(
                { heliEmitter = heliEmitter, heliSound = heliSound },
                HELI_SOUND_DURATION_MS,
                noop,
                HeliSoundEnd,
                HeliSoundEnd
            )
        end
    end

    for _ = 1, MERCENARY_COUNT do
        local square = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, 2, 5, 50, true, true, false)
        if square then
            local newZombies = ChaosZombie.SpawnZombieAt(
                square:getX(),
                square:getY(),
                square:getZ(),
                1,
                "PrivateMilitia",
                0
            )

            local zombie = newZombies and newZombies:getFirst() or nil
            if zombie then
                local npc = ChaosNPC:new(zombie, self.effectNickname)
                npc:initializeHuman()
                npc.npcGroup = ChaosNPCGroupID.COMPANIONS
                npc.maxHealth = MERCENARY_HEALTH
                zombie:setHealth(MERCENARY_HEALTH)
                npc.canGiftItems = false
                npc.canBePanicked = false
                npc.chanceToDropWeaponOnDeath = 0.0
                npc.firearmAccuracyZombies = 100.0
                npc.DamageMultiplier = 5.0
                npc.enemyDistanceFindRadius = 20.0
                npc:AddTag("no_betray")

                npc:SetWeapon("Base.AssaultRifle")

                table.insert(self.npcs, npc)
            end
        end
    end
end

---@param deltaMs integer
function EffectHireMercenaries:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)

    if not self.npcs then return end

    for _, npc in ipairs(self.npcs) do
        if npc and npc.zombie and npc.zombie:isAlive() then
            npc.zombie:setHealth(npc.maxHealth)
        end
    end
end

function EffectHireMercenaries:OnEnd()
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
