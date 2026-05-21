---@param character IsoGameCharacter
function ChaosNPC:MoveToCharacter(character)
    if not self.zombie then return end
    if not character then return end

    local zombie = self.zombie
    if zombie:getVehicle() then
        return
    end

    local actionState = zombie:getActionStateName()
    local allowActionState = actionState == "walktoward" or actionState == "idle" or
        actionState == "pathfinding" or actionState == "run"

    if not allowActionState then
        self:StopMoving(true, "not_allowed_action_state")
        return
    end

    local oldCharacter = self.moveTargetCharacter
    local sameCharacter = oldCharacter == character

    self.moveTargetCharacter = character
    self.moveTargetLocation = character:getSquare()

    if not self.moveTargetLocation then
        return
    end

    local x = 0
    local y = 0
    local z = 0

    if self.moveTargetLocation then
        x = self.moveTargetLocation:getX()
        y = self.moveTargetLocation:getY()
        z = self.moveTargetLocation:getZ()
    end

    if not sameCharacter then
        zombie:getPathFindBehavior2():reset()
        zombie:getPathFindBehavior2():cancel()
        ---@diagnostic disable-next-line: param-type-mismatch
        zombie:setPath2(nil)
    end

    if not self.moveTargetCharacter then
        return
    end

    local characterVehicle = self.moveTargetCharacter:getVehicle()
    if characterVehicle then
        zombie:getPathFindBehavior2():pathToLocation(x, y, z)
    else
        ---@diagnostic disable-next-line: param-type-mismatch
        zombie:getPathFindBehavior2():pathToCharacter(self.moveTargetCharacter)
    end

    self.pathfindUpdateMs = 0
    self.moving = true

    local dist = ChaosUtils.distTo(zombie:getX(), zombie:getY(), x, y)
    if dist >= 6.5 or dist <= 3.0 then
        self.walkType = self.canRun and "Run" or "Walk"
    else
        self.walkType = "Walk"
    end

    self.debugLastTimePathfindMs = ChaosMod.lastTimeTickMs
end

---@param force? boolean
---@param reason? string
function ChaosNPC:StopMoving(force, reason)
    force = force or false

    if not self.moving and not force then
        return
    end

    if not self.zombie then
        return
    end

    local zombie = self.zombie
    zombie:getPathFindBehavior2():reset()
    zombie:getPathFindBehavior2():cancel()
    ---@diagnostic disable-next-line: param-type-mismatch
    zombie:setPath2(nil)

    zombie:setVariable("bPathfind", false)
    zombie:setVariable("bMoving", false)
    self.moving = false
end

---@param square IsoGridSquare
function ChaosNPC:MoveToLocation(square)
    if not self.zombie or not square then return end

    local zombie = self.zombie
    if zombie:getVehicle() then return end

    local actionState = zombie:getActionStateName()
    local allowActionState = actionState == "walktoward" or actionState == "idle" or
        actionState == "pathfinding" or actionState == "run"
    if not allowActionState then
        self:StopMoving(true, "not_allowed_action_state")
        return
    end

    self.moveTargetCharacter = nil
    self.moveTargetLocation = square

    local x = square:getX()
    local y = square:getY()
    local z = square:getZ()

    zombie:getPathFindBehavior2():reset()
    zombie:getPathFindBehavior2():cancel()
    ---@diagnostic disable-next-line: param-type-mismatch
    zombie:setPath2(nil)

    zombie:getPathFindBehavior2():pathToLocation(x, y, z)
    self.pathfindUpdateMs = 0
    self.moving = true
    self.walkType = self.canRun and "Run" or "Walk"
    self.debugLastTimePathfindMs = ChaosMod.lastTimeTickMs
end

function ChaosNPC:UpdateNextTargetMoveCharacter()
    if not self.zombie then
        return
    end

    local zombie = self.zombie
    if zombie:isDead() then return end

    local followTarget = self:GetFollowTarget()
    if followTarget then
        self.enemy = nil
        self:MoveToCharacter(followTarget)
    end
end

function ChaosNPC:UpdateWanderTarget()
    if not self.zombie then return end

    local x = math.floor(self.zombie:getX())
    local y = math.floor(self.zombie:getY())
    local z = math.floor(self.zombie:getZ())
    for _ = 1, 20 do
        local dx = ZombRand(5, 16) * (ZombRand(2) == 0 and 1 or -1)
        local dy = ZombRand(5, 16) * (ZombRand(2) == 0 and 1 or -1)
        local sq = getSquare(x + dx, y + dy, z)
        if sq then
            self:MoveToLocation(sq)
            return
        end
    end
