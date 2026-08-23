    Default = Library.Settings.GradientIntensity,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library.Settings.GradientIntensity = v
        Library:RefreshGradients()
    end,
})
GradientSection:AddSeparator()
GradientSection:AddColorPicker({
    Name = Library:L("GradientColorA"),
    LocaleKey = "GradientColorA",
    Flag = "UI_GradientColorA",
    Default = Library.Settings.GradientColorA,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library.Settings.GradientColorA = v
        Library.Settings.GradientPreset = "Custom"
        Library:RefreshGradients()
    end,
})
GradientSection:AddColorPicker({
    Name = Library:L("GradientColorB"),
    LocaleKey = "GradientColorB",
    Flag = "UI_GradientColorB",
    Default = Library.Settings.GradientColorB,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library.Settings.GradientColorB = v
        Library.Settings.GradientPreset = "Custom"
        Library:RefreshGradients()
    end,
})

-- SETTINGS: watermarks
local WatermarkSection = SettingsTab:CreateSection(Library:L("Watermarks"), false, "Watermarks")
WatermarkSection:AddToggle({
    Name = Library:L("EnableWatermark"),
    LocaleKey = "EnableWatermark",
    Flag = "UI_WatermarkEnabled",
    Default = Library.Settings.WatermarkEnabled,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library.Settings.WatermarkEnabled = v == true
        Library:RefreshWatermark()
    end,
})
WatermarkSection:AddInput({
    Name = Library:L("WatermarkText"),
    LocaleKey = "WatermarkText",
    Flag = "UI_WatermarkText",
    Default = Library.Settings.WatermarkText,
    Placeholder = "Experiment 17 [Visuals]",
    RequiredGraphics = "Low",
    Callback = function(v)
        Library.Settings.WatermarkText = tostring(v)
        Library:RefreshWatermark()
    end,
})

-- Display fields are one related group.
WatermarkSection:AddSeparator()
WatermarkSection:AddToggle({
    Name = Library:L("ShowGraphicsLevel"),
    LocaleKey = "ShowGraphicsLevel",
    Flag = "UI_WatermarkGraphics",
    Default = Library.Settings.WatermarkShowGraphics,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library.Settings.WatermarkShowGraphics = v == true
        Library:RefreshWatermark()
    end,
})
WatermarkSection:AddToggle({
    Name = Library:L("ShowFPS"),
    LocaleKey = "ShowFPS",
    Flag = "UI_WatermarkFPS",
    Default = Library.Settings.WatermarkShowFPS,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library.Settings.WatermarkShowFPS = v == true
        Library:RefreshWatermark()
    end,
})
WatermarkSection:AddToggle({
    Name = Library:L("ShowPing"),
    LocaleKey = "ShowPing",
    Flag = "UI_WatermarkPing",
    Default = Library.Settings.WatermarkShowPing,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library.Settings.WatermarkShowPing = v == true
        Library:RefreshWatermark()
    end,
})
WatermarkSection:AddToggle({
    Name = Library:L("ShowOSTime"),
    LocaleKey = "ShowOSTime",
    Flag = "UI_WatermarkTime",
    Default = Library.Settings.WatermarkShowTime,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library.Settings.WatermarkShowTime = v == true
        Library:RefreshWatermark()
    end,
})

-- Positioning is its own group.
WatermarkSection:AddSeparator()
WatermarkSection:AddToggle({
    Name = Library:L("DraggableWatermark"),
    LocaleKey = "DraggableWatermark",
    Flag = "UI_WatermarkDraggable",
    Default = Library.Settings.WatermarkDraggable,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library.Settings.WatermarkDraggable = v == true
    end,
})
WatermarkSection:AddButton({
    Name = Library:L("ResetWatermarkPosition"),
    LocaleKey = "ResetWatermarkPosition",
    ButtonText = Library:L("Reset"),
    ButtonLocaleKey = "Reset",
    RequiredGraphics = "Low",
    Callback = function()
        Library:ResetWatermarkPosition()
    end,
})

