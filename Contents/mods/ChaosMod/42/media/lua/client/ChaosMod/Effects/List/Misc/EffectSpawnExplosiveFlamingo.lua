---@class EffectSpawnExplosiveFlamingo : ChaosEffectBase
---@field prop IsoObject?
---@field propSquare IsoGridSquare?
---@field moveTimer number
---@field teleportDone boolean
EffectSpawnExplosiveFlamingo = ChaosEffectBase:derive("EffectSpawnExplosiveFlamingo", "spawn_explosive_flamingo")

local SPRITE_NAME = "vegetation_ornamental_01_25"
local EXPLOSION_RADIUS = 5
local MIN_DISTANCE = 1
local MAX_DISTANCE = 6
local MOVE_INTERVAL = 600

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
    self.moveTimer = 0
    self.teleportDone = false
end

function EffectSpawnExplosiveFlamingo:OnTick(deltaMs)
    if not self.prop then return end

    if not self.teleportDone and (self.maxTicks - self.ticksActiveTime) < 3000 then
        self.teleportDone = true
        local player = getPlayer()
        if player then
            local propSq = self.prop:getSquare()
            local playerSq = player:getSquare()
            if propSq and playerSq then
                local dist = ChaosUtils.distTo(propSq:getX(), propSq:getY(), playerSq:getX(), playerSq:getY())
                if dist > 3.0 then
                    local newSq = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, 1, 3, 10, true, true, false)
                    if newSq then
                        local obj = self.prop
                        obj:removeFromSquare()
                        if self.propSquare then
                            self.propSquare:RemoveTileObject(obj)
                        end
                        obj:setSquare(newSq)
                        newSq:AddTileObject(obj)
                        self.propSquare = newSq
                    end
                end
            end
        end
    end

    self.moveTimer = self.moveTimer + deltaMs
    if self.moveTimer < MOVE_INTERVAL then return end
    self.moveTimer = self.moveTimer - MOVE_INTERVAL

    local player = getPlayer()
    if not player then return end

    local propSq = self.prop:getSquare()
    if not propSq then return end

    local playerSq = player:getSquare()
    if not playerSq then return end

    local propX = propSq:getX()
    local propY = propSq:getY()
    local propZ = propSq:getZ()

    local dx = playerSq:getX() - propX
    local dy = playerSq:getY() - propY

    if dx == 0 and dy == 0 then return end

    local stepX = dx == 0 and 0 or (dx > 0 and 1 or -1)
    local stepY = dy == 0 and 0 or (dy > 0 and 1 or -1)

    local newSq = getCell():getGridSquare(propX + stepX, propY + stepY, propZ)
    if not newSq then return end

    local obj = self.prop
    obj:removeFromSquare()
    if self.propSquare then
        self.propSquare:RemoveTileObject(obj)
    end
    obj:setSquare(newSq)
    newSq:AddTileObject(obj)

    self.propSquare = newSq
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
        self.prop:removeFromWorld()
        self.prop = nil
    end

    ChaosUtils.TriggerExplosionAt(square, EXPLOSION_RADIUS)
    print("[EffectSpawnExplosiveFlamingo] Flamingo exploded")
end
