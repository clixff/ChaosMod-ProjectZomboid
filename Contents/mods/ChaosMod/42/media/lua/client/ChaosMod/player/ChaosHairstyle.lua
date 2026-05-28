---@class ChaosHairstyleTable
---@field hairModel string? name of hairstyle, nil to skip
---@field beardModel string? name of beard, nil to skip
---@field hairColor ChaosRGB?
---@field beardColor ChaosRGB?
---@field useHairColorForBeard boolean?


---@type table<integer, string>
local MaleHairstyles = {
    "Bald",              -- Bald
    "Picard",            -- Picard
    "CrewCut",           -- Crew Cut
    "Baldspot",          -- Bald Spot
    "Recede",            -- Receding
    "Hat",               -- Hat
    "Messy",             -- Messy
    "Short",             -- Short
    "Donny",             -- Errol Costello
    "Mullet",            -- Mullet
    "Metal",             -- Straight Long
    "Fabian",            -- Fabian
    "PonyTail",          -- Pony Tail
    "FabianCurly",       -- Fabian (Curly)
    "MessyCurly",        -- Messy (Curly)
    "MulletCurly",       -- Mullet (Curly)
    "ShortAfroCurly",    -- Short Afro
    "ShortHatCurly",     -- Short (Curly)
    "CentreParting",     -- Center Parting
    "LeftParting",       -- Left Parting
    "RightParting",      -- Right Parting
    "CentrePartingLong", -- Long Center Parting
    "Cornrows",          -- Cornrows
    "Fresh",             -- Buzz Cut
    "LibertySpikes",     -- Spikes
    "MohawkFan",         -- Mohawk Fan
    "MohawkShort",       -- Mohawk Short
    "MohawkSpike",       -- Mohawk Spike
    "MohawkFlat",        -- Mohawk Flat
    "FlatTop",           -- Flat Top
    "Buffont",           -- Buffont
    "GreasedBack",       -- Greased Back
    "Spike",             -- Ducktail
    "LongBraids",        -- Long Braids
    "PonyTailBraids",    -- Pony Tail Braids
    "LongBraids02",      -- Longer Braids
    "Braids",            -- Braids
    "Grungey",           -- Grungey
    "GrungeyBehindEars", -- Grungey Behind Ears
    "HatLong",           -- HatLong
    "HatLongBraided",    -- HatLongBraided
    "HatLongCurly",      -- HatLongCurly
}

---@type table<integer, string>
local FemaleHairstyles = {
    "Bald",              -- Bald
    "Demi",              -- Crew Cut
    "Spike",             -- Ducktail
    "Hat",               -- Hat
    "OverEye",           -- Over Right Eye
    "Bob",               -- Bob
    "Bun",               -- Bun
    "Back",              -- Pulled Back
    "Long",              -- Lob
    "Kate",              -- Mullet
    "Long2",             -- Long
    "PonyTail",          -- Pony Tail
    "Longcurly",         -- Lob (Curly)
    "Long2curly",        -- Long (Curly)
    "BobCurly",          -- Bob (Curly)
    "BunCurly",          -- Bun (Curly)
    "HatCurly",          -- Hat (Curly)
    "KateCurly",         -- Mullet (Curly)
    "OverEyeCurly",      -- Over Right Eye (Curly)
    "RachelCurly",       -- Raquel (Curly)
    "ShortCurly",        -- Short (Curly)
    "Rachel",            -- Raquel
    "CentreParting",     -- Center Parting
    "CentrePartingLong", -- Long Center Parting
    "LeftParting",       -- Left Parting
    "RightParting",      -- Right Parting
    "TopCurls",          -- Top Curls
    "Grungey",           -- Grungey
    "GrungeyParted",     -- Grungey Parted
    "Cornrows",          -- Cornrows
    "MohawkFan",         -- Mohawk Fan
    "MohawkShort",       -- Mohawk Short
    "MohawkSpike",       -- Mohawk Spike
    "LibertySpikes",     -- Spikes
    "MohawkFlat",        -- Mohawk Flat
    "FlatTop",           -- Flat Top
    "Buffont",           -- Buffont
    "GreasedBack",       -- Greased Back
    "Fresh",             -- Buzz Cut
    "Grungey02",         -- Grungey Long
    "GrungeyBehindEars", -- Grungey Behind Ears
    "OverLeftEye",       -- Over Left Eye
    "LongBraids",        -- Long Braids
    "LongBraids02",      -- Longer Braids
    "Braids",            -- Braids
    "PonyTailBraids",    -- Pony Tail Braids
    "HatLong",           -- HatLong
    "HatLongCurly",      -- HatLongCurly
    "HatLongBraided",    -- HatLongBraided
}

---@type table<integer, string>
local ChaosBeardStyles = {
    "None",        -- None
    "Chops",       -- Chops
    "Moustache",   -- Mustache
    "Goatee",      -- Goatee
    "BeardOnly",   -- Honest Abe
    "Full",        -- Full
    "Long",        -- Long
    "LongScruffy", -- Scruffy
    "Chin",        -- Chin
    "PointyChin",  -- Pointy Chin
}
