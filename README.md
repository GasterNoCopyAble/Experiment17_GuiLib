# Experiment 17 UI Library

A dark modular Roblox UI library with desktop and mobile support, configurable animations, themes, gradients, localization, configs, startup prompts, notifications, keybinds, search, favorites, and reusable controls.

Repository: `GasterNoCopyAble/Experiment17_GuiLib`

## Load

```lua
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/GasterNoCopyAble/Experiment17_GuiLib/main/Experiment17.lua"
))()
```

## Highlights

- Desktop + touch/mobile input
- Draggable main window, watermark, keybind list, and mobile GUI button
- Touch-friendly sliders with visible circular handles
- Touch-friendly two-handle range slider
- HSV color picker with mouse + touch support
- Smaller notification layout on mobile
- Search and Favorites in the topbar
- Context menu for controls
- Dependencies and conditional visibility
- Config browser with save/load/delete/autoload
- Startup questions and Yes/No confirmations
- Built-in profile engine
- 14 theme styles including animated RGB
- 30 gradient presets + custom gradient colors
- Animated gradient rotation, speed, angle, and intensity
- Settings tab always remains the last sidebar tab
- Roblox locale auto-detection

## Repository layout

```text
Experiment17_GuiLib/
├── Experiment17.lua          # stable loader
├── src/
│   └── v21/
│       ├── part01.luau
│       ├── ...
│       └── part29.luau
├── README.md
└── Contact.txt
```

`Experiment17.lua` is the public entry point. It downloads the ordered v21 source parts, joins them, compiles the result, and returns the library. Users normally only need the root loader URL.

No assets, `.gitignore`, or license file are required for the library to work.

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

    Description = "Example function.",
    FPSImpact = 0,
    PingImpact = 0,

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

The built-in Settings tab always stays after user-created tabs:

```text
Main
Visuals
Misc
Settings
```

Create a section:

```lua
local Section = Main:CreateSection("General", false)
```

`false` means closed by default. `true` means open by default.

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

Sliders have a visible circular handle and a larger invisible touch target.

```lua
Section:AddSlider({
    Name = "Distance",
    Flag = "Distance",
    Min = 0,
    Max = 5000,
    Default = 1500,
    Callback = function(Value)
        print(Value)
    end,
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
    Callback = function(Value, Low, High)
        print(Low, High)
    end,
})
```

# Dropdown

```lua
Section:AddChoice({
    Name = "Mode",
    Flag = "Mode",
    Values = {"Normal", "Outline", "Glow"},
    Default = "Normal",
    Callback = function(Value)
        print(Value)
    end,
})
```

# Multi dropdown

