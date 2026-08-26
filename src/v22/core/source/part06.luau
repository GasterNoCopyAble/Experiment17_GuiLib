            value[code]
            or value.en
            or value.default
            or value[1]

        if resolved ~= nil then
            return tostring(resolved)
        end
    elseif value ~= nil then
        return tostring(value)
    end

    if fallback ~= nil then
        return tostring(fallback)
    end

    return ""
end

function Library:BindLocaleText(object, key, property)
    if not object or not key then
        return
    end

    property = property or "Text"
    object[property] = self:L(key)
    table.insert(self.LocalizationBindings, {
        Object = object,
        Key = key,
        Property = property,
    })
end

function Library:RefreshLocalization()
    for _, binding in ipairs(self.LocalizationBindings) do
        local object = binding.Object
        if object and object.Parent then
            object[binding.Property] = self:L(binding.Key)
        end
    end

    for _, tab in ipairs(self.Tabs or {}) do
        if tab.LocaleKey then
            tab.Name = self:L(tab.LocaleKey)
            if tab.TabText and tab.TabText.Parent then
                tab.TabText.Text = tab.Name
            end
        end
    end

    for _, control in ipairs(self.Controls or {}) do
        if control.LocaleKey then
            control.DisplayName = self:L(control.LocaleKey)
            if control.Label and control.Label.Parent then
                control.Label.Text = control.DisplayName
            end
        end
        if control.DescriptionKey then
            control.Description = self:L(control.DescriptionKey)
        end
    end

    if self.CurrentTab and self.Breadcrumb and self.Breadcrumb.Parent then
        self.Breadcrumb.Text = self.CurrentTab.LocaleKey and self:L(self.CurrentTab.LocaleKey) or self.CurrentTab.Name
    elseif self.Breadcrumb and self.Breadcrumb.Parent then
        self.Breadcrumb.Text = self:L("Home")
    end

    if self.LanguageChoiceControl and self.LanguageChoiceControl.Set then
        local display = self:GetLanguageDisplay(self.Settings.Language)
        if self.LanguageChoiceControl:Get() ~= display then
            self.LanguageChoiceControl:Set(display, true)
        end
    end

    if self.RefreshWatermark then
        self:RefreshWatermark()
    end
end

function Library:SetLanguage(selection)
    local raw = tostring(selection or "Auto")
    local code = LANGUAGE_DISPLAY_TO_CODE[raw] or raw

    if code ~= "Auto" and not LOCALIZATION[code] then
        code = "en"
    end

    self.Settings.Language = code
    self:RefreshLocalization()
    return code
end

pcall(function()
    LocalizationService:GetPropertyChangedSignal("RobloxLocaleId"):Connect(function()
        if not Library.Unloaded and Library.Settings.Language == "Auto" then
            Library:RefreshLocalization()
        end
    end)
end)

--============================================================
-- THEME / FONT / CORNERS
--============================================================

function Library:BindTheme(object, property, key)
    object[property] = self.Theme[key]
    table.insert(self.ThemeBindings, {
        Object = object,
        Property = property,
        Key = key,
    })
end

function Library:RegisterFont(object, bold)
    local baseTextSize = tonumber(object.TextSize) or 12

    table.insert(self.FontObjects, {
        Object = object,
        Bold = bold == true,
        BaseTextSize = baseTextSize,
    })

    -- Keep one visual font family across the whole interface.
    -- Some legacy Enum.Font families (including Oswald) do not expose
    -- a separate Bold enum, so headings use the same family as controls.
    object.Font = FONT_MAP[self.Settings.Font] or Enum.Font.Oswald
    object.TextSize = math.max(6, math.floor(baseTextSize * ((self.Settings.TextScale or 100) / 100) + 0.5))
end

