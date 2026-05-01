---@class EffectBarricadeNearbyWindows : ChaosEffectBase
EffectBarricadeNearbyWindows = ChaosEffectBase:derive("EffectBarricadeNearbyWindows", "barricade_nearby_windows")

local RANGE = 45
local PLANKS_PER_WINDOW = 2

---@param window IsoWindow
---@return table<integer, boolean>
local function getPreferredBarricadeSides(window)
    local sameSq = window:getSquare()
    local outside = sameSq:getRoom() == nil and sameSq or window:getOppositeSquare()
    local addOppositeFirst = outside ~= sameSq

    if addOppositeFirst then
        return { true, false }
    else
        return { false, true }
    end
end

---@param window IsoWindow
---@param addOpposite boolean
---@return IsoBarricade | nil
local function getBarricadeOnSide(window, addOpposite)
    if addOpposite then
        return window:getBarricadeOnOppositeSquare()
    else
        return window:getBarricadeOnSameSquare()
    end
end

---@param window IsoWindow
---@param amount integer
---@param chr IsoGameCharacter | nil
---@return integer, integer
local function addPlanksToWindow(window, amount, chr)
    local remaining = amount
    local added = 0

    for _, addOpposite in ipairs(getPreferredBarricadeSides(window)) do
        if remaining <= 0 then
            break
        end

        local barricade = getBarricadeOnSide(window, addOpposite)
        if barricade == nil then
            barricade = IsoBarricade.AddBarricadeToObject(window, addOpposite)
        end

        if barricade and not barricade:isMetal() and not barricade:isMetalBar() then
            while remaining > 0 and barricade:canAddPlank() do
                ---@diagnostic disable-next-line: param-type-mismatch
                barricade:addPlank(chr, nil)
                remaining = remaining - 1
                added = added + 1
            end

            if isServer() then
                barricade:transmitCompleteItemToClients()
            end
        end
    end

    return added, remaining
end

function EffectBarricadeNearbyWindows:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local x, y, z = square:getX(), square:getY(), square:getZ()
    local windowsBarricaded = 0
    local planksAdded = 0

    ChaosUtils.SquareRingSearchTile_2D(x, y, function(sq)
        if not sq then return end

        ChaosUtils.ForAllObjectsInSquare(sq, function(obj)
            if not obj or not instanceof(obj, "IsoWindow") then
                return false
            end

            ---@type IsoWindow
            local window = obj
            local added = addPlanksToWindow(window, PLANKS_PER_WINDOW, nil)
            if added > 0 then
                windowsBarricaded = windowsBarricaded + 1
                planksAdded = planksAdded + added
            end

            return false
        end)
    end, 0, RANGE, false, false, true, z, z)

    print("[EffectBarricadeNearbyWindows] Barricaded windows: " .. tostring(windowsBarricaded) ..
        ", planks added: " .. tostring(planksAdded))
end
