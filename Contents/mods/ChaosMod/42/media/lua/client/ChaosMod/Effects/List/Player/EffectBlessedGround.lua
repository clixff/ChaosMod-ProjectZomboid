---@class EffectBlessedGround : ChaosEffectBase
---@field marker WorldMarkers.GridSquareMarker?
---@field markerSquare IsoGridSquare?
---@field markerCenterX number
---@field markerCenterY number
---@field markerZ integer
---@field woundTimer ChaosManualTimer
---@field damageTimer ChaosManualTimer
EffectBlessedGround = ChaosEffectBase:derive("EffectBlessedGround", "blessed_ground")

local HEAL_RADIUS = 4.0
local MARKER_RENDER_RADIUS = HEAL_RADIUS * math.sqrt(2.0)
local HP_PER_MINUTE = 200.0
local WOUND_HEAL_INTERVAL_MS = 5000
local ZOMBIE_DAMAGE_INTERVAL_MS = 16
local ZOMBIE_DAMAGE_PER_HIT = 0.2
local MIN_SPAWN_DIST = 8
local MAX_SPAWN_DIST = 15

local COLOR_R = 1.0
local COLOR_G = 1.0
local COLOR_B = 0.4

---@param zombie IsoZombie
---@param player IsoPlayer
---@return boolean
local function isHostileTarget(zombie, player)
    if not zombie or not zombie:isAlive() then return false end
    if not ChaosNPCUtils.IsNPC(zombie) then return true end
    local npc = ChaosNPCUtils.GetNPCFromZombie(zombie)
    if not npc then return true end
    local relation = ChaosNPCRelations.GetRelationForNPC(npc, player)
    return relation == ChaosNPCRelationType.ATTACK
end

---@param player IsoPlayer
local function curePlayerVirus(player)
    local bd = player:getBodyDamage()
    local stats = player:getStats()
    if not bd or not stats then return end

    bd:setInfected(false)
    bd:setIsFakeInfected(false)
    bd:setInfectionTime(-1)
    bd:setInfectionMortalityDuration(-1)

    local bodyParts = bd:getBodyParts()
    if bodyParts then
        for i = 0, bodyParts:size() - 1 do
            local part = bodyParts:get(i)
            if part then
                part:SetInfected(false)
                part:SetFakeInfected(false)
                part:SetBitten(false)
            end
        end
    end

    stats:reset(CharacterStat.getById("ZombieInfection"))
    stats:reset(CharacterStat.getById("ZombieFever"))
end

---@param player IsoPlayer
---@return boolean healed
local function healRandomWound(player)
    local partName = ChaosPlayer.HealRandomWound(player)
    if not partName then return false end
    return true
end

---@param self EffectBlessedGround
---@param player IsoPlayer
local function damageEnemiesInArea(self, player)
    ChaosZombie.ForEachZombieInRange(self.markerCenterX, self.markerCenterY, HEAL_RADIUS, function(zombie)
        if not isHostileTarget(zombie, player) then return end
        ChaosZombie.DamageZombie(zombie, ZOMBIE_DAMAGE_PER_HIT, player)
    end, false, self.markerZ)
end

function EffectBlessedGround:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    local square = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, MIN_SPAWN_DIST, MAX_SPAWN_DIST, 80, true, false,
        false)
    if not square then
        square = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, MIN_SPAWN_DIST, MAX_SPAWN_DIST, 80, false, true,
            false)
    end
    if not square then return end

    self.markerSquare = square
    self.markerCenterX = square:getX() + 0.5
    self.markerCenterY = square:getY() + 0.5
    self.markerZ = square:getZ()

    local markers = getWorldMarkers()
    if markers then
        self.marker = markers:addGridSquareMarker(square, COLOR_R, COLOR_G, COLOR_B, true, MARKER_RENDER_RADIUS)
        if self.marker then
            self.marker:setScaleCircleTexture(false)
        end
    end

    self.woundTimer = ChaosManualTimer.new(WOUND_HEAL_INTERVAL_MS)
    self.damageTimer = ChaosManualTimer.new(ZOMBIE_DAMAGE_INTERVAL_MS)
end

---@param deltaMs integer
function EffectBlessedGround:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)

    local player = getPlayer()
    if not player or not self.markerSquare then return end

    self.damageTimer:add(deltaMs)
    self.woundTimer:add(deltaMs)

    local px = player:getX()
    local py = player:getY()
    local pz = math.floor(player:getZ())

    local inside = pz == self.markerZ
        and ChaosUtils.isInRange(px, py, self.markerCenterX, self.markerCenterY, HEAL_RADIUS)

    if inside then
        curePlayerVirus(player)

        if self.woundTimer:isEnded() then
            self.woundTimer:reset()
            if healRandomWound(player) then
                ChaosPlayer.SayLineByColor(player, "Random wound healed", ChaosPlayerChatColors.green)
            end
        else
            local bd = player:getBodyDamage()
            if bd then
                bd:AddGeneralHealth(HP_PER_MINUTE * (deltaMs / 60000.0))
            end
        end
    end

    if self.damageTimer:isEnded() then
        self.damageTimer:reset()
        damageEnemiesInArea(self, player)
    end
end

function EffectBlessedGround:OnEnd()
    ChaosEffectBase:OnEnd()

    if self.marker then
        self.marker:remove()
        self.marker = nil
    end
    self.markerSquare = nil
end
