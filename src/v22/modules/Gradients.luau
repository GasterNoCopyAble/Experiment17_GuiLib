-- Experiment 17 Legacy v22 - hierarchical UIStroke gradient renderer
-- Large shells use a restrained gradient; interactive/selected borders get
-- progressively stronger color. Custom picker values stay synchronized.

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

    -- Remove only decorative gradients registered by the old engine helper.
    -- HSV/color-picker gradients are not part of GradientObjects and stay intact.
    for _, gradient in ipairs(Library.GradientObjects or {}) do
        if gradient and gradient.Parent then gradient:Destroy() end
    end
    if Library.GradientObjects then table.clear(Library.GradientObjects) end

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

    local function hasAncestorNamed(object, name)
        local node = object and object.Parent
        while node and node ~= Root do
            if node.Name == name then return true end
            node = node.Parent
        end
        return false
    end

    local function tabForStroke(stroke)
        for _, tab in ipairs(Library.Tabs or {}) do
            if tab.TabStroke == stroke then
                return tab
            end
        end
        return nil
    end

    -- Option 2 hierarchy:
    -- shell < passive widgets < tiles/popups < hovered/active < selected tab.
    local function visualStrength(stroke)
        local explicit = tonumber(stroke:GetAttribute("E17GradientStrength"))
        if explicit then
            return math.clamp(explicit, 0, 1)
        end

        local tab = tabForStroke(stroke)
        if tab then
            return Library.CurrentTab == tab and 1.00 or 0.46
        end

        if Library.Main and stroke.Parent == Library.Main then
            return 0.40
        end

        if Library.Watermark and stroke:IsDescendantOf(Library.Watermark) then
            return 0.58
        end

        if hasAncestorNamed(stroke, "E17_TilePage") then
            return stroke.Transparency <= 0.16 and 0.88 or 0.72
        end

        -- Hover/selected borders usually lower their transparency.
        if stroke.Transparency <= 0.14 then
            return 0.86
        elseif stroke.Transparency <= 0.24 then
            return 0.70
        end

        return 0.60
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

    local function buildSequence(level)
        local colors = getPresetColors()
        local intensity = math.clamp(tonumber(Library.Settings.GradientIntensity) or 28,0,100)/100
        -- Intensity controls global vividness, while level controls UI hierarchy.
        local globalVividness = 0.52 + intensity * 0.48
        local strength = math.clamp(globalVividness * level, 0, 1)
        local base = (Library.Theme and Library.Theme.Outline) or Color3.fromRGB(105,70,190)
        local points = {}

        for index,color in ipairs(colors) do
            local alpha = (#colors <= 1) and 0 or ((index-1)/(#colors-1))
            points[#points+1] = ColorSequenceKeypoint.new(alpha, base:Lerp(color,strength))
        end

        if #points == 0 then
            points = {
                ColorSequenceKeypoint.new(0,base),
                ColorSequenceKeypoint.new(1,base),
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
            LastLevel = -1,
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
            state.LastLevel = -1
        end
    end

    local function normalizePreset()
        local preset = tostring(Library.Settings.GradientPreset or "Violet")
        local pairs = Library.LegacyThemePairs
        if type(pairs) == "table" and preset ~= "Custom" and not pairs[preset] then
            local fallback = tostring(Library.ThemeName or "Violet")
            if not pairs[fallback] then fallback = "Violet" end
            Library.Settings.GradientPreset = fallback
        end
    end

    local function syncPickerControls()
        local controls = Library.ControlsByFlag
        if type(controls) ~= "table" then return end

        local presetControl = controls.UI_GradientPreset
        local colorAControl = controls.UI_GradientColorA
        local colorBControl = controls.UI_GradientColorB

        if presetControl and type(presetControl.Set) == "function" then
            presetControl:Set(tostring(Library.Settings.GradientPreset or "Custom"), true)
        end
        if colorAControl and type(colorAControl.Set) == "function"
            and typeof(Library.Settings.GradientColorA) == "Color3"
        then
            colorAControl:Set(Library.Settings.GradientColorA, true)
        end
        if colorBControl and type(colorBControl.Set) == "function"
            and typeof(Library.Settings.GradientColorB) == "Color3"
        then
            colorBControl:Set(Library.Settings.GradientColorB, true)
        end
    end

    local function updateSequenceIfNeeded(stroke,state,force)
        local level = visualStrength(stroke)
        if force or math.abs(level - (state.LastLevel or -1)) > 0.001 then
            state.LastLevel = level
            state.Gradient.Color = buildSequence(level)
        end
    end

    local function applyState()
        normalizePreset()
        scanAll()
        syncPickerControls()

        local enabled = Library.Settings.GradientsEnabled == true
            and (tonumber(Library.Settings.GradientIntensity) or 0) > 0
        local baseRotation = tonumber(Library.Settings.GradientRotation) or 25

        for stroke,state in pairs(tracked) do
            local gradient = state.Gradient
            if stroke and stroke.Parent and gradient and gradient.Parent == stroke then
                updateSequenceIfNeeded(stroke,state,true)
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
            normalizePreset()
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

    -- Clearly visible flow without rebuilding ColorSequence every frame.
    -- ~77 degrees/sec at the default speed plus a safe, small traveling offset.
    connections[#connections+1] = RunService.RenderStepped:Connect(function(dt)
        if Library.Unloaded then return end
        if Library.Settings.GradientsEnabled ~= true then return end
        if Library.Settings.GradientAnimated ~= true then return end
        if (tonumber(Library.Settings.GradientIntensity) or 0) <= 0 then return end

        local speed = math.clamp(tonumber(Library.Settings.GradientSpeed) or 24,0,180)
        if speed <= 0 then return end

        motion = (motion + dt*speed) % 3600
        local baseRotation = tonumber(Library.Settings.GradientRotation) or 25
        local rotation = baseRotation + motion*3.2
        local radians = math.rad(motion*4.4)
        local offsetX = math.sin(radians)*0.17
        local offsetY = math.cos(radians*0.57)*0.045

        for stroke,state in pairs(tracked) do
            local gradient = state.Gradient
            if stroke and stroke.Parent and gradient and gradient.Parent == stroke then
                local hiddenByMenu = Library.Main
                    and stroke:IsDescendantOf(Library.Main)
                    and not Library.MenuVisible

                if not hiddenByMenu then
                    updateSequenceIfNeeded(stroke,state,false)
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
