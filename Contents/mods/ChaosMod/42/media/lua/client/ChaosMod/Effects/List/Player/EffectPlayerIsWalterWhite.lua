---@class EffectPlayerIsWalterWhite : ChaosEffectBase
EffectPlayerIsWalterWhite = ChaosEffectBase:derive("EffectPlayerIsWalterWhite", "player_is_walter_white")

---@param player IsoPlayer
---@param fullType string
---@param tint table?
---@param textureChoice integer?
local function EquipClothing(player, fullType, tint, textureChoice)
    local inventory = player:getInventory()
    if not inventory then return end

    local item = inventory:AddItem(fullType)
    if not item then
        print("[EffectPlayerIsWalterWhite] Failed to create item: " .. tostring(fullType))
        return
    end

    local visual = item:getVisual()
    if visual then
        if textureChoice ~= nil then
            visual:setTextureChoice(textureChoice)
        end
        if tint then
            visual:setTint(ImmutableColor.new(tint.r, tint.g, tint.b))
        end
    end

    ChaosPlayer.EquipClothes(player, item)
end

---@param player IsoPlayer
local function SpawnJessePinkman(player)
    local randomSquare = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, 0, 3, 50, true, true, true)
    if not randomSquare then return end

    local newZombies = ChaosZombie.SpawnZombieAt(
        randomSquare:getX(),
        randomSquare:getY(),
        randomSquare:getZ(),
        1,
        "Naked",
        0
    )

    local zombie = newZombies and newZombies:getFirst() or nil
    if not zombie then return end

    local npc = ChaosNPC:new(zombie, nil)
    npc:SetHealthGroup(CHAOS_NPC_HEALTH_GROUP.STRONG)
    npc:initializeHuman()
    npc.npcGroup = ChaosNPCGroupID.COMPANIONS

    ChaosZombie.HumanizeZombie(zombie)

    zombie:getItemVisuals():clear()
    zombie:getWornItems():clear()

    ChaosZombie.AddZombieClothesBatch(zombie, {
        { type = "Base.Trousers_JeanBaggy",   textureChoice = 1 },
        { type = "Base.Shoes_TrainerTINT",    tint = ChaosUtils.MakeRGB(255, 255, 255, true) },
        { type = "Base.HoodieDOWN_WhiteTINT", tint = ChaosUtils.MakeRGB(253, 190, 59, true) },
        { type = "Base.Hat_Beany",            tint = ChaosUtils.MakeRGB(60, 60, 60, true) },
    })

    ChaosZombie.SetHairstyleAndBeard(zombie, {
        hairModel = "Messy",
        beardModel = "",
        hairColor = ChaosUtils.MakeRGB(89, 56, 30, true),
    })

    npc:SetWeapon("Base.MetalPipe")

    zombie:getWornItems():setFromItemVisuals(zombie:getItemVisuals())
    zombie:resetModelNextFrame()
    zombie:onWornItemsChanged()
end

function EffectPlayerIsWalterWhite:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectPlayerIsWalterWhite] OnStart " .. tostring(self.effectId))

    local player = getPlayer()
    if not player then return end

    -- Walter White is male, so force the player's gender and a fresh body/voice.
    local desc = player:getDescriptor()
    desc:setFemale(false)
    player:setFemale(false)
    SurvivorFactory.setTorso(desc)
    desc:setVoicePrefix("VoiceMale")
    player:setVoiceType(ChaosUtils.RandInteger(4))
    player:setVoicePitch(ChaosUtils.RandFloat(-100.0, 100.0))

    -- Take off whatever the player is currently wearing before the costume.
    ChaosPlayer.UnequipAllClothes(player)

    -- Heisenberg's outfit.
    EquipClothing(player, "Base.Trousers_Suit")
    EquipClothing(player, "Base.Shoes_Black")
    EquipClothing(player, "Base.Glasses_Normal", nil, 0)
    EquipClothing(player, "Base.Shirt_FormalTINT", ChaosUtils.MakeRGB(112, 163, 101, true))

    -- Bald head, brown goatee, plain skin.
    local visual = player:getHumanVisual()
    if visual then
        visual:setSkinTextureName("MaleBody01")
        visual:setHairModel("")
        visual:setBeardModel("Goatee")

        local beardColor = ChaosUtils.MakeRGB(102, 74, 74, true)
        local imColor = ImmutableColor.new(beardColor.r, beardColor.g, beardColor.b)
        visual:setBeardColor(imColor)
        visual:setNaturalBeardColor(imColor)
    end

    player:resetModelNextFrame()

    SpawnJessePinkman(player)
end

function EffectPlayerIsWalterWhite:OnEnd()
    ChaosEffectBase:OnEnd()
end
