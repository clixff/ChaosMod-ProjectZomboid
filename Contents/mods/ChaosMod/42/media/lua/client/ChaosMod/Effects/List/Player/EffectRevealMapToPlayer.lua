---@class EffectRevealMapToPlayer : ChaosEffectBase
EffectRevealMapToPlayer = ChaosEffectBase:derive("EffectRevealMapToPlayer", "reveal_map_to_player")

local function setHideUnvisited(hide)
    local map = ISWorldMap.instance
    if map then
        map:setHideUnvisitedAreas(hide)
    end
end

function EffectRevealMapToPlayer:OnStart()
    ChaosEffectBase:OnStart()
    setHideUnvisited(false)
end

---@param deltaMs integer
function EffectRevealMapToPlayer:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)
    setHideUnvisited(false)
end

function EffectRevealMapToPlayer:OnEnd()
    ChaosEffectBase:OnEnd()
    setHideUnvisited(true)
end
