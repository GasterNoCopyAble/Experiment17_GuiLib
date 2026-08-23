Library:BindTheme(Sidebar, "BackgroundColor3", "Panel")
Library:AdaptiveCorner(Sidebar, 4)

local MainGradient = Library:RegisterGradient(Main)
local TopbarGradient = Library:RegisterGradient(Topbar)
local SidebarGradient = Library:RegisterGradient(Sidebar)
local MobileButtonGradient = Library:RegisterGradient(MobileMenuButton)
Library:RefreshGradients()

-- UICorner rounds every sidebar corner. These masks restore the two internal
-- square corners while leaving the actual bottom-left outer corner rounded.
local SidebarTopMask = Create("Frame", {
    Parent = Sidebar,
    Position = UDim2.fromOffset(0, 0),
    Size = UDim2.new(1, 0, 0, 14),
    BorderSizePixel = 0,
    ZIndex = 11,
})
Library:BindTheme(SidebarTopMask, "BackgroundColor3", "Panel")

local SidebarBottomRightMask = Create("Frame", {
    Parent = Sidebar,
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.fromScale(1, 1),
    Size = UDim2.fromOffset(14, 14),
    BorderSizePixel = 0,
    ZIndex = 11,
})
Library:BindTheme(SidebarBottomRightMask, "BackgroundColor3", "Panel")

local Divider = Create("Frame", {
    Parent = Sidebar,
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, 0, 0, 0),
    Size = UDim2.new(0, 1, 1, 0),
    BorderSizePixel = 0,
    ZIndex = 12,
})
Library:BindTheme(Divider, "BackgroundColor3", "Outline")

local TabList = Create("ScrollingFrame", {
    Parent = Sidebar,
    Position = UDim2.fromOffset(9, 9),
    Size = UDim2.new(1, -18, 1, -68),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 0,
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    CanvasSize = UDim2.new(),
    ClipsDescendants = true,
    ZIndex = 12,
})
-- Keep selected-tab UIStroke fully inside the scrolling viewport.
Create("UIPadding", {
    Parent = TabList,
    PaddingTop = UDim.new(0, 3),
    PaddingBottom = UDim.new(0, 3),
    PaddingLeft = UDim.new(0, 2),
    PaddingRight = UDim.new(0, 2),
})
Create("UIListLayout", {
    Parent = TabList,
    Padding = UDim.new(0, 5),
    SortOrder = Enum.SortOrder.LayoutOrder,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
})

-- Bottom-left actions: unload (X) and hide (_).
local SidebarActions = Create("Frame", {
    Parent = Sidebar,
    Position = UDim2.new(0, 10, 1, -48),
    Size = UDim2.fromOffset(78, 38),
    BackgroundTransparency = 1,
    ZIndex = 14,
})

local function makeSidebarAction(text, x)
    local button = Create("TextButton", {
        Parent = SidebarActions,
        Position = UDim2.fromOffset(x, 2),
        Size = UDim2.fromOffset(34, 34),
        BorderSizePixel = 0,
        Text = text,
        TextSize = 16,
        AutoButtonColor = false,
        ZIndex = 15,
    })
    Library:BindTheme(button, "BackgroundColor3", "Control2")
    Library:BindTheme(button, "TextColor3", "Text")
    Library:RegisterFont(button, true)
    Library:AdaptiveCorner(button, -2)

    local stroke = Create("UIStroke", {
        Parent = button,
        Thickness = 1.1,
        Transparency = 0.22,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
    Library:BindTheme(stroke, "Color", "Outline")

    return button
end

local UnloadButton = makeSidebarAction("X", 0)
local HideButton = makeSidebarAction("_", 42)

local Content = Create("Frame", {
    Parent = MainVisual,
    Position = UDim2.fromOffset(172, 52),
    Size = UDim2.new(1, -172, 1, -52),
    BackgroundTransparency = 1,
    ZIndex = 11,
})

Library.TabList = TabList
Library.Content = Content
Library.Tabs = {}
Library.ControlsByFlag = {}

local viewportConnection
local function hookViewport(camera)
    if viewportConnection then
        viewportConnection:Disconnect()
        viewportConnection = nil
    end
    if camera then
        viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            Library:ApplyDPIScale()
        end)
    end
    Library:ApplyDPIScale()
end

hookViewport(workspace.CurrentCamera)
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    if Library.Unloaded then return end
    hookViewport(workspace.CurrentCamera)
end)

--============================================================
-- DRAGGING
--============================================================

local dragging = false
local dragSettling = false
local dragStart = nil
local startPos = nil
local dragTarget = Main.Position
local dragInputType = nil

local function positionDistance(a, b)
    return math.abs(a.X.Offset - b.X.Offset) + math.abs(a.Y.Offset - b.Y.Offset)
end

local function dragPointer(input)
    return Vector2.new(input.Position.X, input.Position.Y)
end

Topbar.InputBegan:Connect(function(input)
    if Library.Unloaded then return end

    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
    then
        dragging = true
        dragSettling = false
        dragInputType = input.UserInputType
        dragStart = dragPointer(input)
        startPos = Main.Position
        dragTarget = Main.Position
    end
end)

UIS.InputChanged:Connect(function(input)
    if Library.Unloaded or not dragging then return end

    local valid =
        (dragInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement)
        or
        (dragInputType == Enum.UserInputType.Touch and input.UserInputType == Enum.UserInputType.Touch)

    if not valid then return end

    local delta = dragPointer(input) - dragStart
    dragTarget = UDim2.new(
        startPos.X.Scale,
        startPos.X.Offset + delta.X,
        startPos.Y.Scale,
        startPos.Y.Offset + delta.Y
    )

    if Library.Settings.DragMode == "Direct" or dragInputType == Enum.UserInputType.Touch then
        Main.Position = dragTarget
    end
end)

