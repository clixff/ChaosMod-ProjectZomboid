---@class EffectBloodBath : ChaosEffectBase
EffectBloodBath = ChaosEffectBase:derive("EffectBloodBath", "blood_bath")

local RANGE = 8

local function makePlayerFullyBloody(player)
    local bloodBodyPartsMaxIndex = BloodBodyPartType.MAX:index()

    local humanVisual = player:getHumanVisual()
    if humanVisual then
        for i = 0, bloodBodyPartsMaxIndex - 1 do
            local part = BloodBodyPartType.FromIndex(i)
            humanVisual:setBlood(part, 1.0)
        end
    end

    local worn = player:getWornItems()
    if worn then
        for i = 0, worn:size() - 1 do
            local item = worn:getItemByIndex(i)
            local visual = item and item:getVisual()
            if visual then
                for j = 0, bloodBodyPartsMaxIndex - 1 do
                    local part = BloodBodyPartType.FromIndex(j)
                    visual:setBlood(part, 1.0)
                end
            end

            if item and instanceof(item, "Clothing") then
                item:setBloodLevel(100)
            end
        end
    end

    player:resetModelNextFrame()
    player:onWornItemsChanged()
end

function EffectBloodBath:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    local square = player:getSquare()
    if not square then return end

    local px = square:getX()
    local py = square:getY()
    local pz = square:getZ()
    local splats = 0

    ChaosUtils.SquareRingSearchTile_2D(px, py, function(sq)
        if not sq then return end
        addBloodSplat(sq, 70)
        splats = splats + 1
    end, 0, RANGE, false, false, true, pz, pz)

    makePlayerFullyBloody(player)
    print("[EffectBloodBath] Added blood to " .. tostring(splats) .. " squares")
end
