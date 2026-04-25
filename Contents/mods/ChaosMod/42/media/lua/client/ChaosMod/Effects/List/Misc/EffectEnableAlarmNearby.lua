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

    local MIN_RADIUS = 30
    local MAX_RADIUS = 80

    local roomDef = nil
    local building = nil

    for _ = 1, 100 do
        local dx = ZombRand(-MAX_RADIUS, MAX_RADIUS + 1)
        local dy = ZombRand(-MAX_RADIUS, MAX_RADIUS + 1)
        local distSq = dx * dx + dy * dy
        if distSq >= MIN_RADIUS * MIN_RADIUS and distSq <= MAX_RADIUS * MAX_RADIUS then
            local sq = cell:getGridSquare(px + dx, py + dy, 0)
            if sq then
                local rd = sq:getRoomDef()
                if rd then
                    local b = rd:getBuilding()
                    if b then
                        roomDef = rd
                        building = b
                        break
                    end
                end
            end
        end
    end

    if not roomDef or not building then return end

    building:setAlarmed(true)
    getAmbientStreamManager():doAlarm(roomDef)
end
