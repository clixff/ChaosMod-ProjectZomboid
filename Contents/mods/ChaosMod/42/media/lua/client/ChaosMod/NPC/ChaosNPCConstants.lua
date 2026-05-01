CHAOS_NPC_MAX_PATHFIND_UPDATE_MS = 1000
CHAOS_NPC_MAX_FIND_ENEMY_TIMEOUT_MS = 2500
CHAOS_NPC_MOD_DATA_KEY = "is_npc"
CHAOS_NPC_MOD_DATA_KEY_2 = "ChaosNPC"

CHAOS_NPC_TIME_TO_ENABLE_AI_AFTER_SPAWN_MS = 3500
CHAOS_NPC_ATTACK_TIMEOUT_MS = 1500

CHAOS_NPC_ENDURANCE_MAX = 100.0
CHAOS_NPC_ENDURANCE_RUN_DRAIN_PER_SEC = 20.0
CHAOS_NPC_ENDURANCE_ATTACK_DRAIN_HANDS = 7.0
CHAOS_NPC_ENDURANCE_ATTACK_DRAIN_ONE_HAND = 10.0
CHAOS_NPC_ENDURANCE_ATTACK_DRAIN_TWO_HAND = 20.0
CHAOS_NPC_ENDURANCE_IDLE_REGEN_PER_SEC = 15.0
CHAOS_NPC_ENDURANCE_WALK_REGEN_PER_SEC = 5.0
CHAOS_NPC_ENDURANCE_ATTACK_REGEN_PER_SEC = 10.0
CHAOS_NPC_ENDURANCE_RUN_THRESHOLD = 20.0

CHAOS_NPC_ATTACK_ANIMS = {
    HANDS = {
        "ZombieAttackPunch01",
        "ZombieAttackPunch02",
        "ZombieAttackPunch03",
        "ZombieAttackPunch04",
        "ZombieAttackPunch05",
        "ZombieAttackPunch06",
    },
    ONE_HAND = {
        "ZombieAttackMelee1_02",
        "ZombieAttackMelee1_03",
        "ZombieAttackMelee1_06",
        "ZombieAttackMelee1_08",
    },
    TWO_HAND = {
        "ZombieAttackMelee2_01",
        "ZombieAttackMelee2_02",
        "ZombieAttackMelee2_03",
        "ZombieAttackMelee2_04",
    },
}

CHAOS_NPC_ATTACK_GROUND = {
    HANDS = "ZombieAttack_Ground_Hands",
    ONE_HAND = "ZombieAttack_Ground_Melee1",
    TWO_HAND = "ZombieAttack_Ground_Melee2",
}

---@type table<integer, string>
CHAOS_NPC_WINDOW_VEHICLE_PART_BY_SEAT = {
    "WindowFrontLeft",
    "WindowFrontRight",
    "WindowMiddleLeft",
    "WindowMiddleRight",
    "WindowRearLeft",
    "WindowRearRight",
}

CHAOS_NPC_STALKER_TELEPORT_COOLDOWN_MS = 2000
CHAOS_NPC_STALKER_MIN_DIST = 10.0
CHAOS_NPC_STALKER_MAX_DIST = 30.0
CHAOS_NPC_STALKER_TELEPORT_MIN_RADIUS = 15
CHAOS_NPC_STALKER_TELEPORT_MAX_RADIUS = 20
