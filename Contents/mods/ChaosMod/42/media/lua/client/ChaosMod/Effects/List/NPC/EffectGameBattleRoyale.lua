---@class EffectGameBattleRoyale : ChaosEffectBase
---@field npcs ChaosNPC[]
---@field npcDead boolean[]
---@field npcRetargetMs integer[]
---@field totalNpcs integer
---@field aliveNpcs integer
---@field centerX integer
---@field centerY integer
---@field centerZ integer
---@field centerSquare? IsoGridSquare
---@field zoneRadius number
---@field elapsedMs integer
---@field damagePhase boolean
---@field marker? WorldMarkers.GridSquareMarker
---@field homingPoint? WorldMarkers.PlayerHomingPoint
EffectGameBattleRoyale = ChaosEffectBase:derive("EffectGameBattleRoyale", "game_battle_royale")

local NPC_COUNT = 45
local NPC_DAMAGE_MULTIPLIER = 0.4
local NPC_SPAWN_MIN_RADIUS = 40
local NPC_SPAWN_MAX_RADIUS = 80
local NPC_MOVE_TO_CENTER_DIST = 4.0
-- How often each NPC re-picks the nearest enemy, even when it already has a valid one.
local NPC_RETARGET_INTERVAL_MS = 1000

local ZONE_MIN_PLAYER_RADIUS = 60
local ZONE_MAX_PLAYER_RADIUS = 90
local ZONE_INITIAL_RADIUS = 60
local ZONE_MIN_RADIUS = 5

local SAFE_PERIOD_MS = 15 * 1000
local DEFAULT_DURATION_MS = 120 * 1000

-- Player damage uses the same metric as "Toxic Rain"
local PLAYER_DAMAGE_PER_SECOND = 0.5
-- Zombie (battle royale NPC) damage ratio, applied as health loss per minute
local NPC_DAMAGE_PER_MINUTE = 2.0

local MARKER_BLUE = { r = 0.2, g = 0.4, b = 1.0 }
local MARKER_RED = { r = 1.0, g = 0.2, b = 0.2 }
local DEATH_LINE_COLOR = { r = 1.0, g = 0.84, b = 0.0 }

-- The BATTLEROYALE relation group is created once and reused across activations.
local battleRoyaleGroupId = nil

---@return integer
local function EnsureBattleRoyaleGroup()
    if battleRoyaleGroupId then return battleRoyaleGroupId end

    -- Default ATTACK relation makes them hostile to every other group.
    local id = ChaosNPCRelations.CreateGroup("BATTLEROYALE", ChaosNPCRelationType.ATTACK, true)
    -- Companions hunt the battle royale NPCs as well.
    ChaosNPCRelations.SetRelation(ChaosNPCGroupID.COMPANIONS, id, ChaosNPCRelationType.ATTACK)

    battleRoyaleGroupId = id
    return id
end

