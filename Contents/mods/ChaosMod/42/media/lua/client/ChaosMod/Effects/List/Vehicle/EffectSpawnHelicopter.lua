EffectSpawnHelicopter = ChaosEffectBase:derive("EffectSpawnHelicopter", "spawn_helicopter")

function EffectSpawnHelicopter:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectSpawnHelicopter] OnStart" .. tostring(self.effectId))

    testHelicopter()
end
