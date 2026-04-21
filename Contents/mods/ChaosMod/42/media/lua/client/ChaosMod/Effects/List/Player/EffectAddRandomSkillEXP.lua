EffectAddRandomSkillEXP = ChaosEffectBase:derive("EffectAddRandomSkillEXP", "add_random_skill_exp")

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

    player:Say(string.format(ChaosLocalization.GetString("misc", "skill_xp_gained"), randomSkillEXP:getName(), xpAmount))
end
