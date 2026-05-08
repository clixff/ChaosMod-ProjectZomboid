---@class SpecialAnimal
---@field animal IsoAnimal
---@field followPlayer boolean
---@field renderNickname boolean
---@field repathTicks integer
SpecialAnimal = SpecialAnimal or {}
SpecialAnimal.__index = SpecialAnimal

SpecialAnimal.modDataNameKey = "ChaosModAnimalNickname"
SpecialAnimal.modDataColorKey = "ChaosModAnimalNicknameColor"

---@param animal IsoAnimal
---@return SpecialAnimal
function SpecialAnimal:new(animal)
    local o = {
        animal = animal,
        followPlayer = true,
        renderNickname = true,
        repathTicks = 20
    }
    setmetatable(o, self)
    table.insert(ChaosMod.specialAnimalsFollowers, o)
    ---@diagnostic disable-next-line: return-type-mismatch
    return o
end

---@return boolean
function SpecialAnimal:isDead()
    return not self.animal or self.animal:isDead()
end

---@return string nickname, ChaosZombieNicknameColor color
function SpecialAnimal:ensureNicknameAndColor()
    local animal = self.animal
    if not animal then return "", { r = 1.00, g = 0.00, b = 0.00 } end
    local md = animal:getModData()
    if not md then return "", { r = 1.00, g = 0.00, b = 0.00 } end
    if not md[SpecialAnimal.modDataNameKey] or not md[SpecialAnimal.modDataColorKey] then
        local newName, newColor = ChaosNicknames.GetRandomNickname()
        md[SpecialAnimal.modDataNameKey] = newName
        md[SpecialAnimal.modDataColorKey] = newColor
    end
    return md[SpecialAnimal.modDataNameKey], md[SpecialAnimal.modDataColorKey]
end

local NICKNAME_RENDER_DIST = 15

function SpecialAnimal:tick()
    local animal = self.animal
    if not animal or animal:isDead() then return end

    local player = getPlayer()

    if self.renderNickname and ChaosConfig.IsAnimalsNicknamesEnabled() and player then
        local inRange = ChaosUtils.isInRange(player:getX(), player:getY(), animal:getX(), animal:getY(),
            NICKNAME_RENDER_DIST)
        if inRange then
            local name, color = self:ensureNicknameAndColor()
            if not color then color = { r = 1.00, g = 0.00, b = 0.00 } end
            if animal.addLineChatElement then
                animal:addLineChatElement(name, color.r, color.g, color.b)
            end
        else
            if animal.addLineChatElement then
                animal:addLineChatElement("")
            end
        end
    else
        if animal.addLineChatElement then
            animal:addLineChatElement("")
        end
    end

    if self.followPlayer then
        self.repathTicks = self.repathTicks - 1
        if self.repathTicks <= 0 then
            self.repathTicks = 20
            if player and animal:DistToProper(player) > 2.0 then
                animal:pathToCharacter(player)
            end
        end
    end
end

return SpecialAnimal
