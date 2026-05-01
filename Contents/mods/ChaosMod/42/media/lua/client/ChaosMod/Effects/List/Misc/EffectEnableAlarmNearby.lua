---@class EffectEnableAlarmNearby : ChaosEffectBase
EffectEnableAlarmNearby = ChaosEffectBase:derive("EffectEnableAlarmNearby", "enable_alarm_nearby")

function EffectEnableAlarmNearby:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectEnableAlarmNearby] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end

    local playerSq = player:getSquare()
    if not playerSq then return end

    local px = playerSq:getX()
    local py = playerSq:getY()
    local cell = getCell()

    local MIN_RADIUS = 5
    local MAX_RADIUS = 80

    local roomDef = nil
    local building = nil

    ChaosUtils.SquareRingSearchTile_2D(px, py, function(sq)
        if sq then
            local rd = sq:getRoomDef()
            if rd then
                local b = rd:getBuilding()
                if b then
                    roomDef = rd
                    building = b
                    return true
                end
            end
        end
    end, 0, MAX_RADIUS, false, false, true, 0, 0)


    if not roomDef or not building then
        ChaosPlayer.SayLine(player, "No building nearby", 1.0, 0.5, 0.0)
        return
    end

    building:setAlarmed(true)
    getAmbientStreamManager():doAlarm(roomDef)
end
