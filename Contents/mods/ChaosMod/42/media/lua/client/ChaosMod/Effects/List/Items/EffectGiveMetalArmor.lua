EffectGiveMetalArmor = ChaosEffectBase:derive("EffectGiveMetalArmor", "give_metal_armor")

function EffectGiveMetalArmor:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectGiveMetalArmor] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end

    local inventory = player:getInventory()
    if not inventory then return end

    local singles = {
        "Base.Hat_MetalHelmet",
        "Base.Codpiece_Metal",
        "Base.Cuirass_Metal",
        "Base.Gorget_Metal",
    }

    local pairs = {
        { "Base.Vambrace_Right",          "Base.Vambrace_Left" },
        { "Base.Greave_Right",            "Base.Greave_Left" },
        { "Base.Shoulderpad_Metal_L",     "Base.Shoulderpad_Metal_R" },
        { "Base.ThighMetal_L",            "Base.ThighMetal_R" },
        { "Base.Vambrace_FullMetal_Right", "Base.Vambrace_FullMetal_Left" },
    }

    for _, itemId in ipairs(singles) do
        local item = inventory:AddItem(itemId)
        if item then
            ChaosPlayer.SayLineNewItem(player, item)
        end
    end

    for _, pair in ipairs(pairs) do
        local item = inventory:AddItem(pair[1])
        inventory:AddItem(pair[2])
        if item then
            ChaosPlayer.SayLineNewItem(player, item, 2)
        end
    end
end
