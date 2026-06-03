## [1.2.1]

### Mod Fixes and Improvements

- Player model now returns back on mod start if player was playing as animal model before a crash.
- Compatible Streamer App and mod version combinations no longer show the version mismatch or update notification.
  — Updated firearms for NPCs: they do not add wounds to the player, but temporarily reduce his overall health.
- NPC melee hits now rarely cause a wound on the player instead of always wounding.
- Downgrading to an older mod version no longer resets your config and effects settings.

### Effect Fixes and Improvements

- `Temporary Army`: removed debug red line
- `Meteor Shower`: updated cooldown between player damage from 1.5s to 15s
- `Doomsday`: updated cooldown between player damage from 5s to 15s, duration changed from 45s to 30s
- `Griefer Pig Turret`: duration changed from 60s to 30s; now temporarily reduces the player's health instead of adding wounds when it hits them
- `Spinning Characters`: duration changed from 45s to 25s
- `Break All Items`: renamed to `Break Random Items` and now only breaks some items at random instead of everything
- `The Magic Broom`:` duration changed from 60s to 30s
- `Hurricane`: duration changed from 35s to 25s
- `Zombie Magnet`: now shows a red marker on the player
- `Wrath of the Gods`: duration changed from 45s to 30s
- `Doomsday`: removed the earthquake phase
- `Earthquake`: player is now set back on the ground when the effect ends, so they no longer take fall damage

## [1.2.0]

## New Services Support

- Added Twitch Bits support for donation-triggered effects. [Experimental]
- Added Twitch Channel Points support for donation-triggered effects. [Experimental]
- Added Twitch Subs support: every N subs can trigger a random effect. [Experimental]
- Added YouTube live chat support for voting and zombie nicknames using your own YouTube Data API key. [Experimental]
- Added multi-currency support for DonationAlerts. Donations in configured currencies are converted into your main currency before triggering effects. [Experimental]

## Meta Effects System

- Added a new meta-effect system for effects that are triggered with new meta effects interval (15 minutes). Highly configurable.
- `Total Chaos`: makes global effects timer faster
- `Combo Time`: activates 2 or more effects instead of one

### New Mod Features

- Added a centered intro overlay: `ChaosMod v{version} Started / {n} effects`. It appears for 8 seconds when the mod starts, with a 1-second fade-out.
- Added in-game mod/StreamerApp version mismatch modal and update notification modal.
- When a mod update replaces `effects.json` with the shipped defaults, the previous file is now backed up as `effects.json.backup` in the same folder.
- Explosions now damage vehicle parts and eject the player from cars.
- Newly spawned vehicles now have randomized part conditions.
- Added a Streamer Mode setting to disable the hidden `Random` vote option, making every vote choice visible.
- OBS vote overlay now shows effect duration next to the effect name when available.
- Added `INSTALL.txt` to release packages with Steam, manual install, and StreamerApp launch instructions.
- Recent effects blocklist now persists between game sessions, preventing repeated effects right after restarting the game.
- Added a recommended-values hint under the `Recent effects block buffer` setting in both the in-game settings window and StreamerApp dashboard.
- Changing the effects interval or vote start time in the in-game settings now restarts the current iteration, so the progress bar reflects the new timing.
- Export your prices, rewards, and effect tweaks as a shareable Chaos Mod Hub Web App config, so viewers can see exactly what is active on your stream.
- Spawn NPC effects triggered by donations now use the donor’s nickname as the NPC nickname.
- Enemy NPCs can now spawn inside the player’s car and will exit when the player exits.
- NPCs now have a 40% chance to drop their weapon on death. They always drop it if they picked it up from the ground.
- Friendly NPCs can now pick up bandages from the ground and heal themselves when out of combat.
- Friendly NPCs occasionally gift a random item to the player when standing nearby and out of combat.
- NPCs now panic and flee to a nearby spot when surrounded by zombies or when their health is low.
- NPCs can now use handguns, rifles, and shotguns. They can aim, fire, reload, and pick up dropped firearms from the ground.
- Animals can now open doors.
- Explosions now damage every item in the player’s inventory and destroy one random item. Both behaviors can be toggled off in settings.
- Long effect names in the OBS vote overlay now scroll to reveal the full name.
- Added optional Fake and Hidden voting effects, which can disguise the winning effect under a decoy name or briefly hide it from the streamer before revealing it.
- Added a `Hide Effect Names` setting that masks every effect name as `???` in the UI.

### Mod Fixes and Improvements

- Fixed localization issues across all language files, including typos, missing diacritics, and incorrect translations.
- Fixed a Japanese translation bug.
- Fixed an issue where players could not press the options button in some localizations or screen sizes.
- Twitch viewers without a chat color now receive a stable color from the chat palette instead of plain white.
- Fixed a crash that could happen when a vehicle carrying an NPC crashed.
- Spawned zombies now respect the player's Sandbox settings and spawn with randomized health instead of always using `1.00`.
- NPCs now have different health groups: weak, default, and strong.
- Improved NPC AI against zombies.
- Improved overall NPC and Zombie vs NPC AI behavior.
- NPCs now deal more damage to zombies.
- Friendly NPCs now consume 25% less stamina when attacking.
- NPCs now close doors behind them after opening.
- Removed the unused `Voting Type` setting from the in-game settings window and StreamerApp dashboard.
- Removed debug keybinds that dropped weapons and changed the player’s clothes.
- Updated the random item pool used by effects such as `Lootbox`, `Find Chest With Loot`, `Courier`, and similar effects.
- Zombie chat lines now linger briefly after the zombie goes out of sight, so messages no longer vanish instantly.
- Weapons spawned in lootboxes and other effects now spawn with full ammo.

### Effect Fixes and Improvements

- Fixed `Player Can't Stop Coughing` not ending after its duration.
- `Hide Random Items` and `Hide Player Clothes` no longer hide bandages equipped on body parts.
- Updated zombie AI for `Zombies Walk Away`.
- Card-select, random-card, and dice-roll effects now keep the game paused during the reveal and only unpause after the window closes.
- `Necromancy` now spawns zombies if no valid corpses can be found, instead of doing nothing.
- `Player Can't Exit Car` duration changed from 100 seconds to 70 seconds.
- `Toxic Rain` no longer damages the player inside a car if the window near the player’s seat is intact. It can now damage car parts.
- `Vampire Weakness` now damages the player inside a car if the window near the player’s seat is open, broken, or missing.
- `Break Nearby Windows` now also smashes nearby car windows.
- `Give Katana` now equips the katana in both hands.
- `Spawn Trees` now lasts 120 seconds, spawns more trees over a wider area, removes trees when the effect ends, and no longer damages the player from car crashes into spawned trees.
- `Spawn Random L4D2 Companion` now gives the NPC a random melee weapon.
- `Griefer Pig Turret` no longer follows zombies and instead wanders to random squares around the player.
- `Griefer Pig Turret` now deals double damage to zombies.
- `Player Falls` no longer makes the player fall while standing still or while inside a car. Duration changed to 40 seconds.
- `Enable Snow` now sets the temperature to `-22 °C / -7.6 °F`.
- `Lags` now lasts 50 seconds instead of 80 seconds.
- `Launch Player Up` now makes zombies ignore the player for a short time.
- `Spawn Explosive Spiffos`, `Explode Nearby Cars`, and `Blow Up Nearby Corpses` no longer spam explosion sounds when many objects explode at once.
- `Spawn Griefer Santa` now gives the NPC an M9 pistol.
- `NPC Duel` now gives revolvers to spawned NPCs.
- `Spawn Griefer Wizard` now always applies clothes to the NPC. Weapon changed from hammer to long stick.
- `Math Captcha` and `Remember Code` now reward a random item on success.
- `Lootbox` and `Spawn Gift With Loot` now generate 5 items in the gift box.
- Hide-item effects, including clothes, weapons, books, and random items, now show a hint line.
- `Invisible Characters` now also hides zombie nicknames.
- `Swap Mouse Buttons` behavior in combat has been fixed.
- `Teleport To Nearest Basement` now falls back to the most recently scanned basement near the player if no basement is found nearby.
- `Nearby Zombies Are Naked` no longer marks affected zombies as reanimated players.
- `Spawn Stalker` now turns hostile and attacks the player after 90 seconds if left alone.
- `Spinning Characters` now also disables AI for NPCs caught in the effect.
- `Dark Souls Bonfire` sword now spawns broken.
- Fixed the item pool used by effects such as `Spawn Items On Walk`.
- `Give Random Item` has been renamed to `Give Random Items` and now gives 3 items.
- `Disney Princess` no longer kills the spawned animals when it ends; instead you can press G to remove them.
- Renamed "Shorter Effects Interval" to "Faster Effect Timer".
- `Time Rewind`: changed time from 120s to 90s
- `Remove Trees Nearby`: fixed effect
- `Boots With Mines` no longer spawns new mines for 5 seconds after the player triggers an explosion.