function EffectGameBattleRoyale:OnStart()
    ChaosEffectBase:OnStart()

    self.npcs = {}
    self.npcDead = {}
    self.npcRetargetMs = {}
    self.totalNpcs = 0
    self.aliveNpcs = 0
    self.elapsedMs = 0
    self.zoneRadius = ZONE_INITIAL_RADIUS
    self.damagePhase = false

    local player = getPlayer()
    if not player then return end

    -- Pick the zone center: a free walkable square in 60-90 tiles around the player.
    local centerSquare = ChaosPlayer.GetRandomSquareAroundPlayer(
        player, nil, ZONE_MIN_PLAYER_RADIUS, ZONE_MAX_PLAYER_RADIUS, 50, true, false, false)
    if not centerSquare then return end

    self.centerSquare = centerSquare
    self.centerX = centerSquare:getX()
    self.centerY = centerSquare:getY()
    self.centerZ = centerSquare:getZ()

    local markers = getWorldMarkers()
    if markers then
        self.marker = markers:addGridSquareMarker(
            centerSquare, MARKER_BLUE.r, MARKER_BLUE.g, MARKER_BLUE.b, true, 1.0)
        if self.marker then
            self.marker:setScaleCircleTexture(false)
            self.marker:setSize(self.zoneRadius * math.sqrt(2.0))
        end

        self.homingPoint = markers:addPlayerHomingPoint(player, self.centerX, self.centerY)
    end

    local groupId = EnsureBattleRoyaleGroup()

    ---@type ChaosNPC[]
    local spawnedNpcs = {}

    for _ = 1, NPC_COUNT do
        -- Prefer outdoor spawns; only fall back to interiors if no outdoor square is found.
        local square = ChaosPlayer.GetRandomSquareAroundPlayer(
            player, nil, NPC_SPAWN_MIN_RADIUS, NPC_SPAWN_MAX_RADIUS, 50, true, false, false)
        if not square then
            square = ChaosPlayer.GetRandomSquareAroundPlayer(
                player, nil, NPC_SPAWN_MIN_RADIUS, NPC_SPAWN_MAX_RADIUS, 50, true, true, false)
        end
        if square then
            local newZombies = ChaosZombie.SpawnZombieAt(
                square:getX(), square:getY(), square:getZ(), 1, "Tourist", 50)
            local zombie = newZombies:getFirst()
            if zombie then
                local npc = ChaosNPC:new(zombie)
                zombie:dressInRandomOutfit()
                npc.healthGroup = CHAOS_NPC_HEALTH_GROUP.WEAK
                npc:initializeHuman()
                npc.npcGroup = groupId
                npc.DamageMultiplier = NPC_DAMAGE_MULTIPLIER
                npc.CanAddWounds = false
                table.insert(spawnedNpcs, npc)
            end
        end
    end

    -- Make every battle royale NPC an enemy of every other one, like "NPC Battle Royale".
    for i = 1, #spawnedNpcs do
        local npc = spawnedNpcs[i]
        if npc and npc.zombie then
            for j = 1, #spawnedNpcs do
                if i ~= j then
                    local other = spawnedNpcs[j]
                    if other and other.zombie then
                        ChaosNPCRelations.SetNPCRelationToCharacterId(
                            npc, other.zombie:getID(), ChaosNPCRelationType.ATTACK)
                    end
                end
            end

            npc.enemy = nil
            npc.findEnemyTimeoutMs = CHAOS_NPC_MAX_FIND_ENEMY_TIMEOUT_MS
        end
    end

    self.npcs = spawnedNpcs
    self.totalNpcs = #spawnedNpcs
    self.aliveNpcs = self.totalNpcs
    for i = 1, self.totalNpcs do
        self.npcDead[i] = false
        -- Stagger the first re-target so all NPCs don't scan on the same tick.
        self.npcRetargetMs[i] = ChaosUtils.RandInteger(NPC_RETARGET_INTERVAL_MS)
    end
end

---@param player IsoPlayer
function EffectGameBattleRoyale:NotifyEnemyDown(player)
    self.aliveNpcs = self.aliveNpcs - 1
    if self.aliveNpcs < 0 then self.aliveNpcs = 0 end

    if player then
        ChaosPlayer.SayLine(
            player,
            "Enemies: " .. self.aliveNpcs .. "/" .. self.totalNpcs,
            DEATH_LINE_COLOR.r, DEATH_LINE_COLOR.g, DEATH_LINE_COLOR.b)
    end
end

