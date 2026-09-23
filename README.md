# 🎹 PianoPlayer

A Lua/Luau MIDI piano player designed to play songs generated specifically for PianoPlayer.

> ⚠️ **Important:** PianoPlayer currently **does not support custom Luau scripts**. The player uses only the Lua/Luau script that is hosted in this GitHub repository. Support for custom Luau scripts may be added in a future update.

---

## 🎼 How to Make a MIDI2Lua Song

Use the **Midi2Lua** website to convert your MIDI files into songs compatible with PianoPlayer.

**[🎵 Open Midi2Lua](https://shadowdev1231.github.io/midi2piano)**

### Steps

1. Get a `.mid` / `.midi` file.
2. Open **Midi2Lua**.
3. Upload your MIDI file.
4. Generate the song.
5. Use the generated file with PianoPlayer.

---

## 🚫 Custom Luau Scripts

PianoPlayer currently **does not have support for custom Luau scripts**.

The player only uses the official Lua/Luau player script hosted in this GitHub repository.

You **cannot replace it with your own custom Luau player script** at the moment.

Support for custom scripts may be added in a future update.

---

## 🎹 How to Load PianoPlayer

Use the following Lua/Luau loadstring:

```lua
loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/ShadowDev1231/PianoPlayer/refs/heads/main/main.lua"
))()
```

The script is hosted directly in this GitHub repository and loads the current `main.lua`.

---

## 💬 Community

Have questions, suggestions, or want to discuss PianoPlayer?

**[💬 Join our Discord](https://discord.gg/e5awQvd9wt)**

---

## 👤 Credits

### ShadowDev

Created and maintained by **ShadowDev1231**.

* 🎹 PianoPlayer
* 🎵 Midi2Lua
* 🔧 Development & maintenance

---

## ⭐ Support the Project

If you find PianoPlayer useful, consider giving the repository a ⭐ on GitHub!

More features and improvements are planned for future updates, including possible support for custom Luau scripts.
