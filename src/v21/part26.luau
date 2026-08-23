    Default = Library.Settings.BlurEnabled,
    RequiredGraphics = "LM",
    Callback = function(v)
        Library.Settings.BlurEnabled = v
        Library:RefreshBackdrop()
    end,
})
InterfaceSection:AddSlider({
    Name = Library:L("BlurStrength"),
    LocaleKey = "BlurStrength",
    Flag = "UI_BlurSize",
    Min = 0,
    Max = 40,
    Default = Library.Settings.BlurSize,
    RequiredGraphics = "LM",
    Callback = function(v)
        Library.Settings.BlurSize = v
        Library:RefreshBackdrop()
    end,
})
InterfaceSection:AddToggle({
    Name = Library:L("BackgroundDim"),
    LocaleKey = "BackgroundDim",
    Flag = "UI_Dim",
    Default = Library.Settings.DimEnabled,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library.Settings.DimEnabled = v
        Library:RefreshBackdrop()
    end,
})
InterfaceSection:AddSlider({
    Name = Library:L("DimAmount"),
    LocaleKey = "DimAmount",
    Flag = "UI_DimAmount",
    Min = 0,
    Max = 90,
    Default = math.floor((1 - Library.Settings.DimTransparency) * 100),
    RequiredGraphics = "Low",
    Callback = function(v)
        Library.Settings.DimTransparency = 1 - (v / 100)
        Library:RefreshBackdrop()
    end,
})

-- SETTINGS: mobile
local MobileSection = SettingsTab:CreateSection(Library:L("Mobile"), false, "Mobile")
MobileSection:AddToggle({
    Name = Library:L("MobileButtonEnabled"),
    LocaleKey = "MobileButtonEnabled",
    Flag = "UI_MobileButtonEnabled",
    Default = Library.Settings.MobileButtonEnabled,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library.Settings.MobileButtonEnabled = v == true
        Library:RefreshMobileButton()
    end,
})
MobileSection:AddInput({
    Name = Library:L("MobileButtonText"),
    LocaleKey = "MobileButtonText",
    Flag = "UI_MobileButtonText",
    Default = Library.Settings.MobileButtonText,
    Placeholder = "E17",
    RequiredGraphics = "Low",
    Callback = function(v)
        Library.Settings.MobileButtonText = tostring(v)
        Library:RefreshMobileButton()
    end,
})
MobileSection:AddSlider({
    Name = Library:L("MobileButtonSize"),
    LocaleKey = "MobileButtonSize",
    Flag = "UI_MobileButtonSize",
    Min = 36,
    Max = 96,
    Default = Library.Settings.MobileButtonSize,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library.Settings.MobileButtonSize = v
        Library:RefreshMobileButton()
    end,
})
MobileSection:AddSlider({
    Name = Library:L("MobileButtonOpacity"),
    LocaleKey = "MobileButtonOpacity",
    Flag = "UI_MobileButtonOpacity",
    Min = 20,
    Max = 100,
    Default = Library.Settings.MobileButtonOpacity,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library.Settings.MobileButtonOpacity = v
        Library:RefreshMobileButton()
    end,
})
MobileSection:AddToggle({
    Name = Library:L("MobileButtonDraggable"),
    LocaleKey = "MobileButtonDraggable",
    Flag = "UI_MobileButtonDraggable",
    Default = Library.Settings.MobileButtonDraggable,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library.Settings.MobileButtonDraggable = v == true
    end,
})
MobileSection:AddButton({
    Name = Library:L("ResetMobileButton"),
    LocaleKey = "ResetMobileButton",
    ButtonText = Library:L("Reset"),
    ButtonLocaleKey = "Reset",
    RequiredGraphics = "Low",
    Callback = function()
        Library.Settings.MobileButtonPosition = nil
        Library:RefreshMobileButton()
    end,
})

