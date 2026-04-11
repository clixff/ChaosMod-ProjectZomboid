EffectBreakPlayerWeapons = ChaosEffectBase:derive("EffectBreakPlayerWeapons", "break_player_weapons")

function EffectBreakPlayerWeapons:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectGiveBatteries] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end


    local inventory = player:getInventory()
    if not inventory then return end

    local weaponsInHand = player:getPrimaryHandItem()
    local secondaryWeapon = player:getSecondaryHandItem()

    if weaponsInHand and weaponsInHand:IsWeapon() then
        weaponsInHand:setConditionNoSound(0)
    end

    if not player:isItemInBothHands(weaponsInHand) then
        if secondaryWeapon and secondaryWeapon:IsWeapon() then
            secondaryWeapon:setConditionNoSound(0)
        end
    end
end