-- SETTINGS: notifications
local NotificationSection = SettingsTab:CreateSection(Library:L("Notifications"), false, "Notifications")
NotificationSection:AddChoice({
    Name = Library:L("NotificationPosition"),
    LocaleKey = "NotificationPosition",
    Flag = "UI_NotificationPosition",
    Values = {"Top Left", "Top Center", "Top Right", "Bottom Left", "Bottom Center", "Bottom Right"},
    Default = Library.Settings.NotificationPosition,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library.Settings.NotificationPosition = v
        Library:ReflowNotifications()
    end,
})
NotificationSection:AddSlider({
    Name = Library:L("NotificationDuration"),
    LocaleKey = "NotificationDuration",
    Flag = "UI_NotificationDuration",
    Min = 1,
    Max = 15,
    Default = Library.Settings.NotificationDuration,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library.Settings.NotificationDuration = v
    end,
})
NotificationSection:AddSlider({
    Name = Library:L("NotificationLimit"),
    LocaleKey = "NotificationLimit",
    Flag = "UI_NotificationLimit",
    Min = 1,
    Max = 10,
    Default = Library.Settings.NotificationLimit,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library.Settings.NotificationLimit = math.floor(v)
    end,
})

-- SETTINGS: profiles
local ProfileSection = SettingsTab:CreateSection(Library:L("Profiles"), false, "Profiles")
local profileNames = {"Performance", "Balanced", "Beauty", "Custom"}
local ProfileChoice = ProfileSection:AddChoice({
    Name = Library:L("ActiveProfile"),
    LocaleKey = "ActiveProfile",
    Flag = "UI_Profile",
    Values = profileNames,
    Default = Library.ActiveProfile,
    RequiredGraphics = "Low",
    Callback = function(v)
        if v == "Custom" then
            Library.ActiveProfile = "Custom"
        else
            Library:ApplyProfile(v)
        end
    end,
})
Library.ProfileChoiceControl = ProfileChoice

ProfileSection:AddButton({
    Name = Library:L("ApplyProfile"),
    LocaleKey = "ApplyProfile",
    ButtonText = Library:L("ApplyProfile"),
    ButtonLocaleKey = "ApplyProfile",
    RequiredGraphics = "Low",
    Callback = function()
        local selected = ProfileChoice:Get()
        if selected ~= "Custom" then
            Library:ApplyProfile(selected)
            Library:Notify({
                Title = "Experiment 17",
                Text = "Profile: " .. tostring(selected),
                Type = "Success",
            })
        end
    end,
})

-- SETTINGS: keybinds
-- Penultimate built-in section. Configs are always last.
local KeybindSection = SettingsTab:CreateSection(Library:L("Keybinds"), false, "Keybinds")
KeybindSection:AddToggle({
    Name = Library:L("EnableKeybindList"),
    LocaleKey = "EnableKeybindList",
    Flag = "UI_KeybindList",
    Default = Library.Settings.KeybindListEnabled,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library.Settings.KeybindListEnabled = v == true
        Library:RefreshKeybindList()
    end,
})
KeybindSection:AddChoice({
    Name = Library:L("KeybindListPosition"),
    LocaleKey = "KeybindListPosition",
    Flag = "UI_KeybindListPosition",
    Values = {"Top Left", "Top Right", "Bottom Left", "Bottom Right"},
    Default = Library.Settings.KeybindListPosition,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library.Settings.KeybindListPosition = v
        Library.Settings.KeybindListCustomPosition = nil
        Library:RefreshKeybindList()
    end,
})
KeybindSection:AddKeybind({
    Name = Library:L("MenuKeybind"),
    LocaleKey = "MenuKeybind",
    Flag = "UI_MenuKey_Secondary",
    Default = Library.Settings.MenuKey,
    Mode = "Press",
    RequiredGraphics = "Low",
    Callback = function(v)
        Library.Settings.MenuKey = v
    end,
})

