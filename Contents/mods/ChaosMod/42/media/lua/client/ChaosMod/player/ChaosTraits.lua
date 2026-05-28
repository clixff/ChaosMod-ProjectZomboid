---@class ChaosTraits
ChaosTraits = ChaosTraits or {}

---@type CharacterTrait[]
local WeightTraits = {}
---@type table<CharacterTrait, integer>
local TraitWeightOnAdd = {}
---@type CharacterTrait[]
local StrengthTraits = {}
---@type table<CharacterTrait, integer>
local TraitStrengthLevel = {}
---@type CharacterTrait[]
local FitnessTraits = {}
---@type table<CharacterTrait, integer>
local TraitFitnessLevel = {}

local lookupsReady = false

---@param player IsoPlayer
local function syncTraitChange(player)
    if SyncXp then
        SyncXp(player)
    end
end

local function initLookupTables()
    if lookupsReady then return end
    lookupsReady = true

    WeightTraits = {
        CharacterTrait.EMACIATED,
        CharacterTrait.VERY_UNDERWEIGHT,
        CharacterTrait.UNDERWEIGHT,
        CharacterTrait.OVERWEIGHT,
        CharacterTrait.OBESE,
    }
    TraitWeightOnAdd = {
        [CharacterTrait.EMACIATED] = 50,
        [CharacterTrait.VERY_UNDERWEIGHT] = 60,
        [CharacterTrait.UNDERWEIGHT] = 70,
        [CharacterTrait.OVERWEIGHT] = 95,
        [CharacterTrait.OBESE] = 105,
    }
    StrengthTraits = {
        CharacterTrait.WEAK,
        CharacterTrait.FEEBLE,
        CharacterTrait.STOUT,
        CharacterTrait.STRONG,
    }
    TraitStrengthLevel = {
        [CharacterTrait.WEAK] = 1,
        [CharacterTrait.FEEBLE] = 3,
        [CharacterTrait.STOUT] = 7,
        [CharacterTrait.STRONG] = 9,
    }
    FitnessTraits = {
        CharacterTrait.UNFIT,
        CharacterTrait.OUT_OF_SHAPE,
        CharacterTrait.FIT,
        CharacterTrait.ATHLETIC,
    }
    TraitFitnessLevel = {
        [CharacterTrait.UNFIT] = 1,
        [CharacterTrait.OUT_OF_SHAPE] = 3,
        [CharacterTrait.FIT] = 7,
        [CharacterTrait.ATHLETIC] = 9,
    }
end

---@param trait CharacterTrait
---@return boolean
local function isWeightTrait(trait)
    return TraitWeightOnAdd[trait] ~= nil
end

---@param trait CharacterTrait
---@return boolean
local function isStrengthTrait(trait)
    return TraitStrengthLevel[trait] ~= nil
end

---@param trait CharacterTrait
---@return boolean
local function isFitnessTrait(trait)
    return TraitFitnessLevel[trait] ~= nil
end

---@param player IsoPlayer
local function removeWeightTraits(player)
    for _, t in ipairs(WeightTraits) do
        player:getCharacterTraits():remove(t)
    end
end

---@param player IsoPlayer
local function removeStrengthTraits(player)
    for _, t in ipairs(StrengthTraits) do
        player:getCharacterTraits():remove(t)
    end
end

---@param player IsoPlayer
local function removeFitnessTraits(player)
    for _, t in ipairs(FitnessTraits) do
        player:getCharacterTraits():remove(t)
    end
end

---@param player IsoPlayer
---@param traitDef CharacterTraitDefinition
local function applyGrantedRecipes(player, traitDef)
    if not traitDef:hasGrantedRecipes() then return end
    local recipes = traitDef:getGrantedRecipes()
    if not recipes then return end
    for i = 0, recipes:size() - 1 do
        player:learnRecipe(recipes:get(i))
    end
end

