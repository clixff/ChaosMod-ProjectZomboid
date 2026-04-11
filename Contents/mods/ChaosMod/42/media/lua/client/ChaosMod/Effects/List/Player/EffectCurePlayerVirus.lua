EffectCurePlayerVirus = ChaosEffectBase:derive("EffectCurePlayerVirus", "cure_player_virus")

function EffectCurePlayerVirus:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local bd = player:getBodyDamage()
    local stats = player:getStats()
    bd:setInfected(false)
    bd:setIsFakeInfected(false)
    bd:setInfectionTime(-1)
    bd:setInfectionMortalityDuration(-1)
    local bodyParts = bd:getBodyParts()
    if not bodyParts then return end
    for i = 0, bodyParts:size() - 1 do
        local part = bodyParts:get(i)
        if part then
            part:SetInfected(false)
            part:SetFakeInfected(false)
            part:SetBitten(false)
        end
    end
    stats:reset(CharacterStat.getById("ZombieInfection"))
    stats:reset(CharacterStat.getById("ZombieFever"))
end
