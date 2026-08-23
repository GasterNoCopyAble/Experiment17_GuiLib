            -- A close was interrupted. Current Position/Scale/Transparency are
            -- already the perfect reverse-animation starting point.
            Main.BackgroundTransparency = 0
        end

        local mainDuration = duration
        if self.Settings.OpenAnimation == "Slide" then
            mainDuration = duration * 1.35
        elseif self.Settings.OpenAnimation == "Scale" then
            mainDuration = duration * 1.08
        elseif self.Settings.OpenAnimation == "Fade" then
            mainDuration = duration * 1.05
        end

        local primary = self:CreateMenuTween(
            MainScale,
            mainDuration,
            {Scale = baseScale},
            Enum.EasingDirection.Out
        )

        self:CreateMenuTween(
            Main,
            mainDuration,
            {Position = basePos},
            Enum.EasingDirection.Out
        )

        self:CreateMenuTween(
            MainVisual,
            math.min(mainDuration, duration),
            {GroupTransparency = 0},
            Enum.EasingDirection.Out
        )

        self:CreateMenuTween(
            Blur,
            duration,
            {Size = blurTarget},
            Enum.EasingDirection.Out
        )

        self:CreateMenuTween(
            Dim,
            duration,
            {BackgroundTransparency = dimTarget},
            Enum.EasingDirection.Out
        )

        local connection
        connection = primary.Completed:Connect(function()
            connection:Disconnect()
            finishOpen()
        end)

    else
        if not Main.Visible then
            self:CancelMenuTweens()
            finishClose()
            return
        end

        if instant or self.Settings.OpenAnimation == "None" then
            self:CancelMenuTweens()
            finishClose()
            return
        end

        -- Keep the stable/resting window position. Never save a half-finished
        -- slide position as the new WindowPosition.
        basePos = self.WindowPosition or UDim2.fromScale(0.5, 0.5)

        local targetPosition = basePos
        local targetScale = baseScale
        local targetTransparency = 0

        if self.Settings.OpenAnimation == "Scale" then
            targetScale = baseScale * 0.10
            targetTransparency = 0.08

        elseif self.Settings.OpenAnimation == "Slide" then
            targetPosition = UDim2.new(
                basePos.X.Scale,
                basePos.X.Offset,
                basePos.Y.Scale,
                basePos.Y.Offset + 4000
            )
            targetScale = baseScale * 0.82
            targetTransparency = 0.08

        elseif self.Settings.OpenAnimation == "Fade" then
            targetPosition = UDim2.new(
                basePos.X.Scale,
                basePos.X.Offset,
                basePos.Y.Scale,
                basePos.Y.Offset + 220
            )
            targetScale = baseScale * 0.82
            targetTransparency = 1
        end

        local mainDuration = duration
        if self.Settings.OpenAnimation == "Slide" then
            mainDuration = duration * 1.35
        elseif self.Settings.OpenAnimation == "Scale" then
            mainDuration = duration * 1.08
        elseif self.Settings.OpenAnimation == "Fade" then
            mainDuration = duration * 1.05
        end

        self:CreateMenuTween(
            Main,
            mainDuration,
            {Position = targetPosition},
            Enum.EasingDirection.In
        )

        local primary = self:CreateMenuTween(
            MainScale,
            mainDuration,
            {Scale = targetScale},
            Enum.EasingDirection.In
        )

        self:CreateMenuTween(
            MainVisual,
            math.min(mainDuration, duration),
            {GroupTransparency = targetTransparency},
            Enum.EasingDirection.In
        )

        self:CreateMenuTween(
            Blur,
            duration,
            {Size = 0},
            Enum.EasingDirection.In
        )

        self:CreateMenuTween(
            Dim,
            duration,
            {BackgroundTransparency = 1},
            Enum.EasingDirection.In
        )

        local connection
        connection = primary.Completed:Connect(function()
            connection:Disconnect()
            finishClose()
        end)
    end
end

function Library:Unload()
    if self.Unloaded then
        return
    end

    self.Unloaded = true
    self.MenuVisible = false
    self:CancelMenuTweens()

    if self.ActivePromptOverlay and self.ActivePromptOverlay.Parent then
        self.ActivePromptOverlay:Destroy()
        self.ActivePromptOverlay = nil
        self.PromptBusy = false
    end

    if self.ActiveDropdown and self.ActiveDropdown.CloseDropdown then
        pcall(function()
            self.ActiveDropdown:CloseDropdown()
        end)
    end

    -- Turn active toggles off so their callbacks can clean up visual effects.
    for _, control in ipairs(self.Controls) do
        if control.IsToggle and control.Get and control.Set then
            local ok, enabled = pcall(function() return control:Get() end)
            if ok and enabled then
                pcall(function() control:Set(false, false) end)
            end
        end
    end

    if self.Blur and self.Blur.Parent then
        self.Blur:Destroy()
    end

    if self.Root and self.Root.Parent then
        self.Root:Destroy()
    end
end

UnloadButton.MouseButton1Click:Connect(function()
    Library:Unload()
end)

HideButton.MouseButton1Click:Connect(function()
    if not Library.Unloaded then
        Library:SetMenuVisible(false)
    end
end)

--============================================================
-- CONTROL BASE
--============================================================