-- SETTINGS: animations
-- These controls are one related group, therefore there are no separators.
local AnimationSection = SettingsTab:CreateSection(Library:L("Animations"), false, "Animations")
AnimationSection:AddChoice({
    Name = Library:L("ControlMotion"),
    LocaleKey = "ControlMotion",
    Flag = "UI_AnimationMode",
    Values = {"Smooth", "Stepped"},
    Default = Library.Settings.AnimationMode,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library.Settings.AnimationMode = v
    end,
})
AnimationSection:AddChoice({
    Name = Library:L("OpenAnimation"),
    LocaleKey = "OpenAnimation",
    Flag = "UI_OpenAnimation",
    Values = {"Scale", "Slide", "Fade", "None"},
    Default = Library.Settings.OpenAnimation,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library.Settings.OpenAnimation = v
    end,
})
AnimationSection:AddSlider({
    Name = Library:L("AnimationSpeed"),
    LocaleKey = "AnimationSpeed",
    Flag = "UI_AnimationSpeed",
    Min = 5,
    Max = 50,
    Default = math.floor(Library.Settings.AnimationSpeed * 100),
    RequiredGraphics = "Low",
    Callback = function(v)
        Library.Settings.AnimationSpeed = v / 100
    end,
})
AnimationSection:AddSeparator()
AnimationSection:AddChoice({
    Name = Library:L("WindowDragging"),
    LocaleKey = "WindowDragging",
    Flag = "UI_DragMode",
    Values = {"Smooth", "Direct"},
    Default = Library.Settings.DragMode,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library.Settings.DragMode = v
    end,
})
AnimationSection:AddSlider({
    Name = Library:L("DragFollowSpeed"),
    LocaleKey = "DragFollowSpeed",
    Flag = "UI_DragSmoothness",
    Min = 5,
    Max = 40,
    Default = Library.Settings.DragSmoothness,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library.Settings.DragSmoothness = v
    end,
})

-- SETTINGS: tooltips
local TooltipSection = SettingsTab:CreateSection(Library:L("Tooltips"), false, "Tooltips")
TooltipSection:AddToggle({
    Name = Library:L("FunctionTooltips"),
    LocaleKey = "FunctionTooltips",
    Flag = "UI_TooltipsEnabled",
    Default = Library.Settings.TooltipsEnabled,
    RequiredGraphics = "Low",
    DescriptionKey = "TooltipDesc",
    FPSImpact = 0,
    PingImpact = 0,
    Callback = function(v)
        Library.Settings.TooltipsEnabled = v == true
        if not Library.Settings.TooltipsEnabled then
            Library:HideControlTooltip(true)
        end
    end,
})
TooltipSection:AddSlider({
    Name = Library:L("TooltipDelay"),
    LocaleKey = "TooltipDelay",
    Flag = "UI_TooltipDelay",
    Min = 0,
    Max = 100,
    Default = math.floor((Library.Settings.TooltipDelay or 0.12) * 100),
    RequiredGraphics = "Low",
    DescriptionKey = "TooltipDelayDesc",
    FPSImpact = 0,
    PingImpact = 0,
    Callback = function(v)
        Library.Settings.TooltipDelay = v / 100
    end,
})
TooltipSection:AddSlider({
    Name = Library:L("TooltipFollowSpeed"),
    LocaleKey = "TooltipFollowSpeed",
    Flag = "UI_TooltipFollowSpeed",
    Min = 5,
    Max = 50,
    Default = Library.Settings.TooltipFollowSpeed,
    RequiredGraphics = "Low",
    DescriptionKey = "TooltipFollowDesc",
    FPSImpact = 0,
    PingImpact = 0,
    Callback = function(v)
        Library.Settings.TooltipFollowSpeed = v
    end,
})

