EffectGivePackOfHotdogs = ChaosEffectBase:derive("EffectGivePackOfHotdogs", "give_pack_of_hotdogs")

function EffectGivePackOfHotdogs:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectGivePackOfHotdogs] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end


    local inventory = player:getInventory()
    if not inventory then return end

    local item = inventory:AddItem("Base.HotdogPack")

    ChaosPlayer.SayLineNewItem(player, item, 1)
end
