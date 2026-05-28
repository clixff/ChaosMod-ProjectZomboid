---@class EffectSkipToWinter : ChaosEffectBase
EffectSkipToWinter = ChaosEffectBase:derive("EffectSkipToWinter", "skip_to_winter")

local TARGET_MONTH = 11
local TARGET_DAY = 30
local TARGET_HOUR = 9

function EffectSkipToWinter:OnStart()
    ChaosEffectBase:OnStart()

    local gameTime = GameTime:getInstance()
    if not gameTime then return end

    gameTime:setMonth(TARGET_MONTH)
    gameTime:setDay(TARGET_DAY)
    gameTime:setTimeOfDay(TARGET_HOUR)
    gameTime:updateCalendar(gameTime:getYear(), gameTime:getMonth(), gameTime:getDay(), TARGET_HOUR, 0)

    local cm = ClimateManager.getInstance()
    if cm then
        cm:forceDayInfoUpdate()
    end

    local em = ErosionMain.getInstance()
    if em then
        local seasons = em:getSeasons()
        if seasons then
            seasons:setDay(gameTime:getDay(), gameTime:getMonth(), gameTime:getYear())
        end
        em:snowCheck()
    end

    if cm then
        cm:postCellLoadSetSnow()
    end
end

function EffectSkipToWinter:OnEnd()
    ChaosEffectBase:OnEnd()
end
