            AutoFitDPI = self.Settings.AutoFitDPI,
            FunctionDPIPreset = self.Settings.FunctionDPIPreset,
            TextScale = self.Settings.TextScale,
            CornerRadius = self.Settings.CornerRadius,
            BlurEnabled = self.Settings.BlurEnabled,
            BlurSize = self.Settings.BlurSize,
            DimEnabled = self.Settings.DimEnabled,
            DimTransparency = self.Settings.DimTransparency,
            AnimationMode = self.Settings.AnimationMode,
            OpenAnimation = self.Settings.OpenAnimation,
            AnimationSpeed = self.Settings.AnimationSpeed,
            DragMode = self.Settings.DragMode,
            DragSmoothness = self.Settings.DragSmoothness,
            TooltipsEnabled = self.Settings.TooltipsEnabled,
            TooltipDelay = self.Settings.TooltipDelay,
            TooltipFollowSpeed = self.Settings.TooltipFollowSpeed,
            NotificationPosition = self.Settings.NotificationPosition,
            NotificationDuration = self.Settings.NotificationDuration,
            NotificationLimit = self.Settings.NotificationLimit,
            KeybindListEnabled = self.Settings.KeybindListEnabled,
            KeybindListPosition = self.Settings.KeybindListPosition,
            KeybindListCustomPosition = self.Settings.KeybindListCustomPosition,
            StartupWizardEnabled = self.Settings.StartupWizardEnabled,
            RGBMenuStyle = self.Settings.RGBMenuStyle,
            RGBSpeed = self.Settings.RGBSpeed,
            GradientsEnabled = self.Settings.GradientsEnabled,
            GradientPreset = self.Settings.GradientPreset,
            GradientAnimated = self.Settings.GradientAnimated,
            GradientSpeed = self.Settings.GradientSpeed,
            GradientRotation = self.Settings.GradientRotation,
            GradientIntensity = self.Settings.GradientIntensity,
            GradientColorA = encodeValue(self.Settings.GradientColorA),
            GradientColorB = encodeValue(self.Settings.GradientColorB),
            MobileButtonEnabled = self.Settings.MobileButtonEnabled,
            MobileButtonText = self.Settings.MobileButtonText,
            MobileButtonSize = self.Settings.MobileButtonSize,
            MobileButtonOpacity = self.Settings.MobileButtonOpacity,
            MobileButtonDraggable = self.Settings.MobileButtonDraggable,
            MobileButtonPosition = self.Settings.MobileButtonPosition,
            ActiveProfile = self.ActiveProfile,
            ThemeName = self.ThemeName,
            WatermarkEnabled = self.Settings.WatermarkEnabled,
            WatermarkText = self.Settings.WatermarkText,
            WatermarkShowGraphics = self.Settings.WatermarkShowGraphics,
            WatermarkShowFPS = self.Settings.WatermarkShowFPS,
            WatermarkShowPing = self.Settings.WatermarkShowPing,
            WatermarkShowTime = self.Settings.WatermarkShowTime,
            WatermarkDraggable = self.Settings.WatermarkDraggable,
            WatermarkX = self.Settings.WatermarkX,
            WatermarkY = self.Settings.WatermarkY,
        },
        theme = {},
    }

    for flag, value in pairs(self.Flags) do
        result.flags[flag] = encodeValue(value)
    end

    for key, value in pairs(self.Theme) do
        result.theme[key] = encodeValue(value)
    end

    return result
end

function Library:RegisterConfigMigration(fromVersion, callback)
    fromVersion = tonumber(fromVersion)
    if not fromVersion or type(callback) ~= "function" then
        return self
    end

    self.ConfigMigrations[fromVersion] = callback
    return self
end

function Library:RunConfigMigrations(data)
    if type(data) ~= "table" then
        return data
    end

    local version = tonumber(data.version) or 1
    local guard = 0

    while version < 21 and guard < 32 do
        guard += 1
        local migration = self.ConfigMigrations[version]

        if migration then
            local ok, migrated = pcall(migration, data)
            if ok and type(migrated) == "table" then
                data = migrated
            elseif not ok then
                warn("[Experiment17 UI] Config migration failed:", migrated)
                break
            end
        end

        version += 1
        data.version = version
    end

    return data