---@param player IsoPlayer
---@param trait CharacterTrait
local function applyExtraAddState(player, trait)
    if isWeightTrait(trait) then
        removeWeightTraits(player)
        player:getCharacterTraits():add(trait)
        player:getNutrition():setWeight(TraitWeightOnAdd[trait] or 80)
    elseif isStrengthTrait(trait) then
        removeStrengthTraits(player)
        player:getCharacterTraits():add(trait)
        player:setPerkLevelDebug(Perks.Strength, TraitStrengthLevel[trait] or 5)
        player:getXp():setXPToLevel(Perks.Strength, player:getPerkLevel(Perks.Strength))
    elseif isFitnessTrait(trait) then
        removeFitnessTraits(player)
        player:getCharacterTraits():add(trait)
        player:setPerkLevelDebug(Perks.Fitness, TraitFitnessLevel[trait] or 5)
        player:getXp():setXPToLevel(Perks.Fitness, player:getPerkLevel(Perks.Fitness))
    elseif trait == CharacterTrait.WEIGHT_GAIN then
        player:getCharacterTraits():add(trait)
        player:getCharacterTraits():remove(CharacterTrait.WEIGHT_LOSS)
        removeWeightTraits(player)
        player:getCharacterTraits():add(CharacterTrait.OVERWEIGHT)
        player:getNutrition():setWeight(95)
    elseif trait == CharacterTrait.WEIGHT_LOSS then
        player:getCharacterTraits():add(trait)
        player:getCharacterTraits():remove(CharacterTrait.WEIGHT_GAIN)
        removeWeightTraits(player)
        player:getCharacterTraits():add(CharacterTrait.UNDERWEIGHT)
        player:getNutrition():setWeight(70)
    elseif trait == CharacterTrait.SMOKER then
        player:getCharacterTraits():add(trait)
        player:setTimeSinceLastSmoke(0)
    else
        player:getCharacterTraits():add(trait)
    end
end

---@param player IsoPlayer
---@param trait CharacterTrait
local function applyExtraRemoveState(player, trait)
    if isWeightTrait(trait) then
        player:getCharacterTraits():remove(trait)
        player:getNutrition():setWeight(80)
    elseif isStrengthTrait(trait) then
        player:getCharacterTraits():remove(trait)
        player:setPerkLevelDebug(Perks.Strength, 5)
        player:getXp():setXPToLevel(Perks.Strength, player:getPerkLevel(Perks.Strength))
    elseif isFitnessTrait(trait) then
        player:getCharacterTraits():remove(trait)
        player:setPerkLevelDebug(Perks.Fitness, 5)
        player:getXp():setXPToLevel(Perks.Fitness, player:getPerkLevel(Perks.Fitness))
    elseif trait == CharacterTrait.SMOKER then
        player:getCharacterTraits():remove(trait)
        player:setTimeSinceLastSmoke(0)
    else
        player:getCharacterTraits():remove(trait)
    end
end

---@param player IsoPlayer
---@param trait CharacterTrait
---@return boolean removed
local function removeTraitObject(player, trait)
    if not player or not trait then return false end
    if not player:hasTrait(trait) then return false end

    applyExtraRemoveState(player, trait)
    player:modifyTraitXPBoost(trait, true)
    return true
end

---@param player IsoPlayer
---@param traitDef CharacterTraitDefinition
---@return boolean added
local function addTraitDefinition(player, traitDef)
    if not player or not traitDef then return false end

    local trait = traitDef:getType()
    if not trait or player:hasTrait(trait) then return false end

    if traitDef:hasMutuallyExclusiveTraits() then
        local excluded = traitDef:getMutuallyExclusiveTraits()
        for i = 0, excluded:size() - 1 do
            removeTraitObject(player, excluded:get(i))
        end
    end

    applyExtraAddState(player, trait)
    player:modifyTraitXPBoost(trait, false)
    applyGrantedRecipes(player, traitDef)
    syncTraitChange(player)
    return true
end