RunService.RenderStepped:Connect(function(dt)
    if Library.Unloaded then return end
    if Library.Settings.DragMode ~= "Smooth" then return end
    if dragInputType == Enum.UserInputType.Touch then return end
    if not dragging and not dragSettling then return end

    local speed = math.clamp(tonumber(Library.Settings.DragSmoothness) or 16, 5, 40)
    local alpha = 1 - math.exp(-speed * dt)
    Main.Position = Main.Position:Lerp(dragTarget, alpha)

    if not dragging and positionDistance(Main.Position, dragTarget) < 0.6 then
        Main.Position = dragTarget
        dragSettling = false
        Library.WindowPosition = dragTarget
    end
end)

UIS.InputEnded:Connect(function(input)
    if Library.Unloaded or not dragging then return end

    local valid =
        (dragInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseButton1)
        or
        (dragInputType == Enum.UserInputType.Touch and input.UserInputType == Enum.UserInputType.Touch)

    if not valid then return end

    dragging = false

    if Library.Settings.DragMode == "Smooth" and dragInputType ~= Enum.UserInputType.Touch then
        dragSettling = true
    else
        Main.Position = dragTarget
        Library.WindowPosition = Main.Position
    end

    dragInputType = nil
end)

--============================================================
-- MENU OPEN / CLOSE
--============================================================

function Library:CancelMenuTweens()
    for _, tween in ipairs(self.MenuTweens) do
        pcall(function()
            tween:Cancel()
        end)
    end

    table.clear(self.MenuTweens)
end

function Library:CreateMenuTween(object, duration, properties, direction)
    local tween = TweenService:Create(
        object,
        TweenInfo.new(
            duration,
            Enum.EasingStyle.Quint,
            direction or Enum.EasingDirection.Out
        ),
        properties
    )

    table.insert(self.MenuTweens, tween)
    tween:Play()
    return tween
end

function Library:SetMenuVisible(visible, instant)
    if self.Unloaded then return end

    visible = visible == true

    self.MenuAnimationToken += 1
    local animationToken = self.MenuAnimationToken

    local wasActuallyVisible = Main.Visible
    local wasClosing = (not self.MenuVisible) and wasActuallyVisible

    self:CancelMenuTweens()
    self.MenuVisible = visible
    self.MenuAnimating = not instant
    self:HideControlTooltip(true)

    SearchResultsFrame.Visible = false
    FavoritesPanel.Visible = false
    ContextMenu.Visible = false

    local duration = math.max(0.26, tonumber(self.Settings.AnimationSpeed) or 0.18)
    local basePos = self.WindowPosition or UDim2.fromScale(0.5, 0.5)
    local baseScale = self.CurrentDPIScale or DPI_BASE_SCALE

    local blurTarget = self.Settings.BlurEnabled and self.Settings.BlurSize or 0
    local dimTarget = self.Settings.DimEnabled and self.Settings.DimTransparency or 1

    -- The actual shell is ALWAYS opaque. No tween is ever allowed to touch
    -- Main.BackgroundTransparency.
    Main.BackgroundTransparency = 0

    local function finishOpen()
        if self.MenuAnimationToken ~= animationToken or not self.MenuVisible or not Main.Parent then
            return
        end

        self.MenuAnimating = false
        Main.Visible = true
        Main.Position = basePos
        MainScale.Scale = baseScale
        MainVisual.GroupTransparency = 0
        Main.BackgroundTransparency = 0
        Blur.Size = blurTarget
        Dim.BackgroundTransparency = dimTarget
    end

    local function finishClose()
        if self.MenuAnimationToken ~= animationToken or self.MenuVisible or not Main.Parent then
            return
        end

        self.MenuAnimating = false
        Main.Visible = false

        -- Reset hidden state only AFTER the real closing tween completes.
        -- There is no extra delayed "dead frame" anymore.
        Main.Position = basePos
        MainScale.Scale = baseScale
        MainVisual.GroupTransparency = 0
        Main.BackgroundTransparency = 0
        Blur.Size = 0
        Dim.BackgroundTransparency = 1
    end

    if visible then
        Main.Visible = true
        Main.Size = UDim2.fromOffset(780, 500)
        Main.BackgroundTransparency = 0

        if instant or self.Settings.OpenAnimation == "None" then
            self:CancelMenuTweens()
            finishOpen()
            return
        end

        -- If the user reopens while a close tween is still moving, continue
        -- directly from the current visual state. Do NOT jump back to the
        -- animation's hidden starting pose.
        if not wasActuallyVisible then
            if self.Settings.OpenAnimation == "Scale" then
                Main.Position = basePos
                MainScale.Scale = baseScale * 0.12
                MainVisual.GroupTransparency = 0.06

            elseif self.Settings.OpenAnimation == "Slide" then
                Main.Position = UDim2.new(
                    basePos.X.Scale,
                    basePos.X.Offset,
                    basePos.Y.Scale,
                    basePos.Y.Offset + 4000
                )
                MainScale.Scale = baseScale * 0.82
                MainVisual.GroupTransparency = 0.08

            elseif self.Settings.OpenAnimation == "Fade" then
                Main.Position = UDim2.new(
                    basePos.X.Scale,
                    basePos.X.Offset,
                    basePos.Y.Scale,
                    basePos.Y.Offset + 220
                )
                MainScale.Scale = baseScale * 0.82
                MainVisual.GroupTransparency = 1
            end
        elseif wasClosing then
