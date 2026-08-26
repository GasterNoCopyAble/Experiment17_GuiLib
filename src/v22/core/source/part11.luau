        TweenInfo.new(0.78, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        {Scale = targetLoaderScale}
    ):Play()

    task.delay(0.10, function()
        if not LoaderBox.Parent then return end
        TweenService:Create(LoaderTitle, TweenInfo.new(0.42), {TextTransparency = 0}):Play()
    end)

    task.delay(0.20, function()
        if not LoaderBox.Parent then return end
        TweenService:Create(LoaderGreeting, TweenInfo.new(0.48), {TextTransparency = 0}):Play()
    end)

    task.delay(0.30, function()
        if not LoaderBox.Parent then return end
        TweenService:Create(LoaderStatus, TweenInfo.new(0.48), {TextTransparency = 0}):Play()
        TweenService:Create(LoaderPercent, TweenInfo.new(0.48), {TextTransparency = 0}):Play()
        TweenService:Create(LoaderBar, TweenInfo.new(0.48), {BackgroundTransparency = 0}):Play()
        TweenService:Create(LoaderFill, TweenInfo.new(0.48), {BackgroundTransparency = 0}):Play()
    end)
end

local MainStroke = Create("UIStroke", {
    Parent = Main,
    Thickness = 1.35,
    Transparency = 0.01,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
})
Library:BindTheme(MainStroke, "Color", "Outline")

local MobileMenuButton = Create("TextButton", {
    Parent = Root,
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -18, 1, -18),
    Size = UDim2.fromOffset(54, 54),
    BackgroundColor3 = Library.Theme.Control,
    BorderSizePixel = 0,
    Text = "E17",
    TextColor3 = Library.Theme.Accent,
    TextSize = 14,
    AutoButtonColor = false,
    Active = true,
    Visible = false,
    ZIndex = 720,
})
Library:RegisterFont(MobileMenuButton, true)
Library:BindTheme(MobileMenuButton, "BackgroundColor3", "Control")
Library:BindTheme(MobileMenuButton, "TextColor3", "Accent")
Library:AdaptiveCorner(MobileMenuButton, 8)

local MobileMenuStroke = Create("UIStroke", {
    Parent = MobileMenuButton,
    Thickness = 1.35,
    Transparency = 0.08,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    Color = Library.Theme.Outline,
})

Library:BindTheme(MobileMenuStroke, "Color", "Outline")

local MobileMenuScale = Create("UIScale", {
    Parent = MobileMenuButton,
    Scale = 1,
})

local mobileButtonDragging = false
local mobileButtonMoved = false
local mobileButtonInputType = nil
local mobileButtonStartPointer = nil
local mobileButtonStartPosition = nil
local mobileButtonStartAnchor = nil

function Library:RefreshMobileButton()
    local size = math.clamp(tonumber(self.Settings.MobileButtonSize) or 54, 36, 96)
    local opacity = math.clamp(tonumber(self.Settings.MobileButtonOpacity) or 100, 20, 100)

    MobileMenuButton.Size = UDim2.fromOffset(size, size)
    MobileMenuButton.Text = tostring(self.Settings.MobileButtonText or "E17")
    MobileMenuButton.BackgroundTransparency = 1 - (opacity / 100)

    local saved = self.Settings.MobileButtonPosition
    if type(saved) == "table" and tonumber(saved.X) and tonumber(saved.Y) then
        MobileMenuButton.AnchorPoint = Vector2.new(0, 0)
        MobileMenuButton.Position = UDim2.fromOffset(saved.X, saved.Y)
    else
        MobileMenuButton.AnchorPoint = Vector2.new(1, 1)
        MobileMenuButton.Position = UDim2.new(1, -18, 1, -18)
    end

    MobileMenuButton.Visible =
        UIS.TouchEnabled == true
        and self.Settings.MobileButtonEnabled == true
        and self.StartupCompleted == true
        and not self.Unloaded
end

local function mobilePointer(input)
    return Vector2.new(input.Position.X, input.Position.Y)
end