function Library:SetTextScale(percent)
    percent = math.clamp(tonumber(percent) or 100, 50, 200)
    self.Settings.TextScale = percent

    for _, item in ipairs(self.FontObjects) do
        if item.Object and item.Object.Parent then
            local base = item.BaseTextSize or 12
            item.Object.TextSize = math.max(6, math.floor(base * (percent / 100) + 0.5))
        end
    end

    if self.RefreshWatermark then
        self:RefreshWatermark()
    end
end

function Library:GetFunctionDPIScale()
    return (FUNCTION_DPI_VALUES[self.Settings.FunctionDPIPreset] or 95) / 100
end

function Library:ApplyFunctionDPIScale()
    local scale = self:GetFunctionDPIScale()

    for _, item in ipairs(self.ControlFrames) do
        local object = item.Object
        if object and object.Parent then
            local current = object.Size
            object.Size = UDim2.new(scale, 0, current.Y.Scale, current.Y.Offset)

            if item.ManualCenter then
                object.Position = UDim2.new((1 - scale) * 0.5, 0, object.Position.Y.Scale, object.Position.Y.Offset)
            end
        end
    end
end

function Library:SetFunctionDPIPreset(preset)
    preset = tostring(preset or "95%")
    if not FUNCTION_DPI_VALUES[preset] then
        return
    end

    self.Settings.FunctionDPIPreset = preset
    self:ApplyFunctionDPIScale()
end

function Library:AdaptiveCorner(object, radiusOffset)
    local corner = Create("UICorner", {
        Parent = object,
        CornerRadius = UDim.new(0, math.max(0, self.Settings.CornerRadius + (radiusOffset or 0))),
    })

    table.insert(self.AdaptiveCorners, {
        Corner = corner,
        Offset = radiusOffset or 0,
    })

    return corner
end

function Library:SetCornerRadius(radius)
    radius = math.clamp(tonumber(radius) or 8, 0, 24)
    self.Settings.CornerRadius = radius

    for _, item in ipairs(self.AdaptiveCorners) do
        if item.Corner and item.Corner.Parent then
            item.Corner.CornerRadius = UDim.new(0, math.max(0, radius + item.Offset))
        end
    end
end

function Library:SetFont(fontName)
    if not FONT_MAP[fontName] then
        return
    end

    self.Settings.Font = fontName

    for _, item in ipairs(self.FontObjects) do
        if item.Object and item.Object.Parent then
            item.Object.Font = FONT_MAP[fontName]
        end
    end
end

function Library:GetRequestedDPIPercent()
    return DPI_VALUES[self.Settings.DPIPreset] or 100
end

function Library:GetFitDPIPercent()
    if not self.Settings.AutoFitDPI then
        return self:GetRequestedDPIPercent()
    end

    local camera = workspace.CurrentCamera
    if not camera then
        return self:GetRequestedDPIPercent()
    end

    local viewport = camera.ViewportSize
    if viewport.X <= 0 or viewport.Y <= 0 then
        return self:GetRequestedDPIPercent()
    end

    local usableX = math.max(1, viewport.X - DPI_SCREEN_MARGIN.X)
    local usableY = math.max(1, viewport.Y - DPI_SCREEN_MARGIN.Y)
    local maxScale = math.min(usableX / BASE_WINDOW_SIZE.X, usableY / BASE_WINDOW_SIZE.Y)
    local maxPercent = (maxScale / DPI_BASE_SCALE) * 100
    local requested = self:GetRequestedDPIPercent()

    if requested <= maxPercent then
        return requested
    end

    -- Snap down only to one of the exposed presets. 5% is the emergency floor.
    for _, percent in ipairs(DPI_FIT_ORDER) do
        if percent <= requested and percent <= maxPercent then
            return percent
        end
    end

    return 5
end

function Library:ApplyDPIScale()
    local effectivePercent = self:GetFitDPIPercent()
    local scale = DPI_BASE_SCALE * (effectivePercent / 100)
    self.EffectiveDPIPercent = effectivePercent
    self.CurrentDPIScale = scale

    if self.MainScale and self.MainScale.Parent then
        self.MainScale.Scale = scale
    end

    if self.LoaderScale and self.LoaderScale.Parent then
        -- Loader follows the interface scale, but never becomes microscopic.
        self.LoaderScale.Scale = math.max(0.45, scale)
    end
