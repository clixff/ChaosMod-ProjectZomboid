---@class EffectTimeRewind : ChaosEffectBase
---@field saves table<integer, {x: number, y: number, z: number}>
---@field elapsedMs number
---@field totalMs number
EffectTimeRewind = ChaosEffectBase:derive("EffectTimeRewind", "time_rewind")

local HISTORY_COPY_MAX = 120

function EffectTimeRewind:OnStart()
    ChaosEffectBase:OnStart()

    -- Snapshot the global position history (most recent HISTORY_COPY_MAX entries)
    local global = ChaosUtils.playerPositionHistory
    local count = #global
    local startIdx = math.max(1, count - HISTORY_COPY_MAX + 1)
    self.saves = {}
    for i = startIdx, count do
        self.saves[#self.saves + 1] = global[i]
    end

    self.elapsedMs = 0
    self.totalMs = self.duration * 1000
end

function EffectTimeRewind:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)

    local n = #self.saves
    if n <= 0 or self.totalMs <= 0 then return end

    self.elapsedMs = self.elapsedMs + deltaMs
    local t = self.elapsedMs / self.totalMs
    if t > 1 then t = 1 end

    local player = getPlayer()
    if not player then return end

    local x, y, z
    if n == 1 then
        local entry = self.saves[1]
        x, y, z = entry.x, entry.y, entry.z
    else
        -- Move from newest (index n) → oldest (index 1) over the effect duration.
        -- floatIdx walks from n down to 1; lerp inside the segment [i, i+1] that contains it.
        local floatIdx = n - t * (n - 1)
        local i = math.floor(floatIdx)
        if i < 1 then i = 1 end
        if i > n then i = n end
        local nextI = i + 1
        if nextI > n then nextI = n end
        local frac = floatIdx - i
        if frac < 0 then frac = 0 end
        if frac > 1 then frac = 1 end
        local a = self.saves[i]
        local b = self.saves[nextI]
        x = a.x + (b.x - a.x) * frac
        y = a.y + (b.y - a.y) * frac
        z = a.z + (b.z - a.z) * frac
    end

    local vehicle = player:getVehicle()
    if vehicle then
        ChaosVehicle.ExitVehicle(player)
    end
    player:teleportTo(math.floor(x), math.floor(y), math.floor(z))
end

function EffectTimeRewind:OnEnd()
    ChaosEffectBase:OnEnd()
end
