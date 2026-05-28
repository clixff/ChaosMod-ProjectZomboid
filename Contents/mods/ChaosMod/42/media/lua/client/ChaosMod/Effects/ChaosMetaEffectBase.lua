---@class ChaosMetaEffectBase
---@field effectId string
---@field effectName string
---@field duration number -- scaled duration in seconds
---@field ticksActiveTime integer -- ms elapsed since activation
---@field maxTicks integer -- duration in ms
---@field variables table -- raw variables block from default_config.json
ChaosMetaEffectBase = {}
ChaosMetaEffectBase.__index = ChaosMetaEffectBase

---@type table<string, ChaosMetaEffectBase>
ChaosMetaEffectsClassMap = ChaosMetaEffectsClassMap or {}

---@generic T : ChaosMetaEffectBase
---@param className string
---@param effectId string?
---@return T
function ChaosMetaEffectBase:derive(className, effectId)
    ---@type T
    local child = {}
    child.__index = child
    child.super = self
    child.className = className

    setmetatable(child, self)

    if effectId then
        ChaosMetaEffectsClassMap[effectId] = child
    end

    return child
end

---@param effectId string
---@param effectName string
---@param duration number
---@param variables table
---@return ChaosMetaEffectBase
function ChaosMetaEffectBase:new(effectId, effectName, duration, variables)
    ---@type ChaosMetaEffectBase
    local o = setmetatable({}, self)
    self.__index = self
    o.effectId = effectId
    o.effectName = effectName or ""
    o.duration = duration or 0
    o.variables = variables or {}
    o.ticksActiveTime = 0
    o.maxTicks = math.floor((duration or 0) * 1000)
    return o
end

function ChaosMetaEffectBase:OnStart()
    print("[ChaosMetaEffectBase] OnStart: " .. tostring(self.effectId))
end

function ChaosMetaEffectBase:OnEnd()
end

---@param deltaMs integer
function ChaosMetaEffectBase:OnTick(deltaMs)
end
