        if resolved then
            return
        end
        resolved = true

        if options.Flag then
            Library.Flags[tostring(options.Flag)] = value
        end

        resultEvent:Fire(value, index)

        TweenService:Create(
            overlay,
            TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
            {BackgroundTransparency = 1}
        ):Play()

        TweenService:Create(
            promptBox,
            TweenInfo.new(0.26, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
            {Position = UDim2.new(0.5, 0, 0.5, 42)}
        ):Play()

        TweenService:Create(
            promptScale,
            TweenInfo.new(0.26, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
            {Scale = math.max(0.45, (Library.CurrentDPIScale or DPI_BASE_SCALE) * 0.72)}
        ):Play()
    end

    local buttonCount = math.max(1, #normalized)
    local widthOffset = -((gap * (buttonCount - 1)) / buttonCount)

    for index, option in ipairs(normalized) do
        local button = Create("TextButton", {
            Parent = buttons,
            Size = UDim2.new(1 / buttonCount, widthOffset, 1, 0),
            BackgroundColor3 = self.Theme.Control,
            BorderSizePixel = 0,
            Text = option.Text,
            TextColor3 = self.Theme.Text,
            TextSize = 14,
            TextWrapped = true,
            AutoButtonColor = false,
            LayoutOrder = index,
            ZIndex = 223,
        })
        self:RegisterFont(button, true)
        self:AdaptiveCorner(button, -2)

        local buttonStroke = Create("UIStroke", {
            Parent = button,
            Thickness = 1.1,
            Transparency = 0.18,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Color = self.Theme.Outline,
        })

        button.MouseEnter:Connect(function()
            if resolved then return end
            self:Animate(buttonStroke, 0.18, {Transparency = 0.02})
            self:Animate(button, 0.18, {BackgroundColor3 = self.Theme.Control2})
        end)

        button.MouseLeave:Connect(function()
            if resolved then return end
            self:Animate(buttonStroke, 0.18, {Transparency = 0.18})
            self:Animate(button, 0.18, {BackgroundColor3 = self.Theme.Control})
        end)

        button.MouseButton1Click:Connect(function()
            finish(option.Value, index)
        end)
    end

    TweenService:Create(
        overlay,
        TweenInfo.new(0.30, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        {BackgroundTransparency = 0.22}
    ):Play()

    TweenService:Create(
        promptBox,
        TweenInfo.new(0.48, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        {Position = UDim2.fromScale(0.5, 0.5)}
    ):Play()

    TweenService:Create(
        promptScale,
        TweenInfo.new(0.52, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Scale = math.max(0.45, self.CurrentDPIScale or DPI_BASE_SCALE)}
    ):Play()

    local value, index = resultEvent.Event:Wait()

    task.wait(0.27)

    if overlay.Parent then
        overlay:Destroy()
    end

    resultEvent:Destroy()
    self.ActivePromptOverlay = nil
    self.PromptBusy = false

    if type(options.Callback) == "function" then
        local ok, err = pcall(options.Callback, value, index)
        if not ok then
            warn("[Experiment17] Prompt callback error:", err)
        end
    end

    return value, index
end

function Library:ShowQuestion(options)
    options = options or {}
    if options.Title == nil then
        options.Title = self:L("Question")
    end
    return self:_ShowPrompt(options)
end

function Library:ShowConfirm(options)
    options = options or {}

    local confirmOptions = {}
    for key, value in pairs(options) do
        confirmOptions[key] = value
    end

    if confirmOptions.Title == nil then
        confirmOptions.Title = self:L("Confirmation")
    end

    confirmOptions.Options = {
        {
            Text = confirmOptions.YesText or self:L("Yes"),
            Value = true,
        },
        {
            Text = confirmOptions.NoText or self:L("No"),
            Value = false,
        },
    }

    return self:_ShowPrompt(confirmOptions)
end

function Library:QueueStartupQuestion(options)
    if self.StartupCompleted then
        task.spawn(function()
            self:ShowQuestion(options)
        end)
        return self
    end

    table.insert(self.StartupPrompts, {
        Type = "Question",
        Options = options or {},
    })

    return self
end

function Library:QueueStartupConfirm(options)
    if self.StartupCompleted then
        task.spawn(function()
            self:ShowConfirm(options)
        end)
        return self
    end

    table.insert(self.StartupPrompts, {
        Type = "Confirm",
        Options = options or {},
    })

    return self
end

-- Friendly aliases for scripts that prefer "Add" terminology.
Library.AddStartupQuestion = Library.QueueStartupQuestion
Library.AddStartupConfirm = Library.QueueStartupConfirm

function Library:GetStartupAnswer(flag)
    return self.StartupAnswers[tostring(flag)] ~= nil
        and self.StartupAnswers[tostring(flag)]
        or self.Flags[tostring(flag)]
end

function Library:ShouldRunStartupPrompt(options)
    options = options or {}

    if options.OnlyOnce and options.Flag and self.Flags[tostring(options.Flag)] ~= nil then
        return false
    end

    if type(options.Condition) == "function" then
        local ok, result = pcall(options.Condition, self.StartupAnswers, self.Flags)
        if not ok then
            warn("[Experiment17 UI] Startup condition error:", result)
            return false
        end
        if result ~= true then
            return false
        end
    end

    if type(options.DependsOn) == "table" then
        for flag, expected in pairs(options.DependsOn) do
            local actual = self:GetStartupAnswer(flag)
            if actual ~= expected then
                return false
            end
        end
    end

    return true
end

function Library:RunStartupPrompts()
    while #self.StartupPrompts > 0 and not self.Unloaded do
        local entry = table.remove(self.StartupPrompts, 1)
        local options = entry.Options or {}

        if self:ShouldRunStartupPrompt(options) then
            local value

            if entry.Type == "Confirm" then
                value = self:ShowConfirm(options)
            else
                value = self:ShowQuestion(options)
            end

            if options.Flag then
                self.StartupAnswers[tostring(options.Flag)] = value
            end

            if options.ApplyProfile then
                local profileName = type(options.ApplyProfile) == "function"
                    and options.ApplyProfile(value, self.StartupAnswers)
                    or options.ApplyProfile

                if profileName then
                    self:ApplyProfile(profileName)
                end
            end
        end
    end

    self.StartupCompleted = true
end

--============================================================
-- NOTIFICATIONS
--============================================================

local NotificationLayer = Create("Frame", {
    Parent = Root,
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 180,
})
Library.NotificationLayer = NotificationLayer

local NOTIFICATION_POSITIONS = {
    ["Top Left"] = {X = 16, Y = 16, AX = 0, AY = 0, Direction = 1},
    ["Top Center"] = {XScale = 0.5, X = 0, Y = 16, AX = 0.5, AY = 0, Direction = 1},
    ["Top Right"] = {XScale = 1, X = -16, Y = 16, AX = 1, AY = 0, Direction = 1},
    ["Bottom Left"] = {X = 16, YScale = 1, Y = -16, AX = 0, AY = 1, Direction = -1},
    ["Bottom Center"] = {XScale = 0.5, X = 0, YScale = 1, Y = -16, AX = 0.5, AY = 1, Direction = -1},
    ["Bottom Right"] = {XScale = 1, X = -16, YScale = 1, Y = -16, AX = 1, AY = 1, Direction = -1},
}

function Library:GetNotificationPositionData(position)
    return NOTIFICATION_POSITIONS[tostring(position)] or NOTIFICATION_POSITIONS["Bottom Right"]
end

function Library:ReflowNotifications()
    local cfg = self:GetNotificationPositionData(self.Settings.NotificationPosition)
    local gap = 8
    local cursor = 0

    for _, item in ipairs(self.NotificationItems) do
        if item.Frame and item.Frame.Parent then
            local height = item.Frame.AbsoluteSize.Y > 0 and item.Frame.AbsoluteSize.Y or 74
            local yOffset = cfg.Direction == 1 and cursor or -cursor

            local xScale = cfg.XScale or 0
            local yScale = cfg.YScale or 0
            local target = UDim2.new(
                xScale,
                cfg.X or 0,
                yScale,
                (cfg.Y or 0) + yOffset
            )

            item.Frame.AnchorPoint = Vector2.new(cfg.AX, cfg.AY)
            self:Animate(item.Frame, 0.34, {Position = target})
            cursor += height + gap
        end
    end
end

function Library:Notify(options)
    options = options or {}

    local title = self:ResolveLocalizedText(options.Title, "Experiment 17")
    local body = self:ResolveLocalizedText(options.Text or options.Description, "")
    local duration = math.clamp(tonumber(options.Duration) or self.Settings.NotificationDuration or 4, 1, 30)
    local kind = tostring(options.Type or "Info")
    local cfg = self:GetNotificationPositionData(options.Position or self.Settings.NotificationPosition)

    while #self.NotificationItems >= math.max(1, self.Settings.NotificationLimit or 5) do
        local oldest = table.remove(self.NotificationItems, 1)
        if oldest and oldest.Close then
            oldest:Close(true)
        end
    end

    local mobileNotification = UIS.TouchEnabled == true
    local notificationWidth = mobileNotification and 220 or 330
    local notificationHeight = mobileNotification and 52 or 76

    local frame = Create("CanvasGroup", {
        Parent = NotificationLayer,
        AnchorPoint = Vector2.new(cfg.AX, cfg.AY),
        Position = UDim2.new(
            cfg.XScale or 0,
            (cfg.X or 0) + (cfg.AX == 1 and 80 or cfg.AX == 0 and -80 or 0),
            cfg.YScale or 0,
            cfg.Y or 0
        ),
        Size = UDim2.fromOffset(notificationWidth, notificationHeight),
        BackgroundColor3 = self.Theme.Panel,
        BorderSizePixel = 0,
        GroupTransparency = 1,
        ZIndex = 181,
    })
    self:AdaptiveCorner(frame, 2)

    local stroke = Create("UIStroke", {
        Parent = frame,
        Thickness = 1.2,
        Transparency = 0.10,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Color = self.Theme.Outline,
    })

    local accent = Create("Frame", {
        Parent = frame,
        Position = UDim2.fromOffset(5, mobileNotification and 5 or 7),
        Size = UDim2.fromOffset(3, mobileNotification and 42 or 62),
        BackgroundColor3 = self.Theme.Accent,
        BorderSizePixel = 0,
        ZIndex = 182,
    })
    Create("UICorner", {Parent = accent, CornerRadius = UDim.new(1, 0)})

    local titleLabel = Create("TextLabel", {
        Parent = frame,
        Position = UDim2.fromOffset(18, mobileNotification and 6 or 10),
        Size = UDim2.new(1, -38, 0, mobileNotification and 16 or 20),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = self.Theme.Text,
        TextSize = mobileNotification and 11 or 14,
