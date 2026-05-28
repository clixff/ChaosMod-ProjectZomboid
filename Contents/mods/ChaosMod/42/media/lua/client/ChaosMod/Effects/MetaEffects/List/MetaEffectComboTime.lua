---@class MetaEffectComboTime : ChaosMetaEffectBase
MetaEffectComboTime = ChaosMetaEffectBase:derive("MetaEffectComboTime", "combo_time")

function MetaEffectComboTime:OnStart()
    ChaosMetaEffectBase.OnStart(self)
end

function MetaEffectComboTime:OnEnd()
    ChaosMetaEffectBase.OnEnd(self)
end

---@return integer
function MetaEffectComboTime:GetEffectsCount()
    local v = self.variables and tonumber(self.variables.effects_count) or 1
    if v < 1 then v = 1 end
    return math.floor(v)
end
