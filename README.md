Experiment 17 UI Library

A dark, modular Roblox UI library built for visual-heavy scripts and configurable client tools.

Experiment 17 focuses on a clean black interface, violet accents, smooth animations, configurable performance tiers, themes, localization, configs, tooltips, DPI scaling, and reusable controls.

Default font: Oswald
Default menu key: RightShift
Default theme: Violet
Default language mode: Auto (Roblox)

Features

Dark black UI with violet accent and outline

Left-side tab navigation

Top breadcrumb:

Experiment 17 [Visuals] > Current Tab

Collapsible sections

All sections closed by default

Smooth and stepped control animations

Menu open/close animations:

Scale

Slide

Fade

None

Smooth window dragging with configurable follow speed

Rebindable menu key

DPI scaling

Separate Function DPI scaling

Text size control

Automatic display fitting

Config save/load/autoload

Optional queue-on-teleport support

Theme presets

Live HSV color picker

Roblox language auto-detection

Manual language selection

Watermark system

Draggable watermark

FPS display

Ping display

OS time display

Function tooltips

FPS / ping impact metadata

Graphics-level requirements for individual controls

Automatic disabling of functions when the selected graphics level becomes too low

5-second loading screen

Username + time-based greeting on startup

Loading particles and background dim

Unload and hide buttons

Installation

Put the library in your repository, for example:

Experiment-17-UI-Library/
├── src/
│   └── Experiment17.lua
├── examples/
│   └── example.lua
├── README.md
└── CHANGELOG.md

Load from GitHub

Replace USERNAME with your GitHub username:

local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/USERNAME/Experiment-17-UI-Library/main/src/Experiment17.lua"
))()

For development builds, you can keep a separate dev branch:

local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/USERNAME/Experiment-17-UI-Library/dev/src/Experiment17.lua"
))()

Recommended branch layout:

main    stable builds
dev     development builds

Quick Start

local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/USERNAME/Experiment-17-UI-Library/main/src/Experiment17.lua"
))()

local MainTab = Library:CreateTab("Main")

local General = MainTab:CreateSection("General", false)

General:AddToggle({
    Name = "Example Toggle",
    Flag = "ExampleToggle",

    Default = false,
    RequiredGraphics = "Low",

    Description = "Example toggle description.",
    FPSImpact = 0,
    PingImpact = 0,

    Callback = function(Value)
        print("Example Toggle:", Value)
    end,
})

Tabs

Create a new tab:

local VisualsTab = Library:CreateTab("Visuals")

Create multiple tabs:

local MainTab = Library:CreateTab("Main")
local VisualsTab = Library:CreateTab("Visuals")
local MiscTab = Library:CreateTab("Misc")

The library already includes its own Settings tab.

Sections

Create a collapsible section:

local Section = MainTab:CreateSection("General", false)

The second argument controls whether the section is opened by default.

false -- closed
true  -- opened

For the intended Experiment 17 layout, using false is recommended.

Toggle

Section:AddToggle({
    Name = "Boxes",
    Flag = "ESP_Boxes",

    Default = false,
    RequiredGraphics = "Low",

    Description = "Draws a box around players.",
    FPSImpact = {-4, -1},
    PingImpact = 0,

    Callback = function(Value)
        print(Value)
    end,
})

Slider

Section:AddSlider({
    Name = "Render Distance",
    Flag = "RenderDistance",

    Min = 100,
    Max = 5000,
    Default = 1500,
    Decimals = 0,

    RequiredGraphics = "Medium",

    Description = "Maximum rendering distance.",
    FPSImpact = {-8, -1},
    PingImpact = 0,

    Callback = function(Value)
        print(Value)
    end,
})

Dropdown / Choice

Section:AddChoice({
    Name = "ESP Mode",
    Flag = "ESPMode",

    Values = {
        "Normal",
        "Outline",
        "Glow",
    },

    Default = "Normal",
    RequiredGraphics = "Low",

    Callback = function(Value)
        print(Value)
    end,
})

Choices open as a dropdown instead of cycling through values.

Button

Section:AddButton({
    Name = "Reset Visuals",
    ButtonText = "Reset",

    RequiredGraphics = "Low",

    Callback = function()
        print("Reset")
    end,
})

Input

Section:AddInput({
    Name = "Config Name",
    Flag = "ConfigName",

    Default = "default",
    Placeholder = "config name",

    RequiredGraphics = "Low",

    Callback = function(Value)
        print(Value)
    end,
})

Keybind

Section:AddKeybind({
    Name = "Menu Key",
    Flag = "MenuKey",

    Default = "RightShift",
    RequiredGraphics = "Low",

    Callback = function(KeyName, KeyCode)
        print(KeyName, KeyCode)
    end,
})

