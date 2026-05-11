[1.1.1]

### New Mod Features

### Mod Fixes

- Fixed chance for "Crouch Mode" and price group for "Hide Effect Names"

### New effects

### Effect Fixes

- Fixed removing bandages from player body parts in effects like "Spawn Robber"
- Updated localization for "Kamikaze Zombies" effect to clarify nearby zombies become kamikaze
- Updated localization for "Zombies Turret" effect to clarify the turret targets zombies

[1.1.0]

### New mod features

- Added settings UI window for configuring mod settings and effects.
- Added dashboard for StreamerApp in browser to configure mod settings and effects.
- Added new command `use_localhost_ip` to set whether the server binds to localhost only (on) or all interfaces (off), and restart the server
- New default donation price groups
- Added `use_animals_nicknames` config option to display Twitch viewer nicknames above follower animals
- Refactored follower animal tracking into a `SpecialAnimal` class
- Moved user `config.json` and `effects.json` to `%UserProfile%\Zomboid\Lua\ChaosMod\`. The mod now ships read-only `default_config.json` and `default_effects.json`; user files are auto-created on first run, and missing keys / new effect ids are merged in from default.
- New Inter-process communication protocol for mod. Lua and Node.js communicates with bridge system in .jsonl files instead of .txt. files.
- Added `streamer_mode.voting_options_number` config (default 4, range 4-8) to control how many voting options are shown each round; chat vote remap range now scales with this value.
- StreamerApp now checks GitHub for the latest version on startup; when a newer version is available it logs the version and download link to the CLI, and exposes the result to the dashboard
- Random Effect voting option now rolls its hidden effect when voting starts (kept secret from `/obs` via a `hidden` API flag) and reveals the rolled effect's localized name on the OBS overlay once voting ends, even if Random Effect didn't win. The hidden effect only enters the recent-effects blocklist if Random Effect actually wins.
- Added `recent_effects_block_buffer` config option (default 60) to control the size of the recently-used effects blocklist in both the mod and StreamerApp.
- Added `effects_duration_multiplier` config option (default 1.0) that scales every effect's duration in game.
- StreamerApp donation parser now also recognizes effect numbers in the donation message via `№<number>`, `!<number>`, and bare `<number>` in addition to `#<id>`.
- StreamerApp can now export effects to a formatted `.xlsx` Excel workbook via `export xlsx` (CLI) and the dashboard's Export card

### Mod fixes

- Updated `obs` command to show the new instructions for setting up the OBS browser source with LAN IP.
- `ChaosUtils.TriggerExplosionAt` now accepts an optional `shouldRemoveProps` parameter (default `true`); when enabled, smashes nearby windows and scatters container items before the explosion
- Increased recent effects cache size from 30 to 60 to prevent duplicates in voting
- Default effect chances are now more balanced and effects have new balanced price groups

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
- All Zombies Are Skeletons
- Spawn Griefer Skeleton

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
- "God Mode" now continuously refreshes invulnerability, heals wounds, resets negative stats, and cures zombie infection every player update