-- SETTINGS: themes
local ThemeSection = SettingsTab:CreateSection(Library:L("Theme"), false, "Theme")
ThemeSection:AddChoice({
    Name = Library:L("ThemePreset"),
    LocaleKey = "ThemePreset",
    Flag = "UI_ThemePreset",
    Values = THEME_LIST,
    Default = "Violet",
    RequiredGraphics = "Low",
    Callback = function(v)
        Library:ApplyThemePreset(v)
    end,
})
ThemeSection:AddToggle({
    Name = Library:L("RGBMenuStyle"),
    LocaleKey = "RGBMenuStyle",
    Flag = "UI_RGBMenuStyle",
    Default = Library.Settings.RGBMenuStyle,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library.Settings.RGBMenuStyle = v == true
        if not v and Library.ThemeName == "RGB" then
            Library:ApplyThemePreset("Violet")
        end
    end,
})
ThemeSection:AddSlider({
    Name = Library:L("RGBSpeed"),
    LocaleKey = "RGBSpeed",
    Flag = "UI_RGBSpeed",
    Min = 2,
    Max = 100,
    Default = math.floor((Library.Settings.RGBSpeed or 0.12) * 100),
    RequiredGraphics = "Low",
    Callback = function(v)
        Library.Settings.RGBSpeed = v / 100
    end,
})
ThemeSection:AddSeparator()
ThemeSection:AddColorPicker({
    Name = Library:L("Accent"),
    LocaleKey = "Accent",
    ThemeKey = "Accent",
    Flag = "UI_AccentColor",
    Default = Library.Theme.Accent,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library:SetThemeColor("Accent", v)
    end,
})
ThemeSection:AddColorPicker({
    Name = Library:L("Background"),
    LocaleKey = "Background",
    ThemeKey = "Background",
    Flag = "UI_BackgroundColor",
    Default = Library.Theme.Background,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library:SetThemeColor("Background", v)
    end,
})
ThemeSection:AddColorPicker({
    Name = Library:L("Outline"),
    LocaleKey = "Outline",
    ThemeKey = "Outline",
    Flag = "UI_OutlineColor",
    Default = Library.Theme.Outline,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library:SetThemeColor("Outline", v)
    end,
})
ThemeSection:AddColorPicker({
    Name = Library:L("ControlBackground"),
    LocaleKey = "ControlBackground",
    ThemeKey = "Control",
    Flag = "UI_ControlColor",
    Default = Library.Theme.Control,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library:SetThemeColor("Control", v)
    end,
})
ThemeSection:AddColorPicker({
    Name = Library:L("HoverHighlight"),
    LocaleKey = "HoverHighlight",
    ThemeKey = "Hover",
    Flag = "UI_HoverColor",
    Default = Library.Theme.Hover,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library:SetThemeColor("Hover", v)
    end,
})

-- SETTINGS: gradients
local GradientSection = SettingsTab:CreateSection(Library:L("Gradients"), false, "Gradients")
GradientSection:AddToggle({
    Name = Library:L("EnableGradients"),
    LocaleKey = "EnableGradients",
    Flag = "UI_GradientsEnabled",
    Default = Library.Settings.GradientsEnabled,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library.Settings.GradientsEnabled = v == true
        Library:RefreshGradients()
    end,
})
GradientSection:AddChoice({
    Name = Library:L("GradientPreset"),
    LocaleKey = "GradientPreset",
    Flag = "UI_GradientPreset",
    Values = GRADIENT_LIST,
    Default = Library.Settings.GradientPreset,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library.Settings.GradientPreset = v
        Library:RefreshGradients()
    end,
})
GradientSection:AddToggle({
    Name = Library:L("GradientAnimation"),
    LocaleKey = "GradientAnimation",
    Flag = "UI_GradientAnimated",
    Default = Library.Settings.GradientAnimated,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library.Settings.GradientAnimated = v == true
        Library:RefreshGradients()
    end,
})
GradientSection:AddSlider({
    Name = Library:L("GradientSpeed"),
    LocaleKey = "GradientSpeed",
    Flag = "UI_GradientSpeed",
    Min = 0,
    Max = 180,
    Default = Library.Settings.GradientSpeed,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library.Settings.GradientSpeed = v
    end,
})
GradientSection:AddSlider({
    Name = Library:L("GradientRotation"),
    LocaleKey = "GradientRotation",
    Flag = "UI_GradientRotation",
    Min = 0,
    Max = 360,
    Default = Library.Settings.GradientRotation,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library.Settings.GradientRotation = v
        Library:RefreshGradients()
    end,
})
GradientSection:AddSlider({
    Name = Library:L("GradientIntensity"),
    LocaleKey = "GradientIntensity",
    Flag = "UI_GradientIntensity",
    Min = 0,
    Max = 100,