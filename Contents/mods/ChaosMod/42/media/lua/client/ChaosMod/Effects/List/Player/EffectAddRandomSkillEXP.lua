EffectAddRandomSkillEXP = ChaosEffectBase:derive("EffectAddRandomSkillEXP", "add_random_skill_exp")

---@type table<integer, PerkFactory.Perk>
local SKILL_EXP_IDS = {
    Perks.Doctor,
    Perks.Axe,
    Perks.Blunt,
    Perks.Aiming,
    Perks.Reloading,
    Perks.Woodwork,
    Perks.Cooking,
    Perks.Electricity,
    Perks.Mechanics,
    Perks.Tailoring,
    Perks.Fishing,
    Perks.PlantScavenging,
    Perks.Farming,
    Perks.Sprinting,
    Perks.Lightfoot,
    Perks.Sneak,
    Perks.Blacksmith,
    Perks.Butchering,
    Perks.Carpentry,
    Perks.Carving,
    Perks.Combat,
    Perks.Crafting,
    Perks.Husbandry,
    Perks.MetalWelding
}

function EffectAddRandomSkillEXP:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectAddRandomSkillEXP] OnStart " .. tostring(self.effectId))
    local player = getPlayer()
    if not player then return end


    local inventory = player:getInventory()
    if not inventory then return end

    local randomIndex = math.floor(ZombRand(1, #SKILL_EXP_IDS + 1))

    local randomSkillEXP = SKILL_EXP_IDS[randomIndex]
    if not randomSkillEXP then return end

    local xpAmount = 50.0

    addXpNoMultiplier(player, randomSkillEXP, xpAmount)

    player:Say(string.format("%s: +%.0f XP of Skill", randomSkillEXP:getName(), xpAmount))
end
