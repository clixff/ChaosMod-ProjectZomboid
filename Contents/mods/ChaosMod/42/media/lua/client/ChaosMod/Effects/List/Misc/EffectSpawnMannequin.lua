---@class EffectSpawnMannequin : ChaosEffectBase
EffectSpawnMannequin = ChaosEffectBase:derive("EffectSpawnMannequin", "spawn_mannequin")

function EffectSpawnMannequin:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectSpawnMannequin] OnStart" .. tostring(self.effectId))

    local player = getPlayer()
    if not player then return end

    local square = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, 2, 8, 20, true, false, false)
    if not square then return end

    local man = ChaosProps.SpawnMannequin(square, "location_shop_mall_01_68")
    if not man then return end

    local container = man:getContainer()
    if container then
        container:removeAllItems()
    end

    ChaosProps.AddClothingToMannequin(man, "Base.Suit_Jacket")
    ChaosProps.AddClothingToMannequin(man, "Base.Shirt_FormatWhite_Short_Sleeve")
    ChaosProps.AddClothingToMannequin(man, "Base.Trousers_Suit")
    ChaosProps.AddClothingToMannequin(man, "Base.Shoes_Black")
    ChaosProps.AddClothingToMannequin(man, "Base.Tie_BowTieWorn")

    print("[EffectSpawnMannequin] Spawned mannequin at " .. tostring(square:getX()) .. ", " .. tostring(square:getY()))
end
