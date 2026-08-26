    task.delay(math.max(0, tonumber(self.Settings.TooltipDelay) or 0.12), function()
        if self.Unloaded or self.TooltipHoverToken ~= token or not control.Hovering or not self.Settings.TooltipsEnabled then
            return
        end

        TooltipTitle.Text = tostring(control.DisplayName or control.Label and control.Label.Text or "Function")
        TooltipDescription.Text = tostring(control.Description or Library:L("NoDescription"))
        TooltipGraphics.Text =
            Library:L("Graphics") .. ": " .. tostring(control.RequiredGraphics or "Low") .. "+"
            .. (control.Locked
                and ("   [" .. Library:L("Locked") .. "]")
                or ("   [" .. Library:L("Available") .. "]"))
        TooltipPerformance.Text =
            Library:L("FPSImpact") .. ": " .. formatImpact(control.FPSImpact, "FPS")
            .. "    |    " .. Library:L("PingImpact") .. ": " .. formatImpact(control.PingImpact, "ms")

        local mouse = UIS:GetMouseLocation()
        self.TooltipCurrentPosition = mouse + Vector2.new(18, 18)
        Tooltip.Position = UDim2.fromOffset(self.TooltipCurrentPosition.X, self.TooltipCurrentPosition.Y)
        Tooltip.GroupTransparency = 1
        Tooltip.Visible = true
        self.TooltipFollowing = true
        self:Animate(Tooltip, 0.13, {GroupTransparency = 0})
    end)
end

RunService.RenderStepped:Connect(function(dt)
    if Library.Unloaded or not Tooltip.Visible or not Library.TooltipFollowing then
        return
    end

    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
    local mouse = UIS:GetMouseLocation()
    local size = Tooltip.AbsoluteSize
    if size.X <= 0 or size.Y <= 0 then
        size = Vector2.new(330, 110)
    end

    local target = mouse + Vector2.new(18, 18)
    if target.X + size.X > viewport.X - 8 then
        target = Vector2.new(math.max(8, mouse.X - size.X - 18), target.Y)
    end
    if target.Y + size.Y > viewport.Y - 8 then
        target = Vector2.new(target.X, math.max(8, viewport.Y - size.Y - 8))
    end

    local follow = math.clamp(tonumber(Library.Settings.TooltipFollowSpeed) or 22, 5, 50)
    local alpha = 1 - math.exp(-follow * dt)
    Library.TooltipCurrentPosition = Library.TooltipCurrentPosition:Lerp(target, alpha)
    Tooltip.Position = UDim2.fromOffset(
        Library.TooltipCurrentPosition.X,
        Library.TooltipCurrentPosition.Y
    )
end)

local Blur = Create("BlurEffect", {
    Name = "Experiment17_MenuBlur",
    Size = 0,
    Parent = Lighting,
})
Library.Blur = Blur

