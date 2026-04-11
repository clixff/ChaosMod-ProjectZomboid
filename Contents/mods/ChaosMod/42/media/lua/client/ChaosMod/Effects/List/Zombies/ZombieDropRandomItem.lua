EffectZombieDropRandomItems = ChaosEffectBase:derive("EffectZombieDropRandomItems", "zombie_drop_random_items")


---@param zombie IsoZombie
local function OnZombieDead(zombie)
    if not zombie then return end

    local lastAttacker = zombie:getAttackedBy()
    if not lastAttacker then return end
    if not instanceof(lastAttacker, "IsoPlayer") then return end

    local inventory = lastAttacker:getInventory()
    if not inventory then return end


    local itemType = ChaosItems.GetRandomItemId()

    if not itemType then return end
    print("[EffectZombieDropRandomItems] Giving item: " .. itemType)

    local newItem = inventory:AddItem(itemType)

    if newItem then
        ChaosPlayer.SayLineNewItem(lastAttacker, newItem)
    end
end

function EffectZombieDropRandomItems:OnStart()
    ChaosEffectBase:OnStart()

    Events.OnZombieDead.Add(OnZombieDead)
end

function EffectZombieDropRandomItems:OnEnd()
    ChaosEffectBase:OnEnd()
    Events.OnZombieDead.Remove(OnZombieDead)
end
