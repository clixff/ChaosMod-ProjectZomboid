---@class EffectSpawnRandomL4D2Companion : ChaosEffectBase
EffectSpawnRandomL4D2Companion = ChaosEffectBase:derive("EffectSpawnRandomL4D2Companion", "spawn_random_l4d2_companion")

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
---@param effectName string
---@param fullType string
---@param tint table?
local function AddClothing(zombie, effectName, fullType, tint)
    local item = instanceItem(fullType)
    if not item then
        print("[" .. effectName .. "] Failed to create item: " .. tostring(fullType))
        return nil
    end

    local scriptItem = item:getScriptItem()
    if not scriptItem then
        print("[" .. effectName .. "] Failed to get script item: " .. tostring(fullType))
        return nil
    end

    local visual = zombie:getHumanVisual():addClothingItem(zombie:getItemVisuals(), scriptItem)
    if not visual then
        print("[" .. effectName .. "] Failed to add clothing visual: " .. tostring(fullType))
        return nil
    end

    if tint then
        visual:setTint(ImmutableColor.new(tint.r, tint.g, tint.b))
    end

    return visual
end

---@param zombie IsoZombie
---@param variant table
local function ApplyVariantVisuals(zombie, variant)
    local humanVisual = zombie:getHumanVisual()
    if not humanVisual then return end

    zombie:getItemVisuals():clear()
    zombie:getWornItems():clear()

    for i = 1, #variant.clothes do
        local clothes = variant.clothes[i]
        AddClothing(zombie, "EffectSpawnRandomL4D2Companion", clothes.fullType, clothes.tint)
    end

    if variant.skinTextureName then
        humanVisual:setSkinTextureName(variant.skinTextureName)
    end

    humanVisual:setHairModel(variant.hairModel or "")

    ---@diagnostic disable-next-line: param-type-mismatch
    humanVisual:setBeardModel(variant.beardModel or "")

    if variant.hairColor then
        local hairColor = ImmutableColor.new(variant.hairColor.r, variant.hairColor.g, variant.hairColor.b)
        humanVisual:setHairColor(hairColor)
        humanVisual:setNaturalHairColor(hairColor)
    end

    zombie:getWornItems():setFromItemVisuals(zombie:getItemVisuals())
    zombie:resetModelNextFrame()
    zombie:onWornItemsChanged()
end

---@type table[]
local variants = {
    {
        femaleChance = 0,
        hairModel = "LeftParting",
        beardModel = "",
        hairColor = MakeTint(28, 21, 18),
        clothes = {
            { fullType = "Base.Suit_JacketTINT",    tint = MakeTint(200, 200, 200) },
            { fullType = "Base.Shirt_FormalTINT",   tint = MakeTint(27, 47, 95) },
            { fullType = "Base.Trousers_WhiteTINT", tint = MakeTint(200, 200, 200) },
            { fullType = "Base.Shoes_Black" }
        }
    },
    {
        femaleChance = 0,
        hairModel = "GreasedBack",
        beardModel = "",
        hairColor = MakeTint(36, 27, 21),
        clothes = {
            { fullType = "Base.Tshirt_DefaultTEXTURE_TINT",   tint = MakeTint(195, 184, 137) },
            { fullType = "Base.Trousers_DefaultTEXTURE_TINT", tint = MakeTint(71, 71, 75) },
            { fullType = "Base.Shoes_TrainerTINT",            tint = MakeTint(0, 0, 0) },
            { fullType = "Base.Hat_BaseballCap_3N" }
        }
    },
    {
        femaleChance = 0,
        skinTextureName = "MaleBody05",
        hairModel = nil,
        beardModel = "",
        hairColor = nil,
        clothes = {
            { fullType = "Base.Tshirt_DefaultTEXTURE_TINT",   tint = MakeTint(94, 79, 104) },
            { fullType = "Base.Trousers_DefaultTEXTURE_TINT", tint = MakeTint(68, 59, 46) },
            { fullType = "Base.Shoes_TrainerTINT",            tint = MakeTint(0, 0, 0) }
        }
    },
    {
        femaleChance = 100,
        skinTextureName = "FemaleBody04",
        hairModel = "PonyTail",
        beardModel = "",
        hairColor = MakeTint(12, 10, 10),
        clothes = {
            { fullType = "Base.Tshirt_PoloTINT",              tint = MakeTint(158, 76, 104) },
            { fullType = "Base.Trousers_DefaultTEXTURE_TINT", tint = MakeTint(53, 57, 60) },
            { fullType = "Base.Shoes_WorkBoots",              tint = MakeTint(0, 0, 0) }
        }
    }
}

function EffectSpawnRandomL4D2Companion:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectSpawnRandomL4D2Companion] OnStart " .. tostring(self.effectId))

    local player = getPlayer()
    if not player then return end

    local variant = variants[ChaosUtils.RandArrayIndex(variants)]
    if not variant then return end

    local randomSquare = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, 0, 3, 50, true, true, true)
    if not randomSquare then return end

    local newZombies = ChaosZombie.SpawnZombieAt(
        randomSquare:getX(),
        randomSquare:getY(),
        randomSquare:getZ(),
        1,
        "Naked",
        variant.femaleChance
    )

    local zombie = newZombies and newZombies:getFirst() or nil
    if not zombie then return end

    local npc = ChaosNPC:new(zombie)
    npc:initializeHuman()
    npc.npcGroup = ChaosNPCGroupID.COMPANIONS

    ChaosZombie.HumanizeZombie(zombie)
    ApplyVariantVisuals(zombie, variant)
end
