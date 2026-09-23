# 🎹 PianoPlayer

A Lua/Luau MIDI piano player that lets you convert MIDI files into Lua and play them through the PianoPlayer script.

> **Note:** Currently, PianoPlayer is designed specifically for scripts generated for this project. Support for custom Lua/Luau piano scripts from other players is planned for a future update.

---

## ✨ Features

* 🎵 Convert MIDI files into Lua/Luau piano scripts
* 🎹 Play converted MIDI songs using PianoPlayer
* ⚡ Simple `loadstring` setup
* 🌐 Web-based MIDI → Lua converter
* 🔧 Custom Lua/Luau player support planned

---

## 🎼 MIDI → Lua

To convert a MIDI file into a PianoPlayer-compatible Lua script, use the **Midi2Lua** converter:

**[🎵 Open Midi2Lua](https://shadowdev1231.github.io/midi2piano)**

### How to use it

1. Open **Midi2Lua**.
2. Upload your `.mid` / `.midi` file.
3. Configure the available options.
4. Generate the Lua script.
5. Use the generated script with PianoPlayer.

---

## 🎹 How to Load PianoPlayer

Run the following Lua/Luau code in your environment:

```lua
loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/ShadowDev1231/PianoPlayer/refs/heads/main/main.lua"
))()
```

This loads the latest version of `main.lua` directly from the repository.

---

## 🛠️ Custom Lua Script Support

At the moment, PianoPlayer does **not** provide a general-purpose API for other players to use their own custom Lua/Luau piano scripts.

This functionality is planned for a future version.

The goal is to make it possible for users to provide their own compatible piano/player scripts instead of being limited to MIDI files generated specifically for PianoPlayer.

---

## 💬 Community

Have questions, suggestions, or want to share your songs?

Join the community on Discord:

**[💬 Join the PianoPlayer Discord](https://discord.gg/e5awQvd9wt)**

---

## 👤 Credits

### ShadowDev

Created and maintained by **ShadowDev1231**.

* 🎹 PianoPlayer
* 🎵 Midi2Lua
* 🔧 Project development and maintenance

---

## 📌 Links

| Resource       | Link                                                              |
| -------------- | ----------------------------------------------------------------- |
| 🎹 PianoPlayer | [GitHub Repository](https://github.com/ShadowDev1231/PianoPlayer) |
| 🎵 Midi2Lua    | [Open Converter](https://shadowdev1231.github.io/midi2piano)      |
| 💬 Discord     | [Join Community](https://discord.gg/e5awQvd9wt)                   |

---

## ⭐ Support the Project

If you find PianoPlayer useful, consider giving the repository a ⭐ on GitHub!

More features and improvements are planned for future releases.