```lua
Section:AddMultiDropdown({
    Name = "ESP Parts",
    Flag = "ESPParts",
    Values = {"Box", "Name", "Health", "Distance", "Skeleton"},
    Default = {"Box", "Name"},
    Callback = function(Values)
        print(Values)
    end,
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

# Number input

```lua
Section:AddNumberInput({
    Name = "Distance",
    Flag = "DistanceNumber",
    Min = 0,
    Max = 5000,
    Default = 1000,
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

# Button group

```lua
Section:AddButtonGroup({
    Name = "Actions",
    Buttons = {
        {Text = "Save", Callback = function() print("save") end},
        {Text = "Load", Callback = function() print("load") end},
    },
})
```

# Color picker

The HSV picker supports mouse and touch.

```lua
Section:AddColorPicker({
    Name = "ESP Color",
    Flag = "ESPColor",
    Default = Color3.fromRGB(170, 100, 255),
    Callback = function(Color)
        print(Color)
    end,
})
```

# Labels and status controls

```lua
Section:AddLabel("Simple text")
```

```lua
Section:AddParagraph({Text = "Longer information text."})
```

```lua
local Progress = Section:AddProgressBar({
    Name = "Loading",
    Min = 0,
    Max = 100,
    Default = 0,
})
Progress:Set(75)
```

```lua
local Status = Section:AddStatus({Name = "Server", Default = "Ready"})
Status:Set("Connected")
```

# Keybinds

Section control:

```lua
Section:AddKeybind({
    Name = "Fly",
    Flag = "FlyKey",
    Default = "F",
    Mode = "Toggle",
    OnTriggered = function(Enabled)
        print(Enabled)
    end,
})
```

Standalone keybind:

```lua
local FlyBind = Library:CreateKeybind({
    Name = "Fly",
    Key = "F",
    Mode = "Toggle",
    Callback = function(Enabled)
        print(Enabled)
    end,
})
```

Modes:

```text
Press
Toggle
Hold
Always
```

# Dependencies

```lua
Section:AddSlider({
    Name = "Skeleton Thickness",
    Flag = "SkeletonThickness",
    DependsOn = "Skeleton",
    Min = 1,
    Max = 5,
    Default = 2,
})
```

Custom condition:

```lua
EnabledWhen = function(Flags)
    return Flags.Skeleton and Flags.TeamESP
end
```

Visibility:

```lua
VisibleWhen = function(Flags)
    return Flags.AdvancedMode
end
```

# Graphics levels

```text
Low
LM
Medium
MH
High
HE
Epic
```

```lua
RequiredGraphics = "High"
```

# Search and Favorites

The topbar search checks control names and descriptions. Selecting a result opens the correct tab/section and scrolls to the control.

Right-click a control for:

```text
Favorite / Remove Favorite
Reset to Default
Copy Value
```

# Notifications

```lua
Library:Notify({
    Title = "Config",
    Text = "Configuration saved",
    Type = "Success",
    Duration = 4,
})
```

Positions:

```text
Top Left
Top Center
Top Right
Bottom Left
Bottom Center
Bottom Right
```

Touch devices automatically use a much smaller notification layout.

# Startup questionnaire

```lua
Library:QueueStartupQuestion({
    Title = {ru = "Профиль визуалов", en = "Visual profile"},
    Question = {ru = "Чего вы добиваетесь визуалами?", en = "What do you want from the visuals?"},
    Options = {
        {Text = {ru = "Баланс", en = "Balance"}, Value = "Balanced"},
        {Text = {ru = "Производительность", en = "Performance"}, Value = "Performance"},
        {Text = {ru = "Красота", en = "Beauty"}, Value = "Beauty"},
    },
    Flag = "VisualProfile",
})
```

Yes/No:

```lua
Library:QueueStartupConfirm({
    Question = {ru = "Включить жесткую оптимизацию?", en = "Enable aggressive optimization?"},
    Flag = "AggressiveOptimization",
    DependsOn = {VisualProfile = "Performance"},
})
```

# Profiles

Built-in:

```text
Performance
Balanced
Beauty
Custom
```

Custom profile:

```lua
Library:RegisterProfile("Cinematic", {
    Settings = {
        GraphicsLevel = "Epic",
        BlurEnabled = true,
        AnimationMode = "Smooth",
    },
    Flags = {
        Boxes = true,
        Skeleton = true,
    },
})

Library:ApplyProfile("Cinematic")
```

# Themes

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

`RGB` enables animated accent/outline/hover colors. RGB speed is configurable in Settings.

# Gradients

Settings:

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

Presets:

```text
Violet Dream
Purple Neon
Blue Neon
Ocean
Aqua
Emerald
Lime
Gold
Amber
Sunset
Fire
Crimson
Rose
Sakura
Candy
Cotton Candy
Ice
Arctic
Midnight
Galaxy
Nebula
Cyber
Matrix
Steel
Silver
Monochrome
Black Violet
Black Red
Black Blue
RGB
Custom
```

The default gradient intensity is intentionally subtle so the interface stays dark and readable.

# Mobile / touch

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

Mobile button settings:

```text
Show Mobile Button
Mobile Button Text
Mobile Button Size
Mobile Button Opacity
Draggable Mobile Button
Reset Mobile Button Position
```

The mobile button appears only after the loader/startup wizard is complete.

# Watermark

```text
Experiment 17 [Visuals] | Epic | 144 FPS | 38 ms | 20:15:22
```

Watermark dragging works with mouse and touch.

# Config system

```text
Experiment17/
├── autoload.txt
└── configs/
    ├── default.json
    ├── performance.json
    └── visuals.json
```

Settings provides a config dropdown, so loading does not require typing the name manually.

Filesystem support depends on the environment exposing functions such as:

```text
writefile
readfile
isfile
makefolder
listfiles
delfile
```

# DPI and text scale

DPI presets:

```text
175%
150%
125%
100%
75%
50%
25%
5%
```

Default text scale:

```text
150%
```

# Languages

Default mode:

```text
Auto (Roblox)
```

The library reads `LocalizationService.RobloxLocaleId`.

Built-in languages include English, Russian, Ukrainian, Spanish, German, French, Portuguese, Polish, and Turkish. Unsupported locales fall back to English.

# Hide / unload

```text
[X] [_]
```

`_` hides the main GUI. `X` unloads the library. On touch devices the floating mobile button can reopen the interface.

# Contact

See `Contact.txt` in the repository.
