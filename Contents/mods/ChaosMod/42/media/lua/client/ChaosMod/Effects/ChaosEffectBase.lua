---@class ChaosEffectBase
---@field effectId string
---@field effectName string
---@field effectNickname string | nil
---@field duration number
---@field withDuration boolean
---@field activationTimeMs integer -- At what time the effect was activated (in milliseconds)
---@field ticksActiveTime integer -- How many ticks the effect has been active for (in milliseconds)
---@field maxTicks integer -- How many ticks the effect will be active for (in milliseconds)
---@field showNameAlways boolean?
ChaosEffectBase = {}
ChaosEffectBase.__index = ChaosEffectBase

---@generic T : ChaosEffectBase
---@param className string
---@param effectId string?
---@return T
function ChaosEffectBase:derive(className, effectId)
    ---@type T
    local child = {}
    child.__index = child
    child.super = self
    child.className = className

    -- Inheritance: method lookup goes child -> base
    setmetatable(child, self)

    if effectId then
        ChaosEffectsClassMap[effectId] = child
    end

    return child
end

--- Constructor
---@param effectId string
---@param effectName string
---@param duration number
---@param withDuration boolean
---@param effectNickname string | nil
---@return ChaosEffectBase
function ChaosEffectBase:new(effectId, effectName, duration, withDuration, effectNickname)
    ---@type ChaosEffectBase
    local o = setmetatable({}, self)
    self.__index = self
    o.effectId = effectId
    o.effectName = effectName or ""
    o.effectNickname = effectNickname
    o.duration = duration or 0
    o.withDuration = withDuration
    o.activationTimeMs = 0
    o.ticksActiveTime = 0
    o.maxTicks = 0
    return o
end

-- Called when the effect starts
-- Override in child classes
function ChaosEffectBase:OnStart()
    print("[ChaosEffectBase] OnStart: " .. tostring(self.effectId))
end

-- Called when the effect ends
-- Override in child classes
function ChaosEffectBase:OnEnd()
end

-- Called when the effect is updated
-- Override in child classes
---@param deltaMs integer
function ChaosEffectBase:OnTick(deltaMs)
end
