---@class EffectInvisibleCharacters : ChaosEffectBase
EffectInvisibleCharacters = ChaosEffectBase:derive("EffectInvisibleCharacters", "invisible_characters")

function EffectInvisibleCharacters:OnStart()
    ChaosEffectBase:OnStart()
end

---@param deltaMs integer
function EffectInvisibleCharacters:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)

    local cell = getCell()
    local zombies = cell:getZombieList()
    local player = getPlayer()
    if player then
        player:setAlpha(0)
    end

    if not zombies then return end

    for i = 0, zombies:size() - 1 do
        local zombie = zombies:get(i)
        if zombie then
            if zombie:isSceneCulled() == false then
                zombie:setAlpha(0)
            end
        end
    end
end