end

function ChaosNPC:UpdateSneakAnim()
    if not self.zombie then return end

    local followTarget = self:GetFollowTarget()
    local isSneak = false
    if followTarget and self.enemy == nil then
        local player = getPlayer()
        if player and player:isSneaking() then
            isSneak = true
        end
    end

    self.zombie:setVariable("ChaosSneak", isSneak)
end

-- Per-tick vehicle bookkeeping for NPCs.
--
-- Two independent rules, applied in order:
--
--   1. Exit rule (NPC currently inside a vehicle):
--      stay only while the NPC's enemy or move target is in the same vehicle,
--      otherwise force-exit. This covers both followers (move target = player)
--      and raiders placed via EnterPlayerVehicle (enemy = player) — when the
--      player leaves the vehicle, the NPC drops out next tick.
--
--   2. Enter rule (NPC outside a vehicle):
--      auto-board the move target's vehicle if standing nearby. Disabled when
--      the NPC has an enemy or belongs to RAIDERS — raiders only ever board
--      via the manual EnterPlayerVehicle entry point, never during combat AI.
function ChaosNPC:VehiclesTick()
    if not self.zombie then return end

    local zombieVehicle = self.zombie:getVehicle()

    if zombieVehicle ~= nil then
        local enemyInVehicle = self.enemy ~= nil and self.enemy:getVehicle() == zombieVehicle
        local moveTargetInVehicle = self.moveTargetCharacter ~= nil and
            self.moveTargetCharacter:getVehicle() == zombieVehicle

        if not enemyInVehicle and not moveTargetInVehicle then
            print("[ChaosNPC] VehiclesTick: exit - enemy/move_target not in same vehicle")
            zombieVehicle:exit(self.zombie)
        end
        return
    end

    -- Combat-engaged NPCs never auto-board: fighting takes priority over riding along.
    if self.enemy ~= nil then return end
    -- Raiders are always treated as enemies even before an explicit enemy is picked,
    -- so block them here too. They board exclusively via EnterPlayerVehicle.
    if self.npcGroup == ChaosNPCGroupID.RAIDERS then return end
    if self.moveTargetCharacter == nil then return end

    local moveTargetVehicle = self.moveTargetCharacter:getVehicle()
    if moveTargetVehicle == nil then return end

    -- skipDriver=true: never displace the player from the driver seat.
    local seat = ChaosVehicle.FindFreeSeat(moveTargetVehicle, true)
    if seat < 1 then return end

    local moveTargetSquare = moveTargetVehicle:getSquare()
    if not moveTargetSquare then return end

    -- Require the NPC to physically reach the vehicle before teleporting them in.
    local x1, y1 = moveTargetSquare:getX(), moveTargetSquare:getY()
    local x2, y2 = self.zombie:getX(), self.zombie:getY()

    if not ChaosUtils.isInRange(x1, y1, x2, y2, 4.0) then return end

    print("[ChaosNPC] VehiclesTick: enter - following move_target into vehicle")
    moveTargetVehicle:enter(seat, self.zombie)
end

-- Manually seat this NPC inside the given player's vehicle.
--
-- The only sanctioned way for an enemy/raider NPC to board a vehicle. Called
-- from effect code at spawn time — not from per-tick AI. Aborts if the player
-- isn't currently driving or every passenger seat is taken.
--
-- Sets the player as the NPC's enemy after seating so VehiclesTick's exit rule
-- has a target to compare against; without this, the NPC would be evicted on
-- the very next tick because both enemy and move_target would still be nil.
-- SetAsTargetEnemy → MoveToCharacter is a no-op while in a vehicle, so this
-- assignment is purely informational until the NPC exits.
---@param player IsoGameCharacter
function ChaosNPC:EnterPlayerVehicle(player)
    if not self.zombie then return end
    if not player then return end

    local vehicle = player:getVehicle()
    if not vehicle then
        print("[ChaosNPC] EnterPlayerVehicle: abort - player has no vehicle")
        return
    end

    local seat = ChaosVehicle.FindFreeSeat(vehicle, true)
    if seat < 1 then
        print("[ChaosNPC] EnterPlayerVehicle: abort - no free seat")
        return
    end

    vehicle:enter(seat, self.zombie)
    self:SetAsTargetEnemy(player)

    print("[ChaosNPC] EnterPlayerVehicle: NPC seated in player vehicle, targeting player")
end
