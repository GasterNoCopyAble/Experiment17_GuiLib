-- Experiment 17 UI Library stable loader
-- Current implementation: v21
-- Repository: GasterNoCopyAble/Experiment17_GuiLib
--
-- v21 is stored as overlapping source windows. Some overlap copies are not
-- byte-identical, so this loader reconstructs them with tolerant line overlap.
-- After the library is created, this stable entry point also installs small
-- forward-compatible v21 extensions used by Experiment17 projects:
--   * gradients are rendered on UIStroke outlines, not panel backgrounds
--   * Section:AddTileButtons() for compact square/preset button grids

local BASE = "https://raw.githubusercontent.com/GasterNoCopyAble/Experiment17_GuiLib/main/src/v21/part"
local PARTS = {
    "01","02","03","04","05","06","07","08","09","10",
    "11","12","13","14","15","16","17","18","19","20",
    "21","22","23","24","25","26","27","28","29",
}

local sourceParts = {}
local finished = 0
local firstError = nil

for index, suffix in ipairs(PARTS) do
    task.spawn(function()
        local ok, result = pcall(function()
            return game:HttpGet(BASE .. suffix .. ".luau")
        end)

        if ok and type(result) == "string" and #result > 0 then
            sourceParts[index] = result
        elseif firstError == nil then
            firstError = ok and ("empty source part " .. tostring(suffix)) or result
        end

        finished = finished + 1
    end)
end

while finished < #PARTS do
    task.wait()
end

if firstError then
    error("[Experiment17] Failed to download library source: " .. tostring(firstError))
end

local function normalizeNewlines(text)
    return tostring(text or ""):gsub("\r\n", "\n"):gsub("\r", "\n")
end

