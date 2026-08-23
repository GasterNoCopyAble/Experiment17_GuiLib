        function section:AddNumberInput(opts)
            opts = opts or {}
            local min = tonumber(opts.Min) or -math.huge
            local max = tonumber(opts.Max) or math.huge
            local default = tonumber(opts.Default) or 0

            local inputOpts = {}
            for k, v in pairs(opts) do inputOpts[k] = v end
            inputOpts.Default = tostring(default)

            local control = self:AddInput(inputOpts)
            local baseSet = control.Set

            function control:Set(v, silent)
                local num = math.clamp(tonumber(v) or default, min, max)
                baseSet(self, tostring(num), true)
                if self.Flag then Library.Flags[self.Flag] = num end
                if not silent then safeCallback(opts.Callback, num) end
                Library:QueueDependencyRefresh()
            end

            control:Set(default, true)
            return control
        end

        -- LABEL / PARAGRAPH
        function section:AddLabel(opts)
            if type(opts) == "string" then opts = {Text = opts} end
            opts = opts or {}

            local Holder, control = newBaseControl(Items, opts.Text or opts.Name or "Label", "Low", opts.Height or 30, {
                Name = opts.Text or opts.Name or "Label",
                Tooltip = false,
            })
            control.Requirement.Visible = false
            control.Label.Size = UDim2.new(1, -24, 1, 0)
            control.Label.Text = tostring(opts.Text or opts.Name or "")
            control.Label.TextSize = tonumber(opts.TextSize) or 12
            return control
        end

        function section:AddParagraph(opts)
            if type(opts) == "string" then opts = {Text = opts} end
            opts = opts or {}
            local control = self:AddLabel({
                Text = opts.Text or "",
                Height = opts.Height or 58,
                TextSize = opts.TextSize or 11,
            })
            control.Label.TextWrapped = true
            control.Label.TextYAlignment = Enum.TextYAlignment.Top
            control.Label.Position = UDim2.fromOffset(12, 8)
            control.Label.Size = UDim2.new(1, -24, 1, -16)
            return control
        end

        section.AddInfo = section.AddParagraph

        -- PROGRESS BAR
        function section:AddProgressBar(opts)
            opts = opts or {}
            local value = math.clamp(tonumber(opts.Default) or 0, tonumber(opts.Min) or 0, tonumber(opts.Max) or 100)
            local min = tonumber(opts.Min) or 0
            local max = tonumber(opts.Max) or 100

            local Holder, control = newBaseControl(Items, opts.Name or "Progress", opts.RequiredGraphics, 42, opts)
            control.Requirement.Visible = false

            local Bar = Create("Frame", {
                Parent = Holder,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -10, 0.5, 0),
                Size = UDim2.fromOffset(160, 8),
                BackgroundColor3 = Library.Theme.Control2,
                BorderSizePixel = 0,
                ZIndex = 18,
            })
            Library:AdaptiveCorner(Bar, -4)

            local Fill = Create("Frame", {
                Parent = Bar,
                Size = UDim2.fromScale(0, 1),
                BackgroundColor3 = Library.Theme.Accent,
                BorderSizePixel = 0,
                ZIndex = 19,
            })
            Library:AdaptiveCorner(Fill, -4)

            function control:Set(v, silent)
                value = math.clamp(tonumber(v) or value, min, max)
                local alpha = max == min and 1 or (value - min) / (max - min)
                Library:Animate(Fill, 0.18, {Size = UDim2.fromScale(alpha, 1)})
                if self.Flag then Library.Flags[self.Flag] = value end
                if not silent then safeCallback(opts.Callback, value) end
                Library:QueueDependencyRefresh()
            end

            function control:Get() return value end

            registerFlag(control, opts.Flag, value)
            control:Set(value, true)
            return control
        end

        -- STATUS
        function section:AddStatus(opts)
            opts = opts or {}
            local Holder, control = newBaseControl(Items, opts.Name or "Status", "Low", 36, opts)
            control.Requirement.Visible = false

            local StatusText = Create("TextLabel", {
                Parent = Holder,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -10, 0.5, 0),
                Size = UDim2.fromOffset(150, 22),
                BackgroundTransparency = 1,
                Text = tostring(opts.Default or "Ready"),
                TextColor3 = Library.Theme.Accent,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Right,
                ZIndex = 18,
            })
            Library:RegisterFont(StatusText, true)

            function control:Set(v)
                StatusText.Text = tostring(v)
            end

            function control:Get()
                return StatusText.Text
            end

            return control
        end

        -- BUTTON GROUP
        function section:AddButtonGroup(opts)
            opts = opts or {}
            local buttons = opts.Buttons or {}
            local Holder, control = newBaseControl(Items, opts.Name or "Actions", opts.RequiredGraphics, 42, opts)
            control.Requirement.Visible = false

            local row = Create("Frame", {
                Parent = Holder,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -10, 0.5, 0),
                Size = UDim2.fromOffset(220, 26),
                BackgroundTransparency = 1,
                ZIndex = 18,
            })
            Create("UIListLayout", {
                Parent = row,
                FillDirection = Enum.FillDirection.Horizontal,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
                Padding = UDim.new(0, 5),
            })

            for _, buttonData in ipairs(buttons) do
                local button = Create("TextButton", {
                    Parent = row,
                    Size = UDim2.fromOffset(68, 26),
                    BackgroundColor3 = Library.Theme.Control2,
                    BorderSizePixel = 0,
                    Text = tostring(buttonData.Text or buttonData.Name or "Button"),
                    TextColor3 = Library.Theme.Text,
                    TextSize = 10,
                    AutoButtonColor = false,
                    ZIndex = 19,
                })
                Library:RegisterFont(button, true)
                Library:AdaptiveCorner(button, -2)

                button.MouseButton1Click:Connect(function()
                    if not control.Locked then
                        safeCallback(buttonData.Callback, buttonData.Value)
                    end
                end)
            end

            return control
        end

        -- RADIO is the same value model as Choice, but gives the author a
        -- semantic API name.
        section.AddRadio = section.AddChoice

        table.insert(tab.Sections, section)
        return section
    end

    table.insert(self.Tabs, tab)
    if #self.Tabs == 1 then
        tab:Select()
    end

    return tab
