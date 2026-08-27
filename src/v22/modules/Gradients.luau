-- Experiment 17 v22 - UIStroke gradient renderer
-- Decorative gradients live only inside UIStroke. Functional UIGradients
-- (HSV picker, etc.) are never replaced or deleted.

return function(Library)
    local RunService = game:GetService("RunService")
    local Root = Library.Root
    if not Root then return end

    local rawRefreshGradients = Library.RefreshGradients
    local rawRegisterGradient = Library.RegisterGradient
    local rawRefreshTheme = Library.RefreshTheme
    local rawImportConfig = Library.ImportConfig
    local rawBindTheme = Library.BindTheme

    local WHITE = Color3.new(1,1,1)
    local GRADIENT_NAME = "E17_StrokeGradientV22"
    local tracked = setmetatable({}, {__mode="k"})
    local connections = {}
    local motion = 0

    local function colorDistance(a,b)
        if typeof(a) ~= "Color3" or typeof(b) ~= "Color3" then return math.huge end
        return math.abs(a.R-b.R)+math.abs(a.G-b.G)+math.abs(a.B-b.B)
    end

    -- Remove only old decorative gradients registered by Engine.
    for _, gradient in ipairs(Library.GradientObjects or {}) do
        if gradient and gradient.Parent then gradient:Destroy() end
    end
    if Library.GradientObjects then table.clear(Library.GradientObjects) end

    -- v22 decoration is stroke-only.
    function Library:RegisterGradient(_object)
        return nil
    end

    local function isOutlineBinding(stroke)
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

    local function shouldUseGradient(stroke)
        if not stroke or not stroke:IsA("UIStroke") then return false end
        if stroke:GetAttribute("E17NoGradient") == true then return false end
        if stroke:GetAttribute("E17OutlineGradient") == true then return true end
        if isOutlineBinding(stroke) then return true end

        local outline = Library.Theme and Library.Theme.Outline
        if outline and colorDistance(stroke.Color, outline) <= 0.06 then
            return true
        end

        return stroke.ApplyStrokeMode == Enum.ApplyStrokeMode.Border
            and stroke.Transparency < 0.92
            and stroke.Thickness >= 0.7
    end

    local function getPresetColors()
        if type(Library.GetGradientColors) == "function" then
            local ok, colors = pcall(function() return Library:GetGradientColors() end)
            if ok and type(colors) == "table" and #colors > 0 then return colors end
        end
        return {
            Library.Theme.Accent or Color3.fromRGB(145,84,255),
            Library.Theme.Hover or Color3.fromRGB(193,145,255),
        }
    end

    local function buildSequence()
        local colors = getPresetColors()
        local intensity = math.clamp(tonumber(Library.Settings.GradientIntensity) or 28,0,100)/100
        -- Even low intensity remains colorful enough to read on a 1px stroke.
        local strength = 0.68 + intensity*0.32
        local points = {}

        for index,color in ipairs(colors) do
            local alpha = (#colors <= 1) and 0 or ((index-1)/(#colors-1))
            points[#points+1] = ColorSequenceKeypoint.new(alpha, WHITE:Lerp(color,strength))
        end

        if #points == 0 then
            points = {
                ColorSequenceKeypoint.new(0,WHITE),
                ColorSequenceKeypoint.new(1,WHITE),
            }
        elseif #points == 1 then
            points[2] = ColorSequenceKeypoint.new(1,points[1].Value)
        end

        return ColorSequence.new(points)
    end

    local function ensureGradient(stroke)
        local state = tracked[stroke]
        if state then return state end

        local gradient = stroke:FindFirstChild(GRADIENT_NAME)
        if gradient and not gradient:IsA("UIGradient") then
            gradient:Destroy()
            gradient = nil
        end
        if not gradient then
            gradient = Instance.new("UIGradient")
            gradient.Name = GRADIENT_NAME
            gradient.Parent = stroke
        end

        state = {
            Stroke = stroke,
            Gradient = gradient,
            OriginalColor = stroke.Color,
        }
        tracked[stroke] = state
        stroke:SetAttribute("E17OutlineGradient",true)
        gradient:SetAttribute("E17StrokeGradient",true)
        return state
    end

    local function scanAll()
        for _,object in ipairs(Root:GetDescendants()) do
            if object:IsA("UIStroke") and shouldUseGradient(object) then
                ensureGradient(object)
            end
        end
    end

    local function captureThemeColors()
        for stroke,state in pairs(tracked) do
            if stroke and stroke.Parent and colorDistance(stroke.Color,WHITE) > 0.01 then
                state.OriginalColor = stroke.Color
            end
        end
    end

    local function applyState()
        scanAll()
        local enabled = Library.Settings.GradientsEnabled == true
            and (tonumber(Library.Settings.GradientIntensity) or 0) > 0
        local sequence = buildSequence()
        local baseRotation = tonumber(Library.Settings.GradientRotation) or 25

        for stroke,state in pairs(tracked) do
            local gradient = state.Gradient
            if stroke and stroke.Parent and gradient and gradient.Parent == stroke then
                gradient.Color = sequence
                gradient.Transparency = NumberSequence.new(0)
                gradient.Enabled = enabled

                if enabled then
                    stroke.Color = WHITE
                    if not Library.Settings.GradientAnimated then
                        gradient.Rotation = baseRotation
                        gradient.Offset = Vector2.zero
                    end
                else
                    stroke.Color = state.OriginalColor
                    gradient.Offset = Vector2.zero
                end
            end
        end
    end

    function Library:RefreshGradients()
        applyState()
    end

    if type(rawBindTheme) == "function" then
        function Library:BindTheme(object,property,key,...)
            local result = rawBindTheme(self,object,property,key,...)
            if object and object:IsA("UIStroke") and property == "Color" and key == "Outline" then
                ensureGradient(object)
                task.defer(applyState)
            end
            return result
        end
    end

    if type(rawRefreshTheme) == "function" then
        function Library:RefreshTheme(...)
            local result = rawRefreshTheme(self,...)
            captureThemeColors()
            applyState()
            return result
        end
    end

    if type(rawImportConfig) == "function" then
        function Library:ImportConfig(data)
            local result = rawImportConfig(self,data)
            applyState()
            return result
        end
    end

    scanAll()
    applyState()

    connections[#connections+1] = Root.DescendantAdded:Connect(function(object)
        if not object:IsA("UIStroke") then return end
        task.defer(function()
            if object.Parent and shouldUseGradient(object) then
                ensureGradient(object)
                applyState()
            end
        end)
    end)

    -- Visible flow: continuous rotation + a small safe horizontal drift.
    -- The Offset range stays tiny, so thin strokes never slide off-screen.
    connections[#connections+1] = RunService.RenderStepped:Connect(function(dt)
        if Library.Unloaded then return end
        if Library.Settings.GradientsEnabled ~= true then return end
        if Library.Settings.GradientAnimated ~= true then return end
        if (tonumber(Library.Settings.GradientIntensity) or 0) <= 0 then return end

        local speed = math.clamp(tonumber(Library.Settings.GradientSpeed) or 24,0,180)
        if speed <= 0 then return end

        motion = (motion + dt*speed) % 3600
        local baseRotation = tonumber(Library.Settings.GradientRotation) or 25
        local rotation = baseRotation + motion*2.15
        local radians = math.rad(motion*3.1)
        local offsetX = math.sin(radians)*0.115
        local offsetY = math.cos(radians*0.63)*0.025

        for stroke,state in pairs(tracked) do
            local gradient = state.Gradient
            if stroke and stroke.Parent and gradient and gradient.Parent == stroke then
                local hiddenByMenu = Library.Main
                    and stroke:IsDescendantOf(Library.Main)
                    and not Library.MenuVisible

                if not hiddenByMenu then
                    stroke.Color = WHITE
                    gradient.Enabled = true
                    gradient.Rotation = rotation
                    gradient.Offset = Vector2.new(offsetX,offsetY)
                end
            end
        end
    end)

    return function()
        for _,connection in ipairs(connections) do
            pcall(function() connection:Disconnect() end)
        end

        for stroke,state in pairs(tracked) do
            if stroke and stroke.Parent then
                stroke.Color = state.OriginalColor
                stroke:SetAttribute("E17OutlineGradient",nil)
            end
            if state.Gradient and state.Gradient.Parent then state.Gradient:Destroy() end
        end

        Library.RefreshGradients = rawRefreshGradients
        Library.RegisterGradient = rawRegisterGradient
        Library.RefreshTheme = rawRefreshTheme
        Library.ImportConfig = rawImportConfig
        Library.BindTheme = rawBindTheme
    end
end
