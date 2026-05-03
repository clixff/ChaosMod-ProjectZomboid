# Chaos Mod

A single-player chaos mod for **Project Zomboid Build 42**.

The mod adds a random effect system to the game. Every 45 seconds, a new effect is activated. Effects can be helpful, harmful, or just completely random.

The mod currently includes **230+ effects**, such as:

- Spawn a Zombie Nearby
- Give Random Tool
- Enable Rain

Chaos Mod also supports Twitch integration. Viewers can vote for the next effect, and Twitch nicknames can be displayed above zombies.

## Installation

### Method 1 — Steam Workshop

1. Set Project Zomboid to the **unstable** branch in Steam.
2. Download the mod from the [Steam Workshop](https://steamcommunity.com/sharedfiles/filedetails/?id=3717082142).
3. Enable the mod in the game.

### Method 2 — Manual Installation

1. Set Project Zomboid to the **unstable** branch in Steam.
2. Download the latest release from [GitHub](https://github.com/clixff/ChaosMod-ProjectZomboid/releases/latest).
3. Extract the **ChaosModPZ** folder to:

   ```txt
   %UserProfile%/Zomboid/Workshop
   ```

   The final path should look like this:

   ```txt
   C:\Users\YourUsername\Zomboid\Workshop\ChaosModPZ
   ```

---

> This mod requires the **unstable** branch of Project Zomboid on Steam.  
> It has been tested on version **42.17.0**.
>
> To enable the unstable branch, open Project Zomboid properties in Steam, go to **Game Versions & Betas**, and select the **unstable** branch.

---

## Twitch Support

Chaos Mod can be used with Twitch integration.

With Twitch support enabled:

- Viewers can vote for the next effect.
- Twitch nicknames can appear above zombies.
- Voting options can be displayed in OBS.

Twitch integration requires a separate application called **StreamerApp**, which handles the connection between Twitch and the mod.

To vote, viewers can either send the option number in chat or use:

```txt
!vote <number>
```

For example:

```txt
!vote 2
```

The option numbers are displayed in OBS.

### Twitch Support Installation

1. Launch the game with the mod enabled at least once.
2. Download the latest release from [GitHub](https://github.com/clixff/ChaosMod-ProjectZomboid/releases/latest).
3. Extract **ZomboidStreamerApp.exe** to any folder.
4. Launch **ZomboidStreamerApp.exe**.
5. Type the following command in the terminal:

   ```txt
   /login
   ```

6. Complete the login process in your browser.
7. After a successful login, restart the mod in the game.

### OBS Setup

To display voting options in OBS, add a browser source.

Type this command in the StreamerApp terminal to get OBS setup instructions:

```txt
/obs
```

## Donation Effect Support

Chaos Mod supports donation-triggered effects.

This feature uses the same **StreamerApp** that is used for Twitch support.

Currently supported donation services:

- **DonationAlerts**

Viewers can activate effects by donating a specific amount of money and including an effect ID in their donation message.

Supported tag formats:

- `#numeric_id` — uses the numeric ID from `/export csv` and `/mod/effects`
- `#effect_name_id` — uses the internal string effect ID

Example donation message:

```txt
Hello! #spawn_zombie_nearby
```

or:

```txt
Hello! #17
```

### DonationAlerts Setup

1. Enable donation mode:

   ```txt
   /donate_mode on
   ```

2. Start DonationAlerts setup:

   ```txt
   /donate on donationalerts
   ```

   StreamerApp will instruct you to create an application on DonationAlerts and get your `app_id` and `client_secret`.

3. Log in with your DonationAlerts application data:

   ```txt
   /donate on donationalerts <app_id> <client_secret> <currency>
   ```

   Example:

   ```txt
   /donate on donationalerts 1234567890 my_secret RUB
   ```

4. After a successful login, restart the mod in the game.

### Donation Prices Export

You can export donation prices to a CSV file with:

```txt
/export csv
```

The exported CSV file can be imported into Google Sheets and shared with viewers as a donation price table.

The `id` column in the CSV is an integer starting from `1`. The same numeric ID is also returned by the local `/mod/effects` endpoint.

### Editing Donation Prices

Donation prices are configured in:

```txt
config.json
```

The file contains an array of price groups:

```txt
streamer_mode.donate_price_groups
```

You can edit existing groups or add new ones using the same format.

Each effect in `effects.json` also has donation-related properties:

- `enabled_donate` — whether the effect can be activated by donation.
- `price_group` — which donation price group the effect uses.

### Adding Other Donation Services — For Developers

You can add support for other donation services by creating your own application that communicates with the local StreamerApp API.

To get effect prices, send a GET request to:

```txt
http://127.0.0.1:3959/mod/effects
```

Each effect entry includes:

- `id` — numeric ID starting from `1`
- `effect_id` — internal string effect ID such as `spawn_zombie_nearby`
- `price_result` — resolved donation price for that effect

To activate an effect, send a request to:

```txt
http://127.0.0.1:3959/mod/activate-effect?effect=effect_id&nickname=nickname
```

The `effect` query parameter accepts either the numeric `id` or the string `effect_id`.

Example:

```txt
http://127.0.0.1:3959/mod/activate-effect?effect=spawn_zombie_nearby&nickname=ViewerName
```

or:

```txt
http://127.0.0.1:3959/mod/activate-effect?effect=17&nickname=ViewerName
```

## Configuration

You can edit the mod configuration in:

```txt
config.json
```

Config file locations:

### Steam Workshop Installation

```txt
YOUR_STEAM_FOLDER\steamapps\workshop\content\108600\3717082142\mods\ChaosMod\common\config.json
```

### Manual Installation

```txt
%UserProfile%/Zomboid/Workshop/ChaosModPZ/Contents/mods/ChaosMod/common/config.json
```

After changing the config, you need to:

1. Disable and enable the mod in the game.
2. Type this command in the StreamerApp terminal:

   ```txt
   /reload
   ```

### Config Properties

`config.json` contains the following properties:

- `lang` — language code, for example `en` or `fr`.
- `effects_interval_enabled` — enables or disables automatic random effects.
- `effects_interval` — time in seconds between automatic effects.
- `vote_start_time` — time in seconds before voting starts after the effect timer resets.
- `hide_progress_bar` — hides the progress bar if set to `true`.
- `ui` — UI configuration.
- `ui_sounds_enabled` — enables or disables UI sounds.
- `ignore_effect_chances` — if `true`, all effects have equal selection chance.
- `streamer_mode` — streamer mode configuration.

### Streamer Mode Configuration

The `streamer_mode` section contains the following properties:

- `streamer_mode_enabled` — enables or disables streamer mode.
- `voting_enabled` — enables or disables Twitch voting.
- `voting_mode` — voting mode:
  - `0` — normal voting. The option with the most votes wins.
  - `1` — weighted random voting. More votes mean a higher chance to win.
- `type` — streamer mode type. Currently only Twitch is supported.
- `use_localhost_ip` — if `true`, the server binds to `127.0.0.1` (localhost only). If `false`, it binds to all interfaces so OBS on another PC on the same network can connect. Can be changed at runtime with `/use_localhost_ip on|off`.
- `use_zombie_nicknames` — displays Twitch nicknames above zombies.
- `say_killed_zombie_name` — says the name of the killed zombie.
- `zombie_nicknames_buffer` — size of the nickname buffer.
- `enable_donate` — enables or disables donation-triggered effects.
- `donate_providers` — list of donation providers. Currently only DonationAlerts is supported.
- `donate_price_groups` — list of donation price groups.
- `allow_vote_command` — enables the `!vote` command in Twitch chat.
- `hide_votes` — hides vote counts in the OBS overlay.

## Effects Configuration

You can edit effect settings in:

```txt
effects.json
```

Effects file locations:

### Steam Workshop Installation

```txt
YOUR_STEAM_FOLDER\steamapps\workshop\content\108600\3717082142\mods\ChaosMod\common\effects.json
```

### Manual Installation

```txt
%UserProfile%/Zomboid/Workshop/ChaosModPZ/Contents/mods/ChaosMod/common/effects.json
```

After changing `effects.json`, you need to:

1. Disable and enable the mod in the game.
2. Type this command in the StreamerApp terminal:

   ```txt
   /reload
   ```

### Effect Properties

Each effect in `effects.json` can contain the following properties:

- `enabled` — if `true`, the effect can be activated.
- `chance` — effect selection weight, from `0` to `100`.
- `withDuration` — if `true`, the effect has a duration.
- `duration` — effect duration in seconds.
- `disable_effects` — list of effects that will be disabled while this effect is active.
- `enabled_donate` — if `true`, the effect can be activated by donation.
- `price_group` — donation price group used by this effect.

## Languages

Chaos Mod supports multiple languages.

You can change the language with this StreamerApp command:

```txt
/lang <language>
```

Example:

```txt
/lang fr
```

You can also change the language manually in `config.json`.

Supported languages:

- English (`en`)
- French (`fr`)
- German (`de`)
- Spanish (`es`)
- Portuguese (`pt`)
- Russian (`ru`)
- Polish (`pl`)
- Turkish (`tr`)
- Simplified Chinese (`zh`)

## FAQ

### Mod does not work. What should I do?

Make sure you are using the **unstable** branch of Project Zomboid on Steam.

### I want to use only donation effects, without random effects every 45 seconds and without voting. How can I do this?

Open `config.json` and set:

```json
{
  "effects_interval_enabled": false,
  "streamer_mode": {
    "streamer_mode_enabled": true,
    "voting_enabled": false,
    "enable_donate": true
  }
}
```

### I only want to display Twitch nicknames above zombies, without random effects every 45 seconds and without voting. How can I do this?

Open `config.json` and set:

```json
{
  "effects_interval_enabled": false,
  "streamer_mode": {
    "streamer_mode_enabled": true,
    "voting_enabled": false,
    "enable_donate": false,
    "use_zombie_nicknames": true
  }
}
```

### I use OBS Studio on a different PC. How can I use StreamerApp?

Run this command in the StreamerApp terminal:

```txt
/use_localhost_ip off
```

This saves the setting and restarts the server so it accepts connections from other PCs on your network. Then run:

```txt
/obs
```

StreamerApp will show instructions for setting up the OBS browser source with your local network IP.

### Is multiplayer supported?

No. Chaos Mod is designed for single-player only.

## Development

To start make edits in Lua, you will need to install [EmmyLua](https://github.com/EmmyLua/VSCode-EmmyLua) and [Project Zomboid Umbrella](https://github.com/PZ-Umbrella/Umbrella).
After installing Umbrella, set environment variable _PZ_UMBRELLA_ to the path of the Umbrella folder.

## Disclaimer

This mod uses the [json.lua](https://github.com/rxi/json.lua) library.

Copyright (c) rxi

Licensed under the MIT License.

## Special Thanks

Chaos Mod uses the ChaosNPC system, which was inspired by the [Bandits NPC](https://steamcommunity.com/workshop/filedetails/?id=3268487204) mod.
