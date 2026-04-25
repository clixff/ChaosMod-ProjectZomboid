---@class EffectLags : ChaosEffectBase
---@field timeSinceLastRubberbandMs integer
---@field totalElapsedMs integer
---@field lastSampleMs integer
---@field positionHistory table<integer, {x: number, y: number, z: number, elapsedMs: integer}>
EffectLags = ChaosEffectBase:derive("EffectLags", "effect_lags")

local RUBBERBAND_INTERVAL_MS = 4000
local ROLLBACK_DELAY_MS = 2000
local SAMPLE_INTERVAL_MS = 200

function EffectLags:OnStart()
    ChaosEffectBase:OnStart()
    self.timeSinceLastRubberbandMs = 0
    self.totalElapsedMs = 0
    self.lastSampleMs = 0
    self.positionHistory = {}
end

function EffectLags:OnTick(deltaMs)
    local player = getPlayer()
    if not player then return end

    self.totalElapsedMs = self.totalElapsedMs + deltaMs
    self.timeSinceLastRubberbandMs = self.timeSinceLastRubberbandMs + deltaMs
    self.lastSampleMs = self.lastSampleMs + deltaMs

    -- Sample player (or vehicle) position every SAMPLE_INTERVAL_MS
    if self.lastSampleMs >= SAMPLE_INTERVAL_MS then
        self.lastSampleMs = 0
        local vehicle = player:getVehicle()
        local refObj = vehicle or player
        if refObj:getSquare() then
            table.insert(self.positionHistory, {
                x = refObj:getX(),
                y = refObj:getY(),
                z = refObj:getZ(),
                elapsedMs = self.totalElapsedMs
            })
        end

        -- Prune entries older than we will ever need
        local cutoff = self.totalElapsedMs - (ROLLBACK_DELAY_MS + 1000)
        while #self.positionHistory > 0 and self.positionHistory[1].elapsedMs < cutoff do
            table.remove(self.positionHistory, 1)
        end
    end

    -- Rubber-band every RUBBERBAND_INTERVAL_MS
    if self.timeSinceLastRubberbandMs >= RUBBERBAND_INTERVAL_MS then
        self.timeSinceLastRubberbandMs = 0

        local targetTime = self.totalElapsedMs - ROLLBACK_DELAY_MS
        local best = nil
        local bestDiff = math.huge

        for _, entry in ipairs(self.positionHistory) do
            local diff = math.abs(entry.elapsedMs - targetTime)
            if diff < bestDiff then
                bestDiff = diff
                best = entry
            end
        end

        if best then
            print("[EffectLags] Rubber-band! Teleporting back to position from ~3s ago")
            local vehicle = player:getVehicle()
            if vehicle then
                ChaosVehicle.ExitVehicle(player)
            end
            player:teleportTo(best.x, best.y, best.z)
        end
    end
end

function EffectLags:OnEnd()
    ChaosEffectBase:OnEnd()
    self.positionHistory = {}
end
