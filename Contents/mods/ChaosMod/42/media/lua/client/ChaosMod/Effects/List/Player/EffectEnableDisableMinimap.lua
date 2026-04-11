EffectEnableDisableMinimap = ChaosEffectBase:derive("EffectEnableDisableMinimap", "enable_disable_minimap")

---@param visible boolean
local function setMinimapVisibility(visible)
    local minimap = getPlayerMiniMap(0) -- returns ISMiniMapOuter
    if minimap then
        minimap:setVisible(visible)
    end

    getSandboxOptions():set("Map.AllowMiniMap", visible)
    getSandboxOptions():toLua()
    SandboxVars.Map.AllowMiniMap = visible
end

function EffectEnableDisableMinimap:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    local allowMiniMap = SandboxVars.Map.AllowMiniMap
    print("[EffectEnableDisableMinimap] allowMiniMap: " .. tostring(allowMiniMap))
    if allowMiniMap then
        setMinimapVisibility(false)
    else
        setMinimapVisibility(true)
    end
end
