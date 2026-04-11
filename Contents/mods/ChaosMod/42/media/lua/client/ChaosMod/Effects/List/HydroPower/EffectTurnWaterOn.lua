EffectTurnWaterOn = ChaosEffectBase:derive("EffectTurnWaterOn", "turn_water_on")

function EffectTurnWaterOn:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectTurnWaterOn] OnStart" .. tostring(self.effectId))
    local player = getPlayer()
    if player then
        local x = player:getX()
        local y = player:getY()
        local z = player:getZ()
    end

    local now = IsoWorld.instance:getWorldAgeDays()
    -- Add 5 nights to the modifier
    print("[EffectTurnWaterOn] Days now: " .. tostring(now))
    local randomDaysToAdd = ZombRand(4, 15 + 1)
    print("[EffectTurnWaterOn] Random days to add: " .. tostring(randomDaysToAdd))
    -- SandboxVars.ElecShutModifier = now + 5
    getSandboxOptions():set("WaterShutModifier", now + randomDaysToAdd)
    getSandboxOptions():toLua()
end
