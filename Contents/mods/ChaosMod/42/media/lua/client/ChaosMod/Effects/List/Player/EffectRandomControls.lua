---@class EffectRandomControls : ChaosEffectBase
---@field savedBindings table<string, {key: integer, alt: integer}>
EffectRandomControls = ChaosEffectBase:derive("EffectRandomControls", "random_controls")

local MOVEMENT_KEYS = { "Forward", "Backward", "Left", "Right" }

function EffectRandomControls:OnStart()
    ChaosEffectBase:OnStart()
    local core = getCore()

    self.savedBindings = {}
    for _, name in ipairs(MOVEMENT_KEYS) do
        self.savedBindings[name] = {
            key = core:getKey(name),
            alt = core:getAltKey(name),
        }
    end

    local shuffled = {}
    for i, v in ipairs(MOVEMENT_KEYS) do
        shuffled[i] = v
    end
    for i = #shuffled, 2, -1 do
        local j = math.floor(ZombRand(1, i + 1))
        shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
    end

    for i, name in ipairs(MOVEMENT_KEYS) do
        local src = shuffled[i]
        core:addKeyBinding(name, self.savedBindings[src].key, self.savedBindings[src].alt, false, false, false)
    end
end

function EffectRandomControls:OnEnd()
    ChaosEffectBase:OnEnd()
    if not self.savedBindings then return end

    local core = getCore()
    for name, bind in pairs(self.savedBindings) do
        core:addKeyBinding(name, bind.key, bind.alt, false, false, false)
    end
    self.savedBindings = nil
end
