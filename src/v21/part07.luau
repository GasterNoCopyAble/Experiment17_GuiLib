            if not self.Settings.GradientAnimated then
                gradient.Rotation = rotation
            end
        end
    end
end

RunService.RenderStepped:Connect(function(dt)
    if Library.Unloaded then return end

    if Library.Settings.RGBMenuStyle then
        Library.RGBAccumulator += dt

        if Library.RGBAccumulator >= 0.045 then
            Library.RGBAccumulator = 0
            local speed = math.clamp(tonumber(Library.Settings.RGBSpeed) or 0.12, 0.02, 1)
            local hue = (os.clock() * speed) % 1

            Library.Theme.Accent = Color3.fromHSV(hue, 0.82, 1)
            Library.Theme.Outline = Color3.fromHSV((hue + 0.035) % 1, 0.72, 0.82)
            Library.Theme.Hover = Color3.fromHSV((hue + 0.065) % 1, 0.64, 1)
            Library:RefreshDynamicAccent()
        end
    end

    if Library.Settings.GradientsEnabled and Library.Settings.GradientAnimated then
        local speed = math.clamp(tonumber(Library.Settings.GradientSpeed) or 24, 0, 180)
        if speed > 0 then
            for _, gradient in ipairs(Library.GradientObjects) do
                if gradient and gradient.Parent and gradient.Enabled then
                    gradient.Rotation = (gradient.Rotation + speed * dt) % 360
                end
            end
        end
    end
end)

--============================================================
-- ANIMATION ENGINE
--============================================================

