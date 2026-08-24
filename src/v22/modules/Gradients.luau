-- Experiment 17 v22 - smooth outline gradients
-- Decorative gradients live on theme-bound UIStroke objects only.
-- Stroke color is forced to white while enabled so preset colors are not tinted.

return function(Library)
    local RunService = game:GetService("RunService")
    local Root = Library.Root
    if not Root then return end

    local rawRefreshGradients = Library.RefreshGradients
    local rawRegisterGradient = Library.RegisterGradient
    local rawImportConfig = Library.ImportConfig
    local connections = {}
    local tracked = setmetatable({}, {__mode = "k"})
    local phase = 0
    local syncTimer = 0

    for _, gradient in ipairs(Library.GradientObjects or {}) do
        if gradient and gradient.Parent then
            gradient.Enabled = false
        end
    end

    if type(rawRegisterGradient) == "function" then
        function Library:RegisterGradient(object)
            local gradient = rawRegisterGradient(self, object)
            if gradient then
                gradient.Enabled = false
            end
            return gradient
        end
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
        local intensity = math.clamp(tonumber(Library.Settings.GradientIntensity) or 28, 0, 100) / 100
        local points = {}

        for index, color in ipairs(colors) do
            local alpha = (#colors <= 1) and 0 or ((index - 1) / (#colors - 1))
            local finalColor = Color3.new(1, 1, 1):Lerp(color, intensity)
            points[#points + 1] = ColorSequenceKeypoint.new(alpha, finalColor)
        end

        if #points == 1 then
            points[#points + 1] = ColorSequenceKeypoint.new(1, points[1].Value)
        end

        return ColorSequence.new(points)
    end

    local function isOutlineStroke(stroke)
        if not stroke or not stroke:IsA("UIStroke") then return false end

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

    local function ensureGradient(stroke)
        local state = tracked[stroke]
        if state then return state end

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
        return state
    end

    local function syncTracked()
        for _, binding in ipairs(Library.ThemeBindings or {}) do
            local object = binding.Object
            if object and object.Parent and object:IsA("UIStroke")
                and binding.Property == "Color"
                and binding.Key == "Outline"
            then
                ensureGradient(object)
            end
        end
    end

    local function refresh()
        local intensity = math.clamp(tonumber(Library.Settings.GradientIntensity) or 28, 0, 100)
        local enabled = Library.Settings.GradientsEnabled == true and intensity > 0
        local sequence = buildSequence()
        local baseRotation = tonumber(Library.Settings.GradientRotation) or 25

        syncTracked()

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

        for _, gradient in ipairs(Library.GradientObjects or {}) do
            if gradient and gradient.Parent then
                gradient.Enabled = false
            end
        end

        if not enabled and type(Library.RefreshTheme) == "function" then
            Library:RefreshTheme()
        end
    end

    function Library:RefreshGradients()
        refresh()
    end

    if type(rawImportConfig) == "function" then
        function Library:ImportConfig(data)
            local result = rawImportConfig(self, data)
            refresh()
            return result
        end
    end

    refresh()

    connections[#connections + 1] = Root.DescendantAdded:Connect(function(object)
        if object:IsA("UIStroke") then
            task.defer(function()
                if object.Parent and isOutlineStroke(object) then
                    ensureGradient(object)
                    refresh()
                end
            end)
        end
    end)

    connections[#connections + 1] = RunService.RenderStepped:Connect(function(dt)
        if Library.Unloaded then return end

        syncTimer = syncTimer + dt
        if syncTimer >= 0.25 then
            syncTimer = 0
            syncTracked()
        end

        local intensity = math.clamp(tonumber(Library.Settings.GradientIntensity) or 28, 0, 100)
        if Library.Settings.GradientsEnabled ~= true or intensity <= 0 then
            return
        end

        local sequence = buildSequence()
        local baseRotation = tonumber(Library.Settings.GradientRotation) or 25
        local speed = math.clamp(tonumber(Library.Settings.GradientSpeed) or 24, 0, 180)

        if Library.Settings.GradientAnimated then
            phase = (phase + speed * dt) % 360
        end

        for stroke, state in pairs(tracked) do
            if stroke and stroke.Parent and state.Gradient and state.Gradient.Parent then
                stroke.Color = Color3.new(1, 1, 1)
                state.Gradient.Enabled = true
                state.Gradient.Color = sequence

                if Library.Settings.GradientAnimated then
                    state.Gradient.Rotation = (baseRotation + phase) % 360
                    local radians = math.rad(phase)
                    state.Gradient.Offset = Vector2.new(math.sin(radians) * 0.06, 0)
                else
                    state.Gradient.Rotation = baseRotation
                    state.Gradient.Offset = Vector2.new(0, 0)
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
            end
            if state.Gradient and state.Gradient.Parent then
                state.Gradient:Destroy()
            end
        end

        Library.RefreshGradients = rawRefreshGradients
        Library.RegisterGradient = rawRegisterGradient
        Library.ImportConfig = rawImportConfig
        if type(rawRefreshGradients) == "function" then
            pcall(function() rawRefreshGradients(Library) end)
        end
    end
end
