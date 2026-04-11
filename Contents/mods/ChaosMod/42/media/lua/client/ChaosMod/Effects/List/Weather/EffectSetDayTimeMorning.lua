EffectSetDayTimeMorning = ChaosEffectBase:derive("EffectSetDayTimeMorning", "set_day_time_morning")

function EffectSetDayTimeMorning:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectSetDayTimeMorning] OnStart" .. tostring(self.effectId))

    ChaosUtils.SetWorldTime(11, 0)
end
