                entry.Active = true
                safeCallback(entry.Callback, entry)
                task.delay(0.08, function()
                    entry.Active = false
                    Library:RefreshKeybindList()
                end)
            end

            Library:RefreshKeybindList()
        end
    end
end)

UIS.InputEnded:Connect(function(input)
    if Library.Unloaded or input.UserInputType ~= Enum.UserInputType.Keyboard then
        return
    end

    for _, entry in ipairs(Library.KeybindRegistry) do
        if entry.Enabled and entry.Mode == "Hold" and Enum.KeyCode[entry.Key] == input.KeyCode then
            entry.Active = false
            safeCallback(entry.Callback, false, entry)
            Library:RefreshKeybindList()
        end
    end
end)

--============================================================
-- WATERMARK
--============================================================

local Watermark = Create("Frame", {
    Parent = Root,
    Active = true,
    AnchorPoint = Vector2.new(0, 0),
    Position = UDim2.fromOffset(16, 16),
    Size = UDim2.fromOffset(250, 30),
    BackgroundTransparency = 0,
    BorderSizePixel = 0,
    Active = true,
    ZIndex = 70,
})
Library:BindTheme(Watermark, "BackgroundColor3", "Panel")
Library:AdaptiveCorner(Watermark, -2)

local WatermarkStroke = Create("UIStroke", {
    Parent = Watermark,
    Thickness = 1.1,
    Transparency = 0.10,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
})
Library:BindTheme(WatermarkStroke, "Color", "Outline")

local WatermarkAccent = Create("Frame", {
    Parent = Watermark,
    -- Inset from every rounded edge. The old full-height strip could visibly
    -- poke through large corner radii.
    Position = UDim2.fromOffset(4, 5),
    Size = UDim2.fromOffset(3, 20),
    BorderSizePixel = 0,
    ZIndex = 71,
})
Library:BindTheme(WatermarkAccent, "BackgroundColor3", "Accent")
Create("UICorner", {Parent = WatermarkAccent, CornerRadius = UDim.new(1, 0)})

local WatermarkLabel = Create("TextLabel", {
    Parent = Watermark,
    Position = UDim2.fromOffset(13, 0),
    Size = UDim2.new(1, -21, 1, 0),
    BackgroundTransparency = 1,
    Text = "Experiment 17 [Visuals]",
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 71,
})
Library:BindTheme(WatermarkLabel, "TextColor3", "Text")
Library:RegisterFont(WatermarkLabel, true)

Library.Watermark = Watermark
Library.WatermarkLabel = WatermarkLabel
Library.CurrentFPS = 0
Library.CurrentPing = 0

function Library:ApplyWatermarkPosition()
    if not self.Watermark or not self.Watermark.Parent then
        return
    end

    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
    local wmSize = self.Watermark.AbsoluteSize
    if wmSize.X <= 0 then
        wmSize = Vector2.new(self.Watermark.Size.X.Offset, self.Watermark.Size.Y.Offset)
    end

    local x = tonumber(self.Settings.WatermarkX) or -1
    local y = tonumber(self.Settings.WatermarkY) or 16

    if x < 0 then
        x = viewport.X - wmSize.X - 16
    end

    x = math.clamp(x, 4, math.max(4, viewport.X - wmSize.X - 4))
    y = math.clamp(y, 4, math.max(4, viewport.Y - wmSize.Y - 4))

    self.Watermark.Position = UDim2.fromOffset(x, y)
end

function Library:ResetWatermarkPosition()
    self.Settings.WatermarkX = -1
    self.Settings.WatermarkY = 16
    self:ApplyWatermarkPosition()
end

function Library:RefreshWatermark()
    if not self.Watermark or not self.Watermark.Parent then
        return
    end

    self.Watermark.Visible = self.Settings.WatermarkEnabled == true
    if not self.Watermark.Visible then
        return
    end

    local pieces = {tostring(self.Settings.WatermarkText or "Experiment 17 [Visuals]")}

    if self.Settings.WatermarkShowGraphics then
        table.insert(pieces, self.Settings.GraphicsLevel)
    end
    if self.Settings.WatermarkShowFPS then
        table.insert(pieces, tostring(self.CurrentFPS or 0) .. " FPS")
    end
    if self.Settings.WatermarkShowPing then
        table.insert(pieces, tostring(self.CurrentPing or 0) .. " ms")
    end
    if self.Settings.WatermarkShowTime then
        table.insert(pieces, os.date("%H:%M:%S"))
    end

    local text = table.concat(pieces, "  |  ")
    self.WatermarkLabel.Text = text

    local ok, measured = pcall(function()
        return TextService:GetTextSize(
            text,
            self.WatermarkLabel.TextSize,
            self.WatermarkLabel.Font,
            Vector2.new(1600, 40)
        )
    end)

    if ok and measured then
        self.Watermark.Size = UDim2.fromOffset(math.max(110, measured.X + 30), 30)
    end

    self:ApplyWatermarkPosition()
end

-- Dragging is optional and the position is saved in the config.
local watermarkDragging = false
local watermarkInputType = nil
local watermarkPointerStart = nil
local watermarkStartX = nil
local watermarkStartY = nil

Watermark.InputBegan:Connect(function(input)
    if Library.Unloaded or not Library.Settings.WatermarkDraggable then
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
    then
        watermarkDragging = true
        watermarkInputType = input.UserInputType
        watermarkPointerStart = Vector2.new(input.Position.X, input.Position.Y)
        watermarkStartX = Watermark.Position.X.Offset
        watermarkStartY = Watermark.Position.Y.Offset
    end
end)