end

function Library:ImportConfig(data)
    if type(data) ~= "table" then
        return false
    end

    data = self:RunConfigMigrations(data)

    local settings = data.settings or {}

    if settings.Language ~= nil then
        self:SetLanguage(settings.Language)
    end

    if settings.ThemeName and THEMES[settings.ThemeName] then
        self:ApplyThemePreset(settings.ThemeName)
    end

    if type(data.theme) == "table" then
        for key, value in pairs(data.theme) do
            local decoded = decodeValue(value)
            if self.Theme[key] and typeof(decoded) == "Color3" then
                self.Theme[key] = decoded
            end
        end
        self:RefreshTheme()
    end

    if settings.Font then
        self:SetFont(settings.Font)
    end
    if settings.MenuKey and Enum.KeyCode[tostring(settings.MenuKey)] then
        self.Settings.MenuKey = tostring(settings.MenuKey)
    end
    if settings.AutoFitDPI ~= nil then
        self.Settings.AutoFitDPI = settings.AutoFitDPI == true
    end
    if settings.FunctionDPIPreset and FUNCTION_DPI_VALUES[tostring(settings.FunctionDPIPreset)] then
        self.Settings.FunctionDPIPreset = tostring(settings.FunctionDPIPreset)
    end
    if settings.TextScale ~= nil then
        self.Settings.TextScale = math.clamp(tonumber(settings.TextScale) or 100, 50, 200)
    end
    if settings.DPIPreset and DPI_VALUES[tostring(settings.DPIPreset)] then
        self:SetDPIPreset(tostring(settings.DPIPreset))
    else
        self:ApplyDPIScale()
    end
    self:ApplyFunctionDPIScale()
    self:SetTextScale(self.Settings.TextScale)
    if settings.CornerRadius ~= nil then
        self:SetCornerRadius(settings.CornerRadius)
    end
    if settings.GraphicsLevel then
        self:SetGraphicsLevel(settings.GraphicsLevel)
    end

    if settings.BlurEnabled ~= nil then self.Settings.BlurEnabled = settings.BlurEnabled end
    if settings.BlurSize ~= nil then self.Settings.BlurSize = settings.BlurSize end
    if settings.DimEnabled ~= nil then self.Settings.DimEnabled = settings.DimEnabled end
    if settings.DimTransparency ~= nil then self.Settings.DimTransparency = settings.DimTransparency end
    if settings.AnimationMode then self.Settings.AnimationMode = settings.AnimationMode end
    if settings.OpenAnimation then self.Settings.OpenAnimation = settings.OpenAnimation end
    if settings.AnimationSpeed then self.Settings.AnimationSpeed = settings.AnimationSpeed end
    if settings.DragMode == "Smooth" or settings.DragMode == "Direct" then self.Settings.DragMode = settings.DragMode end
    if settings.DragSmoothness ~= nil then self.Settings.DragSmoothness = math.clamp(tonumber(settings.DragSmoothness) or 16, 5, 40) end
    if settings.TooltipsEnabled ~= nil then self.Settings.TooltipsEnabled = settings.TooltipsEnabled == true end
    if settings.TooltipDelay ~= nil then self.Settings.TooltipDelay = math.clamp(tonumber(settings.TooltipDelay) or 0.12, 0, 1) end
    if settings.TooltipFollowSpeed ~= nil then self.Settings.TooltipFollowSpeed = math.clamp(tonumber(settings.TooltipFollowSpeed) or 22, 5, 50) end
    if settings.NotificationPosition then self.Settings.NotificationPosition = tostring(settings.NotificationPosition) end
    if settings.RGBMenuStyle ~= nil then self.Settings.RGBMenuStyle = settings.RGBMenuStyle == true end
    if settings.RGBSpeed ~= nil then self.Settings.RGBSpeed = math.clamp(tonumber(settings.RGBSpeed) or 0.12, 0.02, 1) end
    if settings.GradientsEnabled ~= nil then self.Settings.GradientsEnabled = settings.GradientsEnabled == true end
    if settings.GradientPreset then self.Settings.GradientPreset = tostring(settings.GradientPreset) end
    if settings.GradientAnimated ~= nil then self.Settings.GradientAnimated = settings.GradientAnimated == true end
    if settings.GradientSpeed ~= nil then self.Settings.GradientSpeed = math.clamp(tonumber(settings.GradientSpeed) or 24, 0, 180) end
    if settings.GradientRotation ~= nil then self.Settings.GradientRotation = tonumber(settings.GradientRotation) or 25 end
    if settings.GradientIntensity ~= nil then self.Settings.GradientIntensity = math.clamp(tonumber(settings.GradientIntensity) or 28, 0, 100) end
    local ga = decodeValue(settings.GradientColorA)
    if typeof(ga) == "Color3" then self.Settings.GradientColorA = ga end
    local gb = decodeValue(settings.GradientColorB)
    if typeof(gb) == "Color3" then self.Settings.GradientColorB = gb end
    if settings.MobileButtonEnabled ~= nil then self.Settings.MobileButtonEnabled = settings.MobileButtonEnabled == true end
    if settings.MobileButtonText ~= nil then self.Settings.MobileButtonText = tostring(settings.MobileButtonText) end
    if settings.MobileButtonSize ~= nil then self.Settings.MobileButtonSize = math.clamp(tonumber(settings.MobileButtonSize) or 54, 36, 96) end
    if settings.MobileButtonOpacity ~= nil then self.Settings.MobileButtonOpacity = math.clamp(tonumber(settings.MobileButtonOpacity) or 100, 20, 100) end
    if settings.MobileButtonDraggable ~= nil then self.Settings.MobileButtonDraggable = settings.MobileButtonDraggable == true end
    if type(settings.MobileButtonPosition) == "table" then
        self.Settings.MobileButtonPosition = {X=tonumber(settings.MobileButtonPosition.X), Y=tonumber(settings.MobileButtonPosition.Y)}
    end
    if settings.NotificationDuration ~= nil then self.Settings.NotificationDuration = math.clamp(tonumber(settings.NotificationDuration) or 4, 1, 30) end
    if settings.NotificationLimit ~= nil then self.Settings.NotificationLimit = math.clamp(math.floor(tonumber(settings.NotificationLimit) or 5), 1, 10) end
    if settings.KeybindListEnabled ~= nil then self.Settings.KeybindListEnabled = settings.KeybindListEnabled == true end
    if settings.KeybindListPosition then self.Settings.KeybindListPosition = tostring(settings.KeybindListPosition) end
    if settings.StartupWizardEnabled ~= nil then
        self.Settings.StartupWizardEnabled = settings.StartupWizardEnabled == true
    end

    if type(settings.KeybindListCustomPosition) == "table" then
        local saved = settings.KeybindListCustomPosition

        if tonumber(saved.XScale) ~= nil
            and tonumber(saved.XOffset) ~= nil
            and tonumber(saved.YScale) ~= nil
            and tonumber(saved.YOffset) ~= nil
        then
            self.Settings.KeybindListCustomPosition = {
                XScale = tonumber(saved.XScale),
                XOffset = tonumber(saved.XOffset),
                YScale = tonumber(saved.YScale),
                YOffset = tonumber(saved.YOffset),
                AnchorX = tonumber(saved.AnchorX) or 0,
                AnchorY = tonumber(saved.AnchorY) or 0,
            }
        else
            -- v14 compatibility
            self.Settings.KeybindListCustomPosition = {
                X = tonumber(saved.X or saved.x),
                Y = tonumber(saved.Y or saved.y),
            }
        end
    else
        self.Settings.KeybindListCustomPosition = nil
    end
    if settings.ActiveProfile then self.ActiveProfile = tostring(settings.ActiveProfile) end