end

function Library:SetDPIPreset(preset)
    preset = tostring(preset or "100%")
    if not DPI_VALUES[preset] then
        return
    end
    self.Settings.DPIPreset = preset
    self:ApplyDPIScale()
end

function Library:SyncThemeColorPickers()
    for _, item in ipairs(self.ThemeColorControls) do
        local control = item.Control
        local color = self.Theme[item.Key]
        if control and control.Set and typeof(color) == "Color3" then
            control:Set(color, true)
        end
    end
end

function Library:RefreshTheme()
    for _, binding in ipairs(self.ThemeBindings) do
        local obj = binding.Object
        if obj and obj.Parent and self.Theme[binding.Key] ~= nil then
            obj[binding.Property] = self.Theme[binding.Key]
        end
    end

    for _, control in ipairs(self.Controls) do
        if control.RefreshStyle then
            control:RefreshStyle()
        end
    end

    -- Theme editor swatches/palettes must follow preset changes too.
    self:SyncThemeColorPickers()
end

function Library:SetThemeColor(key, color)
    if self.Theme[key] and typeof(color) == "Color3" then
        self.Theme[key] = color
        self:RefreshTheme()
    end
end

function Library:ApplyThemePreset(name)
    if not THEMES[name] then
        return
    end

    self.ThemeName = name
    self.Theme = cloneTable(THEMES[name])

    if name == "RGB" then
        self.Settings.RGBMenuStyle = true
    end

    self:RefreshTheme()
end

function Library:RefreshDynamicAccent()
    for _, binding in ipairs(self.ThemeBindings) do
        local obj = binding.Object
        local key = binding.Key

        if obj and obj.Parent and (key == "Accent" or key == "Outline" or key == "Hover") then
            obj[binding.Property] = self.Theme[key]
        end
    end
end

function Library:RegisterGradient(object)
    if not object then return nil end

    local gradient = Create("UIGradient", {
        Parent = object,
        Enabled = self.Settings.GradientsEnabled,
        Rotation = self.Settings.GradientRotation or 25,
    })

    table.insert(self.GradientObjects, gradient)
    return gradient
end

local function makeGradientSequence(colors)
    colors = colors or {Color3.new(1, 1, 1), Color3.new(1, 1, 1)}

    local keypoints = {}
    for index, color in ipairs(colors) do
        local alpha = (#colors <= 1) and 0 or ((index - 1) / (#colors - 1))
        table.insert(keypoints, ColorSequenceKeypoint.new(alpha, color))
    end

    if #keypoints == 1 then
        table.insert(keypoints, ColorSequenceKeypoint.new(1, colors[1]))
    end

    return ColorSequence.new(keypoints)
end

function Library:GetGradientColors()
    if self.Settings.GradientPreset == "Custom" then
        return {
            self.Settings.GradientColorA or self.Theme.Accent,
            self.Settings.GradientColorB or self.Theme.Hover,
        }
    end

    return GRADIENT_PRESETS[self.Settings.GradientPreset]
        or GRADIENT_PRESETS["Violet Dream"]
end

function Library:RefreshGradients()
    local sequence = makeGradientSequence(self:GetGradientColors())
    local enabled = self.Settings.GradientsEnabled == true
    local rotation = tonumber(self.Settings.GradientRotation) or 25
    local intensity = math.clamp(tonumber(self.Settings.GradientIntensity) or 28, 0, 100)
    local transparency = 1 - (intensity / 100)

    for _, gradient in ipairs(self.GradientObjects) do
        if gradient and gradient.Parent then
            gradient.Enabled = enabled
            gradient.Color = sequence
            gradient.Transparency = NumberSequence.new(transparency)
