EffectDisableSounds = ChaosEffectBase:derive("EffectDisableSounds", "disable_sounds")

function EffectDisableSounds:OnStart()
    ChaosEffectBase:OnStart()
    pauseSoundAndMusic()
end

function EffectDisableSounds:OnEnd()
    ChaosEffectBase:OnEnd()
    resumeSoundAndMusic()
end
