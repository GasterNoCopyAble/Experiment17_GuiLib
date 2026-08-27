-- Experiment 17 v22 - exclusive drag ownership + low-latency touch motion
-- Prevents Main / Watermark / mobile toggle from dragging together when they overlap.

return function(Library)
    local UIS = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    local TweenService = game:GetService("TweenService")

    local Root = Library.Root
    local Main = Library.Main
    local MainVisual = Library.MainVisual
    local Watermark = Library.Watermark
    if not Root or not Main then return end

    local connections = {}
    local activeInput = nil
    local owner = nil
    local startPointer = nil
    local startMain = nil
    local startWatermark = nil
    local startMobile = nil

    local function isPhoneLayout()
        if not UIS.TouchEnabled then return false end
        local camera = workspace.CurrentCamera
        local viewport = camera and camera.ViewportSize or Vector2.new(1920,1080)
        return (not UIS.KeyboardEnabled) or math.min(viewport.X, viewport.Y) < 700
    end

    local function findTopbar()
        if not MainVisual then return nil end
        for _, child in ipairs(MainVisual:GetChildren()) do
            if child:IsA("Frame")
                and child.Active == true
                and child.Size.Y.Scale == 0
                and math.abs(child.Size.Y.Offset - 52) <= 2
            then
                return child
            end
        end
        return nil
    end

    local function findMobileButton()
        for _, child in ipairs(Root:GetChildren()) do
            if child:IsA("TextButton")
                and not child:IsDescendantOf(Main)
                and child.ZIndex >= 700
            then
                return child
            end
        end
        return nil
    end

    local function contains(gui, point)
        if not gui or not gui.Parent or not gui.Visible then return false end
        local p = gui.AbsolutePosition
        local s = gui.AbsoluteSize
        return point.X >= p.X and point.X <= p.X + s.X
            and point.Y >= p.Y and point.Y <= p.Y + s.Y
    end

    local function chooseOwner(point)
        local mobile = findMobileButton()
        if mobile and contains(mobile, point) and Library.Settings.MobileButtonDraggable ~= false then
            return "mobile", mobile
        end

        if Watermark and contains(Watermark, point) and Library.Settings.WatermarkDraggable == true then
            return "watermark", mobile
        end

        local topbar = findTopbar()
        if topbar and contains(topbar, point) then
            return "main", mobile
        end

        return nil, mobile
    end

    local function clampTopLeft(x, y, size)
        local camera = workspace.CurrentCamera
        local viewport = camera and camera.ViewportSize or Vector2.new(1920,1080)
        return math.clamp(x, 4, math.max(4, viewport.X - size.X - 4)),
            math.clamp(y, 4, math.max(4, viewport.Y - size.Y - 4))
    end

    local function restoreNonOwner(mobile)
        if owner ~= "main" and startMain then
            Main.Position = startMain
        end
        if Watermark and owner ~= "watermark" and startWatermark then
            Watermark.Position = startWatermark
        end
        if mobile and owner ~= "mobile" and startMobile then
            mobile.Position = startMobile
        end
    end

    connections[#connections+1] = UIS.InputBegan:Connect(function(input, processed)
        if Library.Unloaded or processed then return end
        if input.UserInputType ~= Enum.UserInputType.Touch
            and input.UserInputType ~= Enum.UserInputType.MouseButton1
        then
            return
        end

        local point = Vector2.new(input.Position.X, input.Position.Y)
        local selected, mobile = chooseOwner(point)
        if not selected then return end

        owner = selected
        activeInput = input
        startPointer = point
        startMain = Main.Position
        startWatermark = Watermark and Watermark.Position or nil
        startMobile = mobile and mobile.Position or nil
    end)

    connections[#connections+1] = UIS.InputEnded:Connect(function(input)
        if input ~= activeInput then return end

        if owner == "main" then
            Library.WindowPosition = Main.Position
        elseif owner == "watermark" and Watermark then
            Library.Settings.WatermarkX = Watermark.Position.X.Offset
            Library.Settings.WatermarkY = Watermark.Position.Y.Offset
        elseif owner == "mobile" then
            local mobile = findMobileButton()
            if mobile then
                Library.Settings.MobileButtonPosition = {
                    X = mobile.AbsolutePosition.X,
                    Y = mobile.AbsolutePosition.Y,
                }
            end
        end

        activeInput = nil
        owner = nil
        startPointer = nil
    end)

    connections[#connections+1] = RunService.RenderStepped:Connect(function()
        if Library.Unloaded or not activeInput or not owner or not startPointer then return end

        local mobile = findMobileButton()
        local point = Vector2.new(activeInput.Position.X, activeInput.Position.Y)
        local delta = point - startPointer

        -- Touch is applied directly from the latest InputObject.Position every
        -- rendered frame. This removes the old follow-behind feeling on phones.
        if activeInput.UserInputType == Enum.UserInputType.Touch then
            if owner == "main" and startMain then
                Main.Position = UDim2.new(
                    startMain.X.Scale, startMain.X.Offset + delta.X,
                    startMain.Y.Scale, startMain.Y.Offset + delta.Y
                )
            elseif owner == "watermark" and Watermark and startWatermark then
                local x, y = clampTopLeft(
                    startWatermark.X.Offset + delta.X,
                    startWatermark.Y.Offset + delta.Y,
                    Watermark.AbsoluteSize
                )
                Watermark.Position = UDim2.fromOffset(x, y)
                Library.Settings.WatermarkX = x
                Library.Settings.WatermarkY = y
            elseif owner == "mobile" and mobile and startMobile then
                local camera = workspace.CurrentCamera
                local viewport = camera and camera.ViewportSize or Vector2.new(1920,1080)
                local anchor = mobile.AnchorPoint
                local anchorX = viewport.X * startMobile.X.Scale + startMobile.X.Offset + delta.X
                local anchorY = viewport.Y * startMobile.Y.Scale + startMobile.Y.Offset + delta.Y
                local topX = anchorX - mobile.AbsoluteSize.X * anchor.X
                local topY = anchorY - mobile.AbsoluteSize.Y * anchor.Y
                local x, y = clampTopLeft(topX, topY, mobile.AbsoluteSize)
                mobile.AnchorPoint = Vector2.zero
                mobile.Position = UDim2.fromOffset(x, y)
                Library.Settings.MobileButtonPosition = {X=x, Y=y}
            end
        end

        -- Core v22 still has its original local drag handlers. When overlapping
        -- elements receive the same press, keep every non-owner at its start.
        restoreNonOwner(mobile)
    end)

    -- Phone open path: skip the expensive multi-tween/blur startup and use a
    -- tiny scale/fade polish after the final state is installed.
    local rawSetMenuVisible = Library.SetMenuVisible
    if type(rawSetMenuVisible) == "function" then
        function Library:SetMenuVisible(visible, instant)
            if not isPhoneLayout() or instant then
                return rawSetMenuVisible(self, visible, instant)
            end

            local oldBlur = self.Settings.BlurEnabled
            self.Settings.BlurEnabled = false
            local result = rawSetMenuVisible(self, visible, true)
            self.Settings.BlurEnabled = oldBlur

            if visible and self.MainScale and self.MainVisual then
                local finalScale = self.CurrentDPIScale or self.MainScale.Scale
                self.MainScale.Scale = finalScale * 0.965
                self.MainVisual.GroupTransparency = 0.18

                TweenService:Create(
                    self.MainScale,
                    TweenInfo.new(0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {Scale = finalScale}
                ):Play()
                TweenService:Create(
                    self.MainVisual,
                    TweenInfo.new(0.11, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    {GroupTransparency = 0}
                ):Play()
            end

            return result
        end
    end

    return function()
        for _, connection in ipairs(connections) do
            pcall(function() connection:Disconnect() end)
        end
        if rawSetMenuVisible then
            Library.SetMenuVisible = rawSetMenuVisible
        end
    end
end
