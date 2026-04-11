EffectGiveRandomMap = ChaosEffectBase:derive("EffectGiveRandomMap", "give_random_map")

local maps = {
    [1] = "Base.WestpointMap",
    [2] = "Base.LouisvilleMap5",
    [3] = "Base.MuldraughMap",
    [4] = "Base.MarchRidgeMap",
    [5] = "Base.RiversideMap",
    [6] = "Base.RosewoodMap"
}
function EffectGiveRandomMap:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectGiveRandomMap] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end

    local inventory = player:getInventory()
    if not inventory then return end

    local randomIndex = ZombRand(1, #maps + 1)
    local randomMap = maps[randomIndex]
    if not randomMap then return end

    local item = inventory:AddItem(randomMap)
    if item then
        ChaosPlayer.SayLineNewItem(player, item)
    end
end