-- Structural/window animations always stay smooth. The Smooth/Stepped
-- setting below is intentionally reserved for interactive controls.
function Library:Animate(object, duration, properties)
    duration = duration or self.Settings.AnimationSpeed

    local tween = TweenService:Create(
        object,
        TweenInfo.new(duration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        properties
    )
    tween:Play()
    return tween
end

function Library:AnimateControl(object, duration, properties)
    duration = duration or 0.12

    if self.Settings.AnimationMode == "Smooth" then
        local tween = TweenService:Create(
            object,
            TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            properties
        )
        tween:Play()
        return tween
    end

    -- Stepped = visible discrete movement instead of easing.
    local steps = 5
    local starts = {}
    for property in pairs(properties) do
        starts[property] = object[property]
    end

    task.spawn(function()
        for i = 1, steps do
            if not object or not object.Parent or Library.Unloaded then
                return
            end

            local alpha = i / steps
            for property, target in pairs(properties) do
                object[property] = lerpValue(starts[property], target, alpha)
            end
            task.wait(duration / steps)
        end
    end)
end

--============================================================
-- GRAPHICS GATING
--============================================================

function Library:IsGraphicsAllowed(required)
    required = required or "Low"
    return (GRAPHICS_ORDER[self.Settings.GraphicsLevel] or 1) >= (GRAPHICS_ORDER[required] or 1)
end

function Library:SetGraphicsLevel(level)
    if not GRAPHICS_ORDER[level] then
        return
    end

    self.Settings.GraphicsLevel = level

    if self.LevelText and self.LevelText.Parent then
        self.LevelText.Text = level
    end

    for _, control in ipairs(self.GatedControls) do
        if control.RefreshGate then
            control:RefreshGate()
        end
    end

    if self.RefreshWatermark then
        self:RefreshWatermark()
    end
end

--============================================================
-- PROFILES / DEPENDENCIES / GLOBAL KEYBINDS
--============================================================

function Library:RegisterProfile(name, profile)
    name = tostring(name or "")
    if name == "" or type(profile) ~= "table" then
        return self
    end

    self.Profiles[name] = profile

    if self.ProfileChoiceControl and self.ProfileChoiceControl.SetValues then
        local names = {}
        for profileName in pairs(self.Profiles) do
            table.insert(names, profileName)
        end
        table.sort(names)
        table.insert(names, "Custom")
        self.ProfileChoiceControl:SetValues(names, false)
    end

    return self
end

function Library:ApplyProfile(name, silent)
    local profile = self.Profiles[tostring(name)]
    if not profile then
        self.ActiveProfile = "Custom"
        return false
    end

    self.ActiveProfile = tostring(name)

    if type(profile.Settings) == "table" then
        local s = profile.Settings

        if s.GraphicsLevel then self:SetGraphicsLevel(s.GraphicsLevel) end
        if s.AnimationMode then self.Settings.AnimationMode = s.AnimationMode end
        if s.OpenAnimation then self.Settings.OpenAnimation = s.OpenAnimation end
        if s.AnimationSpeed then self.Settings.AnimationSpeed = s.AnimationSpeed end
        if s.BlurEnabled ~= nil then self.Settings.BlurEnabled = s.BlurEnabled == true end
        if s.BlurSize ~= nil then self.Settings.BlurSize = tonumber(s.BlurSize) or self.Settings.BlurSize end
        if s.DimEnabled ~= nil then self.Settings.DimEnabled = s.DimEnabled == true end
        if s.TooltipsEnabled ~= nil then self.Settings.TooltipsEnabled = s.TooltipsEnabled == true end
        if s.FunctionDPIPreset and FUNCTION_DPI_VALUES[s.FunctionDPIPreset] then
            self.Settings.FunctionDPIPreset = s.FunctionDPIPreset
            self:ApplyFunctionDPIScale()
        end
    end

    if type(profile.Theme) == "table" then
        for key, value in pairs(profile.Theme) do
            if self.Theme[key] ~= nil and typeof(value) == "Color3" then
                self.Theme[key] = value
            end
        end
        self:RefreshTheme()
    end

    if type(profile.Flags) == "table" then
        for flag, value in pairs(profile.Flags) do
            local control = self.ControlsByFlag and self.ControlsByFlag[flag]
            if control and control.Set then
                control:Set(value, silent == true)
            else
                self.Flags[flag] = value
            end
        end
    end

    if self.RefreshBackdrop then self:RefreshBackdrop() end
    if self.RefreshWatermark then self:RefreshWatermark() end
    if self.RefreshDependencies then self:RefreshDependencies() end

    return true
end

function Library:RegisterDefaultProfiles()
    self:RegisterProfile("Performance", {
        Settings = {
            GraphicsLevel = "Low",
            AnimationMode = "Stepped",
            OpenAnimation = "None",
            AnimationSpeed = 0.12,
            BlurEnabled = false,
            DimEnabled = false,
            TooltipsEnabled = false,
            FunctionDPIPreset = "90%",
        },
    })

    self:RegisterProfile("Balanced", {
        Settings = {
            GraphicsLevel = "Medium",
            AnimationMode = "Smooth",
            OpenAnimation = "Scale",
            AnimationSpeed = 0.18,
            BlurEnabled = true,
            BlurSize = 10,
            DimEnabled = true,
            TooltipsEnabled = true,
            FunctionDPIPreset = "95%",
        },
    })

    self:RegisterProfile("Beauty", {
        Settings = {
            GraphicsLevel = "Epic",
            AnimationMode = "Smooth",
            OpenAnimation = "Scale",
            AnimationSpeed = 0.24,
            BlurEnabled = true,
            BlurSize = 18,
            DimEnabled = true,
            TooltipsEnabled = true,
            FunctionDPIPreset = "100%",
        },
    })
end

function Library:EvaluateDependency(control)
    if not control then
        return true, true
    end

    local visible = true
    local enabled = true
    local opts = control.DependencyOptions or {}

    local function flagValue(flag)
        return self.Flags[tostring(flag)]
    end

    if opts.DependsOn ~= nil then
        if type(opts.DependsOn) == "string" then
            enabled = flagValue(opts.DependsOn) == true
        elseif type(opts.DependsOn) == "table" then
            for _, flag in ipairs(opts.DependsOn) do
                if flagValue(flag) ~= true then
                    enabled = false
                    break
                end
            end
        elseif type(opts.DependsOn) == "function" then
            local ok, result = pcall(opts.DependsOn, self.Flags)
            enabled = ok and result == true
        end
    end

    if type(opts.EnabledWhen) == "function" then
        local ok, result = pcall(opts.EnabledWhen, self.Flags)
        enabled = enabled and ok and result == true
    end

    if type(opts.VisibleWhen) == "function" then
        local ok, result = pcall(opts.VisibleWhen, self.Flags)
        visible = ok and result == true
    end

    return visible, enabled
end

function Library:RefreshDependencies()
    for _, control in ipairs(self.Controls) do
        if control.Holder and control.Holder.Parent then
            local visible, enabled = self:EvaluateDependency(control)
            control.DependencyEnabled = enabled

            if control.Holder.Visible ~= visible then
                control.Holder.Visible = visible
            end

            if control.RefreshGate then
                control:RefreshGate()
            end
        end
    end
end

function Library:QueueDependencyRefresh()
    if self.DependencyRefreshQueued then
        return
    end

    self.DependencyRefreshQueued = true
    task.defer(function()
        self.DependencyRefreshQueued = false
        if not self.Unloaded then
            self:RefreshDependencies()
        end
    end)
end

function Library:CreateKeybind(options)
    options = options or {}

    local entry = {
        Name = tostring(options.Name or "Keybind"),
        Key = tostring(options.Key or options.Default or "Unknown"),
        Mode = tostring(options.Mode or "Press"),
        Callback = options.Callback,
        Enabled = true,
        Active = false,
    }

    if not Enum.KeyCode[entry.Key] then
        entry.Key = "Unknown"
    end

    function entry:SetKey(key)
        local name = typeof(key) == "EnumItem" and key.Name or tostring(key)
        if Enum.KeyCode[name] then
            self.Key = name
        end
    end

    function entry:SetEnabled(state)
        self.Enabled = state == true
    end

    function entry:Destroy()
        self.Enabled = false
        local index = table.find(Library.KeybindRegistry, self)
        if index then
            table.remove(Library.KeybindRegistry, index)
        end
        if Library.RefreshKeybindList then
            Library:RefreshKeybindList()
        end
    end

    table.insert(self.KeybindRegistry, entry)

    if self.RefreshKeybindList then
        self:RefreshKeybindList()
    end

    return entry
end

Library.AddKeybind = Library.CreateKeybind

--============================================================
-- CONFIG SYSTEM
--============================================================

function Library:ExportConfig()
    local result = {
        version = 21,
        flags = {},
        settings = {
            Language = self.Settings.Language,
            GraphicsLevel = self.Settings.GraphicsLevel,
            Font = self.Settings.Font,
            MenuKey = self.Settings.MenuKey,
            DPIPreset = self.Settings.DPIPreset,