MobileMenuButton.InputBegan:Connect(function(input)
    if Library.Unloaded or not Library.Settings.MobileButtonDraggable then
        return
    end

    if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1
    then
        mobileButtonDragging = true
        mobileButtonMoved = false
        mobileButtonInputType = input.UserInputType
        mobileButtonStartPointer = mobilePointer(input)
        mobileButtonStartPosition = MobileMenuButton.Position
        mobileButtonStartAnchor = MobileMenuButton.AnchorPoint
    end
end)

UIS.InputChanged:Connect(function(input)
    if Library.Unloaded or not mobileButtonDragging then return end

    local valid =
        (mobileButtonInputType == Enum.UserInputType.Touch and input.UserInputType == Enum.UserInputType.Touch)
        or
        (mobileButtonInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement)

    if not valid then return end

    local pointer = mobilePointer(input)
    local delta = pointer - mobileButtonStartPointer

    if delta.Magnitude > 7 then
        mobileButtonMoved = true
    end

    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
    local size = MobileMenuButton.AbsoluteSize
    local start = mobileButtonStartPosition
    local anchor = mobileButtonStartAnchor or Vector2.new(0, 0)

    local desiredAnchorX = viewport.X * start.X.Scale + start.X.Offset + delta.X
    local desiredAnchorY = viewport.Y * start.Y.Scale + start.Y.Offset + delta.Y

    local topLeftX = desiredAnchorX - size.X * anchor.X
    local topLeftY = desiredAnchorY - size.Y * anchor.Y

    local clampedX = math.clamp(topLeftX, 4, math.max(4, viewport.X - size.X - 4))
    local clampedY = math.clamp(topLeftY, 4, math.max(4, viewport.Y - size.Y - 4))

    MobileMenuButton.AnchorPoint = Vector2.new(0, 0)
    MobileMenuButton.Position = UDim2.fromOffset(clampedX, clampedY)

    Library.Settings.MobileButtonPosition = {X = clampedX, Y = clampedY}
end)

UIS.InputEnded:Connect(function(input)
    if not mobileButtonDragging then return end

    local valid =
        (mobileButtonInputType == Enum.UserInputType.Touch and input.UserInputType == Enum.UserInputType.Touch)
        or
        (mobileButtonInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseButton1)

    if valid then
        mobileButtonDragging = false
        mobileButtonInputType = nil
    end
end)

MobileMenuButton.Activated:Connect(function()
    if Library.Unloaded or Library.PromptBusy then
        return
    end

    if mobileButtonMoved then
        mobileButtonMoved = false
        return
    end

    MobileMenuScale.Scale = 0.86
    Library:Animate(MobileMenuScale, 0.22, {Scale = 1})
    Library:SetMenuVisible(not Library.MenuVisible)
end)

local Topbar = Create("Frame", {
    Parent = MainVisual,
    Size = UDim2.new(1, 0, 0, 52),
    BorderSizePixel = 0,
    Active = true,
    ZIndex = 11,
})
Library:BindTheme(Topbar, "BackgroundColor3", "Panel")
Library:AdaptiveCorner(Topbar, 4)

local TopbarSquare = Create("Frame", {
    Parent = Topbar,
    Position = UDim2.new(0, 0, 1, -10),
    Size = UDim2.new(1, 0, 0, 10),
    BorderSizePixel = 0,
    ZIndex = 11,
})
Library:BindTheme(TopbarSquare, "BackgroundColor3", "Panel")

local PathBar = Create("Frame", {
    Parent = Topbar,
    Position = UDim2.fromOffset(18, 0),
    Size = UDim2.new(1, -150, 1, 0),
    BackgroundTransparency = 1,
    ZIndex = 12,
})

Create("UIListLayout", {
    Parent = PathBar,
    FillDirection = Enum.FillDirection.Horizontal,
    VerticalAlignment = Enum.VerticalAlignment.Center,
    HorizontalAlignment = Enum.HorizontalAlignment.Left,
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
})

local Title = Create("TextLabel", {
    Parent = PathBar,
    Size = UDim2.fromOffset(0, 52),
    AutomaticSize = Enum.AutomaticSize.X,
    BackgroundTransparency = 1,
    Text = "Experiment 17 [Visuals]",
    TextSize = 16,
    TextXAlignment = Enum.TextXAlignment.Left,
    LayoutOrder = 1,
    ZIndex = 12,
})
Library:BindTheme(Title, "TextColor3", "Text")
Library:RegisterFont(Title, true)

