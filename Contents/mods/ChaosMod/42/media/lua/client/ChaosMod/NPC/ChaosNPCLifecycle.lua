function ChaosNPC:initializeHuman()
    if not self.zombie then
        return
    end

    local zombie = self.zombie

    ChaosZombie.HumanizeZombie(zombie)

    zombie:setWalkType(self.walkType)
    zombie:setNoTeeth(true)
    zombie:setVariable("ChaosNPC", true)
    self.weaponItemCached = instanceItem("Base.BareHands")
    zombie:setPrimaryHandItem(nil)
    zombie:setSecondaryHandItem(nil)

    local md = zombie:getModData()
    if md then
        md[CHAOS_NPC_MOD_DATA_KEY] = true
        md[CHAOS_NPC_MOD_DATA_KEY_2] = self
    end

    self.spawnTimeMs = ChaosMod.lastTimeTickMs
    zombie:setVariable("Chaos2HandsWeapon", false)
    zombie:setVariable("ChaosSneak", false)

    self:DisableZombieVoice()

    ChaosNPCUtils.npcList:add(self)
end

---@param worldObj IsoWorldInventoryObject
---@return boolean
function ChaosNPC:IsGroundMeleeWeaponWorldObject(worldObj)
    if not worldObj then return false end

    local item = worldObj:getItem()
    if not item or not item:IsWeapon() then
        return false
    end

    ---@cast item HandWeapon
    return item:isMelee()
end

---@param worldObj IsoWorldInventoryObject
---@return boolean
function ChaosNPC:CanUseGroundMeleeWeaponWorldObject(worldObj)
    if not self:IsGroundMeleeWeaponWorldObject(worldObj) then
        return false
    end

    local owner = self:GetGroundWeaponClaimOwner(worldObj)
    local token = self:GetGroundWeaponClaimToken()
    return owner == nil or owner == token
end

---@return boolean
function ChaosNPC:HasEquippedWeapon()
    local weapon = self.weaponItemCached
    return weapon ~= nil and weapon:getFullType() ~= "Base.BareHands"
end

---@return string
function ChaosNPC:GetGroundWeaponClaimToken()
    return self.actionWorldObjectClaimToken or ""
end

---@param worldObj IsoWorldInventoryObject
---@return string?
function ChaosNPC:GetGroundWeaponClaimOwner(worldObj)
    if not worldObj then return nil end

    local item = worldObj:getItem()
    if not item then return nil end

    local md = item:getModData()
    if not md then return nil end

    local owner = md[CHAOS_NPC_GROUND_WEAPON_CLAIM_KEY]
    if type(owner) ~= "string" or owner == "" then
        return nil
    end

    return owner
end

---@param worldObj IsoWorldInventoryObject
---@return boolean
function ChaosNPC:TryClaimGroundWeapon(worldObj)
    if not worldObj then return false end

    local item = worldObj:getItem()
    if not item then return false end

    local token = self:GetGroundWeaponClaimToken()
    local md = item:getModData()
    if not md then return false end

    local owner = md[CHAOS_NPC_GROUND_WEAPON_CLAIM_KEY]
    if owner and owner ~= token then
        return false
    end

    md[CHAOS_NPC_GROUND_WEAPON_CLAIM_KEY] = token
    return true
end

---@param worldObj IsoWorldInventoryObject
function ChaosNPC:ReleaseGroundWeaponClaim(worldObj)
    if not worldObj then return end

    local item = worldObj:getItem()
    if not item then return end

    local md = item:getModData()
    if not md then return end

    local token = self:GetGroundWeaponClaimToken()
    if md[CHAOS_NPC_GROUND_WEAPON_CLAIM_KEY] == token then
        md[CHAOS_NPC_GROUND_WEAPON_CLAIM_KEY] = nil
    end
end

function ChaosNPC:ClearAction()
    if self.actionType == "pickup_ground_weapon" and self.actionWorldObjectTarget then
        self:ReleaseGroundWeaponClaim(self.actionWorldObjectTarget)
    end

    self.actionType = nil
    self.actionWorldObjectTarget = nil
end

---@param worldObj IsoWorldInventoryObject
function ChaosNPC:StartPickupGroundWeaponAction(worldObj)
    if not self.zombie or not worldObj then return end
    if self.enemy then return end
    if self:HasEquippedWeapon() then return end
    if not self:TryClaimGroundWeapon(worldObj) then return end

    local square = worldObj:getSquare()
    if not square then
        self:ReleaseGroundWeaponClaim(worldObj)
        return
    end

    self.actionType = "pickup_ground_weapon"
    self.actionWorldObjectTarget = worldObj
    self:MoveToLocation(square)
end

---@param worldObj IsoWorldInventoryObject
---@return InventoryItem?
function ChaosNPC:pickGroundItemToPrimary(worldObj)
    if not self.zombie or not worldObj then return nil end

    local character = self.zombie
    local claimOwner = self:GetGroundWeaponClaimOwner(worldObj)
    if claimOwner ~= self:GetGroundWeaponClaimToken() then
        return nil
    end

    local item = worldObj:getItem()
    if not item then return nil end

    InventoryItem.RemoveFromContainer(item)
    self.weaponItemCached = item
    character:setPrimaryHandItem(item)

    if item:IsWeapon() and item.isTwoHandWeapon and item:isTwoHandWeapon() then
        character:setSecondaryHandItem(item)
        character:setVariable("Chaos2HandsWeapon", true)
    else
        ---@diagnostic disable-next-line: param-type-mismatch
        character:setSecondaryHandItem(nil)
        character:setVariable("Chaos2HandsWeapon", false)
    end

    local md = item:getModData()
    if md then
        md[CHAOS_NPC_GROUND_WEAPON_CLAIM_KEY] = nil
    end

    return item