local function splitLines(text)
    text = normalizeNewlines(text)
    local out = {}
    for line in (text .. "\n"):gmatch("(.-)\n") do
        out[#out + 1] = line
    end
    if out[#out] == "" then
        out[#out] = nil
    end
    return out
end

local function trim(line)
    return tostring(line or ""):match("^%s*(.-)%s*$") or ""
end

local function linesEquivalent(a, b)
    return trim(a) == trim(b)
end

local function findLineOverlap(left, right)
    local maxOverlap = math.min(#left, #right)
    if maxOverlap <= 0 then
        return 0, 0
    end

    local minOverlap = math.min(6, maxOverlap)

    for amount = maxOverlap, minOverlap, -1 do
        local mismatches = 0
        local compared = 0
        local allowed = math.max(1, math.floor(amount * 0.08 + 0.5))

        for offset = 1, amount do
            local a = left[#left - amount + offset]
            local b = right[offset]
            if not linesEquivalent(a, b) then
                mismatches = mismatches + 1
                if mismatches > allowed then
                    break
                end
            end
            compared = compared + 1
        end

        if compared == amount and mismatches <= allowed then
            local firstOK = linesEquivalent(left[#left - amount + 1], right[1])
                or (amount >= 2 and linesEquivalent(left[#left - amount + 2], right[2]))
            local lastOK = linesEquivalent(left[#left], right[amount])
                or (amount >= 2 and linesEquivalent(left[#left - 1], right[amount - 1]))

            if firstOK and lastOK then
                return amount, mismatches
            end
        end
    end

    return 0, 0
end

local function mergeParts(parts)
    local merged = splitLines(parts[1] or "")
    local removedLines = 0
    local fuzzyBoundaries = 0

    for index = 2, #parts do
        local nextLines = splitLines(parts[index] or "")
        local overlap, mismatches = findLineOverlap(merged, nextLines)

        if overlap > 0 then
            removedLines = removedLines + overlap
            if mismatches > 0 then
                fuzzyBoundaries = fuzzyBoundaries + 1
            end
            for lineIndex = overlap + 1, #nextLines do
                merged[#merged + 1] = nextLines[lineIndex]
            end
        else
            merged[#merged + 1] = ""
            for lineIndex = 1, #nextLines do
                merged[#merged + 1] = nextLines[lineIndex]
            end
            warn(string.format("[Experiment17] GuiLib v21: no overlap at part %02d", index))
        end
    end

    return table.concat(merged, "\n"), removedLines, fuzzyBoundaries
end

local source, removedLines, fuzzyBoundaries = mergeParts(sourceParts)
print(string.format(
    "[Experiment17] GuiLib v21 merged; removed %d overlap lines (%d fuzzy boundaries)",
    removedLines,
    fuzzyBoundaries
))

local compiler = loadstring or (getgenv and getgenv().loadstring)
if type(compiler) ~= "function" then
    error("[Experiment17] loadstring is unavailable in this environment")
end

local chunk, compileError = compiler(source)
if not chunk then
    local errorText = tostring(compileError)
    local lineNumber = tonumber(errorText:match(":(%d+):"))

    if lineNumber then
        local lines = splitLines(source)
        local fromLine = math.max(1, lineNumber - 4)
        local toLine = math.min(#lines, lineNumber + 4)
        local context = {}

        for i = fromLine, toLine do
            context[#context + 1] = string.format("%s%05d | %s", i == lineNumber and ">> " or "   ", i, lines[i])
        end

        error(
            "[Experiment17] Failed to compile library: " .. errorText
            .. "\n[Experiment17] Source context:\n"
            .. table.concat(context, "\n")
        )
    end

    error("[Experiment17] Failed to compile library: " .. errorText)
end

local Library = chunk()

--============================================================
-- STABLE V21 EXTENSIONS
--============================================================

local function installTileButtons()
    local decoratedTabs = setmetatable({}, {__mode = "k"})
    local decoratedSections = setmetatable({}, {__mode = "k"})

    local function styleTileControl(control, options)
        task.defer(function()
            if not control or not control.Holder or not control.Holder.Parent then return end

            local holder = control.Holder
            local buttons = {}
            for _, object in ipairs(holder:GetDescendants()) do
                if object:IsA("TextButton") and object.Visible then
                    buttons[#buttons + 1] = object
                end
            end
            if #buttons == 0 then return end

            local parent = buttons[1].Parent
            if not parent then return end
            for _, button in ipairs(buttons) do
                if button.Parent ~= parent then return end
            end

            local oldList = parent:FindFirstChildOfClass("UIListLayout")
            if oldList then oldList:Destroy() end
            local oldGrid = parent:FindFirstChild("E17_TileGrid")
            if oldGrid then oldGrid:Destroy() end

            local size = math.clamp(tonumber(options.TileSize) or 72, 48, 128)
            local gap = math.clamp(tonumber(options.Gap) or 6, 2, 20)
            local columns = math.clamp(math.floor(tonumber(options.Columns) or 4), 1, 8)

            local grid = Instance.new("UIGridLayout")
            grid.Name = "E17_TileGrid"
            grid.CellSize = UDim2.fromOffset(size, size)
            grid.CellPadding = UDim2.fromOffset(gap, gap)
            grid.FillDirection = Enum.FillDirection.Horizontal
            grid.FillDirectionMaxCells = columns
            grid.HorizontalAlignment = Enum.HorizontalAlignment.Left
            grid.SortOrder = Enum.SortOrder.LayoutOrder
            grid.Parent = parent

            for index, button in ipairs(buttons) do
                button.LayoutOrder = index
                button.Size = UDim2.fromOffset(size, size)
                button.TextWrapped = true
                button.TextScaled = false
                if button.TextSize > 13 then button.TextSize = 13 end
            end

            parent.AutomaticSize = Enum.AutomaticSize.Y
            parent.Size = UDim2.new(1, 0, 0, 0)
            holder.AutomaticSize = Enum.AutomaticSize.Y
        end)
    end

    local function decorateSection(section)
        if not section or decoratedSections[section] then return section end
        decoratedSections[section] = true

        if type(section.AddButtonGroup) == "function" and type(section.AddTileButtons) ~= "function" then
            local rawButtonGroup = section.AddButtonGroup
            function section:AddTileButtons(options)
                options = options or {}
                local buttons = options.Buttons or {}
                local normalized = {}
                for _, info in ipairs(buttons) do
                    normalized[#normalized + 1] = {
                        Text = tostring(info.Text or info.Name or "Button"),
                        Callback = info.Callback,
                    }
                end

                local control = rawButtonGroup(self, {
                    Name = options.Name or "",
                    Buttons = normalized,
                    RequiredGraphics = options.RequiredGraphics or "Low",
                    Description = options.Description,
                })
                styleTileControl(control, options)
                return control
            end
        end

        if type(section.AddTileButton) ~= "function" then
            function section:AddTileButton(options)
                options = options or {}
                return self:AddTileButtons({
                    Name = options.Name or "",
                    TileSize = options.TileSize,
                    Gap = options.Gap,
                    Columns = 1,
                    RequiredGraphics = options.RequiredGraphics,
                    Description = options.Description,
                    Buttons = {{
                        Text = options.ButtonText or options.Text or options.Name or "Button",
                        Callback = options.Callback,
                    }},
                })
            end
        end

        return section
    end

    local function decorateTab(tab)
        if not tab or decoratedTabs[tab] then return tab end
        decoratedTabs[tab] = true
        if type(tab.CreateSection) == "function" then
            local rawCreateSection = tab.CreateSection
            function tab:CreateSection(...)
                return decorateSection(rawCreateSection(self, ...))
            end
        end
        return tab
    end

    if type(Library.CreateTab) == "function" then
        local rawCreateTab = Library.CreateTab
        function Library:CreateTab(...)
            return decorateTab(rawCreateTab(self, ...))
        end
    end

    decorateTab(Library.SettingsTab)
    for _, tab in pairs(Library.Tabs or {}) do
        decorateTab(tab)
    end

    Library.DecorateSection = decorateSection
end

local function installStrokeGradients()
    local Root = Library.Root
    if not Root then return end

    local tracked = setmetatable({}, {__mode = "k"})
    local connections = Library.__E17StableConnections or {}
    Library.__E17StableConnections = connections

    local PRESETS = {
        ["Violet Dream"] = {Color3.fromRGB(124,58,237), Color3.fromRGB(192,132,252), Color3.fromRGB(76,29,149)},
        ["Purple Neon"] = {Color3.fromRGB(76,29,149), Color3.fromRGB(168,85,247), Color3.fromRGB(236,72,153)},
        ["Blue Neon"] = {Color3.fromRGB(30,64,175), Color3.fromRGB(59,130,246), Color3.fromRGB(34,211,238)},
        ["Ocean"] = {Color3.fromRGB(8,47,73), Color3.fromRGB(14,116,144), Color3.fromRGB(34,211,238)},
        ["Aqua"] = {Color3.fromRGB(6,78,59), Color3.fromRGB(20,184,166), Color3.fromRGB(103,232,249)},
        ["Emerald"] = {Color3.fromRGB(6,78,59), Color3.fromRGB(16,185,129), Color3.fromRGB(110,231,183)},
        ["Gold"] = {Color3.fromRGB(113,63,18), Color3.fromRGB(245,158,11), Color3.fromRGB(253,224,71)},
        ["Sunset"] = {Color3.fromRGB(159,18,57), Color3.fromRGB(249,115,22), Color3.fromRGB(253,186,116)},
        ["Fire"] = {Color3.fromRGB(127,29,29), Color3.fromRGB(239,68,68), Color3.fromRGB(249,115,22)},
        ["Crimson"] = {Color3.fromRGB(76,5,25), Color3.fromRGB(225,29,72), Color3.fromRGB(251,113,133)},
        ["Rose"] = {Color3.fromRGB(131,24,67), Color3.fromRGB(244,114,182), Color3.fromRGB(251,207,232)},
        ["Sakura"] = {Color3.fromRGB(136,19,55), Color3.fromRGB(251,113,133), Color3.fromRGB(254,205,211)},
        ["Candy"] = {Color3.fromRGB(126,34,206), Color3.fromRGB(236,72,153), Color3.fromRGB(34,211,238)},
        ["Ice"] = {Color3.fromRGB(30,58,138), Color3.fromRGB(125,211,252), Color3.fromRGB(224,242,254)},
        ["Arctic"] = {Color3.fromRGB(14,116,144), Color3.fromRGB(186,230,253), Color3.fromRGB(255,255,255)},
        ["Midnight"] = {Color3.fromRGB(15,23,42), Color3.fromRGB(67,56,202), Color3.fromRGB(30,41,59)},
        ["Cyber"] = {Color3.fromRGB(6,78,59), Color3.fromRGB(0,255,190), Color3.fromRGB(34,211,238)},
        ["Matrix"] = {Color3.fromRGB(3,46,21), Color3.fromRGB(34,197,94), Color3.fromRGB(134,239,172)},
        ["RGB"] = {Color3.fromRGB(255,0,0), Color3.fromRGB(0,255,0), Color3.fromRGB(0,85,255)},
    }

    local function gradientControls()
        local out = {}
        for _, control in pairs(Library.Controls or {}) do
            local flag = tostring(control.Flag or ""):lower()
            if flag:find("gradient", 1, true) and type(control.Get) == "function" then
                local ok, value = pcall(function() return control:Get() end)
                if ok then
                    if flag:find("preset",1,true) then out.Preset = value
                    elseif flag:find("speed",1,true) then out.Speed = value
                    elseif flag:find("rotation",1,true) then out.Rotation = value
                    elseif flag:find("intensity",1,true) then out.Intensity = value
                    elseif flag:find("colora",1,true) or flag:find("color_a",1,true) then out.ColorA = value
                    elseif flag:find("colorb",1,true) or flag:find("color_b",1,true) then out.ColorB = value
                    elseif flag:find("anim",1,true) then out.Animate = value
                    elseif flag:find("enable",1,true) or flag:find("enabled",1,true) then out.Enabled = value end
                end
            end
        end

        local settings = Library.Settings or {}
        if out.Enabled == nil then out.Enabled = settings.GradientEnabled or settings.GradientsEnabled or settings.EnableGradients or false end
        if out.Preset == nil then out.Preset = settings.GradientPreset or "Violet Dream" end
        if out.Animate == nil then out.Animate = settings.GradientAnimation or settings.AnimateGradient or false end
        if out.Speed == nil then out.Speed = settings.GradientSpeed or 0.2 end
        if out.Rotation == nil then out.Rotation = settings.GradientRotation or 0 end
        if out.Intensity == nil then out.Intensity = settings.GradientIntensity or 1 end
        if out.ColorA == nil then out.ColorA = settings.GradientColorA end
        if out.ColorB == nil then out.ColorB = settings.GradientColorB end
        return out
    end

    local function removeBackgroundGradient(object)
        if object:IsA("UIGradient") and not object.Parent:IsA("UIStroke") then
            object:Destroy()
            return true
        end
        return false
    end

    local function ensureStroke(stroke)
        if tracked[stroke] and tracked[stroke].Parent == stroke then return tracked[stroke] end
        local existing = stroke:FindFirstChild("E17_StrokeGradient")
        if existing and existing:IsA("UIGradient") then
            tracked[stroke] = existing
            return existing
        end
        local gradient = Instance.new("UIGradient")
        gradient.Name = "E17_StrokeGradient"
        gradient.Parent = stroke
        tracked[stroke] = gradient
        return gradient
    end

    local function refresh(now)
        local cfg = gradientControls()
        local theme = Library.Theme or {}
        local fallback = {
            theme.Outline or Color3.fromRGB(116,72,205),
            theme.Accent or Color3.fromRGB(139,92,246),
            theme.Hover or Color3.fromRGB(176,130,255),
        }
        local colors = PRESETS[tostring(cfg.Preset)] or fallback
        if tostring(cfg.Preset) == "Custom" and typeof(cfg.ColorA) == "Color3" and typeof(cfg.ColorB) == "Color3" then
            colors = {cfg.ColorA, cfg.ColorB, cfg.ColorA}
        end

        local intensity = math.clamp(tonumber(cfg.Intensity) or 1, 0, 1)
        local base = theme.Outline or colors[1]
        local a = base:Lerp(colors[1], intensity)
        local b = base:Lerp(colors[2] or colors[1], intensity)
        local c = base:Lerp(colors[3] or colors[1], intensity)

        for _, object in ipairs(Root:GetDescendants()) do
            if object:IsA("UIGradient") and not object.Parent:IsA("UIStroke") then
                removeBackgroundGradient(object)
            elseif object:IsA("UIStroke") then
                local gradient = object:FindFirstChild("E17_StrokeGradient")
                if cfg.Enabled then
                    gradient = gradient or ensureStroke(object)
                    gradient.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, a),
                        ColorSequenceKeypoint.new(0.5, b),
                        ColorSequenceKeypoint.new(1, c),
                    })
                    local rotation = tonumber(cfg.Rotation) or 0
                    if cfg.Animate then
                        rotation = rotation + (now * 90 * math.max(0.02, tonumber(cfg.Speed) or 0.2))
                    end
                    gradient.Rotation = rotation % 360
                elseif gradient then
                    gradient:Destroy()
                    tracked[object] = nil
                end
            end
        end
    end

    for _, object in ipairs(Root:GetDescendants()) do
        if object:IsA("UIGradient") and not object.Parent:IsA("UIStroke") then
            removeBackgroundGradient(object)
        end
    end

    connections[#connections + 1] = Root.DescendantAdded:Connect(function(object)
        if object:IsA("UIGradient") and not object.Parent:IsA("UIStroke") then
            task.defer(function()
                if object.Parent and not object.Parent:IsA("UIStroke") then object:Destroy() end
            end)
        end
    end)

    local RunService = game:GetService("RunService")
    local accumulator = 0
    connections[#connections + 1] = RunService.Heartbeat:Connect(function(dt)
        accumulator = accumulator + dt
        if accumulator < 0.12 then return end
        accumulator = 0
        refresh(os.clock())
    end)

    Library.RefreshStrokeGradients = function()
        refresh(os.clock())
    end
    refresh(os.clock())
end

installTileButtons()
installStrokeGradients()

local rawUnload = Library.Unload
if type(rawUnload) == "function" then
    function Library:Unload(...)
        for _, connection in ipairs(self.__E17StableConnections or {}) do
            pcall(function() connection:Disconnect() end)
        end
        table.clear(self.__E17StableConnections or {})
        return rawUnload(self, ...)
    end
end

return Library