-- SETTINGS: configs
local ConfigSection = SettingsTab:CreateSection(Library:L("Configs"), false, "Configs")

local ConfigNameInput = ConfigSection:AddInput({
    Name = Library:L("NewConfigName"),
    LocaleKey = "NewConfigName",
    Flag = "UI_ConfigName",
    Default = "default",
    Placeholder = "config name",
    RequiredGraphics = "Low",
    Callback = function(v)
        Library.CurrentConfigName = sanitizeName(v)
    end,
})

local initialConfigs = Library:ListConfigs()
if #initialConfigs == 0 then
    initialConfigs = {"default"}
end

local ConfigListChoice = ConfigSection:AddChoice({
    Name = Library:L("ConfigList"),
    LocaleKey = "ConfigList",
    Flag = "UI_ConfigList",
    Values = initialConfigs,
    Default = initialConfigs[1],
    RequiredGraphics = "Low",
    Callback = function(v)
        Library.CurrentConfigName = sanitizeName(v)
    end,
})

local function refreshConfigList(selectNewest)
    local configs = Library:ListConfigs()
    if #configs == 0 then
        configs = {"default"}
    end

    ConfigListChoice:SetValues(configs, not selectNewest)

    if selectNewest and #configs > 0 then
        ConfigListChoice:Set(configs[#configs], true)
    end
end

ConfigSection:AddSeparator()
ConfigSection:AddButtonGroup({
    Name = Library:L("RefreshConfigs"),
    Buttons = {
        {
            Text = Library:L("Save"),
            Callback = function()
                local name = sanitizeName(ConfigNameInput:Get())
                if Library:SaveConfig(name) then
                    refreshConfigList(false)
                    ConfigListChoice:Set(name, true)
                    Library:Notify({Title = "Config", Text = "Saved: " .. name, Type = "Success"})
                end
            end,
        },
        {
            Text = Library:L("Load"),
            Callback = function()
                local name = ConfigListChoice:Get()
                if Library:LoadConfig(name) then
                    Library:Notify({Title = "Config", Text = "Loaded: " .. name, Type = "Success"})
                end
            end,
        },
        {
            Text = "↻",
            Callback = function()
                refreshConfigList(false)
            end,
        },
    },
})

ConfigSection:AddButton({
    Name = Library:L("DeleteConfig"),
    LocaleKey = "DeleteConfig",
    ButtonText = Library:L("DeleteConfig"),
    RequiredGraphics = "Low",
    Callback = function()
        local name = ConfigListChoice:Get()
        if Library:DeleteConfig(name) then
            refreshConfigList(false)
            Library:Notify({Title = "Config", Text = "Deleted: " .. tostring(name), Type = "Warning"})
        end
    end,
})

ConfigSection:AddSeparator()
ConfigSection:AddToggle({
    Name = Library:L("AutoloadConfig"),
    LocaleKey = "AutoloadConfig",
    Flag = "UI_AutoloadConfig",
    Default = true,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library:SetAutoload(ConfigListChoice:Get(), v)
    end,
})
ConfigSection:AddButton({
    Name = Library:L("SetAsAutoload"),
    LocaleKey = "SetAsAutoload",
    ButtonText = Library:L("Set"),
    ButtonLocaleKey = "Set",
    RequiredGraphics = "Low",
    Callback = function()
        Library:SetAutoload(ConfigListChoice:Get(), true)
        Library:Notify({Title = "Config", Text = "Autoload: " .. tostring(ConfigListChoice:Get())})
    end,
})

ConfigSection:AddSeparator()
ConfigSection:AddButton({
    Name = Library:L("QueueOnTeleport"),
    LocaleKey = "QueueOnTeleport",
    ButtonText = Library:L("Queue"),
    ButtonLocaleKey = "Queue",
    RequiredGraphics = "Low",
    Callback = function()
        local ok = Library:EnableTeleportAutoload()
        Library:Notify({