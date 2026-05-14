---@class ChaosSpecialActionInstance
---@field data table
---@field maxDuration number -- max duration in milliseconds
---@field elapsedMs number
---@field tickFn fun(deltaMs: integer, data: table)
---@field endFn fun(data: table)
---@field cancelFn (fun(data: table)) | nil

---@class ChaosSpecialAction
---@field actions table<integer, ChaosSpecialActionInstance>
ChaosSpecialAction = ChaosSpecialAction or {
    actions = {}
}

---Register a new special action that runs every tick until its duration expires or the mod is disabled.
---@param data table -- arbitrary data object passed to all callbacks
---@param maxDuration number -- max action duration in milliseconds
---@param tickFn fun(deltaMs: integer, data: table) -- called every tick while active
---@param endFn fun(data: table) -- called once when duration expires naturally
---@param cancelFn (fun(data: table)) | nil -- optional, called when action is cancelled on mod disable
function ChaosSpecialAction.AddNewAction(data, maxDuration, tickFn, endFn, cancelFn)
    if type(data) ~= "table" then
        data = {}
    end
    if type(maxDuration) ~= "number" or maxDuration <= 0 then
        print("[ChaosSpecialAction] Invalid maxDuration")
        return
    end
    if type(tickFn) ~= "function" or type(endFn) ~= "function" then
        print("[ChaosSpecialAction] tick and end callbacks are required")
        return
    end

    ---@type ChaosSpecialActionInstance
    local instance = {
        data = data,
        maxDuration = maxDuration,
        elapsedMs = 0,
        tickFn = tickFn,
        endFn = endFn,
        cancelFn = cancelFn
    }
    table.insert(ChaosSpecialAction.actions, instance)
end

---@param deltaMs integer
function ChaosSpecialAction.OnTick(deltaMs)
    for i = #ChaosSpecialAction.actions, 1, -1 do
        local action = ChaosSpecialAction.actions[i]
        if not action then
            table.remove(ChaosSpecialAction.actions, i)
        else
            action.tickFn(deltaMs, action.data)
            action.elapsedMs = action.elapsedMs + deltaMs
            if action.elapsedMs >= action.maxDuration then
                action.endFn(action.data)
                table.remove(ChaosSpecialAction.actions, i)
            end
        end
    end
end

---Cancels all active actions, calling cancelFn (or endFn if no cancel callback is set).
function ChaosSpecialAction.StopAll()
    for i = #ChaosSpecialAction.actions, 1, -1 do
        local action = ChaosSpecialAction.actions[i]
        if action then
            if action.cancelFn then
                action.cancelFn(action.data)
            end
        end
        ChaosSpecialAction.actions[i] = nil
    end
    ChaosSpecialAction.actions = {}
end

return ChaosSpecialAction
