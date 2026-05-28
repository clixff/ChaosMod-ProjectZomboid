---@class ChaosToxicPuddle
---@field x integer
---@field y integer
---@field z integer
---@field centerX number
---@field centerY number
---@field square IsoGridSquare
---@field marker WorldMarkers.GridSquareMarker?
---@field damageCooldownMs integer

---@class EffectToxicPuddles : ChaosEffectBase
---@field puddles ChaosToxicPuddle[]
---@field playerHighlightMs integer
---@field markerUpdateTimer ChaosManualTimer
---@field damageCheckTimer ChaosManualTimer
EffectToxicPuddles = ChaosEffectBase:derive("EffectToxicPuddles", "toxic_puddles")

local SEARCH_RANGE = 80
local MIN_SPAWN_DIST_FROM_PLAYER = 4.0
local SPAWN_CHANCE = 0.1
local MIN_DIST_BETWEEN_PUDDLES = 4.0
local PUDDLE_RADIUS = 2.0
local MARKER_RADIUS = PUDDLE_RADIUS * math.sqrt(2.0)
local PLAYER_DAMAGE_COOLDOWN_MS = 700
local PLAYER_HEALTH_DAMAGE = 5.0
local PLAYER_POISON_GAIN = 2.0
local ZOMBIE_DAMAGE_PER_MINUTE = 4.0
local HIGHLIGHT_DURATION_MS = 500
local MARKER_RENDER_RADIUS = 10.0
local MARKER_RENDER_Z_DIFF = 0.6
local MARKER_UPDATE_INTERVAL_MS = 100
local DAMAGE_CHECK_INTERVAL_MS = 16

local COLOR_R = 0.2
local COLOR_G = 1.0
local COLOR_B = 0.1

---@param puddles ChaosToxicPuddle[]
---@param x integer
---@param y integer
---@return boolean
local function hasPuddleNearby(puddles, x, y)
    for i = 1, #puddles do
        local p = puddles[i]
        if ChaosUtils.isInRange(p.x, p.y, x, y, MIN_DIST_BETWEEN_PUDDLES) then
            return true
        end
    end
    return false
end

---@param player IsoPlayer
local function applyPlayerHighlight(player)
    ChaosUtils.SetCharacterOutlineHighlightEnabled(0, player, COLOR_R, COLOR_G, COLOR_B, 1.0)
end

---@param player IsoPlayer?
local function clearPlayerHighlight(player)
    if not player then return end
    ChaosUtils.SetCharacterOutlineHighlightDisabled(player)
end

---@param self EffectToxicPuddles
---@param player IsoPlayer
local function damagePlayer(self, player)
    local bd = player:getBodyDamage()
    if bd then
        bd:ReduceGeneralHealth(PLAYER_HEALTH_DAMAGE)
    end
    local stats = player:getStats()
    if stats then
        local oldPoison = stats:get(CharacterStat.POISON)
        local newPoison = math.min(oldPoison + PLAYER_POISON_GAIN, 100)

        stats:set(CharacterStat.POISON, newPoison)
        local poisonInt = math.floor(newPoison)
        ChaosPlayer.SayLineByColor(player, string.format("Poison: %d%%", poisonInt),
            { r = COLOR_R, g = COLOR_G, b = COLOR_B })
    end
    self.playerHighlightMs = HIGHLIGHT_DURATION_MS
    applyPlayerHighlight(player)
end

---@param puddle ChaosToxicPuddle
local function createMarker(puddle)
    if puddle.marker then return end
    local markers = getWorldMarkers()
    if not markers then return end
    puddle.marker = markers:addGridSquareMarker(puddle.square, COLOR_R, COLOR_G, COLOR_B, true, MARKER_RADIUS)
    if puddle.marker then
        puddle.marker:setScaleCircleTexture(false)
    end
end

---@param puddle ChaosToxicPuddle
local function removeMarker(puddle)
    if not puddle.marker then return end
    puddle.marker:remove()
    puddle.marker = nil
end