---@param deltaMs integer
function EffectGameBattleRoyale:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)

    local player = getPlayer()
    if not player then return end

    self.elapsedMs = self.elapsedMs + deltaMs

    local maxTicks = (self.maxTicks and self.maxTicks > 0) and self.maxTicks or DEFAULT_DURATION_MS

    -- The zone stays put during the blue safe period and only shrinks once it turns red.
    local shrinkDuration = maxTicks - SAFE_PERIOD_MS
    local progress = 0.0
    if shrinkDuration > 0 then
        progress = (self.elapsedMs - SAFE_PERIOD_MS) / shrinkDuration
    end
    if progress < 0 then progress = 0 end
    if progress > 1 then progress = 1 end

    self.zoneRadius = ZONE_INITIAL_RADIUS - (ZONE_INITIAL_RADIUS - ZONE_MIN_RADIUS) * progress

    if self.marker then
        self.marker:setSize(self.zoneRadius * math.sqrt(2.0))
        self.marker:setPos(self.centerX, self.centerY, math.floor(player:getZ()))
    end

    -- After the safe period the zone turns red and starts damaging anything outside it.
    if not self.damagePhase and self.elapsedMs >= SAFE_PERIOD_MS then
        self.damagePhase = true
        if self.marker then
            self.marker:setR(MARKER_RED.r)
            self.marker:setG(MARKER_RED.g)
            self.marker:setB(MARKER_RED.b)
        end
    end

    local deltaSeconds = deltaMs / 1000
    local npcDamage = deltaSeconds * (NPC_DAMAGE_PER_MINUTE / 60.0)

    -- Damage the player when outside the zone (same metric as Toxic Rain).
    if self.damagePhase then
        local insideZone = ChaosUtils.isInRange(
            player:getX(), player:getY(), self.centerX, self.centerY, self.zoneRadius)
        if not insideZone then
            local bodyDamage = player:getBodyDamage()
            if bodyDamage then
                bodyDamage:ReduceGeneralHealth(deltaSeconds * PLAYER_DAMAGE_PER_SECOND)
            end
        end
    end

    for i = 1, self.totalNpcs do
        if not self.npcDead[i] then
            local npc = self.npcs[i]

            -- A nil npc or nil zombie means it was garbage-collected: treat as a death.
            if not npc or not npc.zombie or npc.zombie:isDead() then
                self.npcDead[i] = true
                self:NotifyEnemyDown(player)
            else
                local zombie = npc.zombie
                local isInsideZone = ChaosUtils.isInRange(
                    zombie:getX(), zombie:getY(), self.centerX, self.centerY, self.zoneRadius)

                -- Inside the zone, re-pick the nearest enemy every second (even with a valid one).
                -- Outside the zone they prefer regrouping toward the center instead of hunting.
                if isInsideZone then
                    self.npcRetargetMs[i] = (self.npcRetargetMs[i] or 0) + deltaMs
                    if self.npcRetargetMs[i] >= NPC_RETARGET_INTERVAL_MS then
                        self.npcRetargetMs[i] = self.npcRetargetMs[i] - NPC_RETARGET_INTERVAL_MS
                        local newEnemy = ChaosNPCUtils.FindNewTargetForNPC(npc)
                        if newEnemy then
                            npc:SetAsTargetEnemy(newEnemy)
                        end
                    end
                end

                -- Custom AI: drop targets that are too far and regroup toward the center.
                local enemy = npc.enemy
                local shouldRegroup = enemy == nil
                if enemy and not isInsideZone then
                    local enemyDist = ChaosUtils.distTo(
                        zombie:getX(), zombie:getY(), enemy:getX(), enemy:getY())
                    if enemyDist > NPC_MOVE_TO_CENTER_DIST then
                        shouldRegroup = true
                        npc.enemy = nil
                        npc.moveTargetCharacter = nil
                        npc.moveTargetLocation = nil
                    end
                end

                if shouldRegroup and npc.moving == false then
                    npc.enemy = nil
                    npc.moveTargetCharacter = nil
                    npc.moveTargetLocation = nil
                    -- print("Regrouping NPC " .. zombie:getID())
                    if self.centerSquare then
                        npc:MoveToLocation(self.centerSquare)
                    end
                end

                -- Damage battle royale NPCs that wander outside the shrinking zone.
                if self.damagePhase then
                    local insideZone = isInsideZone
                    if not insideZone then
                        ChaosZombie.DamageZombie(zombie, npcDamage, nil)
                    end
                end
            end
        end
    end
end

function EffectGameBattleRoyale:OnEnd()
    ChaosEffectBase:OnEnd()

    if self.marker then
        self.marker:remove()
        self.marker = nil
    end

    if self.homingPoint then
        self.homingPoint:remove()
        self.homingPoint = nil
    end

    if self.npcs then
        for i = 1, #self.npcs do
            local npc = self.npcs[i]
            if npc and npc.zombie then
                npc:Destroy()
            end
        end
    end
    self.npcs = {}
    self.centerSquare = nil

    local player = getPlayer()
    if not player or player:isDead() then return end

    -- Only the player who finished inside the safe zone wins the rewards.
    local insideZone = ChaosUtils.isInRange(
        player:getX(), player:getY(), self.centerX, self.centerY, self.zoneRadius)
    if not insideZone then return end

    local inventory = player:getInventory()
    if inventory then
        for _ = 1, 3 do
            local itemId = GetRandomLootboxItem()
            if itemId then
                local item = inventory:AddItem(itemId)
                if item then
                    ChaosItems.SetFullAmmoIfWeapon(item)
                    ChaosPlayer.SayLineNewItem(player, item)
                end
            end
        end
    end

    local bodyDamage = player:getBodyDamage()
    if bodyDamage then
        bodyDamage:RestoreToFullHealth()
    end

    if player.playGainExperienceLevelSound then
        player:playGainExperienceLevelSound()
    end
end
