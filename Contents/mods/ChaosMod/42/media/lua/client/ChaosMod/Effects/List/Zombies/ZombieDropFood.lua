EffectZombieDropFood = ChaosEffectBase:derive("EffectZombieDropFood", "zombie_drop_food")


---@param zombie IsoZombie
local function OnZombieDead(zombie)
    if not zombie then return end

    local lastAttacker = zombie:getAttackedBy()
    if not lastAttacker then return end
    if not instanceof(lastAttacker, "IsoPlayer") then return end

    local inventory = lastAttacker:getInventory()
    if not inventory then return end

    local randomFoodItemId = ChaosItems.GetRandomFoodItemId()
    if not randomFoodItemId then return end
    local newItem = inventory:AddItem(randomFoodItemId)
    if not newItem then return end

    ChaosPlayer.SayLineNewItem(lastAttacker, newItem)
end

function EffectZombieDropFood:OnStart()
    ChaosEffectBase:OnStart()

    Events.OnZombieDead.Add(OnZombieDead)
end

function EffectZombieDropFood:OnEnd()
    ChaosEffectBase:OnEnd()
    Events.OnZombieDead.Remove(OnZombieDead)
end
