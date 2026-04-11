EffectSetRandomHairstyle = ChaosEffectBase:derive("EffectSetRandomHairstyle", "set_random_hairstyle")

function EffectSetRandomHairstyle:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectSetRandomHairstyle] OnStart" .. tostring(self.effectId))

    local player = getPlayer()
    if not player then return end

    local isFemale = player:isFemale()

    -- Get all available styles
    local hairStyles = getAllHairStyles(isFemale)
    local beardStyles = getAllBeardStyles()

    local humanVisual = player:getHumanVisual()

    if hairStyles and hairStyles:size() > 1 then
        local idx = math.floor(ZombRand(hairStyles:size()))
        humanVisual:setHairModel(hairStyles:get(idx))
    end


    if not isFemale and beardStyles and beardStyles:size() > 1 then
        local idx = math.floor(ZombRand(beardStyles:size()))
        humanVisual:setBeardModel(beardStyles:get(idx))
    end

    -- Apply the visual change
    player:resetModel()
end