local Dim = Create("Frame", {
    Name = "Dim",
    Parent = Root,
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Color3.new(0, 0, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 1,
})
Library.Dim = Dim

function Library:RefreshBackdrop()
    if not self.MenuVisible then
        return
    end

    Blur.Size = self.Settings.BlurEnabled and self.Settings.BlurSize or 0
    Dim.BackgroundTransparency = self.Settings.DimEnabled and self.Settings.DimTransparency or 1
end

--============================================================
-- LOADER GREETING
--============================================================

local function getLocalHour()
    -- os.date("*t") uses the local OS clock exposed to the Luau environment.
    local ok, dateTable = pcall(function()
        return os.date("*t")
    end)

    if ok and type(dateTable) == "table" and tonumber(dateTable.hour) then
        return tonumber(dateTable.hour)
    end

    -- Fallback for environments where os.date is restricted.
    local okDateTime, hour = pcall(function()
        return DateTime.now():ToLocalTime().Hour
    end)

    if okDateTime and tonumber(hour) then
        return tonumber(hour)
    end

    return 12
end

local function getTimeGreeting()
    local hour = getLocalHour()

    if hour >= 22 then
        return Library:L("GreetingSleepSoon")
    elseif hour >= 18 then
        return Library:L("GreetingEvening")
    elseif hour >= 10 then
        return Library:L("GreetingMorning")
    elseif hour >= 8 then
        return Library:L("GreetingEarly")
    elseif hour >= 2 then
        return Library:L("GreetingWhyAwake")
    end

    return Library:L("GreetingNight")
end

local function getLocalizedGreeting()
    return string.format(
        Library:L("HelloUser"),
        tostring(LocalPlayer.Name),
        getTimeGreeting()
    )
end

--============================================================
-- LOADING SCREEN
--============================================================

local Loader = Create("Frame", {
    Parent = Root,
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Color3.new(0, 0, 0),
    BackgroundTransparency = 0.2,
    BorderSizePixel = 0,
    ZIndex = 100,
})

local ParticleLayer = Create("Frame", {
    Parent = Loader,
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    ZIndex = 101,
})

for i = 1, 26 do
    local size = math.random(2, 5)
    local dot = Create("Frame", {
        Parent = ParticleLayer,
        Size = UDim2.fromOffset(size, size),
        Position = UDim2.fromScale(math.random(), math.random()),
        BackgroundColor3 = Library.Theme.Accent,
        BackgroundTransparency = math.random(20, 70) / 100,
        BorderSizePixel = 0,
        ZIndex = 101,
    })
    Create("UICorner", {Parent = dot, CornerRadius = UDim.new(1, 0)})

    task.spawn(function()
        while dot.Parent do
            local tween = TweenService:Create(
                dot,
                TweenInfo.new(math.random(12, 28) / 10, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                {
                    Position = UDim2.fromScale(math.random(), math.random()),
                    BackgroundTransparency = math.random(20, 75) / 100,
                }
            )
            tween:Play()
            tween.Completed:Wait()
        end
    end)
end

local LoaderBox = Create("Frame", {
    Parent = Loader,
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),

    -- v10: loader itself is 25% larger than the original 360x116 layout.
    Size = UDim2.fromOffset(450, 145),

    BackgroundColor3 = Library.Theme.Background,
    BorderSizePixel = 0,
    ZIndex = 102,
})
Library:AdaptiveCorner(LoaderBox, 4)

local LoaderScale = Create("UIScale", {
    Parent = LoaderBox,
    Scale = DPI_BASE_SCALE,
})
Library.LoaderScale = LoaderScale

local LoaderStroke = Create("UIStroke", {
    Parent = LoaderBox,
    Color = Library.Theme.Outline,
    Thickness = 1.25,
    Transparency = 0.12,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
})

-- The old top accent strip was intentionally removed in v10.

local LoaderTitle = Create("TextLabel", {
    Parent = LoaderBox,
    Position = UDim2.fromOffset(23, 18),
    Size = UDim2.new(1, -46, 0, 30),
    BackgroundTransparency = 1,
    Text = "Experiment 17 [Visuals]",
    TextColor3 = Library.Theme.Text,

    -- 18 -> ~23 (+25%)
    TextSize = 23,

    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 103,
})
Library:RegisterFont(LoaderTitle, true)

local LoaderGreeting = Create("TextLabel", {
    Parent = LoaderBox,
    Position = UDim2.fromOffset(23, 51),
    Size = UDim2.new(1, -46, 0, 26),
    BackgroundTransparency = 1,

    Text = getLocalizedGreeting(),
    TextColor3 = Library.Theme.Text,
    TextSize = 17,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
    ZIndex = 103,
})
Library:RegisterFont(LoaderGreeting, true)

local LoaderStatus = Create("TextLabel", {
    Parent = LoaderBox,
    Position = UDim2.fromOffset(23, 79),
    Size = UDim2.new(1, -118, 0, 20),
    BackgroundTransparency = 1,
    Text = Library:L("LoadingInterface"),
    TextColor3 = Library.Theme.SubText,

    -- 12 -> 15 (+25%)
    TextSize = 15,

    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 103,
})
Library:RegisterFont(LoaderStatus)

local LoaderPercent = Create("TextLabel", {
    Parent = LoaderBox,
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -23, 0, 79),
    Size = UDim2.fromOffset(64, 20),
    BackgroundTransparency = 1,
    Text = "0%",
    TextColor3 = Library.Theme.Accent,
    TextSize = 15,
    TextXAlignment = Enum.TextXAlignment.Right,
    ZIndex = 103,
})
Library:RegisterFont(LoaderPercent, true)