### New Effects

- UFO Abduction
- Supersonic
- UFO Abducts Zombies
- Roll Dice
- Zombies Can Smell You
- Spawn Orc Friend
- Spawn Griefer Alien
- Spawn Homer Simpson
- Spawn Doctor
- Spawn Carl Johnson
- NPC Deathmatch
- Rubber Duck Steps
- Hurricane
- The Magic Broom
- Spawn Pirate Companion
- Earthquake
- Equip Bulletproof Vest
- Give Military Backpack
- Midas Touch
- Spawn Fire Chickens
- Zombie Fire Steps
- Player Fire Steps
- Ignite Recent Player Positions
- Spawn Griefer Jesus
- Spawn Griefer Cowboy
- Spawn Cowboy Companion
- Sack Over Head
- Bandage Every Wound
- All Zombies Are Crawlers
- Spawn Mysterious Stranger
- Better Call Saul
- Spawn Agent 47
- Player Can't Knock Down Zombies
- Random Zombies Are Sprinters
- Teleport From Zombies
- Military Supply Drop
- Zombies Magnet
- Energy Shield
- Tame a Caveman
- Cow, the Zombie Killer
- Every Room Has a Zombie
- Female Zombies Spotted You
- Spinning Characters
- Steal Shoes From Every Zombie
- Vertical Video
- Cinema
- Infinite Endurance
- Serial Killer Hunt
- Replace Food With Cat Food
- Replace Food With Dead Rats
- Teleport Into Random Building
- Player Is a Rat
- Repair Cars Nearby
- Add Positive Trait
- Add Negative Trait
- Remove All Positive Traits
- Remove All Negative Traits
- Add Character Trait
- Remove Character Trait
- Need For Speed
- Very Slow Cars
- Player Rolls Effects
- Cursed Clothes
- Sword Aura
- Shadow Clones
- Teleport To Random Old Position
- Spiffo Apocalypse
- Teleport Malfunction
- Reveal Full Map
- Random Skill Max Level
- All Zombies Look Like You
- Grove Street Gang
- Give Random Weapon
- Give Random Melee Weapon
- Give Random Firearm Weapon
- Refuel Cars Nearby
- Spawn Shaun of the Dead
- Zombies Dead by Daylight
- Zombies Have All Car Keys
- Electric Zombies
- Electric Weapons
- Pet Cemetery
- Lootbox Roll
- Traveling Merchant
- Wrath of the Gods
- Spawn Race Car
- Spawn Sports Car
- Meteor Shower
- Kill Zombies With Lightning
- Short Circuit
- Q to Spawn Items
- Christmas
- Medical Supplies Drop
- Add Random Items to Containers
- Explode Nearby Electronics
- Player's Food Is Poisoned
- Nearby Food Is Poisoned
- Give Molotov Cocktails
- Knockback Hits
- Teleport To Last Death
- Skip To Winter
- Camera Pulse
- Zombie Spawner Nearby
- Skyrim Shout
- Fake Teleport
- Temporary Army
- Zombie Hivemind
- Spawn Jay's Employee
- Kill Bill
- Unlock Nearby Cars
- Laser Vision
- Hire Mercenaries
- Battle Royale
- Loot Magnet
- Spawn Zombies In Trees
- Ignite Trees
- Remove Furniture Nearby
- Player Is Walter White
- Spawn Wizard Companion
- Caveman Mode
- Zombie Hydra
- Replace Zombies With Aliens
- Black Hole
- Solar Flare
- Player Is a Chicken
- Blessed Ground
- Scatter Random Items
- Item Rain
- Unstable Portals
- Toxic Puddles
- Slippery Oil Puddles
- Spawn Treasure In World
- Doomsday

## [1.1.1]

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

# [1.1.0]

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
