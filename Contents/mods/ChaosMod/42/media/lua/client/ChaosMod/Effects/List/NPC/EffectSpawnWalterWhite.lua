---@class EffectSpawnWalterWhite : ChaosEffectBase
EffectSpawnWalterWhite = ChaosEffectBase:derive("EffectSpawnWalterWhite", "spawn_walter_white")

---@param r number
---@param g number
---@param b number
---@return table
local function MakeTint(r, g, b)
    return {
        r = r / 255,
        g = g / 255,
        b = b / 255
    }
end

---@param zombie IsoZombie
---@param fullType string
---@param tint table?
---@param textureChoice integer?
local function AddClothing(zombie, fullType, tint, textureChoice)
    local item = instanceItem(fullType)
    if not item then
        print("[EffectSpawnWalterWhite] Failed to create item: " .. tostring(fullType))
        return nil
    end

    local scriptItem = item:getScriptItem()
    if not scriptItem then
        print("[EffectSpawnWalterWhite] Failed to get script item: " .. tostring(fullType))
        return nil
    end

    local visual = zombie:getHumanVisual():addClothingItem(zombie:getItemVisuals(), scriptItem)
    if not visual then
        print("[EffectSpawnWalterWhite] Failed to add clothing visual: " .. tostring(fullType))
        return nil
    end

    visual:setInventoryItem(item)

    if textureChoice ~= nil then
        visual:setTextureChoice(textureChoice)
    end


    if tint then
        visual:setTint(ImmutableColor.new(tint.r, tint.g, tint.b))
    end

    return visual
end

---@param zombie IsoZombie
local function ApplyWalterWhiteVisuals(zombie)
    local humanVisual = zombie:getHumanVisual()
    if not humanVisual then return end

    zombie:getItemVisuals():clear()
    zombie:getWornItems():clear()

    AddClothing(zombie, "Base.Shirt_FormalTINT", MakeTint(112, 163, 101))
    -- AddClothing(zombie, "Base.Suit_Jacket")
    AddClothing(zombie, "Base.Trousers_Suit")
    AddClothing(zombie, "Base.Shoes_Black")
    AddClothing(zombie, "Base.Glasses_Normal", nil, 0)
    -- AddClothing(zombie, "Base.Hat_Fedora", MakeTint(15, 15, 15))

    humanVisual:setHairModel("")

    ---@diagnostic disable-next-line: param-type-mismatch
    humanVisual:setBeardModel("Goatee")

    local beardColor = ImmutableColor.new(102 / 255, 74 / 255, 35 / 255)
    humanVisual:setBeardColor(beardColor)
    humanVisual:setNaturalBeardColor(beardColor)

    zombie:getWornItems():setFromItemVisuals(zombie:getItemVisuals())
    zombie:resetModelNextFrame()
    zombie:onWornItemsChanged()
end

function EffectSpawnWalterWhite:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectSpawnWalterWhite] OnStart " .. tostring(self.effectId))

    local player = getPlayer()
    if not player then return end

    local randomSquare = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, 0, 3, 50, true, true, true)
    if not randomSquare then return end

    local newZombies = ChaosZombie.SpawnZombieAt(
        randomSquare:getX(),
        randomSquare:getY(),
        randomSquare:getZ(),
        1,
        "Naked",
        0
    )

    local zombie = newZombies and newZombies:getFirst() or nil
    if not zombie then return end

    local npc = ChaosNPC:new(zombie)
    npc:initializeHuman()
    npc.npcGroup = ChaosNPCGroupID.COMPANIONS

    ChaosZombie.HumanizeZombie(zombie)
    ApplyWalterWhiteVisuals(zombie)
end
