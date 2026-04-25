EffectGiveNailsBox = ChaosEffectBase:derive("EffectGiveNailsBox", "give_nails_box")

function EffectGiveNailsBox:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectGiveNailsBox] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end

    local inventory = player:getInventory()
    if not inventory then return end

    local amount = math.floor(ZombRand(1, 3 + 1))

    ChaosPlayer.SayLineNewItemByString(player, "Base.NailsBox", amount)

    for i = 1, amount do
        inventory:AddItem("Base.NailsBox")
    end
end
