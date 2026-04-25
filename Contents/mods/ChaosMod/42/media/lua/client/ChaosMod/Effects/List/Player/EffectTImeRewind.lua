---@class EffectTimeRewind : ChaosEffectBase
---@field saves table<integer, {x: number, y: number, z: number}>
---@field replayIndex integer
---@field replayTimeMs number
---@field replayIntervalMs number
EffectTimeRewind = ChaosEffectBase:derive("EffectTimeRewind", "time_rewind")

local HISTORY_COPY_MAX = 30

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

    local n = #self.saves
    -- Distribute teleports evenly across the full effect duration
    -- replayIntervalMs is computed from self.duration since maxTicks isn't set yet
    self.replayIntervalMs = n > 0 and (self.duration * 1000) / n or 0
    self.replayIndex = n -- replay from newest → oldest
    self.replayTimeMs = 0
end

function EffectTimeRewind:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)

    if self.replayIndex <= 0 or self.replayIntervalMs <= 0 then return end

    self.replayTimeMs = self.replayTimeMs + deltaMs
    while self.replayTimeMs >= self.replayIntervalMs and self.replayIndex > 0 do
        self.replayTimeMs = self.replayTimeMs - self.replayIntervalMs

        local player = getPlayer()
        if player then
            local entry = self.saves[self.replayIndex]
            if entry then
                local vehicle = player:getVehicle()
                if vehicle then
                    ChaosVehicle.ExitVehicle(player)
                end
                player:teleportTo(math.floor(entry.x), math.floor(entry.y), math.floor(entry.z))
            end
        end

        self.replayIndex = self.replayIndex - 1
    end
end

function EffectTimeRewind:OnEnd()
    ChaosEffectBase:OnEnd()
end
