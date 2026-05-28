---@class EffectKillBill : ChaosEffectBase
EffectKillBill = ChaosEffectBase:derive("EffectKillBill", "kill_bill")

function EffectKillBill:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local inventory = player:getInventory()
    if not inventory then return end

    local katana = inventory:AddItem("Base.Katana")
    if katana then
        ChaosPlayer.EquipWeapon(player, katana)
        ChaosPlayer.SayLineNewItem(player, katana)
    end

    local boilersuit = inventory:AddItem("Base.Boilersuit_Yellow")
    if boilersuit then
        ChaosPlayer.EquipClothes(player, boilersuit)
        ChaosPlayer.SayLineNewItem(player, boilersuit)
    end
end

function EffectKillBill:OnEnd()
    ChaosEffectBase:OnEnd()
end