end

--============================================================
-- QUESTION / CONFIRM MODALS
--============================================================

local function normalizePromptOption(LibraryRef, option, index)
    if type(option) == "table" then
        local rawText = option.Text or option.Name or option.Label or option.Value or ("Option " .. tostring(index))
        return {
            Text = LibraryRef:ResolveLocalizedText(rawText, "Option " .. tostring(index)),
            Value = option.Value ~= nil and option.Value or LibraryRef:ResolveLocalizedText(rawText),
        }
    end

    return {
        Text = LibraryRef:ResolveLocalizedText(option, "Option " .. tostring(index)),
        Value = option,
    }
end

function Library:_ShowPrompt(options)
    options = options or {}

    if self.Unloaded then
        return nil, nil
    end

    self:HideControlTooltip(true)

    if self.ActiveDropdown and self.ActiveDropdown.CloseDropdown then
        pcall(function()
            self.ActiveDropdown:CloseDropdown()
        end)
    end

    self.PromptBusy = true

    local optionSource = options.Options or {}
    local normalized = {}

    for index, option in ipairs(optionSource) do
        table.insert(normalized, normalizePromptOption(self, option, index))
    end

    if #normalized == 0 then
        normalized = {
            {
                Text = self:L("Continue"),
                Value = true,
            }
        }
    end

    local overlay = Create("Frame", {
        Parent = Root,
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Active = true,
        ZIndex = 220,
    })
    self.ActivePromptOverlay = overlay

    local promptBox = Create("Frame", {
        Parent = overlay,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 64),
        Size = UDim2.fromOffset(540, 220),
        BackgroundColor3 = self.Theme.Background,
        BorderSizePixel = 0,
        ZIndex = 221,
    })
    self:AdaptiveCorner(promptBox, 4)

    local promptScale = Create("UIScale", {
        Parent = promptBox,
        Scale = math.max(0.45, (self.CurrentDPIScale or DPI_BASE_SCALE) * 0.70),
    })

    local promptStroke = Create("UIStroke", {
        Parent = promptBox,
        Thickness = 1.35,
        Transparency = 0.08,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Color = self.Theme.Outline,
    })

    local title = Create("TextLabel", {
        Parent = promptBox,
        Position = UDim2.fromOffset(24, 18),
        Size = UDim2.new(1, -48, 0, 30),
        BackgroundTransparency = 1,
        Text = self:ResolveLocalizedText(options.Title, self:L("Question")),
        TextColor3 = self.Theme.Text,
        TextSize = 22,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 222,
    })
    self:RegisterFont(title, true)

    local question = Create("TextLabel", {
        Parent = promptBox,
        Position = UDim2.fromOffset(24, 54),
        Size = UDim2.new(1, -48, 0, 72),
        BackgroundTransparency = 1,
        Text = self:ResolveLocalizedText(options.Question or options.Text, ""),
        TextColor3 = self.Theme.SubText,
        TextSize = 15,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        ZIndex = 222,
    })
    self:RegisterFont(question)

    local buttons = Create("Frame", {
        Parent = promptBox,
        Position = UDim2.new(0, 24, 1, -66),
        Size = UDim2.new(1, -48, 0, 42),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 222,
    })

    local gap = 8
    Create("UIListLayout", {
        Parent = buttons,
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, gap),
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Center,
    })

    local resultEvent = Instance.new("BindableEvent")
    local resolved = false

    local function finish(value, index)
