        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 182,
    })
    self:RegisterFont(titleLabel, true)

    local bodyLabel = Create("TextLabel", {
        Parent = frame,
        Position = UDim2.fromOffset(18, mobileNotification and 22 or 31),
        Size = UDim2.new(1, -38, 0, mobileNotification and 18 or 28),
        BackgroundTransparency = 1,
        Text = body,
        TextColor3 = self.Theme.SubText,
        TextSize = mobileNotification and 9 or 11,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        ZIndex = 182,
    })
    self:RegisterFont(bodyLabel)

    local progress = Create("Frame", {
        Parent = frame,
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 12, 1, -6),
        Size = UDim2.new(1, -24, 0, 2),
        BackgroundColor3 = self.Theme.Accent,
        BorderSizePixel = 0,
        ZIndex = 182,
    })
    Create("UICorner", {Parent = progress, CornerRadius = UDim.new(1, 0)})

    local item = {
        Frame = frame,
        Kind = kind,
        Closed = false,
    }

    function item:Close(immediate)
        if self.Closed then return end
        self.Closed = true

        local idx = table.find(Library.NotificationItems, self)
        if idx then
            table.remove(Library.NotificationItems, idx)
        end

        if immediate then
            if frame.Parent then frame:Destroy() end
            Library:ReflowNotifications()
            return
        end

        Library:Animate(frame, 0.24, {
            GroupTransparency = 1,
            Position = UDim2.new(
                frame.Position.X.Scale,
                frame.Position.X.Offset + (cfg.AX == 1 and 70 or cfg.AX == 0 and -70 or 0),
                frame.Position.Y.Scale,
                frame.Position.Y.Offset
            ),
        })

        task.delay(0.25, function()
            if frame.Parent then frame:Destroy() end
            Library:ReflowNotifications()
        end)
    end

    table.insert(self.NotificationItems, item)
    self:ReflowNotifications()

    self:Animate(frame, 0.36, {GroupTransparency = 0})

    TweenService:Create(
        progress,
        TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
        {Size = UDim2.new(0, 0, 0, 2)}
    ):Play()

    task.delay(duration, function()
        item:Close(false)
    end)

    return item
end

--============================================================
-- KEYBIND LIST / GLOBAL KEYBIND EXECUTION
--============================================================

