[1.1.0]

### New mod features

- Added new command `use_localhost_ip` to set whether the server binds to localhost only (on) or all interfaces (off), and restart the server
- New default donation price groups
- Added `use_animals_nicknames` config option to display Twitch viewer nicknames above follower animals
- Refactored follower animal tracking into a `SpecialAnimal` class
- Moved user `config.json` and `effects.json` to `%UserProfile%\Zomboid\Lua\ChaosMod\`. The mod now ships read-only `default_config.json` and `default_effects.json`; user files are auto-created on first run, and missing keys / new effect ids are merged in from default.

### Mod fixes

- Updated `obs` command to show the new instructions for setting up the OBS browser source with LAN IP.
- `ChaosUtils.TriggerExplosionAt` now accepts an optional `shouldRemoveProps` parameter (default `true`); when enabled, smashes nearby windows and scatters container items before the explosion

### New Effects

- Remove Player Hat
- Hide Effect Names
- Select Card: Remove Items
- Select Card: Add Items
- Equip Bunny Costume
- Equip Spiffo Costume
- Equip Furry Ears
- Spawn Explosive Spiffos
- Spawn Many Explosive Chickens
- Replace Furniture With Zombies
- Food Thief
- Shorter Effects Interval
- Less Inventory Capacity
- More Inventory Capacity
- Random Items Weight More
- Necromancy
- Spawn Griefer Miner
- Teleport To Nearest Bed
- Vampire Weakness
- Toxic Rain
- Remove Nearby Items
- Player Can't Stop Coughing
- Spawn Kamikaze NPC
- Quest: Kill 4 Zombies
- Dark Souls Bonfire
- Pick Up Nearby Items
- Medieval Plague
- Heal Random Wound
- Temporary Obesity
- Start Fire
- Random Item Bomb
- Teleport To Previous Location
- Add Bomb To Player Inventory
- Restore Standard Weight
- Player Can't Eat
- Hide Player's Clothes
- Hide Player's Weapons
- Blow Up Nearby Corpses
- Immortal Zombies
- Remove Medical Items
- Replace Items With Rocks
- Remove Items In Cars
- Find Chest With Loot
- Fill Area With Zombies
- Spawn Random L4D2 Companion
- DOOM
- Medieval Times
- Zombies Turret
- Spawn Walter White
- Pig Turret
- Spawn Annoying Pig
- Zombies Rain
- Spawn Courier
- Food Delivery
- Spawn NPC With Loot
- Bounty On Player Head

### Effect Fixes

- Fixed 'Select Random Card' UI (text wrapping)
- Fixed "Spawn Explosive Flamingo" effect to use movement system
- Renamed "Spawn Chicken" → "Spawn Chicken Follower" (`spawn_chicken_follower`): now follows the player and shows viewer nickname
- Renamed "Spawn Cow" → "Spawn Cow Follower" (`spawn_cow_follower`): now follows the player and shows viewer nickname
- Renamed "Spawn Random Animal" → "Spawn Random Animal Follower" (`spawn_random_animal_follower`): now follows the player and shows viewer nickname
- "Spawn Explosion Chicken" now follows the player and shows viewer nickname until it explodes
- "Math Captcha" now generates random numbers between 0 and 999 and has 20s duration
- "Insanity" effect now spawns some real zombies and has 60s duration
- "Remove Bandages" now removes similar items
- "Spawn Robber" now steals 3 items
- Renamed "Player Gains Weight" → "Player Is Obese" (`player_is_obese`): now sets weight to 100 if below it
- Renamed "Player Loses Weight" → "Player Is Underweight" (`player_is_underweight`): now sets weight to 55 if above it
- "Spawn Stalker" has updated AI and can attack the player
- Renamed "Hide Random Item" → "Hide Random Items" (`hide_random_items`) and now hides 3 random items
- "Force Zoom In" and "Force Zoom Out" now set zoom levels to 25-250%
- Effect "Teleport To Last Used Bed" now uses the saved spawn point if available
- Effect "Insane Traffic" now causes player to take damage from vehicles
- Fixed Courier, Food Delivery, and Spawn NPC With Loot NPC movement to use the ChaosNPC AI movement system correctly
- Increased Courier and Food Delivery spawn distance so they do not appear too close to the player