UIS.InputChanged:Connect(function(input)
    if Library.Unloaded or not watermarkDragging then
        return
    end

    local valid =
        (watermarkInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement)
        or
        (watermarkInputType == Enum.UserInputType.Touch and input.UserInputType == Enum.UserInputType.Touch)

    if not valid then return end

    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
    local pointer = Vector2.new(input.Position.X, input.Position.Y)
    local delta = pointer - watermarkPointerStart
    local wmSize = Watermark.AbsoluteSize

    local x = math.clamp((watermarkStartX or 0) + delta.X, 4, math.max(4, viewport.X - wmSize.X - 4))
    local y = math.clamp((watermarkStartY or 0) + delta.Y, 4, math.max(4, viewport.Y - wmSize.Y - 4))

    Watermark.Position = UDim2.fromOffset(x, y)
    Library.Settings.WatermarkX = x
    Library.Settings.WatermarkY = y
end)

UIS.InputEnded:Connect(function(input)
    if not watermarkDragging then return end

    local valid =
        (watermarkInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseButton1)
        or
        (watermarkInputType == Enum.UserInputType.Touch and input.UserInputType == Enum.UserInputType.Touch)

    if valid then
        watermarkDragging = false
        watermarkInputType = nil
    end
end)

local fpsFrames = 0
local fpsStarted = os.clock()
RunService.RenderStepped:Connect(function()
    if Library.Unloaded then
        return
    end

    fpsFrames += 1
    local now = os.clock()
    local elapsed = now - fpsStarted

    if elapsed >= 0.5 then
        Library.CurrentFPS = math.floor((fpsFrames / elapsed) + 0.5)
        fpsFrames = 0
        fpsStarted = now

        local ok, ping = pcall(function()
            return LocalPlayer:GetNetworkPing()
        end)
        if ok and type(ping) == "number" then
            Library.CurrentPing = math.max(0, math.floor(ping * 1000 + 0.5))
        end

        Library:RefreshWatermark()
    end
end)

Library:RefreshWatermark()

--============================================================
-- DEFAULT TABS / SETTINGS
--============================================================

-- The library itself ships only with Settings.
-- Feature tabs are created by the script that consumes the library via
-- Library:CreateTab(...), keeping this file reusable instead of acting like
-- a prebuilt Visuals/ESP/World/Player menu.
local SettingsTab = Library:CreateTab(Library:L("Settings"), "Settings")
Library.SettingsTab = SettingsTab

-- All sections start collapsed. Pass true to CreateSection only when a
-- specific custom section should intentionally start opened.

-- SETTINGS: Interface
local InterfaceSection = SettingsTab:CreateSection(Library:L("Interface"), false, "Interface")

local LanguageChoice = InterfaceSection:AddChoice({
    Name = Library:L("Language"),
    LocaleKey = "Language",
    Flag = "UI_Language",
    Values = LANGUAGE_CHOICES,
    Default = Library:GetLanguageDisplay(Library.Settings.Language),
    RequiredGraphics = "Low",
    Callback = function(v)
        Library:SetLanguage(v)
    end,
})
Library.LanguageChoiceControl = LanguageChoice

InterfaceSection:AddSeparator()

InterfaceSection:AddChoice({
    Name = Library:L("GraphicsLevel"),
    LocaleKey = "GraphicsLevel",
    Flag = "UI_GraphicsLevel",
    Values = GRAPHICS_LIST,
    Default = Library.Settings.GraphicsLevel,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library:SetGraphicsLevel(v)
        Library.LevelText.Text = v
    end,
})

-- New logical group: typography.
InterfaceSection:AddSeparator()
InterfaceSection:AddChoice({
    Name = Library:L("Font"),
    LocaleKey = "Font",
    Flag = "UI_Font",
    Values = FONT_LIST,
    Default = Library.Settings.Font,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library:SetFont(v)
    end,
})
InterfaceSection:AddSlider({
    Name = Library:L("TextSize"),
    LocaleKey = "TextSize",
    Flag = "UI_TextScale",
    Min = 50,
    Max = 200,
    Default = Library.Settings.TextScale,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library:SetTextScale(v)
    end,
})

-- New logical group: global/function scaling.
InterfaceSection:AddSeparator()
InterfaceSection:AddChoice({
    Name = Library:L("DPIScale"),
    LocaleKey = "DPIScale",
    Flag = "UI_DPIScale",
    Values = DPI_LIST,
    Default = Library.Settings.DPIPreset,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library:SetDPIPreset(v)
    end,
})
InterfaceSection:AddToggle({
    Name = Library:L("AutoFitToDisplay"),
    LocaleKey = "AutoFitToDisplay",
    Flag = "UI_AutoFitDPI",
    Default = Library.Settings.AutoFitDPI,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library.Settings.AutoFitDPI = v == true
        Library:ApplyDPIScale()
    end,
})
InterfaceSection:AddChoice({
    Name = Library:L("FunctionDPI"),
    LocaleKey = "FunctionDPI",
    Flag = "UI_FunctionDPI",
    Values = FUNCTION_DPI_LIST,
    Default = Library.Settings.FunctionDPIPreset,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library:SetFunctionDPIPreset(v)
    end,
})

-- New logical group: navigation/window shape.
InterfaceSection:AddSeparator()
InterfaceSection:AddSlider({
    Name = Library:L("CornerRadius"),
    LocaleKey = "CornerRadius",
    Flag = "UI_CornerRadius",
    Min = 0,
    Max = 20,
    Default = Library.Settings.CornerRadius,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library:SetCornerRadius(v)
    end,
})

-- New logical group: backdrop effects. Blur + strength and dim + amount
-- belong together, so no lines inside this group.
InterfaceSection:AddSeparator()
InterfaceSection:AddToggle({
    Name = Library:L("BackgroundBlur"),
    LocaleKey = "BackgroundBlur",
    Flag = "UI_Blur",