---@class EffectSpawnRainCollector : ChaosEffectBase
EffectSpawnRainCollector = ChaosEffectBase:derive("EffectSpawnRainCollector", "spawn_rain_collector")

local SPRITE = "carpentry_02_54"

local function attachRainCollectorEntity(obj)
    local spriteName = obj:getSprite():getName()
    local info = SpriteConfigManager.getObjectInfoFromSprite(spriteName)
    if info and info:getScript() and info:getScript():getParent() then
        GameEntityFactory.CreateIsoObjectEntity(obj, info:getScript():getParent(), true)
    end
end

function EffectSpawnRainCollector:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local sq = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, 0, 3, 50, true, true, true)
    if not sq then
        print("[EffectSpawnRainCollector] No square found")
        return
    end

    local barrel = RainCollectorBarrel:new(0, SPRITE, RainCollectorBarrel.smallWaterMax)
    barrel:create(sq:getX(), sq:getY(), sq:getZ(), false, SPRITE)

    local obj = nil
    for i = 0, sq:getObjects():size() - 1 do
        local o = sq:getObjects():get(i)
        if instanceof(o, "IsoThumpable") then
            obj = o
            break
        end
    end

    if obj then
        attachRainCollectorEntity(obj)
        obj:transmitCompleteItemToClients()
    end

    print("[EffectSpawnRainCollector] Spawned rain collector at " .. tostring(sq:getX()) .. ", " .. tostring(sq:getY()))
end
