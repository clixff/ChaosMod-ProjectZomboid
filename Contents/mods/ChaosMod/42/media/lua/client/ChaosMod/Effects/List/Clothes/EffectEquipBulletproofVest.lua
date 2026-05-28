---@class EffectEquipBulletproofVest : ChaosEffectBase
EffectEquipBulletproofVest = ChaosEffectBase:derive("EffectEquipBulletproofVest", "equip_bulletproof_vest")

function EffectEquipBulletproofVest:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local inventory = player:getInventory()
    if not inventory then return end

    local item = inventory:AddItem("Base.Vest_BulletPolice")
    if item then
        ChaosPlayer.EquipClothes(player, item)
        ChaosPlayer.SayLineNewItem(player, item)
    end
end
