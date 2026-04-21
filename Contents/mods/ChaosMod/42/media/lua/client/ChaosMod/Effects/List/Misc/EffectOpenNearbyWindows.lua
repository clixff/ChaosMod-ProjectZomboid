EffectOpenNearbyWindows = ChaosEffectBase:derive("EffectOpenNearbyWindows", "open_nearby_windows")

---@param window IsoWindow
---@param player IsoPlayer
---@return boolean
local function forceUnlockAndOpenWindow(window, player)
    if not window or not instanceof(window, "IsoWindow") then
        return false
    end
    window:setPermaLocked(false)
    window:setIsLocked(false)
    window:sync()
    if not window:IsOpen() then
        window:ToggleWindow(player)
    end
    return window:IsOpen()
end

function EffectOpenNearbyWindows:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end
    local square = player:getSquare()
    if not square then return end

    local radius = 35
    local x, y, z = square:getX(), square:getY(), square:getZ()
    local cell = getCell()
    local countOpened = 0

    for dz = -1, 2 do
        for dx = -radius, radius do
            for dy = -radius, radius do
                local sq = cell:getGridSquare(x + dx, y + dy, z + dz)
                if sq then
                    local objects = sq:getObjects()
                    for i = 0, objects:size() - 1 do
                        local obj = objects:get(i)
                        if instanceof(obj, "IsoWindow") then
                            ---@type IsoWindow
                            local window = obj
                            if not window:isSmashed() then
                                if forceUnlockAndOpenWindow(window, player) then
                                    countOpened = countOpened + 1
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    local str = string.format(ChaosLocalization.GetString("misc", "opened_windows"), countOpened)
    ChaosPlayer.SayLineByColor(player, str, ChaosPlayerChatColors.green)
    print("[EffectOpenNearbyWindows] Opened " .. tostring(countOpened) .. " windows")
end
