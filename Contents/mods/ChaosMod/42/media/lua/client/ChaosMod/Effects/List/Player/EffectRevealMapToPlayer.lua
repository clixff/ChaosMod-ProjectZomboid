---@class EffectRevealMapToPlayer : ChaosEffectBase
EffectRevealMapToPlayer = ChaosEffectBase:derive("EffectRevealMapToPlayer", "reveal_map_to_player")

EffectRevealMapToPlayer.IsActive = false
EffectRevealMapToPlayer.IsEventRegistered = false

local function getWorldMapUI()
    ---@diagnostic disable-next-line: undefined-global
    -- ISWorldMap.instance is only set while the map is rendering/open.
    -- ISWorldMap_instance is the vanilla persistent singleton and can still exist after the map is closed.
    return ISWorldMap_instance or ISWorldMap.instance
end

local function setHideUnvisitedAreas(hide)
    local map = getWorldMapUI()
    if map then
        map:setHideUnvisitedAreas(hide)
    end
end

local function applyRevealMapEffect()
    setHideUnvisitedAreas(not EffectRevealMapToPlayer.IsActive)
end

function EffectRevealMapToPlayer:OnStart()
    ChaosEffectBase:OnStart()

    EffectRevealMapToPlayer.IsActive = true
    setHideUnvisitedAreas(false)

    if not EffectRevealMapToPlayer.IsEventRegistered then
        Events.OnRenderTick.Add(applyRevealMapEffect)
        EffectRevealMapToPlayer.IsEventRegistered = true
    end
end

---@param deltaMs integer
function EffectRevealMapToPlayer:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)
    setHideUnvisitedAreas(false)
end

function EffectRevealMapToPlayer:OnEnd()
    ChaosEffectBase:OnEnd()

    EffectRevealMapToPlayer.IsActive = false
    setHideUnvisitedAreas(true)

    if EffectRevealMapToPlayer.IsEventRegistered then
        Events.OnRenderTick.Remove(applyRevealMapEffect)
        EffectRevealMapToPlayer.IsEventRegistered = false
    end
end
