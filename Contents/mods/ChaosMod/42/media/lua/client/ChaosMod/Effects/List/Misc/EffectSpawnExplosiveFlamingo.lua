---@class EffectSpawnExplosiveFlamingo : ChaosEffectBase
---@field prop IsoObject?
---@field propSquare IsoGridSquare?
EffectSpawnExplosiveFlamingo = ChaosEffectBase:derive("EffectSpawnExplosiveFlamingo", "spawn_explosive_flamingo")

local SPRITE_NAME = "vegetation_ornamental_01_25"
local EXPLOSION_RADIUS = 5
local MIN_DISTANCE = 1
local MAX_DISTANCE = 6

function EffectSpawnExplosiveFlamingo:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectSpawnExplosiveFlamingo] OnStart " .. tostring(self.effectId))

    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local x = square:getX()
    local y = square:getY()
    local z = square:getZ()

    local targetSquare = nil

    ChaosUtils.SquareRingSearchTile_2D(x, y, function(sq)
        targetSquare = sq
        return true
    end, MIN_DISTANCE, MAX_DISTANCE, true, true, true, z, z)

    if not targetSquare then return end

    self.propSquare = targetSquare
    self.prop = ChaosProps.SpawnProp(targetSquare, SPRITE_NAME)
end

function EffectSpawnExplosiveFlamingo:OnEnd()
    ChaosEffectBase:OnEnd()

    local square = self.propSquare
    if not square and self.prop then
        square = self.prop:getSquare()
    end
    if not square then return end

    if self.prop then
        if square then
            square:RemoveTileObject(self.prop)
        end
        self.prop:removeFromSquare()
        self.prop = nil
    end

    ChaosUtils.TriggerExplosionAt(square, EXPLOSION_RADIUS)
    print("[EffectSpawnExplosiveFlamingo] Flamingo exploded")
end
