# Chaos Mod

A single-player chaos mod for **Project Zomboid Build 42**.

The mod adds a random effect system to the game. Every 45 seconds, a new effect is activated. Effects can be helpful, harmful, or just completely random.

The mod currently includes **310+ effects**, such as:

- Spawn a Zombie Nearby
- Give Random Tool
- Enable Rain

You can see the the full list of effects in [Google Sheets](https://docs.google.com/spreadsheets/d/11eyODgqo1gVIdKHx2ZYvHZq6GDGwLoQKZm4SDoZ262I).

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
5. After dashboard is launched in your browser, click on the **"Login"** button in the Twitch section.
6. Complete the login process in your browser

### OBS Setup

To display voting options in OBS, add a browser source.
You can see instructions on how to set up the browser source in the StreamerApp dashboard.

## Donation Effect Support

Chaos Mod supports donation-triggered effects.

This feature uses the same **StreamerApp** that is used for Twitch support.

Currently supported donation services:

- **DonationAlerts**

Viewers can activate effects by donating a specific amount of money and including an effect ID in their donation message.

Supported tag formats:

- `#numeric_id` — uses the numeric ID from `/export csv` and `/mod/effects`
- `№<number>` — numeric ID prefixed with `№`
- `!<number>` — numeric ID prefixed with `!`
- `<number>` — bare numeric ID anywhere in the message

Example donation messages:

```txt
#50 Some message
Hello! №41
!137
Hello! 22
```

### DonationAlerts Setup

You can set up DonationAlerts in the StreamerApp dashboard.

### Donation Prices Export

You can export donation prices to a XLSX file on StreamerApp dashboard.

The exported XLSX file can be imported into Google Sheets and shared with viewers as a donation price table.

The `id` column in the XLSX is an integer starting from `1`. The same numeric ID is also returned by the local `/mod/effects` endpoint.

### Editing Donation Prices

Donation prices are configured in StreamerApp dashboard.

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

You can edit the mod configuration in StreamerApp dashboard or using button with gear icon in game (bottom-left corner).

Raw config file location:

```txt
%UserProfile%\Zomboid\Lua\ChaosMod\config.json
```

## Effects Configuration

You can edit settings for each effect in StreamerApp dashboard or using button with gear icon in game (bottom-left corner).

Raw effects file location:

```txt
%UserProfile%\Zomboid\Lua\ChaosMod\effects.json
```

## Languages

Chaos Mod supports multiple languages.

You can change the language in StreamerApp dashboard or using button with gear icon in game (bottom-left corner).

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

In StreamerApp dashboard set these settings:

- Effects interval enabled: false
- Streamer mode enabled: true
- Voting enabled: false
- Donations enabled: true

### I only want to display Twitch nicknames above zombies, without random effects every 45 seconds and without voting. How can I do this?

In StreamerApp dashboard set these settings:

- Effects interval enabled: false
- Streamer mode enabled: true
- Voting enabled: false
- Donations enabled: false
- Use zombie nicknames: true

### I use OBS Studio on a different PC. How can I use StreamerApp?

In StreamerApp dashboard set this setting:

- Bind to localhost only: false

StreamerApp OBS section now should display correct URL.
If that URL does not work, restart the StreamerApp.

### Is multiplayer supported?

No. Chaos Mod is designed for single-player only.

## Development

To start make edits in Lua, you will need to install [EmmyLua](https://github.com/EmmyLua/VSCode-EmmyLua) and [Project Zomboid Umbrella](https://github.com/PZ-Umbrella/Umbrella).
After installing Umbrella, set environment variable _PZ_UMBRELLA_ to the path of the Umbrella folder.

## How to compile ZomboidStreamerApp.exe by yourself

This is not required if you use precompiled **ZomboidStreamerApp.exe** from releases.

1. Install Bun: [bun.com](https://bun.com/)
2. Use command `bun build --compile --minify index.ts --outfile dist/ZomboidStreamerApp.exe` in StreamerMode folder

## Disclaimer

This mod uses the [json.lua](https://github.com/rxi/json.lua) library.

Copyright (c) rxi

Licensed under the MIT License.

## Special Thanks

Chaos Mod uses the ChaosNPC system, which was inspired by the [Bandits NPC](https://steamcommunity.com/workshop/filedetails/?id=3268487204) mod.
