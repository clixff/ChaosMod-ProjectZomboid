[1.1.2]

### New mod features

- Added a centered "ChaosMod v{version} Started / {n} effects" intro overlay that appears for 8 seconds (with a 1-second fade-out) when the mod is started
- Added in-game modal about version mismatch between the mod and StreamerApp and new update modal.
- When a mod version change replaces `effects.json` with the shipped defaults, the previous `effects.json` is now copied to `effects.json.backup` in the same folder first
- Explosions now damage vehicle parts and kick player out of cars
- New vehicles now spawn with random part conditions
- Added Twitch Bits donation system for effects activation
- Added YouTube provider for live chat support for voting and zombie nicknames using your own YouTube Data API key
- OBS vote overlay now shows the effect duration next to its name when the effect has one

### New Effects

- UFO Abduction
- Supersonic
- UFO Abducts Zombies
- Roll Dice

### Mod Fixes

- Fixed localization across all language files: corrected typos and missing diacritics translations
- Twitch viewers without a chat color now get a stable color from the chat palette instead of plain white

### Effect Fixes

- Fixed "Player Can't Stop Coughing" effect not ending after duration

[1.1.1]

### New Mod Features

- On mod version change (tracked via `VERSION.txt` in the Lua folder), both the mod and StreamerApp now fully replace `effects.json` with the shipped defaults to pick up rebalanced chances, durations, and price groups
- Added player knockdown for all explosion effects
- Added Korean and Japanese translations

### Mod Fixes

- Fixed chance for "Crouch Mode" and price group for "Hide Effect Names"
- Fixed "NPC Died" message to only show if NPC has a nickname
- NPCs with weapons now have 20% chance to knock down characters
- NPCs can knock down zombies
- Increased NPC damage to player
- StreamerApp now does not generate effects in JavaScript, and get random effects for vote from Lua.
- Effect `chance` is now a floating-point weight (min `0.0`, no max cap; `0.0` disables the effect). The in-game settings UI, StreamerApp dashboard, and CSV/XLSX exports no longer treat it as a 0-100 percentage and no longer render a `%` suffix.
- Changing the in-game language now immediately updates effect names in the in-game effect selection window, the settings effects list, and currently active effects — previously the names only refreshed after toggling the mod off and on.
- NPCs no longer target zombies that are being grappled by the player (or were reanimated for grapple only)

### Effect Fixes

- Fixed removing bandages from player body parts in effects like "Spawn Robber"
- Updated localization for "Kamikaze Zombies" effect to clarify nearby zombies become kamikaze
- Updated localization for "Zombies Turret" effect to clarify the turret targets zombies
- Fixed "Immortal Zombies" effect
- "Zombies Are Coming" is more powerful now
- "Math Captcha" now adds a calculator to the player's inventory on wrong answer
- Fixed "Zombies Can't See You" effect
- Fixed "Spawn Griefer Skeleton" effect
- "Zombies Rain" effect now spawns zombies more frequently
- "Remove Bandages" effect now does not remove bandages from player body
- Fixed "Disable Sounds" effect
- Fixed Ghost Items in effects like "Hide Player Weapons"
- Effects "Hide Player Clothes", "Hide Player Weapons" now hides items on various locations
- Renamed "Spawn Sprinter Zombie (Random Radius)" → "Spawn Sprinter Zombies" (`spawn_sprinter_zombies`); now has a 10s duration and spawns one sprinter on start and one on end
- Renamed "Spawn Zombie Nearby" → "Spawn Zombies Nearby" (`spawn_zombies_nearby`); now has a 30s duration, spawns multiple zombies over its duration, and spawned zombies path to the player
- "Spawn Few Zombies" effect now spawns a random number of zombies between 4 and 6
- "Fill Area With Zombies" effect now spawns more zombies in a random area around the player
- "Time Rewind" effect now has a 15s duration and rewinds the player across the last 120s of tracked positions
- Fixed "Move Or Get Damage" effect incorrectly damaging the player when walking away and back to the previous square within 1 second; total distance traveled per second is now accumulated each tick
- "DOOM" effect now blocks reloading and unloading rounds on the temporary shotgun for the duration
- "Zombies Turret" effect - added blocking of grabbing and other weapon actions
- "Pig Turret" effect now retargets a nearby zombie every 4 seconds, so the pig rotates to face zombies, and wanders to a random nearby tile every second when no live target is set
- "Refill Car Fuel", "Remove Car Fuel", "Set Random Car Fuel", "Damage Car Engine" effects now display the resulting fuel/engine condition as a green/red chat line on the player
- Effect "Insane Traffic": fix for 42.18.0 version
- Effect "Spawn Barricade Kit": now spawns 9 planks and 9 nails
- Effect "Necromancy": now does not humanize dead zombies, keeps zombie skin
- Effect "Teleport To Nearest Basement": now finds better square to teleport
- Effects "Launch Player Up" and "Launch Everyone Up" now do special actions with custom damage
- Effects "Add Bomb To Player Inventory", "Random Item Bomb", and "Spawn Explosive Spiffos" now show a progress bar countdown to detonation via UI
- Effect "Medieval Times" now shows a green "Modified N zombies" chat line on the player when it adds helmets

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
