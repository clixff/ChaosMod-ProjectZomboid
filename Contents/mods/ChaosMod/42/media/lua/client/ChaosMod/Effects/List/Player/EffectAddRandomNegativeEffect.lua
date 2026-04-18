---@class EffectAddRandomNegativeEffect : ChaosEffectBase
EffectAddRandomNegativeEffect = ChaosEffectBase:derive("EffectAddRandomNegativeEffect", "add_random_negative_effect")

---@param stats Stats
---@param stat CharacterStat
---@param value number
local function setStatIfLower(stats, stat, value)
    if stats:get(stat) < value then
        stats:set(stat, value)
    end
end

---@param stats Stats
---@param stat CharacterStat
---@param value number
local function setStatIfHigher(stats, stat, value)
    if stats:get(stat) > value then
        stats:set(stat, value)
    end
end

function EffectAddRandomNegativeEffect:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local stats = player:getStats()
    local str

    local idx = ZombRand(1, 10)

    if idx == 1 then
        setStatIfLower(stats, CharacterStat.HUNGER, 0.7)
        player:getBodyDamage():setHealthFromFoodTimer(0.0)
        str = "Hunger"
    elseif idx == 2 then
        setStatIfLower(stats, CharacterStat.THIRST, 0.7)
        str = "Thirst"
    elseif idx == 3 then
        setStatIfLower(stats, CharacterStat.FATIGUE, 0.7)
        str = "Fatigue"
    elseif idx == 4 then
        setStatIfHigher(stats, CharacterStat.ENDURANCE, 0.5)
        str = "Endurance"
    elseif idx == 5 then
        setStatIfLower(stats, CharacterStat.INTOXICATION, 100.0)
        str = "Intoxication"
    elseif idx == 6 then
        setStatIfLower(stats, CharacterStat.PANIC, 80)
        str = "Panic"
    elseif idx == 7 then
        setStatIfLower(stats, CharacterStat.STRESS, 0.8)
        str = "Stress"
    elseif idx == 8 then
        setStatIfLower(stats, CharacterStat.BOREDOM, 80.0)
        str = "Boredom"
    elseif idx == 9 then
        setStatIfLower(stats, CharacterStat.WETNESS, 80.0)
        str = "Wetness"
    end

    ChaosPlayer.SayLineByColor(player, string.format(ChaosLocalization.GetString("misc", "negative_effect"), str), ChaosPlayerChatColors.removedItem)
end

function EffectAddRandomNegativeEffect:OnEnd()
    ChaosEffectBase:OnEnd()
end
