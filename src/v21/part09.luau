    if settings.WatermarkEnabled ~= nil then self.Settings.WatermarkEnabled = settings.WatermarkEnabled == true end
    if settings.WatermarkText ~= nil then self.Settings.WatermarkText = tostring(settings.WatermarkText) end
    if settings.WatermarkShowGraphics ~= nil then self.Settings.WatermarkShowGraphics = settings.WatermarkShowGraphics == true end
    if settings.WatermarkShowFPS ~= nil then self.Settings.WatermarkShowFPS = settings.WatermarkShowFPS == true end
    if settings.WatermarkShowPing ~= nil then self.Settings.WatermarkShowPing = settings.WatermarkShowPing == true end
    if settings.WatermarkShowTime ~= nil then self.Settings.WatermarkShowTime = settings.WatermarkShowTime == true end
    if settings.WatermarkDraggable ~= nil then self.Settings.WatermarkDraggable = settings.WatermarkDraggable == true end
    if settings.WatermarkX ~= nil then self.Settings.WatermarkX = tonumber(settings.WatermarkX) or -1 end
    if settings.WatermarkY ~= nil then self.Settings.WatermarkY = tonumber(settings.WatermarkY) or 16 end

    for flag, encoded in pairs(data.flags or {}) do
        local control = self.ControlsByFlag and self.ControlsByFlag[flag]
        if control and control.Set then
            control:Set(decodeValue(encoded), true)
        else
            self.Flags[flag] = decodeValue(encoded)
        end
    end

    self:RefreshBackdrop()
    if self.RefreshWatermark then self:RefreshWatermark() end
    return true
end

function Library:ListConfigs()
    local results = {}

    if not FS_AVAILABLE then
        return results
    end

    ensureFolders()

    if listfilesFn then
        local ok, files = pcall(function()
            return listfilesFn(CONFIG_SUBFOLDER)
        end)

        if ok and type(files) == "table" then
            for _, path in ipairs(files) do
                local normalized = tostring(path):gsub("\\", "/")
                local name = normalized:match("([^/]+)%.json$")
                if name and name ~= "" then
                    table.insert(results, name)
                end
            end
        end
    end

    table.sort(results, function(a, b)
        return a:lower() < b:lower()
    end)

    return results
end

function Library:DeleteConfig(name)
    name = sanitizeName(name or self.CurrentConfigName)

    if not FS_AVAILABLE or not delfileFn then
        return false
    end

    local path = CONFIG_SUBFOLDER .. "/" .. name .. ".json"
    if not isfileFn(path) then
        return false
    end

    local ok = pcall(function()
        delfileFn(path)
    end)

    return ok
end

function Library:SaveConfig(name)
    name = sanitizeName(name or self.CurrentConfigName)
    self.CurrentConfigName = name

    if not FS_AVAILABLE then
        warn("[Experiment17 UI] writefile/readfile are unavailable; config kept only in memory.")
        return false
    end

    ensureFolders()
    local path = CONFIG_SUBFOLDER .. "/" .. name .. ".json"

    local ok, encoded = pcall(function()
        return HttpService:JSONEncode(self:ExportConfig())
    end)

    if not ok then
        warn("[Experiment17 UI] JSON encode failed:", encoded)
        return false
    end

    local success, err = pcall(function()
        writefileFn(path, encoded)
    end)

    if not success then
        warn("[Experiment17 UI] Save failed:", err)
        return false
    end

    return true
end

function Library:LoadConfig(name)
    name = sanitizeName(name or self.CurrentConfigName)
    self.CurrentConfigName = name

    if not FS_AVAILABLE then
        return false
    end

    local path = CONFIG_SUBFOLDER .. "/" .. name .. ".json"
    if not isfileFn(path) then
        return false
    end

    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfileFn(path))
    end)

    if not ok then
        warn("[Experiment17 UI] Load failed:", data)
        return false
    end

    return self:ImportConfig(data)
end

function Library:SetAutoload(name, enabled)
    self.Settings.AutoloadConfig = enabled == true
    name = sanitizeName(name or self.CurrentConfigName)

    if not FS_AVAILABLE then
        return
    end

    ensureFolders()

    pcall(function()
        if enabled then
            writefileFn(AUTOLOAD_FILE, name)
        else
            writefileFn(AUTOLOAD_FILE, "")
        end
    end)
end

function Library:TryAutoload()
    if not FS_AVAILABLE or not isfileFn(AUTOLOAD_FILE) then
        return false
    end

    local ok, name = pcall(function()
        return readfileFn(AUTOLOAD_FILE)
    end)

    if not ok or not name or name == "" then
        return false
    end

    self.CurrentConfigName = sanitizeName(name)
    return self:LoadConfig(self.CurrentConfigName)
end

-- Optional cross-place restart hook.
-- Save this complete script as Experiment17/visuals.lua if your environment
-- supports readfile + loadstring + queue_on_teleport.
function Library:EnableTeleportAutoload()
    if not queueTeleportFn then
        return false
    end

    local code = self.TeleportLoader

    if not code and readfileFn and isfileFn and isfileFn(DEFAULT_TELEPORT_SCRIPT) then
        code = [[
            task.wait(1)
            if readfile and loadstring and isfile and isfile("Experiment17/visuals.lua") then
                loadstring(readfile("Experiment17/visuals.lua"))()
            end
        ]]
    end

    if not code then
        return false
    end

    local ok = pcall(function()
        queueTeleportFn(code)
    end)

    return ok
end

--============================================================
-- GUI ROOT / BACKDROP / BLUR
--============================================================

local old = PlayerGui:FindFirstChild("Experiment17_VisualUI")
if old then
    old:Destroy()
