EffectGiveSaw = ChaosEffectBase:derive("EffectGiveSaw", "give_saw")

function EffectGiveSaw:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectGiveSaw] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end


    local inventory = player:getInventory()
    if not inventory then return end

    local item = inventory:AddItem("Base.Saw")
    if item then
        ChaosPlayer.SayLineNewItem(player, item)
    end
end
