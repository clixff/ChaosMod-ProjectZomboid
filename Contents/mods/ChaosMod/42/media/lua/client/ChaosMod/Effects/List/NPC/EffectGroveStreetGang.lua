---@class EffectGroveStreetGang : ChaosEffectBase
---@field npcs ChaosNPC[]
EffectGroveStreetGang = ChaosEffectBase:derive("EffectGroveStreetGang", "grove_street_gang")

local GANG_COUNT = 3

function EffectGroveStreetGang:OnStart()
    ChaosEffectBase:OnStart()

    self.npcs = {}

    local player = getPlayer()
    if not player then return end

    local npcToHaveWeapon = ChaosUtils.RandIntegerRange(1, GANG_COUNT + 1)

    for _ = 1, GANG_COUNT do
        local randomSquare = ChaosPlayer.GetRandomSquareAroundPlayer(player, nil, 2, 4, 50, true, true, false)
        if randomSquare then
            local newZombies = ChaosZombie.SpawnZombieAt(
                randomSquare:getX(),
                randomSquare:getY(),
                randomSquare:getZ(),
                1,
                "Naked",
                0
            )

            local zombie = newZombies and newZombies:getFirst() or nil
            if zombie then
                local npc = ChaosNPC:new(zombie, self.effectNickname)
                npc:initializeHuman()
                npc.npcGroup = ChaosNPCGroupID.COMPANIONS


                npc:SetHealthGroup(CHAOS_NPC_HEALTH_GROUP.STRONG)

                --- Hair / beard
                if _ == 1 then
                    zombie:getHumanVisual():setHairModel("ShortAfroCurly")
                else
                    zombie:getHumanVisual():setHairModel("Cornrows")
                end
                zombie:getHumanVisual():setHairColor(ImmutableColor.new(0, 0, 0))
                if _ == 2 then
                    zombie:getHumanVisual():setBeardModel("")
                else
                    ---@diagnostic disable-next-line: param-type-mismatch
                    zombie:getHumanVisual():setBeardModel("")
                end

                zombie:getHumanVisual():setBeardColor(ImmutableColor.new(0, 0, 0))
                zombie:getHumanVisual():setNaturalBeardColor(ImmutableColor.new(0, 0, 0))

                --- Remove clothes
                local visuals = zombie:getItemVisuals()

                for i = visuals:size() - 1, 0, -1 do
                    local visual = visuals:get(i)
                    if visual then
                        visuals:clear()
                        zombie:clearWornItems()
                    end
                end

                if _ == 1 then
                    ChaosZombie.AddZombieClothesBatch(zombie, {
                        { type = "Base.Hat_BandanaMask_Green" },
                        { type = "Base.Shoes_TrainerTINT",     tint = ChaosUtils.MakeRGB(1.0, 1.0, 1.0),    textureChoice = 0 },
                        { type = "Base.Shirt_Lumberjack_TINT", tint = ChaosUtils.MakeRGB(62, 131, 47, true) },
                        { type = "Base.Trousers_Suit" }
                    })
                elseif _ == 2 then
                    ChaosZombie.AddZombieClothesBatch(zombie, {
                        { type = "Base.Hat_Bandana_Green" },
                        { type = "Base.Shoes_TrainerTINT",          tint = ChaosUtils.MakeRGB(0.5, 0.5, 0.5),    textureChoice = 0 },
                        { type = "Base.Tshirt_DefaultTEXTURE_TINT", tint = ChaosUtils.MakeRGB(62, 131, 47, true) },
                        { type = "Base.Trousers_Suit" }

                    })
                else
                    ChaosZombie.AddZombieClothesBatch(zombie, {
                        { type = "Base.Trousers_Suit" },
                        { type = "Base.Hat_BandanaMask_Green" },
                        { type = "Base.Hat_BaseballCapTINT_Reverse", tint = ChaosUtils.MakeRGB(0, 0, 0) },
                        { type = "Base.Shoes_TrainerTINT",           tint = ChaosUtils.MakeRGB(1.0, 1.0, 1.0),    textureChoice = 0 },
                        { type = "Base.HoodieDOWN_WhiteTINT",        tint = ChaosUtils.MakeRGB(62, 131, 47, true) },

                    })
                end

                zombie:getHumanVisual():setSkinTextureName("MaleBody04")

                zombie:resetModelNextFrame()

                if npcToHaveWeapon == _ then
                    npc:SetWeapon("Base.BaseballBat")
                    npc.chanceToDropWeaponOnDeath = 0.0
                end

                table.insert(self.npcs, npc)
            end
        end
    end
end

---@param deltaMs integer
function EffectGroveStreetGang:OnTick(deltaMs)
    ChaosEffectBase:OnTick(deltaMs)
end

function EffectGroveStreetGang:OnEnd()
    ChaosEffectBase:OnEnd()

    if self.npcs then
        for _, npc in ipairs(self.npcs) do
            if npc and npc.zombie then
                npc:Destroy(true)
            end
        end
        self.npcs = nil
    end
end