local LoaderBar = Create("Frame", {
    Parent = LoaderBox,
    Position = UDim2.new(0, 23, 1, -27),
    Size = UDim2.new(1, -46, 0, 6),
    BackgroundColor3 = Library.Theme.Control2,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    ZIndex = 103,
})
Create("UICorner", {Parent = LoaderBar, CornerRadius = UDim.new(1, 0)})

local LoaderFill = Create("Frame", {
    Parent = LoaderBar,
    Size = UDim2.fromScale(0, 1),
    BackgroundColor3 = Library.Theme.Accent,
    BorderSizePixel = 0,
    ZIndex = 104,
})
Create("UICorner", {Parent = LoaderFill, CornerRadius = UDim.new(1, 0)})

local LoaderGlow = Create("Frame", {
    Parent = LoaderFill,
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, 0, 0, 0),
    Size = UDim2.fromOffset(30, 6),
    BackgroundColor3 = Color3.new(1, 1, 1),
    BackgroundTransparency = 0.72,
    BorderSizePixel = 0,
    ZIndex = 105,
})
Create("UICorner", {Parent = LoaderGlow, CornerRadius = UDim.new(1, 0)})

--============================================================
-- MAIN WINDOW
--============================================================

local Main = Create("Frame", {
    Parent = Root,
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(780, 500),
    BackgroundTransparency = 0,
    BorderSizePixel = 0,
    ClipsDescendants = true, -- clips sidebar/topbar to the rounded outer silhouette
    Visible = false,
    ZIndex = 10,
})
Library:BindTheme(Main, "BackgroundColor3", "Background")
Library:AdaptiveCorner(Main, 4)
Library.Main = Main

-- Keep the black shell separate from animated content. In v7 the whole
-- window was a CanvasGroup, so GroupTransparency also faded the black
-- background and could make the GUI look transparent during Scale/Fade.
-- v8 keeps Main permanently opaque and fades/moves only this child group.
local MainVisual = Create("CanvasGroup", {
    Parent = Main,
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    GroupTransparency = 0,
    ClipsDescendants = true,
    ZIndex = 10,
})
Library.MainVisual = MainVisual

local MainScale = Create("UIScale", {
    Parent = Main,
    Scale = DPI_BASE_SCALE,
})
Library.MainScale = MainScale
Library:ApplyDPIScale()

-- v13 loader entrance: the panel rises into place and grows from a compact
-- state instead of simply appearing in the middle of the screen.
do
    local targetLoaderScale = math.max(0.45, Library.CurrentDPIScale or DPI_BASE_SCALE)

    LoaderBox.Position = UDim2.new(0.5, 0, 0.5, 46)
    LoaderScale.Scale = targetLoaderScale * 0.70

    LoaderTitle.TextTransparency = 1
    LoaderGreeting.TextTransparency = 1
    LoaderStatus.TextTransparency = 1
    LoaderPercent.TextTransparency = 1
    LoaderBar.BackgroundTransparency = 1
    LoaderFill.BackgroundTransparency = 1

    TweenService:Create(
        LoaderBox,
        TweenInfo.new(0.72, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        {Position = UDim2.fromScale(0.5, 0.5)}
    ):Play()

    TweenService:Create(
        LoaderScale,
