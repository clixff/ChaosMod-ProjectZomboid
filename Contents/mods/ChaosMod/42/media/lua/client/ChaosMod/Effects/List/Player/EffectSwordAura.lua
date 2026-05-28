---@class EffectSwordAura : ChaosEffectBase
---@field worldSwordItem InventoryItem?
---@field worldSwordObj IsoWorldInventoryObject?
---@field anchorSquare IsoGridSquare?
---@field angle number
---@field spin number
---@field lastSquareCheckMs integer
---@field marker WorldMarkers.GridSquareMarker?
---@field damageCooldown table<integer, integer>
EffectSwordAura = ChaosEffectBase:derive("EffectSwordAura", "sword_aura")

---@type string
local SWORD_ITEM_ID = "Base.Sword"
---@type number
local ORBIT_RADIUS = 3.0
---@type number
local DAMAGE_BAND = 1.0
---@type number
local ORBIT_SPEED_DEG_PER_SEC = 180.0 * 1.5
---@type number
local SPIN_SPEED_DEG_PER_SEC = 720.0
---@type number
local SWORD_OFF_Z = 0.0
---@type number
local SWORD_X_ROT = 0.0
---@type number
local SWORD_Y_ROT = 0.0
---@type integer
local HIT_COOLDOWN_MS = 500
---@type integer
local SQUARE_REFRESH_MS = 5000

---@param self EffectSwordAura
local function despawnSword(self)
    if self.worldSwordObj then
        self.worldSwordObj:setHighlighted(0, false, false)
        self.worldSwordObj:setOutlineHighlight(0, false)
        ChaosUtils.RemoveWorldObject(self.worldSwordObj)
    end
    self.worldSwordItem = nil
    self.worldSwordObj = nil
    self.anchorSquare = nil
end

---@param self EffectSwordAura
---@param square IsoGridSquare
local function spawnSwordOnSquare(self, square)
    local item = instanceItem(SWORD_ITEM_ID)
    if not item then return end

    local placedItem = square:AddWorldInventoryItem(item, 0.5, 0.5, SWORD_OFF_Z, false)
    if not placedItem then return end

    local worldObj = placedItem:getWorldItem()
    if not worldObj then return end

    self.worldSwordItem = placedItem
    self.worldSwordObj = worldObj
    self.anchorSquare = square

    worldObj:setHighlighted(0, true, false)
end

---@param self EffectSwordAura
---@param player IsoPlayer
local function updateSwordTransform(self, player)
    local item = self.worldSwordItem
    local worldObj = self.worldSwordObj
    local anchor = self.anchorSquare
    if not item or not worldObj or not anchor then return end

    local rad = math.rad(self.angle)
    local swordX = player:getX() + math.cos(rad) * ORBIT_RADIUS
    local swordY = player:getY() + math.sin(rad) * ORBIT_RADIUS
    local swordZ = player:getZ()

    local offX = swordX - anchor:getX()
    local offY = swordY - anchor:getY()
    local offZ = (swordZ - anchor:getZ()) + SWORD_OFF_Z

    item:setWorldXRotation(SWORD_X_ROT)
    item:setWorldYRotation(SWORD_Y_ROT)
    item:setWorldZRotation(ChaosUtils.Normalize360(self.angle + self.spin))

    worldObj:setOffX(offX)
    worldObj:setOffY(offY)
    worldObj:setOffZ(offZ)
    worldObj:setExtendedPlacement(true)
    worldObj:syncExtendedPlacement()
    worldObj:invalidateRenderChunkLevel(256)
    worldObj:setTargetAlpha(0, 1.0)
end

---@param zombie IsoZombie
---@param player IsoPlayer
---@return boolean
local function isValidTarget(zombie, player)
    if not zombie or not zombie:isAlive() then return false end
    if not ChaosNPCUtils.IsNPC(zombie) then return true end
    local npc = ChaosNPCUtils.GetNPCFromZombie(zombie)
    if not npc then return true end
    local relation = ChaosNPCRelations.GetRelationForNPC(npc, player)
    return relation == ChaosNPCRelationType.ATTACK
end

---@param self EffectSwordAura
---@param player IsoPlayer
local function damageZombiesInBand(self, player)
    local px = player:getX()
    local py = player:getY()
    local pz = player:getZ()
    local outerBand = ORBIT_RADIUS + DAMAGE_BAND
    local now = getTimestampMs()

    ChaosZombie.ForEachZombieInRange(px, py, outerBand, function(zombie)
        local zx = zombie:getX()
        local zy = zombie:getY()
        local dx = zx - px
        local dy = zy - py
        local dist = math.sqrt(dx * dx + dy * dy)
        if not isValidTarget(zombie, player) then return end

        local id = zombie:getID()
        local last = self.damageCooldown[id] or 0
        if now - last < HIT_COOLDOWN_MS then return end
        self.damageCooldown[id] = now

        ---@type HandWeapon?
        local weapon = instanceItem(SWORD_ITEM_ID)
        if not weapon then return end


        local maxDamage = weapon:getMaxDamage()
        zombie:Hit(weapon, player, maxDamage, false, 5.0, false)
        zombie:knockDown(false)
        print("Hit with damage " .. maxDamage)
    end, false, pz)
end

function EffectSwordAura:OnStart()
    ChaosEffectBase:OnStart()
    local player = getPlayer()
    if not player then return end

    self.angle = 0
    self.spin = 0
    self.damageCooldown = {}
    self.lastSquareCheckMs = getTimestampMs()

    local playerSquare = player:getSquare()
    if playerSquare then
        spawnSwordOnSquare(self, playerSquare)

        local markers = getWorldMarkers()
        if markers then
            self.marker = markers:addGridSquareMarker(
                playerSquare,
                1.0, 0.2, 0.2,
                true,
                ORBIT_RADIUS * math.sqrt(2.0)
            )
            if self.marker then
                self.marker:setScaleCircleTexture(false)
            end
        end
    end

    updateSwordTransform(self, player)
end

---@param deltaMs integer
function EffectSwordAura:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)
    local player = getPlayer()
    if not player then return end

    self.angle = ChaosUtils.Normalize360(self.angle + ORBIT_SPEED_DEG_PER_SEC * (deltaMs / 1000.0))
    self.spin = ChaosUtils.Normalize360(self.spin + SPIN_SPEED_DEG_PER_SEC * (deltaMs / 1000.0))

    if self.marker then
        self.marker:setPos(math.floor(player:getX()), math.floor(player:getY()), math.floor(player:getZ()))
    end

    local now = getTimestampMs()
    if now - (self.lastSquareCheckMs or 0) >= SQUARE_REFRESH_MS then
        self.lastSquareCheckMs = now
        local playerSquare = player:getSquare()
        if playerSquare and playerSquare ~= self.anchorSquare then
            despawnSword(self)
            spawnSwordOnSquare(self, playerSquare)
        end
    end

    if not self.worldSwordItem or not self.worldSwordObj or not self.anchorSquare then
        local playerSquare = player:getSquare()
        if playerSquare then
            spawnSwordOnSquare(self, playerSquare)
        end
    end

    updateSwordTransform(self, player)
    damageZombiesInBand(self, player)
end

function EffectSwordAura:OnEnd()
    ChaosEffectBase:OnEnd()
    despawnSword(self)
    if self.marker then
        self.marker:remove()
        self.marker = nil
    end
end
