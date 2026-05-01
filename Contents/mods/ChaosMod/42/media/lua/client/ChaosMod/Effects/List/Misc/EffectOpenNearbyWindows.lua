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

    local Z = square:getZ()

    ChaosUtils.SquareRingSearchTile_2D(x, y, function(sq)
        if sq then
            ChaosUtils.ForAllObjectsInSquare(sq, function(obj)
                if not obj or not instanceof(obj, "IsoWindow") then
                    return false
                end
                ---@type IsoWindow | nil
                local window = obj
                if window and not window:isSmashed() then
                    if forceUnlockAndOpenWindow(window, player) then
                        countOpened = countOpened + 1
                    end
                end
            end)
        end
    end, 0, radius, false, false, true, Z - 1, Z + 3)

    local str = string.format(ChaosLocalization.GetString("misc", "opened_windows"), countOpened)
    ChaosPlayer.SayLineByColor(player, str, ChaosPlayerChatColors.green)
    print("[EffectOpenNearbyWindows] Opened " .. tostring(countOpened) .. " windows")
end
