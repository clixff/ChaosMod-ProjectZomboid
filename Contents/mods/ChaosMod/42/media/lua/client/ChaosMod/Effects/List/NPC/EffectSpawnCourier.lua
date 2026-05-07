require "ChaosMod/NPC/ChaosCourierEffectUtils"

---@class EffectSpawnCourier : ChaosEffectBase, ChaosCourierEffectData
EffectSpawnCourier = ChaosEffectBase:derive("EffectSpawnCourier", "spawn_courier")

function EffectSpawnCourier:OnStart()
    ChaosEffectBase:OnStart()
    ChaosCourierEffectUtils.Start(self, {
        outfit = "Tourist",
        itemCount = 1,
        itemProvider = GetRandomLootboxItem,
    })
end

---@param _deltaMs integer
function EffectSpawnCourier:OnTick(_deltaMs)
    ChaosCourierEffectUtils.Update(self)
end

function EffectSpawnCourier:OnEnd()
    ChaosEffectBase:OnEnd()
    ChaosCourierEffectUtils.Destroy(self)
end
