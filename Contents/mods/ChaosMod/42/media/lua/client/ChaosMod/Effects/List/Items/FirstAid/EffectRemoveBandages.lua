EffectRemoveBandages = ChaosEffectBase:derive("EffectRemoveBandages", "remove_bandages")

---@param item InventoryItem
local function handleItemRemove(item)
    if not item then return end

    local fullType = item:getFullType()

    if fullType == "Base.Bandage" or fullType == "Base.BandageDirty" or fullType == "Base.AlcoholBandage" then
        item:Remove()
        return
    end
end

function EffectRemoveBandages:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectRemoveBandages] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end

    local inventory = player:getInventory()
    if not inventory then return end

    ChaosPlayer.RecursiveInventoryLookup(inventory, true, true, handleItemRemove)

    local bodyDamage = player:getBodyDamage()
    local bodyParts = bodyDamage:getBodyParts()

    for i = 0, bodyParts:size() - 1 do
        local part = bodyParts:get(i)
        if part:bandaged() then
            ---@diagnostic disable-next-line: param-type-mismatch
            bodyDamage:SetBandaged(i, false, 0.0, false, nil)
        end
    end
end
