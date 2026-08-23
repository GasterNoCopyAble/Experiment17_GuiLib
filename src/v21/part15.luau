    Holder.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            Library:HideControlTooltip(true)
            Library:OpenContextMenu(Control)
        end
    end)

    table.insert(Library.Controls, Control)
    table.insert(Library.GatedControls, Control)

    -- Find the section owning this row, including wrapped controls such as
    -- color pickers, and register the row for staggered section animation.
    local ownerNode = parent
    while ownerNode and not Library.SectionByItems[ownerNode] do
        ownerNode = ownerNode.Parent
    end
    if ownerNode then
        local ownerSection = Library.SectionByItems[ownerNode]
        ownerSection.Controls = ownerSection.Controls or {}
        Control.Section = ownerSection
        Control.Tab = ownerSection.Tab
        table.insert(ownerSection.Controls, Control)
    end

    Control:RefreshGate()

    return Holder, Control
end

local function registerFlag(control, flag, default)
    if not flag then
        return
    end
    control.Flag = flag
    Library.Flags[flag] = default
    Library.ControlsByFlag[flag] = control
end

--============================================================
-- TAB / SECTION API
--============================================================

function Library:CreateTab(name, localeKey)
    local isSettingsTab = localeKey == "Settings"

    if not isSettingsTab then
        self.NextTabLayoutOrder += 1
    end

    local tab = {
        Name = localeKey and self:L(localeKey) or name,
        LocaleKey = localeKey,
        Sections = {},
    }

    local Button = Create("TextButton", {
        Parent = TabList,
        Size = UDim2.new(1, -6, 0, 38),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = isSettingsTab and 100000 or self.NextTabLayoutOrder,
        ZIndex = 13,
    })
    Library:AdaptiveCorner(Button, -2)

    local TabStroke = Create("UIStroke", {
        Parent = Button,
        Thickness = 1.35,
        Transparency = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
    Library:BindTheme(TabStroke, "Color", "Outline")

    local TabText = Create("TextLabel", {
        Parent = Button,
        Position = UDim2.fromOffset(18, 0),
        Size = UDim2.new(1, -28, 1, 0),
        BackgroundTransparency = 1,
        Text = localeKey and Library:L(localeKey) or name,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 14,
    })
    Library:BindTheme(TabText, "TextColor3", "SubText")
    Library:RegisterFont(TabText)

    local Indicator = Create("Frame", {
        Parent = Button,
        Position = UDim2.new(0, 5, 0.5, -10),
        Size = UDim2.fromOffset(3, 20),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 15,
    })
    Library:BindTheme(Indicator, "BackgroundColor3", "Accent")
    Create("UICorner", {Parent = Indicator, CornerRadius = UDim.new(1, 0)})

    local PageGroup = Create("CanvasGroup", {
        Parent = Content,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        GroupTransparency = 1,
        Visible = false,
        ZIndex = 14,
    })

    local PageScale = Create("UIScale", {
        Parent = PageGroup,
        Scale = 1,
    })

    local Page = Create("ScrollingFrame", {
        Parent = PageGroup,
        Position = UDim2.fromOffset(15, 14),
        Size = UDim2.new(1, -26, 1, -28),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(),
        Visible = true,
        ZIndex = 14,
    })
    Library:BindTheme(Page, "ScrollBarImageColor3", "Accent")

    Create("UIPadding", {
        Parent = Page,
        PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 10),
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 10),
    })

    Create("UIListLayout", {
        Parent = Page,
        Padding = UDim.new(0, 9),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    tab.Button = Button
    tab.TabText = TabText
    tab.TabStroke = TabStroke
    tab.Indicator = Indicator
    tab.Page = Page
    tab.PageGroup = PageGroup
    tab.PageScale = PageScale

    function tab:Select()
        if Library.ActiveDropdown and Library.ActiveDropdown.CloseDropdown then
            Library.ActiveDropdown:CloseDropdown()
        end

        if Library.CurrentTab == self then
            return
        end

        local oldTab = Library.CurrentTab
        local duration = math.max(0.12, (Library.Settings.AnimationSpeed or 0.18) * 0.85)

        for _, other in ipairs(Library.Tabs) do
            if other ~= self then
                Library:Animate(other.Button, duration, {
                    BackgroundTransparency = 1,
                })
                Library:Animate(other.Indicator, duration, {
                    BackgroundTransparency = 1,
                    Size = UDim2.fromOffset(3, 6),
                })
                Library:Animate(other.TabStroke, duration, {Transparency = 1})
                Library:Animate(other.TabText, duration, {TextColor3 = Library.Theme.SubText})
            end
        end

        if oldTab and oldTab.PageGroup and oldTab.PageGroup.Visible then
            local oldGroup = oldTab.PageGroup
            Library:Animate(oldGroup, duration, {
                GroupTransparency = 1,
                Position = UDim2.fromOffset(-44, 0),
            })
            if oldTab.PageScale then
                Library:Animate(oldTab.PageScale, duration, {Scale = 0.94})
            end
            task.delay(duration + 0.02, function()
                if Library.CurrentTab ~= oldTab and oldGroup.Parent then
                    oldGroup.Visible = false
                    oldGroup.Position = UDim2.fromOffset(0, 0)
                    if oldTab.PageScale then
                        oldTab.PageScale.Scale = 1
                    end
                end
            end)
        end

        self.PageGroup.Visible = true
        self.PageGroup.Position = UDim2.fromOffset(48, 0)
        self.PageGroup.GroupTransparency = 1
        if self.PageScale then
            self.PageScale.Scale = 0.93
        end
        Library:Animate(self.PageGroup, duration, {
            Position = UDim2.fromOffset(0, 0),
            GroupTransparency = 0,
        })
        if self.PageScale then
            Library:Animate(self.PageScale, duration, {Scale = 1})
        end

        self.Button.BackgroundColor3 = Library.Theme.Control2
        Library:Animate(self.Button, duration, {BackgroundTransparency = 0.08})
        Library:Animate(self.TabStroke, duration, {Transparency = 0.12})
        Library:Animate(self.TabText, duration, {TextColor3 = Library.Theme.Text})
        self.Indicator.Size = UDim2.fromOffset(3, 6)
        Library:Animate(self.Indicator, duration, {
            BackgroundTransparency = 0,
            Size = UDim2.fromOffset(3, 20),
        })

        Library.CurrentTab = self
        Library.Breadcrumb.Text = self.LocaleKey and Library:L(self.LocaleKey) or self.Name
    end

    Button.MouseButton1Click:Connect(function()
        tab:Select()
    end)

    function tab:CreateSection(title, defaultOpen, localeKey)
        local section = {
            LocaleKey = localeKey,
            Tab = tab,
            -- Closed unless a caller explicitly opts in with true.
            Open = defaultOpen == true,
            Controls = {},
        }

        local SectionFrame = Create("Frame", {
            Parent = Page,
            Size = UDim2.new(1, -2, 0, 42),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AutomaticSize = Enum.AutomaticSize.Y,
            ZIndex = 14,
        })

        local Header = Create("TextButton", {
            Parent = SectionFrame,
            Size = UDim2.new(1, 0, 0, 38),
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            ZIndex = 15,
        })
        Library:BindTheme(Header, "BackgroundColor3", "Panel")
        Library:AdaptiveCorner(Header, 0)

        local HeaderStroke = Create("UIStroke", {
            Parent = Header,
            Thickness = 1.2,
            Transparency = 0.24,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        })
        Library:BindTheme(HeaderStroke, "Color", "Outline")

        local HeaderText = Create("TextLabel", {
            Parent = Header,
            Position = UDim2.fromOffset(12, 0),
            Size = UDim2.new(1, -48, 1, 0),
            BackgroundTransparency = 1,
            Text = localeKey and Library:L(localeKey) or title,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 16,
        })
        Library:BindTheme(HeaderText, "TextColor3", "Text")
        Library:RegisterFont(HeaderText, true)
        if localeKey then
            Library:BindLocaleText(HeaderText, localeKey)
        end

        local Arrow = Create("TextLabel", {
            Parent = Header,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -12, 0.5, 0),
            Size = UDim2.fromOffset(24, 24),
            BackgroundTransparency = 1,
            Text = section.Open and "-" or "+",
            TextSize = 18,
            ZIndex = 16,
        })
        Library:BindTheme(Arrow, "TextColor3", "Accent")
        Library:RegisterFont(Arrow, true)

        local Items = Create("CanvasGroup", {
            Parent = SectionFrame,
            Position = UDim2.fromOffset(0, 44),
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            GroupTransparency = section.Open and 0 or 1,
            Visible = section.Open,
            ZIndex = 15,
        })

        local ItemsScale = Create("UIScale", {
            Parent = Items,
            Scale = section.Open and 1 or 0.90,
        })

        -- CanvasGroup can clip the first child's outside stroke at its own top
        -- edge. Even though v7 uses an inset border for rows, this padding also
        -- gives dropdowns/pickers and future custom controls safe breathing room.
        Create("UIPadding", {
            Parent = Items,
            PaddingLeft = UDim.new(0, 3),
            PaddingRight = UDim.new(0, 3),
            PaddingTop = UDim.new(0, 4),
            PaddingBottom = UDim.new(0, 4),
        })

        local ItemsLayout = Create("UIListLayout", {
            Parent = Items,
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
        })

        section.Frame = SectionFrame
        section.Header = Header
        section.Items = Items
        section.ItemsLayout = ItemsLayout
        section.AnimationToken = 0
        Library.SectionByItems[Items] = section

        function section:SetOpen(state, instant)
            if not state and Library.ActiveDropdown and Library.ActiveDropdown.CloseDropdown then
                Library.ActiveDropdown:CloseDropdown()
            end

            state = state == true
            if self.Open == state and not instant then
                return