Press the keybind control and then press a new keyboard key.

Escape cancels rebinding.

Color Picker

Experiment 17 uses an HSV palette picker instead of RGB input fields.

Section:AddColorPicker({
    Name = "ESP Color",
    Flag = "ESPColor",

    Default = Color3.fromRGB(170, 100, 255),
    RequiredGraphics = "Low",

    Callback = function(Color)
        print(Color)
    end,
})

The picker includes:

Saturation / value palette

Hue strip

Live color preview

Theme synchronization

Separators

Separators are intended for logical groups, not every function.

Example:

Section:AddChoice({
    Name = "Control Motion",
    Values = {"Smooth", "Stepped"},
    Default = "Smooth",
})

Section:AddChoice({
    Name = "Open Animation",
    Values = {"Scale", "Slide", "Fade", "None"},
    Default = "Scale",
})

Section:AddSlider({
    Name = "Animation Speed",
    Min = 5,
    Max = 50,
    Default = 18,
})

-- New group starts here
Section:AddSeparator()

Section:AddToggle({
    Name = "Background Blur",
    Default = true,
})

Use a separator when the next setting belongs to a different category.

Graphics Levels

Experiment 17 supports seven graphics tiers:

Low
LM
Medium
MH
High
HE
Epic

Each control can define the minimum required level:

RequiredGraphics = "High"

That means the function is available on:

High
HE
Epic

and locked on:

Low
LM
Medium
MH

Locked controls:

become darker

cannot be interacted with

display the required graphics tier

automatically disable themselves if they were active before the graphics preset was lowered

Example:

Section:AddToggle({
    Name = "Volumetric Overlay",
    Flag = "VolumetricOverlay",

    Default = false,
    RequiredGraphics = "HE",

    Callback = function(Value)
        print(Value)
    end,
})

Function Tooltips

Every control can include a description and estimated performance impact.

Section:AddToggle({
    Name = "Skeleton",
    Flag = "Skeleton",

    Default = false,
    RequiredGraphics = "High",

    Description = "Draws lines between character joints.",

    FPSImpact = {-10, -3},
    PingImpact = 0,

    Callback = function(Value)
        print(Value)
    end,
})

On hover, the tooltip can show:

Skeleton

Draws lines between character joints.

Graphics: High+ [AVAILABLE]

FPS impact: -10 .. -3 FPS
Ping impact: 0 ms

You can also use text values:

FPSImpact = "-5 .. -15 FPS"
PingImpact = "+0 .. +3 ms"

Performance impact values are metadata supplied by the script author. They are not guaranteed automatic benchmark results.

Settings

The built-in Settings tab contains:

Interface

Language

Graphics Level

Font

Text Size

DPI Scale

Auto Fit To Display

Function DPI

Menu Keybind

Corner Radius

Background Blur

Blur Strength

Background Dim

Dim Amount

Animations

Control Motion

Smooth

Stepped

Open Animation

Scale

Slide

Fade

None

Animation Speed

Window Dragging

Smooth

Direct

Drag Follow Speed

Tooltips

Function Tooltips

Tooltip Delay

Tooltip Follow Speed

Theme

Theme Preset

Accent

Background

Outline

Control Background

Watermarks

Enable Watermark

Watermark Text

Show Graphics Level

Show FPS

Show Ping

Show OS Time

Draggable Watermark

Reset Watermark Position

Configs

Config Name

Save Current Config

Load Config

Autoload Config

Set As Autoload

Queue On Teleport

DPI Scaling

Main UI DPI presets:

175%
150%
125%
100%
75%
50%
25%
5%

100% is intentionally larger than the original early Experiment 17 layout.

The library can automatically lower the effective DPI if the selected size does not fit the current display.

Function DPI

Function DPI changes the width / visual size of controls inside a section without shrinking the section itself.

This creates a more nested layout where functions can be slightly smaller than their section header.

Example presets:

100%
95%
90%
85%
80%
75%
50%
25%

Fonts

Default:

Oswald

Available built-in choices include:

Oswald
Gotham
GothamMedium
Code
RobotoMono
SourceSans

Themes

Built-in presets:

Violet
Mono
Crimson
Emerald

The default style is:

Background: black
Accent: violet
Outline: violet
Font: Oswald

Theme colors can also be edited manually with the HSV color picker.

Changing a theme preset also refreshes theme-related color pickers.

Languages

The default mode is:

Auto (Roblox)

The library checks:

LocalizationService.RobloxLocaleId

and chooses a supported language automatically.

Current built-in languages:

English
Русский
Українська
Español
Deutsch
Français
Português
Polski
Türkçe

