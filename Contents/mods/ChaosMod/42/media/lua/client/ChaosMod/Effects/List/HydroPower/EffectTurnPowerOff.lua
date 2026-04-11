EffectTurnPowerOff = ChaosEffectBase:derive("EffectTurnPowerOff", "turn_power_off")

function EffectTurnPowerOff:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectTurnPowerOff] OnStart" .. tostring(self.effectId))
    local player = getPlayer()
    if player then
        local x = player:getX()
        local y = player:getY()
        local z = player:getZ()
    end

    getWorld():setHydroPowerOn(false)
    local now = IsoWorld.instance:getWorldAgeDays()
    print("[EffectTurnPowerOff] Days now: " .. tostring(now))
    getSandboxOptions():set("ElecShutModifier", now)
    getSandboxOptions():toLua()
end