---@param player IsoPlayer
---@param wantPositive boolean|nil true = positive, false = negative, nil = either
---@return CharacterTraitDefinition[]
local function collectCandidateTraitDefs(player, wantPositive)
    local out = {}
    local all = CharacterTraitDefinition.getTraits()
    if not all then return out end

    for i = 0, all:size() - 1 do
        local traitDef = all:get(i)
        local cost = traitDef:getCost()
        local trait = traitDef:getType()

        local wanted
        if wantPositive == true then
            wanted = cost > 0
        elseif wantPositive == false then
            wanted = cost < 0
        else
            wanted = cost ~= 0
        end

        if wanted
            and not traitDef:isFree()
            and not player:hasTrait(trait)
            and (not isMultiplayer() or not traitDef:isDisabledInMultiplayer()) then
            out[#out + 1] = traitDef
        end
    end

    return out
end

---@param trait CharacterTrait
---@return string
function ChaosTraits.GetTraitLabel(trait)
    if not trait then return "" end
    local def = CharacterTraitDefinition.getCharacterTraitDefinition(trait)
    if def then
        local label = def:getLabel()
        if label and label ~= "" then return label end
    end
    return trait:getName() or ""
end

---@param player IsoPlayer|nil
---@param wantPositive boolean|nil true = positive, false = negative, nil = either
---@return CharacterTrait|nil addedTrait
function ChaosTraits.AddRandomTrait(player, wantPositive)
    player = player or getPlayer()
    if not player then return nil end
    initLookupTables()

    local candidates = collectCandidateTraitDefs(player, wantPositive)
    if #candidates == 0 then return nil end

    local picked = candidates[ChaosUtils.RandArrayIndex(candidates)]
    if not picked then return nil end
    if addTraitDefinition(player, picked) then
        return picked:getType()
    end
    return nil
end

---@param player IsoPlayer|nil
---@return CharacterTrait|nil
function ChaosTraits.AddRandomPositiveTrait(player)
    return ChaosTraits.AddRandomTrait(player or getPlayer(), true)
end

---@param player IsoPlayer|nil
---@return CharacterTrait|nil
function ChaosTraits.AddRandomNegativeTrait(player)
    return ChaosTraits.AddRandomTrait(player or getPlayer(), false)
end

---@param player IsoPlayer|nil
---@param wantPositive boolean true = positive traits, false = negative traits
---@return integer removedCount
local function removeAllByPolarity(player, wantPositive)
    player = player or getPlayer()
    if not player then return 0 end
    initLookupTables()

    local known = player:getCharacterTraits():getKnownTraits()
    if not known then return 0 end

    local toRemove = {}
    for i = 0, known:size() - 1 do
        local trait = known:get(i)
        local def = CharacterTraitDefinition.getCharacterTraitDefinition(trait)
        if def and not def:isFree() then
            local cost = def:getCost()
            if (wantPositive and cost > 0) or (not wantPositive and cost < 0) then
                toRemove[#toRemove + 1] = trait
            end
        end
    end

    local removed = 0
    for _, trait in ipairs(toRemove) do
        if removeTraitObject(player, trait) then
            removed = removed + 1
        end
    end

    if removed > 0 then syncTraitChange(player) end
    return removed
end

---@param player IsoPlayer|nil
---@return integer removedCount
function ChaosTraits.RemoveAllPositiveTraits(player)
    return removeAllByPolarity(player, true)
end

---@param player IsoPlayer|nil
---@return integer removedCount
function ChaosTraits.RemoveAllNegativeTraits(player)
    return removeAllByPolarity(player, false)
end

---@param player IsoPlayer|nil
---@return CharacterTrait|nil removedTrait
function ChaosTraits.RemoveRandomTrait(player)
    player = player or getPlayer()
    if not player then return nil end
    initLookupTables()

    local known = player:getCharacterTraits():getKnownTraits()
    if not known or known:size() == 0 then return nil end

    local candidates = {}
    for i = 0, known:size() - 1 do
        local trait = known:get(i)
        local def = CharacterTraitDefinition.getCharacterTraitDefinition(trait)
        if def and not def:isFree() then
            candidates[#candidates + 1] = trait
        end
    end

    if #candidates == 0 then return nil end

    local picked = candidates[ChaosUtils.RandArrayIndex(candidates)]
    if not picked then return nil end
    if removeTraitObject(player, picked) then
        syncTraitChange(player)
        return picked
    end
    return nil
end

return ChaosTraits
