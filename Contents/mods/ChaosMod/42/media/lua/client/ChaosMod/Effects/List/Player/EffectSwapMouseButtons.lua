---@class EffectSwapMouseButtons : ChaosEffectBase
---@field savedBindings table<string, {key: integer, alt: integer}>
EffectSwapMouseButtons = ChaosEffectBase:derive("EffectSwapMouseButtons", "swap_mouse_buttons")

local SWAP_PAIRS = {
    { "Aim", "Attack/Click" },
}

function EffectSwapMouseButtons:OnStart()
    ChaosEffectBase:OnStart()
    local core = getCore()

    self.savedBindings = {}
    for _, pair in ipairs(SWAP_PAIRS) do
        for _, name in ipairs(pair) do
            self.savedBindings[name] = {
                key = core:getKey(name),
                alt = core:getAltKey(name),
            }
        end
    end

    for _, pair in ipairs(SWAP_PAIRS) do
        local a, b = pair[1], pair[2]
        core:addKeyBinding(a, self.savedBindings[b].key, self.savedBindings[b].alt, false, false, false)
        core:addKeyBinding(b, self.savedBindings[a].key, self.savedBindings[a].alt, false, false, false)
    end
end

function EffectSwapMouseButtons:OnEnd()
    ChaosEffectBase:OnEnd()
    if not self.savedBindings then return end

    local core = getCore()
    for name, bind in pairs(self.savedBindings) do
        core:addKeyBinding(name, bind.key, bind.alt, false, false, false)
    end
    self.savedBindings = nil
end