local KeybindList = Create("Frame", {
    Parent = Root,
    Position = UDim2.fromOffset(16, 120),
    Size = UDim2.fromOffset(220, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundColor3 = Library.Theme.Panel,
    BackgroundTransparency = 0.05,
    BorderSizePixel = 0,
    Visible = false,
    Active = true,
    ZIndex = 90,
})
Library:AdaptiveCorner(KeybindList, -2)
Create("UIStroke", {
    Parent = KeybindList,
    Thickness = 1.0,
    Transparency = 0.16,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    Color = Library.Theme.Outline,
})

local KeybindListInner = Create("Frame", {
    Parent = KeybindList,
    Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
    ZIndex = 91,
})
Create("UIPadding", {
    Parent = KeybindListInner,
    PaddingTop = UDim.new(0, 7),
    PaddingBottom = UDim.new(0, 7),
    PaddingLeft = UDim.new(0, 8),
    PaddingRight = UDim.new(0, 8),
})
Create("UIListLayout", {
    Parent = KeybindListInner,
    Padding = UDim.new(0, 3),
    SortOrder = Enum.SortOrder.LayoutOrder,
})

function Library:ApplyCornerWidgetPosition(widget, position, defaultPosition)
    if not widget then return end
    position = tostring(position or defaultPosition)

    local map = {
        ["Top Left"] = {Vector2.new(0,0), UDim2.fromOffset(16, 90)},
        ["Top Right"] = {Vector2.new(1,0), UDim2.new(1,-16,0,90)},
        ["Bottom Left"] = {Vector2.new(0,1), UDim2.new(0,16,1,-16)},
        ["Bottom Right"] = {Vector2.new(1,1), UDim2.new(1,-16,1,-16)},
    }

    local data = map[position] or map[defaultPosition] or map["Top Left"]
    widget.AnchorPoint = data[1]
    widget.Position = data[2]
end

function Library:RefreshKeybindList()
    for _, child in ipairs(KeybindListInner:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end

    local shown = 0

    for _, entry in ipairs(self.KeybindRegistry) do
        if entry.Enabled and entry.Key ~= "Unknown" then
            local label = Create("TextLabel", {
                Parent = KeybindListInner,
                Size = UDim2.new(1, 0, 0, 20),
                BackgroundTransparency = 1,
                Text = string.format("%s   [%s]  %s", entry.Name, entry.Key, entry.Mode),
                TextColor3 = entry.Active and self.Theme.Accent or self.Theme.Text,
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Left,
                ZIndex = 92,
            })
            self:RegisterFont(label, entry.Active)
            shown += 1
        end
    end

    KeybindList.Visible = self.Settings.KeybindListEnabled == true and shown > 0

    local custom = self.Settings.KeybindListCustomPosition

    if type(custom) == "table"
        and tonumber(custom.XScale) ~= nil
        and tonumber(custom.XOffset) ~= nil
        and tonumber(custom.YScale) ~= nil
        and tonumber(custom.YOffset) ~= nil
    then
        KeybindList.AnchorPoint = Vector2.new(
            tonumber(custom.AnchorX) or 0,
            tonumber(custom.AnchorY) or 0
        )

        KeybindList.Position = UDim2.new(
            tonumber(custom.XScale),
            tonumber(custom.XOffset),
            tonumber(custom.YScale),
            tonumber(custom.YOffset)
        )

    elseif type(custom) == "table" and tonumber(custom.X) and tonumber(custom.Y) then
        -- Compatibility with v14 saved positions.
        KeybindList.AnchorPoint = Vector2.new(0, 0)
        KeybindList.Position = UDim2.fromOffset(
            tonumber(custom.X),
            tonumber(custom.Y)
        )
    else
        self:ApplyCornerWidgetPosition(KeybindList, self.Settings.KeybindListPosition, "Bottom Left")
    end
end

local keybindDragging = false
local keybindDragStartPointer = nil
local keybindDragStartPosition = nil
local keybindDragStartAnchor = nil
local keybindDragInputType = nil

local function getPointerPosition(input)
    if input and input.UserInputType == Enum.UserInputType.Touch then
        return Vector2.new(input.Position.X, input.Position.Y)
    end

    -- For mouse dragging InputObject.Position and its movement events use the
    -- same coordinate system, avoiding CoreGui/topbar inset jumps.
    if input and (
        input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.MouseMovement
    ) then
        return Vector2.new(input.Position.X, input.Position.Y)
    end

    return UIS:GetMouseLocation()
end

KeybindList.InputBegan:Connect(function(input)
    if Library.Unloaded or not KeybindList.Visible then
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
    then
        keybindDragging = true
        keybindDragInputType = input.UserInputType
        keybindDragStartPointer = getPointerPosition(input)

        -- IMPORTANT:
        -- Do not read AbsolutePosition and convert it back into Position.
        -- That was the source of the ~100px jump on some executors.
        keybindDragStartPosition = KeybindList.Position
        keybindDragStartAnchor = KeybindList.AnchorPoint
    end
end)

UIS.InputChanged:Connect(function(input)
    if Library.Unloaded or not keybindDragging then
        return
    end

    local validMovement =
        (keybindDragInputType == Enum.UserInputType.MouseButton1
            and input.UserInputType == Enum.UserInputType.MouseMovement)
        or
        (keybindDragInputType == Enum.UserInputType.Touch
            and input.UserInputType == Enum.UserInputType.Touch)

    if not validMovement then
        return
    end

    local pointerNow = getPointerPosition(input)
    local delta = pointerNow - keybindDragStartPointer

    local start = keybindDragStartPosition
    local anchor = keybindDragStartAnchor or Vector2.new(0, 0)

    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
    local size = KeybindList.AbsoluteSize

    -- Convert the stored UDim2 into the position of the object's anchor point,
    -- move that anchor by the mouse delta, then clamp the resulting TOP-LEFT
    -- without ever touching AbsolutePosition.
    local desiredAnchorX =
        viewport.X * start.X.Scale
        + start.X.Offset
        + delta.X

    local desiredAnchorY =
        viewport.Y * start.Y.Scale
        + start.Y.Offset
        + delta.Y

    local desiredTopLeftX = desiredAnchorX - size.X * anchor.X
    local desiredTopLeftY = desiredAnchorY - size.Y * anchor.Y

    local clampedTopLeftX = math.clamp(
        desiredTopLeftX,
        4,
        math.max(4, viewport.X - size.X - 4)
    )

    local clampedTopLeftY = math.clamp(
        desiredTopLeftY,
        4,
        math.max(4, viewport.Y - size.Y - 4)
    )

    local clampedAnchorX = clampedTopLeftX + size.X * anchor.X
    local clampedAnchorY = clampedTopLeftY + size.Y * anchor.Y

    local xOffset = clampedAnchorX - viewport.X * start.X.Scale
    local yOffset = clampedAnchorY - viewport.Y * start.Y.Scale

    KeybindList.Position = UDim2.new(
        start.X.Scale,
        xOffset,
        start.Y.Scale,
        yOffset
    )
end)

UIS.InputEnded:Connect(function(input)
    if not keybindDragging then
        return
    end

    local ended =
        (keybindDragInputType == Enum.UserInputType.MouseButton1
            and input.UserInputType == Enum.UserInputType.MouseButton1)
        or
        (keybindDragInputType == Enum.UserInputType.Touch
            and input.UserInputType == Enum.UserInputType.Touch)

    if not ended then
        return
    end

    keybindDragging = false
    keybindDragInputType = nil

    local pos = KeybindList.Position
    local anchor = KeybindList.AnchorPoint

    Library.Settings.KeybindListCustomPosition = {
        XScale = pos.X.Scale,
        XOffset = pos.X.Offset,
        YScale = pos.Y.Scale,
        YOffset = pos.Y.Offset,
        AnchorX = anchor.X,
        AnchorY = anchor.Y,
    }
end)

UIS.InputBegan:Connect(function(input, processed)
    if Library.Unloaded or processed or input.UserInputType ~= Enum.UserInputType.Keyboard then
        return
    end

    if Library.BindingKey then
        return
    end

    for _, entry in ipairs(Library.KeybindRegistry) do
        if entry.Enabled and Enum.KeyCode[entry.Key] == input.KeyCode then
            if entry.Mode == "Hold" then
                entry.Active = true
                safeCallback(entry.Callback, true, entry)
            elseif entry.Mode == "Toggle" then
                entry.Active = not entry.Active
                safeCallback(entry.Callback, entry.Active, entry)
            elseif entry.Mode == "Always" then
                entry.Active = true
                safeCallback(entry.Callback, true, entry)
            else