local BreadcrumbArrow = Create("TextLabel", {
    Parent = PathBar,
    Size = UDim2.fromOffset(12, 52),
    BackgroundTransparency = 1,
    Text = ">",
    TextSize = 16,
    LayoutOrder = 2,
    ZIndex = 12,
})
Library:BindTheme(BreadcrumbArrow, "TextColor3", "Accent")
Library:RegisterFont(BreadcrumbArrow, true)

local Breadcrumb = Create("TextLabel", {
    Parent = PathBar,
    Size = UDim2.fromOffset(0, 52),
    AutomaticSize = Enum.AutomaticSize.X,
    BackgroundTransparency = 1,
    Text = Library:L("Home"),
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
    LayoutOrder = 3,
    ZIndex = 12,
})
Library:BindTheme(Breadcrumb, "TextColor3", "SubText")
Library:RegisterFont(Breadcrumb)
Library.Breadcrumb = Breadcrumb

local LevelText = Create("TextLabel", {
    Parent = Topbar,
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -15, 0, 0),
    Size = UDim2.fromOffset(105, 52),
    BackgroundTransparency = 1,
    Text = "Epic",
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Right,
    ZIndex = 12,
})
Library:BindTheme(LevelText, "TextColor3", "Accent")
Library:RegisterFont(LevelText, true)
Library.LevelText = LevelText

-- Topbar search.
PathBar.Size = UDim2.new(1, -390, 1, 0)
LevelText.Position = UDim2.new(1, -14, 0, 0)
LevelText.Size = UDim2.fromOffset(70, 52)

local SearchBox = Create("TextBox", {
    Parent = Topbar,
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -94, 0.5, 0),
    Size = UDim2.fromOffset(188, 28),
    BackgroundColor3 = Library.Theme.Control2,
    BorderSizePixel = 0,
    Text = "",
    PlaceholderText = Library:L("SearchPlaceholder"),
    ClearTextOnFocus = false,
    TextColor3 = Library.Theme.Text,
    PlaceholderColor3 = Library.Theme.SubText,
    TextSize = 11,
    ZIndex = 28,
})
Library:RegisterFont(SearchBox)
Library:BindLocaleText(SearchBox, "SearchPlaceholder", "PlaceholderText")
Library:AdaptiveCorner(SearchBox, -2)

local SearchStroke = Create("UIStroke", {
    Parent = SearchBox,
    Thickness = 1.0,
    Transparency = 0.28,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    Color = Library.Theme.Outline,
})

local SearchResultsFrame = Create("Frame", {
    Parent = Root,
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -94, 1, 3),
    Size = UDim2.fromOffset(260, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundColor3 = Library.Theme.Panel,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 620,
})
Library:AdaptiveCorner(SearchResultsFrame, -2)

local SearchResultsStroke = Create("UIStroke", {
    Parent = SearchResultsFrame,
    Thickness = 1.1,
    Transparency = 0.12,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    Color = Library.Theme.Outline,
})

local SearchResultsInner = Create("Frame", {
    Parent = SearchResultsFrame,
    Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
    ZIndex = 621,
})
Create("UIPadding", {
    Parent = SearchResultsInner,
    PaddingTop = UDim.new(0, 6),
    PaddingBottom = UDim.new(0, 6),
    PaddingLeft = UDim.new(0, 6),
    PaddingRight = UDim.new(0, 6),
})
Create("UIListLayout", {
    Parent = SearchResultsInner,
    Padding = UDim.new(0, 3),
    SortOrder = Enum.SortOrder.LayoutOrder,
})

local FavoritesButton = Create("TextButton", {
    Parent = Topbar,
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -288, 0.5, 0),
    Size = UDim2.fromOffset(32, 28),
    BackgroundColor3 = Library.Theme.Control2,
    BorderSizePixel = 0,
    Text = "★",
    TextColor3 = Library.Theme.Accent,
    TextSize = 14,
    AutoButtonColor = false,
    ZIndex = 28,
})
