EffectSetDayTimeNight = ChaosEffectBase:derive("EffectSetDayTimeNight", "set_day_time_night")

function EffectSetDayTimeNight:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectSetDayTimeNight] OnStart" .. tostring(self.effectId))

    ChaosUtils.SetWorldTime(3, 0)
end
