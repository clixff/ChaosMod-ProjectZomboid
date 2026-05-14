EffectDisableSounds = ChaosEffectBase:derive("EffectDisableSounds", "disable_sounds")

function EffectDisableSounds:OnStart()
    ChaosEffectBase:OnStart()
    pauseSoundAndMusic()
end

function EffectDisableSounds:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)

    pauseSoundAndMusic()
end

function EffectDisableSounds:OnEnd()
    ChaosEffectBase:OnEnd()
    resumeSoundAndMusic()
end
