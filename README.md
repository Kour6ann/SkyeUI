# SkyeUI

A lightweight, modern Roblox UI library with built-in profile saving and interface management.

## ✨ Features
- Clean animated UI (tabs, sections, toggles, sliders, dropdowns, inputs, labels)
- SaveManager for config saving/loading (profiles)
- InterfaceManager for layout persistence & global toggle key
- Extensible theming system
- Easy to integrate with exploits (Synapse, Script-Ware, etc.)

---

## 📦 Installation
Load directly from GitHub:

```lua
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/<user>/SkyeUI/main/lib/SkyeUI.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/<user>/SkyeUI/main/lib/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/<user>/SkyeUI/main/lib/InterfaceManager.lua"))()

Library:SetSaveManager(SaveManager)
Library:SetInterfaceManager(InterfaceManager)
