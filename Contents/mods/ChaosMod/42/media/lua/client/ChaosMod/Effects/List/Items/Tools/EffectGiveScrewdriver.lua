EffectGiveScrewdriver = ChaosEffectBase:derive("EffectGiveScrewdriver", "give_screwdriver")

function EffectGiveScrewdriver:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectGiveScrewdriver] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end


    local inventory = player:getInventory()
    if not inventory then return end

    local item = inventory:AddItem("Base.Screwdriver")
    if item then
        ChaosPlayer.SayLineNewItem(player, item)
    end
end
