---@class EffectGiveMolotovCocktails : ChaosEffectBase
EffectGiveMolotovCocktails = ChaosEffectBase:derive("EffectGiveMolotovCocktails", "give_molotov_cocktails")

function EffectGiveMolotovCocktails:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local inventory = player:getInventory()
    if not inventory then return end

    local molotovAmount = 3
    local firstMolotov = nil

    for i = 1, molotovAmount do
        local item = inventory:AddItem("Base.Molotov")
        if item and not firstMolotov then
            firstMolotov = item
        end
    end

    if firstMolotov then
        ChaosPlayer.SayLineNewItem(player, firstMolotov, molotovAmount)
        player:setPrimaryHandItem(firstMolotov)
    end

    local lighter = inventory:AddItem("Base.Lighter")
    if lighter then
        ChaosPlayer.SayLineNewItem(player, lighter, 1)
        player:setSecondaryHandItem(lighter)
    end
end

function EffectGiveMolotovCocktails:OnEnd()
    ChaosEffectBase:OnEnd()
end
