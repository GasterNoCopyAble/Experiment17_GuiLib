# Experiment 17 UI Library

Dark modular Roblox UI library with desktop/mobile input, configs, paired themes and gradients, RGB, notifications, search, favorites, keybinds, startup prompts, tiles, and reusable controls.

Current stable family: **Legacy v22**.

## Load

```lua
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/GasterNoCopyAble/Experiment17_GuiLib/main/Experiment17.lua"
))()
```

Runtime identity:

```lua
Library.Version        -- "v22"
Library.DisplayVersion -- "Legacy v22"
Library.UIFamily       -- "Legacy"
Library.Legacy         -- true
```

## Legacy v22 highlights

- Modular `core/` + `modules/` architecture
- Desktop and touch input
- Low-latency phone dragging and lighter phone menu opening
- Independent dragging for the main window, watermark, and mobile GUI button
- Dynamic desktop watermark sizing
- Config save/load/autoload when executor filesystem APIs are available
- Search, favorites, notifications, keybind list, profiles, startup prompts
- 14 public theme families with matching 1:1 gradient palettes
- Theme selection and gradient selection stay synchronized; `Custom` remains independent
- UIStroke-only decorative gradients with visible animated flow and strength hierarchy
- Dynamic RGB color-picker state support
- Styled scrollbars with extra spacing from tab/page content
- Redesigned tile pages with top/bottom separators and compact pagination

## Repository layout

```text
Experiment17_GuiLib/
├── Experiment17.lua
├── README.md
├── Contact.txt
├── assets/
│   └── Icons/
└── src/
    └── v22/
        ├── core/
        │   ├── Main.luau
        │   └── Engine.luau
        └── modules/
            ├── Mobile.luau
            ├── Sliders.luau
            ├── Themes.luau
            ├── RGB.luau
            ├── Gradients.luau
            ├── ColorPickerRGB.luau
            ├── Runtime.luau
            ├── Interaction.luau
            ├── Scrolling.luau
            └── Tiles.luau
```

`Experiment17.lua` is intentionally tiny. It loads `src/v22/core/Main.luau`; the bootstrap loads `Engine.luau` and then installs the feature modules. Old v21 assemblers and runtime source-window merging are not used.

---

## Quick start

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

The built-in `Settings` tab always stays after user-created tabs. Sections are closed by default unless `true` is passed as the second argument.

## Common controls

```lua
General:AddSlider({
    Name = "Distance",
    Flag = "Distance",
    Min = 0,
    Max = 5000,
    Default = 1500,
})

General:AddChoice({
    Name = "Mode",
    Flag = "Mode",
    Values = {"Normal", "Outline", "Glow"},
    Default = "Normal",
})

General:AddMultiDropdown({
    Name = "ESP Parts",
    Flag = "ESPParts",
    Values = {"Box", "Name", "Health", "Distance", "Skeleton"},
    Default = {"Box", "Name"},
})

General:AddInput({
    Name = "Player Name",
    Flag = "Target",
    Default = "",
    Placeholder = "username...",
})

General:AddColorPicker({
    Name = "Color",
    Flag = "ExampleColor",
    Default = Color3.fromRGB(170, 100, 255),
})
```

Color pickers support mouse and touch. Their preview can also represent a dynamic RGB state instead of pretending an animated color is static.

## Tile pages

Tiles are direct tab content rather than normal section rows.

```lua
local Visuals = Library:CreateTab("Visuals")

local Presets = Visuals:AddTilePage({
    Name = "Visual Presets",
    TilesPerPage = 8,
    Columns = 4,
    TileSize = 78,

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
        },
    },
})

Presets:SetPage(2)
Presets:SetTilesPerPage(12)
```

Compatibility calls still exist:

```lua
Section:AddTileButtons({...})
Section:AddTileButton({...})
```

They create direct tab tile content in Legacy v22.

## Themes and gradients

Public theme families:

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

Each public family has a matching gradient with the same name. Selecting either side keeps the pair synchronized. Manually editing `Gradient Color A/B` switches the gradient to `Custom`.

Gradient settings:

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

Decorative gradients are children of outline `UIStroke` objects only. Large shells use restrained color while selected/interactive borders receive stronger gradient contrast. Hidden main-window strokes are skipped while the menu is closed.

Functional gradients such as the HSV color picker are not replaced by the decorative gradient module.

## RGB

The RGB theme animates `Accent`, `Outline`, `Hover`, and active toggle visuals. Expensive GUI propagation is skipped while the main menu is hidden.

## Mobile

Touch support includes:

```text
Main window dragging
Watermark dragging
Mobile GUI button dragging
Keybind-list dragging
Sliders
Range sliders
HSV color picker
```

Phone opening uses a lighter path than desktop and touch dragging follows the latest pointer position directly.

## Notifications

```lua
Library:Notify({
    Title = "Config",
    Text = "Configuration saved",
    Type = "Success",
    Duration = 4,
})
```

Touch devices automatically use a more compact notification layout.

## Configs

When supported by the executor filesystem:

```text
Experiment17/
├── autoload.txt
└── configs/
    ├── default.json
    └── visuals.json
```

## Languages

`Auto (Roblox)` follows `LocalizationService.RobloxLocaleId`.

Built-in languages include English, Russian, Ukrainian, Spanish, German, French, Portuguese, Polish, and Turkish. Unsupported locales fall back to English.

## Source note

Legacy is a client-side UI library. Any code delivered to the client can ultimately be inspected or modified, so sensitive secrets, authentication material, or authoritative security checks should never live only in this client source.

## Contact

See `Contact.txt`.
