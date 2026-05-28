---@class EffectRandomPlayerAppearance : ChaosEffectBase
EffectRandomPlayerAppearance = ChaosEffectBase:derive("EffectRandomPlayerAppearance", "random_player_appearance")

function EffectRandomPlayerAppearance:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    local desc = player:getDescriptor()
    local female = ChaosUtils.RandInteger(2) == 0

    desc:setFemale(female)
    player:setFemale(female)
    SurvivorFactory.setTorso(desc)
    SurvivorFactory.randomName(desc)

    desc:setVoicePrefix(female and "VoiceFemale" or "VoiceMale")
    player:setVoiceType(ChaosUtils.RandInteger(4))
    player:setVoicePitch(ChaosUtils.RandFloat(-100.0, 100.0))

    local visual = player:getHumanVisual()
    ---@type ArrayList<string>
    local hairStylesArray = ArrayList.new()

    ---@type ArrayList<string>
    local beardStylesArray = ArrayList.new()

    if female then
        hairStylesArray = getAllHairStyles(true)
        -- visual:setHairModel(HairStyles.instance:getRandomFemaleStyle(""))
        -- visual:setBeardModel("")
    else
        hairStylesArray = getAllHairStyles(false)
        beardStylesArray = getAllBeardStyles()

        local randBeardIndex = ChaosUtils.RandInteger(beardStylesArray:size())
        local beardStyle = beardStylesArray:get(randBeardIndex)
        if beardStyle ~= nil or beardStyle == "" then
            visual:setBeardModel(beardStyle)
        end

        local randBeardColor = ImmutableColor.new(ChaosUtils.RandFloat(0, 1), ChaosUtils.RandFloat(0, 1),
            ChaosUtils.RandFloat(0, 1))
        visual:setBeardColor(randBeardColor)
        visual:setNaturalBeardColor(randBeardColor)
    end

    local randHairIndex = ChaosUtils.RandInteger(hairStylesArray:size())
    local hairStyle = hairStylesArray:get(randHairIndex)
    if hairStyle ~= nil or hairStyle == "" then
        visual:setHairModel(hairStyle)
    end

    local randHairColor = ImmutableColor.new(ChaosUtils.RandFloat(0, 1), ChaosUtils.RandFloat(0, 1),
        ChaosUtils.RandFloat(0, 1))

    visual:setHairColor(randHairColor)
    visual:setNaturalHairColor(randHairColor)

    player:resetModelNextFrame()
end

function EffectRandomPlayerAppearance:OnEnd()
    ChaosEffectBase:OnEnd()
end