end

local oldBlur = Lighting:FindFirstChild("Experiment17_MenuBlur")
if oldBlur then
    oldBlur:Destroy()
end

Library:RegisterDefaultProfiles()

local Root = Create("ScreenGui", {
    Name = "Experiment17_VisualUI",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 999999,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})

local guiParent = PlayerGui
pcall(function()
    if gethui then
        guiParent = gethui()
    end
end)

Root.Parent = guiParent
Library.Root = Root

--============================================================
-- FUNCTION TOOLTIP / PERFORMANCE HINTS
--============================================================

local function formatImpact(value, unit)
    if value == nil then
        return Library:L("NotSpecified")
    end

    if type(value) == "number" then
        local prefix = value > 0 and "+" or ""
        return prefix .. tostring(value) .. " " .. unit
    end

    if type(value) == "table" then
        local minValue = value.Min or value.min or value[1]
        local maxValue = value.Max or value.max or value[2]
        if tonumber(minValue) and tonumber(maxValue) then
            local function signed(n)
                n = tonumber(n) or 0
                return (n > 0 and "+" or "") .. tostring(n)
            end
            return signed(minValue) .. " .. " .. signed(maxValue) .. " " .. unit
        end
    end

    return tostring(value)
end

local Tooltip = Create("CanvasGroup", {
    Name = "FunctionTooltip",
    Parent = Root,
    Position = UDim2.fromOffset(0, 0),
    Size = UDim2.fromOffset(330, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 0,
    BorderSizePixel = 0,
    GroupTransparency = 1,
    Visible = false,
    ZIndex = 500,
})
Library:BindTheme(Tooltip, "BackgroundColor3", "Control")
Library:AdaptiveCorner(Tooltip, 0)

local TooltipStroke = Create("UIStroke", {
    Parent = Tooltip,
    Thickness = 1.35,
    Transparency = 0.08,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
})
Library:BindTheme(TooltipStroke, "Color", "Outline")

local TooltipAccent = Create("Frame", {
    Parent = Tooltip,
    Size = UDim2.new(1, 0, 0, 2),
    BackgroundTransparency = 0,
    BorderSizePixel = 0,
    ZIndex = 501,
})
Library:BindTheme(TooltipAccent, "BackgroundColor3", "Accent")

Create("UIPadding", {
    Parent = Tooltip,
    PaddingLeft = UDim.new(0, 12),
    PaddingRight = UDim.new(0, 12),
    PaddingTop = UDim.new(0, 10),
    PaddingBottom = UDim.new(0, 10),
})

Create("UIListLayout", {
    Parent = Tooltip,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 5),
})

local TooltipTitle = Create("TextLabel", {
    Parent = Tooltip,
    Size = UDim2.new(1, 0, 0, 20),
    BackgroundTransparency = 1,
    Text = "",
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center,
    LayoutOrder = 1,
    ZIndex = 502,
})
Library:BindTheme(TooltipTitle, "TextColor3", "Text")
Library:RegisterFont(TooltipTitle, true)

local TooltipDescription = Create("TextLabel", {
    Parent = Tooltip,
    Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
    Text = "",
    TextWrapped = true,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    LayoutOrder = 2,
    ZIndex = 502,
})
Library:BindTheme(TooltipDescription, "TextColor3", "SubText")
Library:RegisterFont(TooltipDescription)

local TooltipDivider = Create("Frame", {
    Parent = Tooltip,
    Size = UDim2.new(1, 0, 0, 1),
    BackgroundTransparency = 0.36,
    BorderSizePixel = 0,
    LayoutOrder = 3,
    ZIndex = 502,
})
Library:BindTheme(TooltipDivider, "BackgroundColor3", "Outline")

local TooltipGraphics = Create("TextLabel", {
    Parent = Tooltip,
    Size = UDim2.new(1, 0, 0, 16),
    BackgroundTransparency = 1,
    Text = "",
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    LayoutOrder = 4,
    ZIndex = 502,
})
Library:BindTheme(TooltipGraphics, "TextColor3", "Accent")
Library:RegisterFont(TooltipGraphics, true)

local TooltipPerformance = Create("TextLabel", {
    Parent = Tooltip,
    Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
    Text = "",
    TextWrapped = true,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    LayoutOrder = 5,
    ZIndex = 502,
})
Library:BindTheme(TooltipPerformance, "TextColor3", "Text")
Library:RegisterFont(TooltipPerformance)

Library.Tooltip = Tooltip
Library.TooltipHoverToken = 0
Library.TooltipCurrentPosition = Vector2.new(0, 0)
Library.TooltipFollowing = false

function Library:HideControlTooltip(immediate)
    self.TooltipHoverToken += 1
    self.TooltipFollowing = false

    if not Tooltip.Visible then
        return
    end

    if immediate then
        Tooltip.Visible = false
        Tooltip.GroupTransparency = 1
        return
    end

    self:Animate(Tooltip, 0.08, {GroupTransparency = 1})
    local token = self.TooltipHoverToken
    task.delay(0.085, function()
        if self.TooltipHoverToken == token and Tooltip.Parent then
            Tooltip.Visible = false
        end
    end)
end

function Library:ShowControlTooltip(control)
    if self.Unloaded or not self.Settings.TooltipsEnabled or not control or control.TooltipEnabled == false then
        return
    end

    -- Never drag the previous tooltip to the next row. Remove it immediately,
    -- then start a fresh delay for the new row.
    self.TooltipHoverToken += 1
    local token = self.TooltipHoverToken
    self.TooltipFollowing = false
    Tooltip.Visible = false
    Tooltip.GroupTransparency = 1
