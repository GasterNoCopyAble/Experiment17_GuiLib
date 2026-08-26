# Experiment 17 UI Library

Dark modular Roblox UI library with desktop/mobile input, configs, themes, RGB, gradients, notifications, search, favorites, keybinds, profiles, startup prompts, and reusable controls.

Current stable architecture: **v22**.

## Load

```lua
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/GasterNoCopyAble/Experiment17_GuiLib/main/Experiment17.lua"
))()
```

## v22 changes

- Project split into logical `core/` and `modules/`
- Main GUI bootstrap lives in `src/v22/core/Main.luau`
- The stable base UI engine now lives entirely under `src/v22/core/`
- `core/SourceAssembler.luau` reconstructs the internal v22 core source snapshot from `core/source/partXX.luau`
- The runtime no longer accesses any `src/v21/` path and the old v21 directory is removed
- Mobile, sliders, RGB, gradients, and tile pages are separate modules
- Smaller mobile watermark text/shell
- Slider handle no longer has the bright white outline
- Active toggle switches now continue following animated RGB accent colors
- Gradients are applied to outline strokes with a white base, so colors are no longer tinted by the previous stroke color
- Gradient motion is updated continuously each rendered frame instead of looking like a slideshow
- Tile controls redesigned as direct tab content with pages, image tiles, captions below tiles, and configurable tiles-per-page
- Old `src/v21/partXX.luau` source windows and `LegacyAssembler.luau` were removed from the active repository structure

## Repository layout

```text
Experiment17_GuiLib/
├── Experiment17.lua
├── README.md
├── Contact.txt
└── src/
    └── v22/
        ├── core/
        │   ├── Main.luau
        │   ├── SourceAssembler.luau
        │   └── source/
        │       ├── part01.luau
        │       ├── ...
        │       └── part29.luau
        └── modules/
            ├── Mobile.luau
            ├── Sliders.luau
            ├── RGB.luau
            ├── Gradients.luau
            └── Tiles.luau
```

`Experiment17.lua` is intentionally tiny. It loads `core/Main.luau`; `Main.luau` builds the v22 base through `core/SourceAssembler.luau` and then installs the feature modules. There is no `src/v21/` runtime dependency anymore.

---

# Quick start

```lua
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/GasterNoCopyAble/Experiment17_GuiLib/main/Experiment17.lua"
))()

local Main = Library:CreateTab("Main")
local General = Main:CreateSection("General", false)

General:AddToggle({
    Name = "Example",
    Flag = "ExampleToggle",
    Default = false,
    RequiredGraphics = "Low",
    Callback = function(Value)
        print(Value)
    end,
})
```

# Tabs and sections

```lua
local Main = Library:CreateTab("Main")
local Visuals = Library:CreateTab("Visuals")
local Misc = Library:CreateTab("Misc")
```

The built-in `Settings` tab always remains below user tabs.

```lua
local Section = Main:CreateSection("General", false)
```

`false` = closed by default, `true` = open by default.

# Toggle

```lua
Section:AddToggle({
    Name = "Boxes",
    Flag = "Boxes",
    Default = false,
    Callback = function(Value)
        print(Value)
    end,
})
```

# Slider

Sliders support mouse + touch and use a compact circular handle without a separate bright outline.

```lua
Section:AddSlider({
    Name = "Distance",
    Flag = "Distance",
    Min = 0,
    Max = 5000,
    Default = 1500,
})
```

# Range slider

```lua
Section:AddRangeSlider({
    Name = "Distance Range",
    Flag = "DistanceRange",
    Min = 0,
    Max = 5000,
    Default = {100, 1500},
})
```

# Dropdown

```lua
Section:AddChoice({
    Name = "Mode",
    Flag = "Mode",
    Values = {"Normal", "Outline", "Glow"},
    Default = "Normal",
})
```

# Multi dropdown

```lua
Section:AddMultiDropdown({
    Name = "ESP Parts",
    Flag = "ESPParts",
    Values = {"Box", "Name", "Health", "Distance", "Skeleton"},
    Default = {"Box", "Name"},
})
```

# Input

```lua
Section:AddInput({
    Name = "Player Name",
    Flag = "Target",
    Default = "",
    Placeholder = "username...",
})
```

# Button

```lua
Section:AddButton({
    Name = "Reset",
    ButtonText = "Reset",
    Callback = function()
        print("reset")
    end,
})
```

# Color picker

HSV color picker supports mouse and touch.

```lua
Section:AddColorPicker({
    Name = "ESP Color",
    Flag = "ESPColor",
    Default = Color3.fromRGB(170, 100, 255),
})
```

# Tile pages

v22 tiles are **direct content of a tab**. They are not placed inside a normal section row.

```lua
local Presets = Visuals:AddTilePage({
    Name = "Visual Presets",
    TilesPerPage = 8,
    Columns = 4,
    TileSize = 82,

    Tiles = {
        {
            Text = "Purple",
            Image = "rbxassetid://123456789",
            Value = "Purple",
            Callback = function(Value)
                print(Value)
            end,
        },
        {
            Text = "Blue",
            Image = "rbxassetid://987654321",
            Value = "Blue",
            Callback = function(Value)
                print(Value)
            end,
        },
    },
})
```

A tile consists of a square image area and text below it.

Change page:

```lua
Presets:SetPage(2)
```

Change how many tiles are shown on one page:

```lua
Presets:SetTilesPerPage(12)
```

Replace tile data:

```lua
Presets:SetTiles({
    {Text = "One", Image = "rbxassetid://1"},
    {Text = "Two", Image = "rbxassetid://2"},
})
```

A global default is also available in:

```text
Settings > Interface > Default Tiles Per Page
```

Compatibility calls still exist:

```lua
Section:AddTileButtons({...})
Section:AddTileButton({...})
```

but in v22 they create direct tab tile content instead of stuffing square buttons inside a section control.

# RGB theme

The `RGB` style animates:

```text
Accent
Outline
Hover
Active toggle switches
```

Active toggles no longer freeze on the accent color from the moment they were enabled.

# Gradients

Gradient settings remain in Settings:

```text
Enable Gradients
Gradient Preset
Animate Gradient
Gradient Speed
Gradient Rotation
Gradient Intensity
Gradient Color A
Gradient Color B
```

v22 applies decorative gradients to theme-bound outline `UIStroke` objects. The stroke is made white while the gradient is active, which prevents the selected gradient preset from being multiplied/tinted by the old outline color.

The animation runs continuously per rendered frame.

Normal UI gradients used by functional controls such as the HSV color picker are not deleted or replaced.

# Mobile

Touch support includes:

```text
Main window dragging
Watermark dragging
Keybind-list dragging
Mobile GUI button dragging
Normal sliders
Range sliders
HSV color picker
```

The watermark automatically uses a smaller font and shell on touch devices.

# Notifications

Touch devices use a smaller notification layout automatically.

```lua
Library:Notify({
    Title = "Config",
    Text = "Configuration saved",
    Type = "Success",
    Duration = 4,
})
```

# Configs

Config files use the executor filesystem when supported.

```text
Experiment17/
├── autoload.txt
└── configs/
    ├── default.json
    └── visuals.json
```

# Themes

Built-in styles include:

```text
Violet
Mono
Crimson
Emerald
Azure
Gold
Rose
Ocean
Midnight
Sakura
Arctic
Sunset
Cyber
RGB
```

# Languages

`Auto (Roblox)` reads `LocalizationService.RobloxLocaleId`.

Built-in languages include English, Russian, Ukrainian, Spanish, German, French, Portuguese, Polish, and Turkish. Unsupported locales fall back to English.

# Contact

See `Contact.txt`.