Unsupported Roblox locales fall back to English.

Users can also select the language manually in:

Settings > Interface > Language

The selected language can be stored in configs.

Startup Loader

Experiment 17 shows a loading interface before opening the main UI.

Current behavior:

background dim

particles

loading progress

minimum 5-second display time

username greeting

OS-time greeting

config loading before the main UI opens

Example:

Experiment 17 [Visuals]

Hello, PlayerName. Good morning.

Applying configuration...

The greeting changes based on local time.

Watermark

Example:

Experiment 17 [Visuals] | Epic | 144 FPS | 42 ms | 18:32:10

Available information:

custom text

graphics level

FPS

ping

OS time

The watermark can be dragged and its position can be stored in the config.

Config System

Controls that use a Flag can automatically participate in config saving.

Example:

Flag = "ESP_Boxes"

Possible filesystem structure:

Experiment17/
├── autoload.txt
└── configs/
    ├── default.json
    ├── legit.json
    └── epic.json

Config support depends on the environment exposing filesystem functions such as:

writefile
readfile
isfile
makefolder

If they are unavailable, persistent file configs cannot be used.

Teleport Autoload

If the environment supports queue_on_teleport, Experiment 17 can queue itself for the next place.

Recommended local path:

Experiment17/visuals.lua

Example loader behavior:

loadstring(readfile("Experiment17/visuals.lua"))()

Teleport persistence depends on the environment and is not a Roblox LocalScript feature by itself.

Hide / Unload

Bottom-left controls:

[X] [_]

_

Hides the interface.
The configured menu key can show it again.

X

Unloads the library and disables active toggles so their callbacks can clean up effects.

Public API Example

local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/USERNAME/Experiment-17-UI-Library/main/src/Experiment17.lua"
))()

local Visuals = Library:CreateTab("Visuals")
local ESP = Visuals:CreateSection("ESP", false)

ESP:AddToggle({
    Name = "Boxes",
    Flag = "ESP_Boxes",

    Default = false,
    RequiredGraphics = "Low",

    Description = "Draws 2D boxes around players.",
    FPSImpact = {-4, -1},
    PingImpact = 0,

    Callback = function(Value)
        print("Boxes:", Value)
    end,
})

ESP:AddToggle({
    Name = "Skeleton",
    Flag = "ESP_Skeleton",

    Default = false,
    RequiredGraphics = "High",

    Description = "Draws a skeleton using character joints.",
    FPSImpact = {-10, -3},
    PingImpact = 0,

    Callback = function(Value)
        print("Skeleton:", Value)
    end,
})

ESP:AddSeparator()

ESP:AddSlider({
    Name = "Render Distance",
    Flag = "ESP_Distance",

    Min = 100,
    Max = 5000,
    Default = 1500,

    RequiredGraphics = "Medium",

    Callback = function(Value)
        print("Distance:", Value)
    end,
})

ESP:AddColorPicker({
    Name = "ESP Color",
    Flag = "ESP_Color",

    Default = Color3.fromRGB(170, 100, 255),
    RequiredGraphics = "Low",

    Callback = function(Color)
        print(Color)
    end,
})

Recommended Repository Layout

Experiment-17-UI-Library/
├── src/
│   └── Experiment17.lua
│
├── examples/
│   ├── basic.lua
│   ├── controls.lua
│   └── visuals.lua
│
├── README.md
└── CHANGELOG.md

Screenshots

Add screenshots to:

assets/

Then show them here:

![Experiment 17 UI](assets/preview.png)

Recommended screenshots:

main Settings tab

dropdown open

color picker open

loading screen

watermark

tooltip

multiple themes

Changelog

Keep major updates inside CHANGELOG.md.

Example:

## v1.0.0

- Initial public release
- Tabs and collapsible sections
- Toggle / Slider / Dropdown / Keybind / Input / Button
- HSV color picker
- Config system
- Themes
- Localization
- Graphics levels
- Tooltips
- Watermark

Versioning

Recommended format:

MAJOR.MINOR.PATCH

Examples:

1.0.0
1.1.0
1.1.1
2.0.0

Use:

PATCH for fixes

MINOR for new backwards-compatible features

MAJOR for breaking API changes

License

Add a LICENSE file before publishing the repository.

For an open-source UI library, the MIT License is a simple option if you want people to freely use, modify, and redistribute the library while keeping the copyright notice.

Credits

Experiment 17 UI Library

Designed as a reusable Roblox UI framework for configurable visual scripts and client-side tools.

Notes

Experiment 17 is a UI framework. Features added through callbacks are implemented by the script using the library.

The library itself provides the interface, controls, configuration system, themes, animations, localization, performance tiers, tooltips, and supporting UI systems.
