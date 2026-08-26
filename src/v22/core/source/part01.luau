--[[
    Experiment 17 [Visuals] - UI Library v21
    Single-file LocalScript / client-side UI framework.

    Features:
      • Loading screen + particles + dim background
      • Left tabs + top breadcrumb
      • Collapsible sections
      • Toggle / Slider / Dropdown / Keybind / Input / Button / ColorPicker
      • Graphics gates: Low, LM, Medium, MH, High, HE, Epic
      • Locked controls are darker and cannot be used
      • Smooth / Stepped control motion for toggles and sliders
      • Menu opening animations
      • Blur + background dim settings
      • Theme presets + live HSV palette color editing
      • Font selection
      • DPI presets + optional automatic display fitting
      • Config save/load/autoload when filesystem APIs exist
      • Watermark controls + unload/minimize sidebar buttons
      • Draggable watermark + ping + OS time
      • Global text scale + separate function/control scale
      • Group separators live BETWEEN related control groups
      • Sections start collapsed by default
      • Animated tab/page, section, dropdown and color-picker transitions
      • Smooth/direct window dragging with configurable follow speed
      • Minimum 5-second loader window before the UI opens
      • RobloxLocaleId language auto-detection + manual language selector
      • Opaque black animation shell (background never fades during menu motion)
      • Extreme menu motion: 4000px slide + stronger scale animation
      • Slow smooth section expansion + staggered function appearance
      • Startup question / confirm modal API
      • Improved loader entrance, progress percentage and transitions
      • Notification system with six screen positions
      • Smart startup conditions + reusable profiles
      • Control dependencies / visibility conditions
      • Topbar search + favorites/context menu
      • Keybind registry/list placed before Configs
      • Config browser + schema migrations
      • Extended controls + lightweight profiler
      • Menu animation race protection + fixed watermark dragging
      • Search/favorites popups moved to a true Root overlay layer
      • Menu animations now cancel/reverse cleanly with no end-frame pause
      • Draggable keybind list with saved custom position
      • Keybind dragging rewritten without AbsolutePosition conversion
      • Search/Favorites popups moved lower below the topbar
      • Slider tracks stay visually separated from hovered function rows
      • Search/Favorites popups shifted further down and right
      • Search/Favorites popup offset increased again for clearer separation
      • Search popup nudged left; Favorites popup nudged right
      • Default text scale raised to 150%
      • Built-in startup visual-profile wizard now actually runs
      • Full touch support for window/watermark/mobile button/sliders/color picker
      • Slider knobs + touch-friendly range slider
      • Mobile button customization + smaller mobile notifications
      • 14 theme styles including RGB + 30 gradient presets
      • Animated gradients with custom colors/rotation/speed
      • Smooth section-close animation without control collapse-to-corner
      • Settings tab is always kept last in the sidebar
      • Touch/mobile floating GUI toggle button
      • Profiler removed from the public UI
      • Optional queue_on_teleport loader hook

    Default font: Oswald
    Default menu key: RightShift (rebindable in Settings)
]]

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local LocalizationService = game:GetService("LocalizationService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--============================================================
-- SETTINGS / CONSTANTS
--============================================================

local GRAPHICS_ORDER = {
    Low = 1,
    LM = 2,
    Medium = 3,
    MH = 4,
    High = 5,
    HE = 6,
    Epic = 7,
}

local GRAPHICS_LIST = {"Low", "LM", "Medium", "MH", "High", "HE", "Epic"}

local FONT_MAP = {
    Oswald = Enum.Font.Oswald,
    Gotham = Enum.Font.Gotham,
    GothamMedium = Enum.Font.GothamMedium,
    GothamBold = Enum.Font.GothamBold,
    Code = Enum.Font.Code,
    RobotoMono = Enum.Font.RobotoMono,
    SourceSans = Enum.Font.SourceSans,
}

local FONT_LIST = {"Oswald", "Gotham", "GothamMedium", "Code", "RobotoMono", "SourceSans"}

-- 100% is intentionally 1.15x larger than the old v2 window.
-- Higher/lower presets are relative to that new 100% baseline.
local DPI_BASE_SCALE = 1.15
local DPI_VALUES = {
    ["175%"] = 175,
    ["150%"] = 150,
    ["125%"] = 125,
    ["100%"] = 100,
    ["75%"] = 75,
    ["50%"] = 50,
    ["25%"] = 25,
    ["5%"] = 5,
}
local DPI_LIST = {"175%", "150%", "125%", "100%", "75%", "50%", "25%", "5%"}
local DPI_FIT_ORDER = {175, 150, 125, 100, 75, 50, 25, 5}
local BASE_WINDOW_SIZE = Vector2.new(780, 500)
local DPI_SCREEN_MARGIN = Vector2.new(34, 34)

-- Controls can be visually smaller than their section header.
-- This is intentionally independent from the whole-window DPI.
local FUNCTION_DPI_VALUES = {
    ["100%"] = 100,
    ["95%"] = 95,
    ["90%"] = 90,
    ["85%"] = 85,
    ["80%"] = 80,
    ["75%"] = 75,
    ["50%"] = 50,
    ["25%"] = 25,
}
local FUNCTION_DPI_LIST = {"100%", "95%", "90%", "85%", "80%", "75%", "50%", "25%"}

local THEMES = {
    Violet = {
        Background = Color3.fromRGB(8, 8, 11),
        Panel = Color3.fromRGB(13, 13, 18),
        Control = Color3.fromRGB(19, 19, 26),
        Control2 = Color3.fromRGB(27, 27, 36),
        Accent = Color3.fromRGB(139, 92, 246),
        Outline = Color3.fromRGB(116, 72, 205),
        Hover = Color3.fromRGB(176, 130, 255),
        Text = Color3.fromRGB(239, 237, 245),
        SubText = Color3.fromRGB(150, 146, 162),
    },

    Mono = {
        Background = Color3.fromRGB(7, 7, 7),
        Panel = Color3.fromRGB(14, 14, 14),
        Control = Color3.fromRGB(20, 20, 20),
        Control2 = Color3.fromRGB(28, 28, 28),
        Accent = Color3.fromRGB(210, 210, 210),
        Outline = Color3.fromRGB(90, 90, 90),
        Hover = Color3.fromRGB(180, 180, 180),
        Text = Color3.fromRGB(245, 245, 245),
        SubText = Color3.fromRGB(145, 145, 145),
    },

    Crimson = {
        Background = Color3.fromRGB(10, 7, 8),
        Panel = Color3.fromRGB(18, 11, 13),
        Control = Color3.fromRGB(27, 15, 18),
        Control2 = Color3.fromRGB(38, 20, 24),
        Accent = Color3.fromRGB(225, 65, 95),
        Outline = Color3.fromRGB(170, 42, 65),
        Hover = Color3.fromRGB(255, 100, 125),
        Text = Color3.fromRGB(245, 236, 239),
        SubText = Color3.fromRGB(165, 138, 145),
    },

    Emerald = {
        Background = Color3.fromRGB(6, 10, 9),
        Panel = Color3.fromRGB(10, 18, 15),
        Control = Color3.fromRGB(15, 27, 23),
        Control2 = Color3.fromRGB(21, 38, 32),
        Accent = Color3.fromRGB(52, 211, 153),
        Outline = Color3.fromRGB(35, 150, 110),
        Hover = Color3.fromRGB(94, 234, 180),
        Text = Color3.fromRGB(235, 245, 241),
        SubText = Color3.fromRGB(136, 163, 152),
    },

    Azure = {
        Background = Color3.fromRGB(5, 9, 15), Panel = Color3.fromRGB(8, 15, 25),
        Control = Color3.fromRGB(12, 22, 36), Control2 = Color3.fromRGB(18, 31, 49),
        Accent = Color3.fromRGB(59, 130, 246), Outline = Color3.fromRGB(37, 99, 235),
        Hover = Color3.fromRGB(96, 165, 250), Text = Color3.fromRGB(239, 246, 255),
        SubText = Color3.fromRGB(148, 163, 184),
    },
    Gold = {
        Background = Color3.fromRGB(11, 9, 5), Panel = Color3.fromRGB(19, 16, 8),
        Control = Color3.fromRGB(30, 24, 11), Control2 = Color3.fromRGB(43, 34, 15),
        Accent = Color3.fromRGB(245, 190, 63), Outline = Color3.fromRGB(190, 139, 35),
        Hover = Color3.fromRGB(255, 215, 105), Text = Color3.fromRGB(255, 249, 229),
        SubText = Color3.fromRGB(184, 168, 126),
    },
    Rose = {
        Background = Color3.fromRGB(12, 7, 10), Panel = Color3.fromRGB(21, 11, 17),
        Control = Color3.fromRGB(31, 15, 25), Control2 = Color3.fromRGB(44, 21, 34),
        Accent = Color3.fromRGB(244, 114, 182), Outline = Color3.fromRGB(190, 70, 130),
        Hover = Color3.fromRGB(251, 160, 205), Text = Color3.fromRGB(253, 242, 248),
        SubText = Color3.fromRGB(180, 140, 160),
    },
    Ocean = {
        Background = Color3.fromRGB(5, 11, 13), Panel = Color3.fromRGB(8, 19, 22),
        Control = Color3.fromRGB(11, 29, 33), Control2 = Color3.fromRGB(16, 41, 47),
        Accent = Color3.fromRGB(34, 211, 238), Outline = Color3.fromRGB(14, 148, 173),
        Hover = Color3.fromRGB(103, 232, 249), Text = Color3.fromRGB(236, 254, 255),
        SubText = Color3.fromRGB(130, 166, 171),
    },
    Midnight = {
        Background = Color3.fromRGB(4, 5, 10), Panel = Color3.fromRGB(8, 9, 18),
        Control = Color3.fromRGB(13, 14, 27), Control2 = Color3.fromRGB(20, 22, 39),
        Accent = Color3.fromRGB(99, 102, 241), Outline = Color3.fromRGB(67, 56, 202),
        Hover = Color3.fromRGB(129, 140, 248), Text = Color3.fromRGB(238, 242, 255),
        SubText = Color3.fromRGB(137, 140, 170),
    },
    Sakura = {
        Background = Color3.fromRGB(13, 8, 11), Panel = Color3.fromRGB(22, 13, 18),
        Control = Color3.fromRGB(32, 18, 27), Control2 = Color3.fromRGB(46, 26, 38),
        Accent = Color3.fromRGB(251, 113, 133), Outline = Color3.fromRGB(190, 70, 95),
        Hover = Color3.fromRGB(253, 164, 175), Text = Color3.fromRGB(255, 241, 242),
        SubText = Color3.fromRGB(183, 143, 151),
    },
    Arctic = {
        Background = Color3.fromRGB(7, 11, 14), Panel = Color3.fromRGB(11, 18, 23),
        Control = Color3.fromRGB(17, 27, 34), Control2 = Color3.fromRGB(23, 39, 48),
        Accent = Color3.fromRGB(125, 211, 252), Outline = Color3.fromRGB(56, 189, 248),
        Hover = Color3.fromRGB(186, 230, 253), Text = Color3.fromRGB(240, 249, 255),
        SubText = Color3.fromRGB(145, 167, 179),
    },
    Sunset = {
        Background = Color3.fromRGB(13, 7, 7), Panel = Color3.fromRGB(23, 12, 10),
        Control = Color3.fromRGB(34, 18, 14), Control2 = Color3.fromRGB(49, 26, 19),
        Accent = Color3.fromRGB(249, 115, 22), Outline = Color3.fromRGB(220, 74, 20),
        Hover = Color3.fromRGB(251, 146, 60), Text = Color3.fromRGB(255, 247, 237),
        SubText = Color3.fromRGB(186, 147, 126),
    },
    Cyber = {
        Background = Color3.fromRGB(5, 7, 8), Panel = Color3.fromRGB(9, 13, 14),
        Control = Color3.fromRGB(13, 20, 21), Control2 = Color3.fromRGB(17, 29, 30),
        Accent = Color3.fromRGB(0, 255, 190), Outline = Color3.fromRGB(0, 190, 145),
        Hover = Color3.fromRGB(80, 255, 215), Text = Color3.fromRGB(233, 255, 249),
        SubText = Color3.fromRGB(128, 170, 161),
    },
    RGB = {
        Background = Color3.fromRGB(8, 8, 11), Panel = Color3.fromRGB(13, 13, 18),
        Control = Color3.fromRGB(19, 19, 26), Control2 = Color3.fromRGB(27, 27, 36),
        Accent = Color3.fromRGB(255, 70, 70), Outline = Color3.fromRGB(210, 50, 50),
        Hover = Color3.fromRGB(255, 120, 120), Text = Color3.fromRGB(242, 242, 246),
        SubText = Color3.fromRGB(151, 150, 163),
    },
}

local THEME_LIST = {
    "Violet", "Mono", "Crimson", "Emerald", "Azure", "Gold", "Rose",
    "Ocean", "Midnight", "Sakura", "Arctic", "Sunset", "Cyber", "RGB",
}

local GRADIENT_PRESETS = {
    ["Violet Dream"]={Color3.fromRGB(124,58,237),Color3.fromRGB(192,132,252),Color3.fromRGB(76,29,149)},
    ["Purple Neon"]={Color3.fromRGB(76,29,149),Color3.fromRGB(168,85,247),Color3.fromRGB(236,72,153)},
    ["Blue Neon"]={Color3.fromRGB(30,64,175),Color3.fromRGB(59,130,246),Color3.fromRGB(34,211,238)},
    ["Ocean"]={Color3.fromRGB(8,47,73),Color3.fromRGB(14,116,144),Color3.fromRGB(34,211,238)},
    ["Aqua"]={Color3.fromRGB(6,78,59),Color3.fromRGB(20,184,166),Color3.fromRGB(103,232,249)},
    ["Emerald"]={Color3.fromRGB(6,78,59),Color3.fromRGB(16,185,129),Color3.fromRGB(110,231,183)},
    ["Lime"]={Color3.fromRGB(54,83,20),Color3.fromRGB(132,204,22),Color3.fromRGB(190,242,100)},
    ["Gold"]={Color3.fromRGB(113,63,18),Color3.fromRGB(245,158,11),Color3.fromRGB(253,224,71)},
    ["Amber"]={Color3.fromRGB(120,53,15),Color3.fromRGB(251,146,60),Color3.fromRGB(254,215,170)},
    ["Sunset"]={Color3.fromRGB(159,18,57),Color3.fromRGB(249,115,22),Color3.fromRGB(253,186,116)},
    ["Fire"]={Color3.fromRGB(127,29,29),Color3.fromRGB(239,68,68),Color3.fromRGB(249,115,22)},
    ["Crimson"]={Color3.fromRGB(76,5,25),Color3.fromRGB(225,29,72),Color3.fromRGB(251,113,133)},
    ["Rose"]={Color3.fromRGB(131,24,67),Color3.fromRGB(244,114,182),Color3.fromRGB(251,207,232)},
    ["Sakura"]={Color3.fromRGB(136,19,55),Color3.fromRGB(251,113,133),Color3.fromRGB(254,205,211)},
    ["Candy"]={Color3.fromRGB(126,34,206),Color3.fromRGB(236,72,153),Color3.fromRGB(34,211,238)},
    ["Cotton Candy"]={Color3.fromRGB(147,51,234),Color3.fromRGB(244,114,182),Color3.fromRGB(125,211,252)},
    ["Ice"]={Color3.fromRGB(30,58,138),Color3.fromRGB(125,211,252),Color3.fromRGB(224,242,254)},
    ["Arctic"]={Color3.fromRGB(14,116,144),Color3.fromRGB(186,230,253),Color3.fromRGB(255,255,255)},
    ["Midnight"]={Color3.fromRGB(15,23,42),Color3.fromRGB(67,56,202),Color3.fromRGB(30,41,59)},
    ["Galaxy"]={Color3.fromRGB(49,46,129),Color3.fromRGB(126,34,206),Color3.fromRGB(190,24,93)},
    ["Nebula"]={Color3.fromRGB(30,27,75),Color3.fromRGB(109,40,217),Color3.fromRGB(219,39,119)},
    ["Cyber"]={Color3.fromRGB(6,78,59),Color3.fromRGB(0,255,190),Color3.fromRGB(34,211,238)},
    ["Matrix"]={Color3.fromRGB(3,46,21),Color3.fromRGB(34,197,94),Color3.fromRGB(134,239,172)},
    ["Steel"]={Color3.fromRGB(30,41,59),Color3.fromRGB(100,116,139),Color3.fromRGB(203,213,225)},
    ["Silver"]={Color3.fromRGB(63,63,70),Color3.fromRGB(161,161,170),Color3.fromRGB(244,244,245)},
    ["Monochrome"]={Color3.fromRGB(10,10,10),Color3.fromRGB(70,70,70),Color3.fromRGB(18,18,18)},
    ["Black Violet"]={Color3.fromRGB(5,5,7),Color3.fromRGB(91,33,182),Color3.fromRGB(5,5,7)},
    ["Black Red"]={Color3.fromRGB(5,5,5),Color3.fromRGB(153,27,27),Color3.fromRGB(5,5,5)},
    ["Black Blue"]={Color3.fromRGB(5,5,7),Color3.fromRGB(30,64,175),Color3.fromRGB(5,5,7)},
    ["RGB"]={Color3.fromRGB(255,0,0),Color3.fromRGB(0,255,0),Color3.fromRGB(0,85,255)},
}
local GRADIENT_LIST = {
    "Violet Dream","Purple Neon","Blue Neon","Ocean","Aqua","Emerald","Lime","Gold","Amber","Sunset",
    "Fire","Crimson","Rose","Sakura","Candy","Cotton Candy","Ice","Arctic","Midnight","Galaxy",
    "Nebula","Cyber","Matrix","Steel","Silver","Monochrome","Black Violet","Black Red","Black Blue","RGB","Custom",
}


--============================================================
-- LOCALIZATION
--============================================================

-- Auto follows the language selected in Roblox through
-- LocalizationService.RobloxLocaleId. Unsupported locales use English.
local LANGUAGE_CHOICES = {
    "Auto (Roblox)",
    "English",
    "Русский",
    "Українська",
    "Español",
    "Deutsch",
    "Français",
    "Português",
    "Polski",
    "Türkçe",
}

local LANGUAGE_DISPLAY_TO_CODE = {
    ["Auto (Roblox)"] = "Auto",
    ["English"] = "en",
    ["Русский"] = "ru",
    ["Українська"] = "uk",
    ["Español"] = "es",
    ["Deutsch"] = "de",
    ["Français"] = "fr",
    ["Português"] = "pt",
    ["Polski"] = "pl",
    ["Türkçe"] = "tr",
}

local LANGUAGE_CODE_TO_DISPLAY = {
    Auto = "Auto (Roblox)",
    en = "English",
    ru = "Русский",
    uk = "Українська",
    es = "Español",
    de = "Deutsch",
    fr = "Français",
    pt = "Português",
    pl = "Polski",
    tr = "Türkçe",
}

local LOCALE_PREFIX_MAP = {
    en = "en", ru = "ru", uk = "uk", es = "es", de = "de",
    fr = "fr", pt = "pt", pl = "pl", tr = "tr",
}

local LOCALIZATION = {
    en = {
        Settings="Settings", Interface="Interface", Animations="Animations", Tooltips="Tooltips",
        Theme="Theme", Watermarks="Watermarks", Configs="Configs", Home="Home",
        Language="Language", GraphicsLevel="Graphics Level", Font="Font", TextSize="Text Size",
        DPIScale="DPI Scale", AutoFitToDisplay="Auto Fit To Display", FunctionDPI="Function DPI",
        MenuKeybind="Menu Keybind", CornerRadius="Corner Radius", BackgroundBlur="Background Blur",
        BlurStrength="Blur Strength", BackgroundDim="Background Dim", DimAmount="Dim Amount",
        ControlMotion="Control Motion", OpenAnimation="Open Animation", AnimationSpeed="Animation Speed",
        WindowDragging="Window Dragging", DragFollowSpeed="Drag Follow Speed",
        FunctionTooltips="Function Tooltips", TooltipDelay="Tooltip Delay", TooltipFollowSpeed="Tooltip Follow Speed",
        ThemePreset="Theme Preset", Accent="Accent", Background="Background", Outline="Outline",
        ControlBackground="Control Background", EnableWatermark="Enable Watermark", WatermarkText="Watermark Text",
        ShowGraphicsLevel="Show Graphics Level", ShowFPS="Show FPS", ShowPing="Show Ping",
        ShowOSTime="Show OS Time", DraggableWatermark="Draggable Watermark",
        ResetWatermarkPosition="Reset Watermark Position", ConfigName="Config Name",
        SaveCurrentConfig="Save Current Config", LoadConfig="Load Config", AutoloadConfig="Autoload Config",
        SetAsAutoload="Set As Autoload", QueueOnTeleport="Queue On Teleport",
        Reset="Reset", Save="Save", Load="Load", Set="Set", Queue="Queue",
        NoDescription="No description provided.", NotSpecified="not specified",
        Graphics="Graphics", Locked="LOCKED", Available="AVAILABLE",
        FPSImpact="FPS impact", PingImpact="Ping impact",
        TooltipDesc="Shows the function description and estimated FPS / ping impact while hovering a row.",
        TooltipDelayDesc="Delay before a hover tooltip appears. Value is stored as hundredths of a second.",
        TooltipFollowDesc="How quickly the tooltip catches up with the mouse. Lower values create more visible lag.",
        GreetingNight="Good night.", GreetingWhyAwake="Why are you still awake?",
        GreetingEarly="Did you wake up early or not sleep?", GreetingMorning="Good morning.",
        GreetingEvening="Good evening.", GreetingSleepSoon="You should probably sleep soon.",
        HelloUser="Hello, %s. %s",
        LoadingInterface="Loading interface...", LoadingModules="Loading modules...",
        PreparingInterface="Preparing interface...", ApplyingConfiguration="Applying configuration...",
        Finalizing="Finalizing...", Ready="Ready",
        Question="Question", Confirmation="Confirmation", Yes="Yes", No="No", Continue="Continue",
        Notifications="Notifications", NotificationPosition="Notification Position",
        NotificationDuration="Notification Duration", NotificationLimit="Notification Limit",
        Profiles="Profiles", ActiveProfile="Active Profile", ApplyProfile="Apply Profile",
        Keybinds="Keybinds", EnableKeybindList="Enable Keybind List", KeybindListPosition="Keybind List Position",
        SearchPlaceholder="Search functions...", Favorites="Favorites",
        HoverHighlight="Hover Highlight", ConfigList="Config List", RefreshConfigs="Refresh Configs",
        DeleteConfig="Delete Config", NewConfigName="New Config Name",
        PerformanceProfile="Performance", BalancedProfile="Balanced", BeautyProfile="Beauty", CustomProfile="Custom",
        Favorite="Favorite", Unfavorite="Remove Favorite", ResetValue="Reset to Default", CopyValue="Copy Value",
        Mobile="Mobile", MobileButtonEnabled="Show Mobile Button", MobileButtonText="Mobile Button Text",
        MobileButtonSize="Mobile Button Size", MobileButtonOpacity="Mobile Button Opacity",
        MobileButtonDraggable="Draggable Mobile Button", ResetMobileButton="Reset Mobile Button Position",
        Gradients="Gradients", EnableGradients="Enable Gradients", GradientPreset="Gradient Preset",
        GradientAnimation="Animate Gradient", GradientSpeed="Gradient Speed", GradientRotation="Gradient Rotation", GradientIntensity="Gradient Intensity",
        GradientColorA="Gradient Color A", GradientColorB="Gradient Color B",
        RGBMenuStyle="RGB Menu Style", RGBSpeed="RGB Speed",
    },

    ru = {
        Settings="Настройки", Interface="Интерфейс", Animations="Анимации", Tooltips="Подсказки",
        Theme="Тема", Watermarks="Вотермарки", Configs="Конфиги", Home="Главная",
        Language="Язык", GraphicsLevel="Уровень графики", Font="Шрифт", TextSize="Размер текста",
        DPIScale="Масштаб DPI", AutoFitToDisplay="Автоподгон под экран", FunctionDPI="DPI функций",
        MenuKeybind="Клавиша меню", CornerRadius="Скругление", BackgroundBlur="Размытие фона",
        BlurStrength="Сила размытия", BackgroundDim="Затемнение фона", DimAmount="Сила затемнения",
        ControlMotion="Движение элементов", OpenAnimation="Анимация меню", AnimationSpeed="Скорость анимаций",
        WindowDragging="Перетаскивание окна", DragFollowSpeed="Скорость следования",
        FunctionTooltips="Подсказки функций", TooltipDelay="Задержка подсказки", TooltipFollowSpeed="Скорость подсказки",
        ThemePreset="Пресет темы", Accent="Акцент", Background="Фон", Outline="Обводка",
        ControlBackground="Фон функций", EnableWatermark="Включить вотермарк", WatermarkText="Текст вотермарка",
        ShowGraphicsLevel="Показывать графику", ShowFPS="Показывать FPS", ShowPing="Показывать пинг",
        ShowOSTime="Показывать время ОС", DraggableWatermark="Перетаскиваемый вотермарк",
        ResetWatermarkPosition="Сбросить позицию вотермарка", ConfigName="Имя конфига",
        SaveCurrentConfig="Сохранить конфиг", LoadConfig="Загрузить конфиг", AutoloadConfig="Автозагрузка конфига",
        SetAsAutoload="Сделать автозагрузкой", QueueOnTeleport="Запуск после телепорта",
        Reset="Сброс", Save="Сохранить", Load="Загрузить", Set="Установить", Queue="Добавить",
        NoDescription="Описание не указано.", NotSpecified="не указано",
        Graphics="Графика", Locked="НЕДОСТУПНО", Available="ДОСТУПНО",
        FPSImpact="Влияние на FPS", PingImpact="Влияние на пинг",
        TooltipDesc="Показывает описание функции и примерное влияние на FPS и пинг при наведении.",
        TooltipDelayDesc="Задержка перед появлением подсказки. Значение хранится в сотых долях секунды.",
        TooltipFollowDesc="Насколько быстро подсказка догоняет мышь. Меньшее значение даёт большее отставание.",
        GreetingNight="Доброй ночи.", GreetingWhyAwake="Почему не спишь?",
        GreetingEarly="Ты проснулся рано или не спал?", GreetingMorning="Доброе утро.",
        GreetingEvening="Доброго вечера.", GreetingSleepSoon="Тебе скоро спать.",
        HelloUser="Привет, %s. %s",
        LoadingInterface="Загрузка интерфейса...", LoadingModules="Загрузка модулей...",
        PreparingInterface="Подготовка интерфейса...", ApplyingConfiguration="Применение конфигурации...",
        Finalizing="Завершение...", Ready="Готово",
        Question="Вопрос", Confirmation="Подтверждение", Yes="Да", No="Нет", Continue="Продолжить",
        Notifications="Уведомления", NotificationPosition="Позиция уведомлений",
        NotificationDuration="Длительность уведомлений", NotificationLimit="Лимит уведомлений",
        Profiles="Профили", ActiveProfile="Активный профиль", ApplyProfile="Применить профиль",
        Keybinds="Кейбинды", EnableKeybindList="Список кейбиндов", KeybindListPosition="Позиция списка кейбиндов",
        SearchPlaceholder="Поиск функций...", Favorites="Избранное",
        HoverHighlight="Цвет подсветки", ConfigList="Список конфигов", RefreshConfigs="Обновить конфиги",
        DeleteConfig="Удалить конфиг", NewConfigName="Имя нового конфига",
        PerformanceProfile="Производительность", BalancedProfile="Баланс", BeautyProfile="Красота", CustomProfile="Свой",
        Favorite="В избранное", Unfavorite="Убрать из избранного", ResetValue="Сбросить", CopyValue="Копировать значение",
        Mobile="Телефон", MobileButtonEnabled="Показывать кнопку GUI", MobileButtonText="Текст кнопки GUI",
        MobileButtonSize="Размер кнопки GUI", MobileButtonOpacity="Прозрачность кнопки GUI",
        MobileButtonDraggable="Перетаскиваемая кнопка GUI", ResetMobileButton="Сбросить позицию кнопки GUI",
        Gradients="Градиенты", EnableGradients="Включить градиенты", GradientPreset="Пресет градиента",
        GradientAnimation="Анимация градиента", GradientSpeed="Скорость градиента", GradientRotation="Поворот градиента", GradientIntensity="Интенсивность градиента",
        GradientColorA="Цвет градиента A", GradientColorB="Цвет градиента B",
        RGBMenuStyle="RGB стиль меню", RGBSpeed="Скорость RGB",
    },

    uk = {
        Settings="Налаштування", Interface="Інтерфейс", Animations="Анімації", Tooltips="Підказки",
        Theme="Тема", Watermarks="Вотермарки", Configs="Конфіги", Home="Головна",
        Language="Мова", GraphicsLevel="Рівень графіки", Font="Шрифт", TextSize="Розмір тексту",
        DPIScale="Масштаб DPI", AutoFitToDisplay="Автопідгонка під екран", FunctionDPI="DPI функцій",
        MenuKeybind="Клавіша меню", CornerRadius="Заокруглення", BackgroundBlur="Розмиття фону",
        BlurStrength="Сила розмиття", BackgroundDim="Затемнення фону", DimAmount="Сила затемнення",
        ControlMotion="Рух елементів", OpenAnimation="Анімація меню", AnimationSpeed="Швидкість анімацій",
        WindowDragging="Перетягування вікна", DragFollowSpeed="Швидкість слідування",
        FunctionTooltips="Підказки функцій", TooltipDelay="Затримка підказки", TooltipFollowSpeed="Швидкість підказки",
        ThemePreset="Пресет теми", Accent="Акцент", Background="Фон", Outline="Обводка",
        ControlBackground="Фон функцій", EnableWatermark="Увімкнути вотермарк", WatermarkText="Текст вотермарка",
        ShowGraphicsLevel="Показувати графіку", ShowFPS="Показувати FPS", ShowPing="Показувати пінг",
        ShowOSTime="Показувати час ОС", DraggableWatermark="Перетягуваний вотермарк",
        ResetWatermarkPosition="Скинути позицію вотермарка", ConfigName="Назва конфіга",
        SaveCurrentConfig="Зберегти конфіг", LoadConfig="Завантажити конфіг", AutoloadConfig="Автозавантаження конфіга",
        SetAsAutoload="Зробити автозавантаженням", QueueOnTeleport="Запуск після телепорту",
        Reset="Скинути", Save="Зберегти", Load="Завантажити", Set="Встановити", Queue="Додати",
        NoDescription="Опис не вказано.", NotSpecified="не вказано",
        Graphics="Графіка", Locked="НЕДОСТУПНО", Available="ДОСТУПНО",
        FPSImpact="Вплив на FPS", PingImpact="Вплив на пінг",
        TooltipDesc="Показує опис функції та приблизний вплив на FPS і пінг при наведенні.",
        TooltipDelayDesc="Затримка перед появою підказки. Значення зберігається у сотих частках секунди.",
        TooltipFollowDesc="Наскільки швидко підказка наздоганяє мишу. Менше значення дає більше відставання.",
        GreetingNight="Доброї ночі.", GreetingWhyAwake="Чому не спиш?",
        GreetingEarly="Ти прокинувся рано чи не спав?", GreetingMorning="Доброго ранку.",
        GreetingEvening="Доброго вечора.", GreetingSleepSoon="Тобі скоро спати.",
        HelloUser="Привіт, %s. %s",
        LoadingInterface="Завантаження інтерфейсу...", LoadingModules="Завантаження модулів...",
        PreparingInterface="Підготовка інтерфейсу...", ApplyingConfiguration="Застосування конфігурації...",
        Finalizing="Завершення...", Ready="Готово",
        Question="Питання", Confirmation="Підтвердження", Yes="Так", No="Ні", Continue="Продовжити",
    },