end

function ChaosNPC:setNPCAsZombie()
    if not self.zombie then
        return
    end

    local zombie = self.zombie

    zombie:clearAggroList()
    ---@diagnostic disable-next-line: param-type-mismatch
    zombie:setTarget(nil)
    zombie:getPathFindBehavior2():reset()
    zombie:getPathFindBehavior2():cancel()
    ---@diagnostic disable-next-line: param-type-mismatch
    zombie:setPath2(nil)
    zombie:setVariable("bPathfind", false)
    zombie:setVariable("bMoving", false)
    zombie:setBumpType("")
    zombie:changeState(ZombieIdleState.instance())

    local md = zombie:getModData()
    if md then
        md[CHAOS_NPC_MOD_DATA_KEY] = nil
        md[CHAOS_NPC_MOD_DATA_KEY_2] = nil
    end

    zombie:setNoTeeth(false)
    zombie:setVariable("ChaosNPC", false)
    zombie:setVariable("Chaos2HandsWeapon", false)
    zombie:setVariable("ChaosSneak", false)
    zombie:setUseless(false)
    zombie:Wander()

    self.weaponItemCached = nil
    self.enemy = nil
    self.moveTargetCharacter = nil
    self.moveTargetLocation = nil
    self.lastCachedTargetMoveLocation = nil
    self.moving = false
    self.isAttacking = false
    self.attackAnimTimeMs = 0
    self.attackAnimWindowMs = 0
    self.attackAnimName = nil
    self.attackHitPassed = false
    self.attackObjectTarget = nil
    self.attackObjectType = nil
    self.findEnemyTimeoutMs = 0
    self.findGroundWeaponTimeoutMs = 0
    self.lastZombieThatAttackedNPC = nil
    self:ClearAction()

    local index = ChaosNPCUtils.npcList:indexOf(self)
    if index ~= -1 then
        ChaosNPCUtils.npcList:remove(index)
    end

    self.zombie = nil
end

function ChaosNPC:Destroy()
    if not self.zombie then return end

    local md = self.zombie:getModData()
    if md then
        md[CHAOS_NPC_MOD_DATA_KEY] = nil
        md[CHAOS_NPC_MOD_DATA_KEY_2] = nil
    end

    if not self.zombie then return end

    self.zombie:removeFromWorld()
    self.zombie:removeFromSquare()
    self.zombie = nil
    self.enemy = nil
    self.moveTargetCharacter = nil
    self.moveTargetLocation = nil
    self.moving = false
    self.isAttacking = false
    self.findGroundWeaponTimeoutMs = 0
    self:ClearAction()

    local index = ChaosNPCUtils.npcList:indexOf(self)
    if index ~= -1 then
        ChaosNPCUtils.npcList:remove(index)
    end
end

function ChaosNPC:OnZombieDead()
    if self.zombie then
        local md = self.zombie:getModData()
        if md then
            md[CHAOS_NPC_MOD_DATA_KEY] = nil
            md[CHAOS_NPC_MOD_DATA_KEY_2] = nil
        end
    end

    local isFollowGroup = self.npcGroup == ChaosNPCGroupID.COMPANIONS or
        self.npcGroup == ChaosNPCGroupID.FOLLOWERS
    if isFollowGroup and self.zombie then
        self.zombie:playSound("deathcrash")
        local player = getPlayer()
        if player then
            local name = ChaosNicknames.ensureZombieNicknameAndColor(self.zombie)
            if name then
                player:Say(string.format(ChaosLocalization.GetString("misc", "npc_died"), name))
            end
        end
    end

    self.zombie = nil
    self.enemy = nil
    self.moveTargetCharacter = nil
    self.moveTargetLocation = nil
    self.lastCachedTargetMoveLocation = nil
    self.moving = false
    self.isAttacking = false
    self.attackAnimTimeMs = 0
    self.attackAnimWindowMs = 0
    self.endurance = CHAOS_NPC_ENDURANCE_MAX
    self.canRun = true
    self.findGroundWeaponTimeoutMs = 0
    self:ClearAction()

    local index = ChaosNPCUtils.npcList:indexOf(self)
    if index ~= -1 then
        ChaosNPCUtils.npcList:remove(index)
    end
end

function ChaosNPC:DisableZombieVoice()
    if not self.zombie then return end
    local zombie = self.zombie

    local isFemale = zombie:isFemale()
    local prefix = isFemale and "VoiceFemale" or "VoiceMale"

    local descriptor = zombie:getDescriptor()
    if not descriptor then return end

    descriptor:setVoicePrefix(prefix)
    zombie:setHurtSound(prefix .. "Hurt")
end

---@param weaponFullType string
function ChaosNPC:SetWeapon(weaponFullType)
    if not weaponFullType then return end
    if not self.zombie then return end

    local inventory = self.zombie:getInventory()
    if not inventory then return end

    local oldWeapon = self.weaponItemCached
    if oldWeapon and oldWeapon:getFullType() ~= "Base.BareHands" then
        inventory:Remove(oldWeapon)
        oldWeapon:removeFromWorld()
    end

    local newWeapon = instanceItem(weaponFullType)
    if newWeapon then
        self.weaponItemCached = newWeapon
        self.zombie:setPrimaryHandItem(newWeapon)
        self.zombie:setVariable("Chaos2HandsWeapon", newWeapon:isTwoHandWeapon())
    end
end
