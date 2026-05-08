require "ChaosMod/NPC/ChaosCourierEffectUtils"

---@class EffectFoodDelivery : ChaosEffectBase, ChaosCourierEffectData
EffectFoodDelivery = ChaosEffectBase:derive("EffectFoodDelivery", "food_delivery")

function EffectFoodDelivery:OnStart()
    ChaosEffectBase:OnStart()
    ChaosCourierEffectUtils.Start(self, {
        outfit = "Tourist",
        itemCount = 3,
        itemProvider = ChaosItems.GetRandomFoodItemId,
    })
end

---@param _deltaMs integer
function EffectFoodDelivery:OnTick(_deltaMs)
    ChaosCourierEffectUtils.Update(self)
end

function EffectFoodDelivery:OnEnd()
    ChaosEffectBase:OnEnd()
    ChaosCourierEffectUtils.Destroy(self)
end
