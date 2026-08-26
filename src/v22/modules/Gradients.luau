-- Experiment 17 v22 - UIStroke gradient renderer
-- Decorative gradients are attached ONLY to UIStroke objects.
-- Legacy background gradients registered by the base engine are removed here.

return function(Library)
    local RunService = game:GetService("RunService")
    local Root = Library.Root
    if not Root then return end

    local rawRefreshGradients = Library.RefreshGradients
    local rawRegisterGradient = Library.RegisterGradient
    local rawRefreshTheme = Library.RefreshTheme
    local rawImportConfig = Library.ImportConfig

    local connections = {}
    local tracked = setmetatable({}, {__mode = "k"})
    local phase = 0

    local function destroyLegacyBackgroundGradients()
        for _, gradient in ipairs(Library.GradientObjects or {}) do
            if gradient and gradient.Parent then
                gradient:Destroy()
            end
        end
        if Library.GradientObjects then
            table.clear(Library.GradientObjects)
        end
    end

    destroyLegacyBackgroundGradients()

    -- v22 gradients are stroke-only. Prevent the old core helper from placing
    -- new UIGradient instances on Frames/TextButtons.
    function Library:RegisterGradient(_object)
        return nil
    end

    local function colorDistance(a, b)
        if typeof(a) ~= "Color3" or typeof(b) ~= "Color3" then
            return math.huge
        end
        return math.abs(a.R - b.R) + math.abs(a.G - b.G) + math.abs(a.B - b.B)
    end

    local function isThemeOutlineStroke(stroke)
        for _, binding in ipairs(Library.ThemeBindings or {}) do
            if binding.Object == stroke
                and binding.Property == "Color"
                and binding.Key == "Outline"
            then
                return true
            end
        end
        return false
    end

    local function isGradientStroke(stroke)
        if not stroke or not stroke:IsA("UIStroke") then
            return false
        end
        if stroke:GetAttribute("E17NoGradient") == true then
            return false
        end
        if stroke:GetAttribute("E17OutlineGradient") == true then
            return true
        end
        if isThemeOutlineStroke(stroke) then
            return true
        end

        -- Several older v22 strokes were created with Color = Theme.Outline
        -- but were not registered through BindTheme. Pick those up too.
        local outline = Library.Theme and Library.Theme.Outline
        if outline and colorDistance(stroke.Color, outline) <= 0.075 then
            return true
        end

        -- Decorative GUI borders explicitly use Border mode. Technical cursor
        -- strokes in the HSV picker do not, so they remain untouched.
        if stroke.ApplyStrokeMode == Enum.ApplyStrokeMode.Border
            and stroke.Transparency < 0.96
        then
            return true
        end

        return false
    end

    local function getPresetColors()
        if type(Library.GetGradientColors) == "function" then
            local ok, colors = pcall(function()
                return Library:GetGradientColors()
            end)
            if ok and type(colors) == "table" and #colors > 0 then
                return colors
            end
        end

        return {
            Library.Theme.Accent or Color3.fromRGB(150, 80, 255),
            Library.Theme.Hover or Color3.fromRGB(210, 140, 255),
        }
    end

    local function buildSequence()
        local colors = getPresetColors()
        local intensity = math.clamp(
            tonumber(Library.Settings.GradientIntensity) or 28,
            0,
            100
        ) / 100

        local points = {}
        for index, color in ipairs(colors) do
            local alpha = (#colors <= 1) and 0 or ((index - 1) / (#colors - 1))
            -- The stroke itself is white while a gradient is enabled. Intensity
            -- only blends the preset toward white; it never multiplies by the
            -- old outline color.
            local finalColor = Color3.new(1, 1, 1):Lerp(color, intensity)
            points[#points + 1] = ColorSequenceKeypoint.new(alpha, finalColor)
        end

        if #points == 1 then
            points[#points + 1] = ColorSequenceKeypoint.new(1, points[1].Value)
        end

        return ColorSequence.new(points)
    end

    local function ensureGradient(stroke)
        local state = tracked[stroke]
        if state then
            return state
        end

        local gradient = stroke:FindFirstChild("E17_StrokeGradientV22")
        if not gradient then
            gradient = Instance.new("UIGradient")
            gradient.Name = "E17_StrokeGradientV22"
            gradient.Parent = stroke
        end

        state = {
            Stroke = stroke,
            Gradient = gradient,
            OriginalColor = stroke.Color,
        }
        tracked[stroke] = state
        stroke:SetAttribute("E17OutlineGradient", true)
        return state
    end

    local function scanAll()
        for _, object in ipairs(Root:GetDescendants()) do
            if object:IsA("UIStroke") and isGradientStroke(object) then
                ensureGradient(object)
            end
        end
    end

    local function refreshOriginalColors()
        for stroke, state in pairs(tracked) do
            if stroke and stroke.Parent then
                -- RefreshTheme writes the real outline color before this is
                -- called. Do not save our temporary white render color.
                if colorDistance(stroke.Color, Color3.new(1, 1, 1)) > 0.01 then
                    state.OriginalColor = stroke.Color
                end
            end
        end
    end

    local function refresh()
        scanAll()

        local intensity = math.clamp(
            tonumber(Library.Settings.GradientIntensity) or 28,
            0,
            100
        )
        local enabled = Library.Settings.GradientsEnabled == true and intensity > 0
        local sequence = buildSequence()
        local baseRotation = tonumber(Library.Settings.GradientRotation) or 25

        for stroke, state in pairs(tracked) do
            if stroke and stroke.Parent and state.Gradient and state.Gradient.Parent then
                state.Gradient.Enabled = enabled
                state.Gradient.Color = sequence
                state.Gradient.Transparency = NumberSequence.new(0)

                if enabled then
                    stroke.Color = Color3.new(1, 1, 1)
                    if not Library.Settings.GradientAnimated then
                        state.Gradient.Rotation = baseRotation
                        state.Gradient.Offset = Vector2.new(0, 0)
                    end
                else
                    stroke.Color = state.OriginalColor
                end
            end
        end
    end

    function Library:RefreshGradients()
        refresh()
    end

    if type(rawRefreshTheme) == "function" then
        function Library:RefreshTheme(...)
            local result = rawRefreshTheme(self, ...)
            refreshOriginalColors()
            refresh()
            return result
        end
    end

    if type(rawImportConfig) == "function" then
        function Library:ImportConfig(data)
            local result = rawImportConfig(self, data)
            refresh()
            return result
        end
    end

    scanAll()
    refresh()

    connections[#connections + 1] = Root.DescendantAdded:Connect(function(object)
        if not object:IsA("UIStroke") then
            return
        end

        task.defer(function()
            if object.Parent and isGradientStroke(object) then
                ensureGradient(object)
                refresh()
            end
        end)
    end)

    -- Only transforms move every frame. ColorSequence construction happens on
    -- settings/theme changes, eliminating the old slideshow-like update path.
    connections[#connections + 1] = RunService.RenderStepped:Connect(function(dt)
        if Library.Unloaded then return end
        if Library.Settings.GradientsEnabled ~= true then return end
        if Library.Settings.GradientAnimated ~= true then return end
        if (tonumber(Library.Settings.GradientIntensity) or 0) <= 0 then return end

        local speed = math.clamp(tonumber(Library.Settings.GradientSpeed) or 24, 0, 180)
        if speed <= 0 then return end

        phase = phase + dt * (speed / 24) * 1.35
        local baseRotation = tonumber(Library.Settings.GradientRotation) or 25
        local rotationWave = math.sin(phase * 0.55) * 28
        local offsetX = math.sin(phase) * 0.32
        local offsetY = math.cos(phase * 0.72) * 0.06

        for stroke, state in pairs(tracked) do
            if stroke and stroke.Parent and state.Gradient and state.Gradient.Parent then
                -- Main-window strokes are invisible while the menu is closed,
                -- so do not spend frame time animating them.
                if not (Library.Main and stroke:IsDescendantOf(Library.Main) and not Library.MenuVisible) then
                    stroke.Color = Color3.new(1, 1, 1)
                    state.Gradient.Enabled = true
                    state.Gradient.Rotation = baseRotation + rotationWave
                    state.Gradient.Offset = Vector2.new(offsetX, offsetY)
                end
            end
        end
    end)

    return function()
        for _, connection in ipairs(connections) do
            pcall(function() connection:Disconnect() end)
        end

        for stroke, state in pairs(tracked) do
            if stroke and stroke.Parent then
                stroke.Color = state.OriginalColor
                stroke:SetAttribute("E17OutlineGradient", nil)
            end
            if state.Gradient and state.Gradient.Parent then
                state.Gradient:Destroy()
            end
        end

        Library.RefreshGradients = rawRefreshGradients
        Library.RegisterGradient = rawRegisterGradient
        Library.RefreshTheme = rawRefreshTheme
        Library.ImportConfig = rawImportConfig
    end
end
