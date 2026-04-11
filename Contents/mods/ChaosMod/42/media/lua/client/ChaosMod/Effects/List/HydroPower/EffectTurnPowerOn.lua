EffectTurnPowerOn = ChaosEffectBase:derive("EffectTurnPowerOn", "turn_power_on")

function EffectTurnPowerOn:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectTurnPowerOn] OnStart" .. tostring(self.effectId))
    local player = getPlayer()
    if player then
        local x = player:getX()
        local y = player:getY()
        local z = player:getZ()
    end

    getWorld():setHydroPowerOn(true)
    local now = IsoWorld.instance:getWorldAgeDays()
    -- Add 5 nights to the modifier
    print("[EffectTurnPowerOn] Days now: " .. tostring(now))
    local randomDaysToAdd = ZombRand(4, 15 + 1)
    print("[EffectTurnPowerOn] Random days to add: " .. tostring(randomDaysToAdd))
    -- SandboxVars.ElecShutModifier = now + 5
    getSandboxOptions():set("ElecShutModifier", now + randomDaysToAdd)
    getSandboxOptions():toLua()
end