local function newBaseControl(parent, titleText, required, height, opts)
    opts = opts or {}
    required = required or "Low"

    local functionScale = Library:GetFunctionDPIScale()
    local hasLayout = parent:FindFirstChildOfClass("UIListLayout") ~= nil

    local Holder = Create("Frame", {
        Parent = parent,
        Size = UDim2.new(functionScale, 0, 0, height or 42),
        BorderSizePixel = 0,
        ZIndex = 15,
    })

    if not hasLayout then
        Holder.Position = UDim2.new((1 - functionScale) * 0.5, 0, 0, 0)
    end

    table.insert(Library.ControlFrames, {
        Object = Holder,
        ManualCenter = not hasLayout,
    })

    -- v8 uses an INSIDE border instead of UIStroke for function rows.
    -- UIStroke extends outside the GuiObject and gets clipped by CanvasGroup /
    -- ScrollingFrame boundaries, which is what caused the first control in a
    -- section to lose parts of its purple outline.
    Library:BindTheme(Holder, "BackgroundColor3", "Outline")
    Library:AdaptiveCorner(Holder, 0)

    local Surface = Create("Frame", {
        Parent = Holder,
        Position = UDim2.fromOffset(1, 1),
        Size = UDim2.new(1, -2, 1, -2),
        BorderSizePixel = 0,
        ZIndex = 15,
    })
    Library:BindTheme(Surface, "BackgroundColor3", "Control")
    Library:AdaptiveCorner(Surface, -1)

    -- Local visual scale used by section open/close animations. Because it
    -- lives on the row itself, the row, its text, toggle, slider and outline
    -- all animate together instead of only the section container moving.
    local MotionScale = Create("UIScale", {
        Parent = Holder,
        Scale = 1,
    })

    local Label = Create("TextLabel", {
        Parent = Holder,
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(1, -145, 1, 0),
        BackgroundTransparency = 1,
        Text = opts.LocaleKey and Library:L(opts.LocaleKey) or titleText,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 16,
    })
    Library:BindTheme(Label, "TextColor3", "Text")
    Library:RegisterFont(Label)

    local Requirement = Create("TextLabel", {
        Parent = Holder,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(72, 20),
        BackgroundTransparency = 1,
        Text = required == "Low" and "" or (required .. "+"),
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 16,
    })
    Library:BindTheme(Requirement, "TextColor3", "SubText")
    Library:RegisterFont(Requirement, true)

    local performance = opts.Performance or opts.PerformanceImpact or {}

    local Control = {
        Holder = Holder,
        Surface = Surface,
        MotionScale = MotionScale,
        Label = Label,
        Requirement = Requirement,
        DisplayName = opts.LocaleKey and Library:L(opts.LocaleKey) or titleText,
        LocaleKey = opts.LocaleKey,
        DescriptionKey = opts.DescriptionKey,
        Description = opts.DescriptionKey and Library:L(opts.DescriptionKey) or opts.Description or Library:L("NoDescription"),
        FPSImpact = opts.FPSImpact ~= nil and opts.FPSImpact
            or opts.EstimatedFPS ~= nil and opts.EstimatedFPS
            or performance.FPS,
        PingImpact = opts.PingImpact ~= nil and opts.PingImpact
            or opts.EstimatedPing ~= nil and opts.EstimatedPing
            or performance.Ping,
        TooltipEnabled = opts.Tooltip ~= false,
        RequiredGraphics = required,
        Locked = false,
        Hovering = false,
        DefaultValue = opts.Default,
        DependencyEnabled = true,
        DependencyOptions = {
            DependsOn = opts.DependsOn,
            EnabledWhen = opts.EnabledWhen,
            VisibleWhen = opts.VisibleWhen,
        },
    }

    function Control:RefreshGate()
        local wasLocked = self.Locked
        self.Locked = (not Library:IsGraphicsAllowed(self.RequiredGraphics)) or (self.DependencyEnabled == false)

        -- Both border and surface dim together, while the border always stays
        -- inside the row bounds so it cannot be clipped.
        self.Holder.BackgroundTransparency = self.Locked and 0.58 or 0
        self.Surface.BackgroundTransparency = self.Locked and 0.42 or 0
        self.Label.TextTransparency = self.Locked and 0.55 or 0
        self.Requirement.TextTransparency = self.Locked and 0.35 or 0

        if self.Locked and not wasLocked and self.OnGraphicsLocked then
            self:OnGraphicsLocked()
        end
    end

    function Control:RefreshStyle()
        self:RefreshGate()
    end

    Holder.MouseEnter:Connect(function()
        if Library.Unloaded then return end
        Control.Hovering = true

        -- v13: the highlight reacts immediately. Tooltip content waits for its
        -- configured delay and the previous tooltip is hidden first.
        Library:Animate(Holder, 0.16, {
            BackgroundColor3 = Library.Theme.Hover or Library.Theme.Accent,
        })
        local hoverSurface =
            Library.Theme.Control:Lerp(
                Library.Theme.Hover or Library.Theme.Accent,
                0.10
            )

        Library:Animate(Surface, 0.16, {
            BackgroundColor3 = hoverSurface,
        })

        Library:ShowControlTooltip(Control)
    end)

    Holder.MouseLeave:Connect(function()
        Control.Hovering = false
        Library:Animate(Holder, 0.18, {
            BackgroundColor3 = Library.Theme.Outline,
        })
        Library:Animate(Surface, 0.18, {
            BackgroundColor3 = Library.Theme.Control,
        })
        Library:HideControlTooltip(false)
    end)

