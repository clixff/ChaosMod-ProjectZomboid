---@class EffectMidasTouchZombieData
---@field wasUseless boolean
---@field originalSkinIndex integer
---@field initialX number
---@field initialY number
---@field initialZ number

---@class EffectMidasTouch : ChaosEffectBase
---@field affectedZombies table<IsoZombie, EffectMidasTouchZombieData>
EffectMidasTouch = ChaosEffectBase:derive("EffectMidasTouch", "midas_touch")

local GOLD_ITEM_ID = "Base.GoldBar"
local GOLD_MALE_TEXTURE = "ChaosGoldMaleBody01"
local GOLD_FEMALE_TEXTURE = "ChaosGoldFemaleBody01"

---@type EffectMidasTouch?
local activeEffect = nil

---@param zombie IsoZombie
local function GoldifyZombie(zombie)
    if not zombie or zombie:isDead() then return end
    if not activeEffect then return end
    if ChaosNPCUtils.IsNPC(zombie) then return end
    if activeEffect.affectedZombies[zombie] then return end

    local humanVisual = zombie:getHumanVisual()
    if not humanVisual then return end

    activeEffect.affectedZombies[zombie] = {
        wasUseless = zombie:isUseless(),
        originalSkinIndex = humanVisual:getSkinTextureIndex(),
        initialX = zombie:getX(),
        initialY = zombie:getY(),
        initialZ = zombie:getZ(),
    }

    local goldTexture = zombie:isFemale() and GOLD_FEMALE_TEXTURE or GOLD_MALE_TEXTURE
    humanVisual:setSkinTextureName(goldTexture)
    zombie:resetModelNextFrame()
end

---@param attacker IsoGameCharacter
---@param target IsoGameCharacter
---@param _weapon HandWeapon
---@param _damage number
local function OnWeaponHit(attacker, target, _weapon, _damage)
    if not activeEffect then return end
    if not attacker or not target then return end
    if not instanceof(attacker, "IsoPlayer") then return end
    if not instanceof(target, "IsoZombie") then return end
    ---@cast attacker IsoPlayer
    ---@cast target IsoZombie
    if ChaosNPCUtils.IsNPC(target) then return end

    GoldifyZombie(target)

    local inventory = attacker:getInventory()
    if not inventory then return end

    local goldBar = inventory:AddItem(GOLD_ITEM_ID)
    if goldBar then
        ChaosPlayer.SayLineNewItem(attacker, goldBar)
    end
end

function EffectMidasTouch:OnStart()
    ChaosEffectBase:OnStart()
    self.affectedZombies = {}
    activeEffect = self
    Events.OnWeaponHitCharacter.Add(OnWeaponHit)
end

---@param _deltaMs integer
function EffectMidasTouch:OnTick(_deltaMs)
    for zombie, data in pairs(self.affectedZombies) do
        if zombie and zombie:isAlive() then
            zombie:clearAggroList()
            ---@diagnostic disable-next-line: param-type-mismatch
            zombie:setTarget(nil)
            zombie:getPathFindBehavior2():reset()
            zombie:getPathFindBehavior2():cancel()
            ---@diagnostic disable-next-line: param-type-mismatch
            zombie:setPath2(nil)
            zombie:setUseless(true)
            -- zombie:changeState(ZombieIdleState.instance())
            zombie:setBumpType("ZombieTPose")
            zombie:teleportTo(data.initialX, data.initialY, math.floor(data.initialZ))
        end
    end
end

function EffectMidasTouch:OnEnd()
    ChaosEffectBase:OnEnd()
    Events.OnWeaponHitCharacter.Remove(OnWeaponHit)

    for zombie, data in pairs(self.affectedZombies) do
        if zombie and zombie:isAlive() then
            zombie:setUseless(data.wasUseless)
            zombie:setBumpType("")

            local humanVisual = zombie:getHumanVisual()
            if humanVisual then
                ---@diagnostic disable-next-line: param-type-mismatch
                humanVisual:setSkinTextureName(nil)
                humanVisual:setSkinTextureIndex(data.originalSkinIndex)
                zombie:resetModelNextFrame()
            end
        end
    end

    self.affectedZombies = {}
    if activeEffect == self then
        activeEffect = nil
    end
end
