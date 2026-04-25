EffectTurnWaterOff = ChaosEffectBase:derive("EffectTurnWaterOff", "turn_water_off")

function EffectTurnWaterOff:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectTurnWaterOff] OnStart" .. tostring(self.effectId))
    local player = getPlayer()
    if player then
        local x = player:getX()
        local y = player:getY()
        local z = player:getZ()
    end

    local now = IsoWorld.instance:getWorldAgeDays()
    print("[EffectTurnWaterOff] Days now: " .. tostring(now))
    getSandboxOptions():set("WaterShutModifier", now)
    getSandboxOptions():toLua()
    ChaosPlayer.SayLineByColor(player, ChaosLocalization.GetString("misc", "water_globally_disabled"), ChaosPlayerChatColors.red)
end
