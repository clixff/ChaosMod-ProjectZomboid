[1.1.0]

### New mod features

- Added new command `use_localhost_ip` to set whether the server binds to localhost only (on) or all interfaces (off), and restart the server
- New default donation price groups
- Added `use_animals_nicknames` config option to display Twitch viewer nicknames above follower animals
- Refactored follower animal tracking into a `SpecialAnimal` class

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
- Temporary Obesity
- Shorter Effects Interval

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
- "Player Lose Weight" was renamed to "Player Is Underweight" (`player_is_underweight`) and now sets weight to 55 Kg
- "Player Gain Weight" was renamed to "Player Is Obese" (`player_is_obese`) and now sets weight to 100 Kg
