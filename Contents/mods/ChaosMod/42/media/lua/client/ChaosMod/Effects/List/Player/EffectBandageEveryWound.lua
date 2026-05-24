local NEW_BANDAGE_TYPE = "Base.AlcoholBandage"
local NEW_BANDAGE_LIFE = 10.0

---@class EffectBandageEveryWound : ChaosEffectBase
EffectBandageEveryWound = ChaosEffectBase:derive("EffectBandageEveryWound", "bandage_every_wound")

function EffectBandageEveryWound:OnStart()
    ChaosEffectBase:OnStart()

    local player = getPlayer()
    if not player then return end

    local bodyDamage = player:getBodyDamage()
    if not bodyDamage then return end

    local inv = player:getInventory()
    local bodyParts = bodyDamage:getBodyParts()
    if not bodyParts then return end

    local count = 0

    for i = 0, bodyParts:size() - 1 do
        local bodyPart = bodyParts:get(i)

        if bodyPart and (bodyPart:HasInjury() or bodyPart:bandaged()) then
            if bodyPart:bandaged() then
                local oldBandageType = bodyPart:getBandageType()
                if oldBandageType and oldBandageType ~= "" then
                    inv:AddItem(oldBandageType)
                end
            end

            bodyDamage:SetBandaged(
                bodyPart:getIndex(),
                true,
                NEW_BANDAGE_LIFE,
                true,
                NEW_BANDAGE_TYPE
            )

            if syncBodyPart then
                syncBodyPart(bodyPart, 0xc001966b8e)
            end

            count = count + 1
        end
    end

    if count > 0 then
        ChaosPlayer.SayLineByColor(player, string.format("Bandaged %d wounds", count),
            ChaosPlayerChatColors.green)
    end
end

function EffectBandageEveryWound:OnEnd()
    ChaosEffectBase:OnEnd()
end
