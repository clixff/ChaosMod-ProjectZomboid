EffectAddRandomWound = ChaosEffectBase:derive("EffectAddRandomWound", "add_random_wound")

function EffectAddRandomWound:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local bodyDamage = player:getBodyDamage()
    if not bodyDamage then return end

    local bodyPartIndex = math.floor(ZombRand(BodyPartType.ToIndex(BodyPartType.Hand_L),
        BodyPartType.ToIndex(BodyPartType.Torso_Lower) + 1))

    local bodyPart = bodyDamage:getBodyPart(BodyPartType.FromIndex(bodyPartIndex))
    if not bodyPart then return end

    bodyPart:setScratched(true, true)

    local pain = bodyDamage:getInitialThumpPain() * BodyPartType.getPainModifyer(bodyPartIndex)
    player:getStats():add(CharacterStat.PAIN, pain)
end
