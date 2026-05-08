EffectHideEffectNames = ChaosEffectBase:derive("EffectHideEffectNames", "hide_effect_names")

function EffectHideEffectNames:OnStart()
    ChaosEffectBase:OnStart()
    self.showNameAlways = true
    ChaosEffectsUI.hideEffectNames = true
end

function EffectHideEffectNames:OnEnd()
    ChaosEffectBase:OnEnd()
    ChaosEffectsUI.hideEffectNames = false
end