---@param puddles ChaosToxicPuddle[]
---@param player IsoPlayer
local function updatePuddleMarkers(puddles, player)
    local px = player:getX()
    local py = player:getY()
    local pz = player:getZ()
    for i = 1, #puddles do
        local puddle = puddles[i]
        local inRange = ChaosUtils.isInRange(px, py, puddle.centerX, puddle.centerY, MARKER_RENDER_RADIUS)
            and math.abs(pz - puddle.z) <= MARKER_RENDER_Z_DIFF
        if inRange and not puddle.marker then
            createMarker(puddle)
        elseif not inRange and puddle.marker then
            removeMarker(puddle)
        end
    end
end

---@param puddle ChaosToxicPuddle
---@param deltaMs integer
local function damageZombiesInPuddle(puddle, deltaMs)
    local damage = ZOMBIE_DAMAGE_PER_MINUTE * (deltaMs / 60000.0)
    if damage <= 0 then return end
    ChaosZombie.ForEachZombieInRange(puddle.centerX, puddle.centerY, PUDDLE_RADIUS, function(zombie)
        ChaosZombie.DamageZombie(zombie, damage)
    end, false, puddle.z)
end

function EffectToxicPuddles:OnStart()
    ChaosEffectBase:OnStart()

    self.puddles = {}
    self.playerHighlightMs = 0
    self.markerUpdateTimer = ChaosManualTimer.new(MARKER_UPDATE_INTERVAL_MS)
    self.damageCheckTimer = ChaosManualTimer.new(DAMAGE_CHECK_INTERVAL_MS)

    local player = getPlayer()
    if not player then return end

    local playerSquare = player:getSquare()
    if not playerSquare then return end

    local px = playerSquare:getX()
    local py = playerSquare:getY()
    local pz = playerSquare:getZ()

    local puddles = self.puddles

    ChaosUtils.SquareRingSearchTile_2D(px, py, function(sq)
        if not sq then return end
        if ChaosUtils.RandFloat(0, 1) > SPAWN_CHANCE then return end

        local sx = sq:getX()
        local sy = sq:getY()
        if hasPuddleNearby(puddles, sx, sy) then return end

        ---@type ChaosToxicPuddle
        local puddle = {
            x = sx,
            y = sy,
            z = sq:getZ(),
            centerX = sx + 0.5,
            centerY = sy + 0.5,
            square = sq,
            marker = nil,
            damageCooldownMs = 0,
        }
        puddles[#puddles + 1] = puddle
    end, MIN_SPAWN_DIST_FROM_PLAYER, SEARCH_RANGE, true, false, true, pz - 1, pz + 2)

    updatePuddleMarkers(puddles, player)
end

---@param deltaMs integer
function EffectToxicPuddles:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)

    local player = getPlayer()
    if not player then return end

    local px = player:getX()
    local py = player:getY()
    local playerZ = math.floor(player:getZ())

    self.markerUpdateTimer:add(deltaMs)
    if self.markerUpdateTimer:isEnded() then
        self.markerUpdateTimer:reset()
        updatePuddleMarkers(self.puddles, player)
    end

    self.damageCheckTimer:add(deltaMs)
    if self.damageCheckTimer:isEnded() then
        self.damageCheckTimer:reset()
        for i = 1, #self.puddles do
            local puddle = self.puddles[i]
            if puddle.damageCooldownMs > 0 then
                puddle.damageCooldownMs = puddle.damageCooldownMs - DAMAGE_CHECK_INTERVAL_MS
            end

            local playerInside = playerZ == puddle.z
                and ChaosUtils.isInRange(px, py, puddle.centerX, puddle.centerY, PUDDLE_RADIUS)

            if playerInside and puddle.damageCooldownMs <= 0 then
                damagePlayer(self, player)
                puddle.damageCooldownMs = PLAYER_DAMAGE_COOLDOWN_MS
            end

            -- damageZombiesInPuddle(puddle, deltaMs)
        end
    end

    if self.playerHighlightMs > 0 then
        self.playerHighlightMs = self.playerHighlightMs - deltaMs
        if self.playerHighlightMs <= 0 then
            clearPlayerHighlight(player)
        else
            applyPlayerHighlight(player)
        end
    end
end

function EffectToxicPuddles:OnEnd()
    ChaosEffectBase:OnEnd()

    if self.puddles then
        for i = 1, #self.puddles do
            removeMarker(self.puddles[i])
        end
        self.puddles = {}
    end

    clearPlayerHighlight(getPlayer())
    self.playerHighlightMs = 0
end
