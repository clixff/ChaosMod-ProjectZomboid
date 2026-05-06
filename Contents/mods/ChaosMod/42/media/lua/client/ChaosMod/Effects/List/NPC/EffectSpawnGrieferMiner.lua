---@class EffectSpawnGrieferMiner : ChaosEffectBase
EffectSpawnGrieferMiner = ChaosEffectBase:derive("EffectSpawnGrieferMiner", "spawn_griefer_miner")

function EffectSpawnGrieferMiner:OnStart()
    ChaosEffectBase:OnStart()
    print("[EffectSpawnGrieferMiner] OnStart " .. tostring(self.effectId))

    local player = getPlayer()
    if not player then return end

    local randomSquare = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, 6, 15, 50, true, true, false)
    if not randomSquare then return end

    local newZombies = ChaosZombie.SpawnZombieAt(
        randomSquare:getX(),
        randomSquare:getY(),
        randomSquare:getZ(),
        1,
        "Naked",
        0
    )

    local zombie = newZombies:getFirst()
    if not zombie then return end

    local npc = ChaosNPC:new(zombie)
    npc:initializeHuman()
    npc.npcGroup = ChaosNPCGroupID.RAIDERS

    zombie:getItemVisuals():clear()
    zombie:getWornItems():clear()

    local function addClothing(fullType, r, g, b)
        local item = instanceItem(fullType)
        if not item then
            print("[EffectSpawnGrieferMiner] Failed to create item: " .. tostring(fullType))
            return
        end

        item:setCustomColor(true)
        item:setColor(Color.new(r, g, b))

        local visual = item:getVisual()
        if visual then
            visual:setTint(ImmutableColor.new(r, g, b))
            zombie:getItemVisuals():add(visual)
        end
    end

    addClothing("Base.Tshirt_DefaultTEXTURE_TINT", 0.32549, 0.64314, 0.60784)
    addClothing("Base.Trousers_DefaultTEXTURE_TINT", 0.24706, 0.19608, 0.55294)
    addClothing("Base.Shoes_TrainerTINT", 0.0, 0.0, 0.0)
    local male = getAllHairStyles(false)


    zombie:getHumanVisual():setHairModel("LeftParting")
    ---@diagnostic disable-next-line: param-type-mismatch
    zombie:getHumanVisual():setBeardModel(nil)
    local haircolor = ImmutableColor.new(53 / 255, 36 / 255, 18 / 255)
    zombie:getHumanVisual():setHairColor(haircolor)
    zombie:getHumanVisual():setNaturalHairColor(haircolor)

    zombie:getWornItems():setFromItemVisuals(zombie:getItemVisuals())
    zombie:resetModelNextFrame()
    zombie:onWornItemsChanged()

    npc:SetWeapon("Base.PickAxe")

    local function addDeathDrop(fullType, count)
        for _ = 1, count do
            local item = instanceItem(fullType)
            if item then
                zombie:addItemToSpawnAtDeath(item)
            else
                print("[EffectSpawnGrieferMiner] Failed to create death drop: " .. tostring(fullType))
            end
        end
    end

    addDeathDrop("Base.Diamond", 5)
    addDeathDrop("Base.IronIngot", 3)
    addDeathDrop("Base.GoldBar", 2)
end
