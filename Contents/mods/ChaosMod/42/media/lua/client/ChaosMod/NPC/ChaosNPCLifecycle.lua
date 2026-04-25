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
