---@class EffectReverseMovement : ChaosEffectBase
---@field savedBindings table<string, {key: integer, alt: integer}>
EffectReverseMovement = ChaosEffectBase:derive("EffectReverseMovement", "reverse_movement")

local SWAP_PAIRS = {
    { "Forward",  "Backward" },
    { "Left",     "Right" },
}

function EffectReverseMovement:OnStart()
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

function EffectReverseMovement:OnEnd()
    ChaosEffectBase:OnEnd()
    if not self.savedBindings then return end

    local core = getCore()
    for name, bind in pairs(self.savedBindings) do
        core:addKeyBinding(name, bind.key, bind.alt, false, false, false)
    end
    self.savedBindings = nil
end
