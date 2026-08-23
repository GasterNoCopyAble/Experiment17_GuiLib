            end

            self.Open = state
            self.AnimationToken += 1
            local token = self.AnimationToken

            -- Deliberately slower than the rest of the UI. Section expansion is
            -- structural and should feel like content unfolding, not popping in.
            local duration = math.max(0.34, (Library.Settings.AnimationSpeed or 0.18) * 1.85)

            local function contentHeight()
                local h = ItemsLayout.AbsoluteContentSize.Y + 8
                return math.max(8, h)
            end

            if instant then
                Items.Visible = state
                Items.GroupTransparency = state and 0 or 1
                Items.Position = UDim2.fromOffset(0, 44)
                ItemsScale.Scale = state and 1 or 0.72
                HeaderStroke.Transparency = state and 0.12 or 0.24
                Arrow.Text = state and "-" or "+"

                if state then
                    Items.AutomaticSize = Enum.AutomaticSize.Y
                    Items.Size = UDim2.new(1, 0, 0, 0)
                else
                    Items.AutomaticSize = Enum.AutomaticSize.None
                    Items.Size = UDim2.new(1, 0, 0, 0)
                end

                for _, control in ipairs(self.Controls) do
                    if control.MotionScale and control.MotionScale.Parent then
                        control.MotionScale.Scale = 1
                    end
                end
                return
            end

            if state then
                Items.Visible = true
                Items.AutomaticSize = Enum.AutomaticSize.None
                Items.Size = UDim2.new(1, 0, 0, 0)
                Items.GroupTransparency = 1
                Items.Position = UDim2.fromOffset(0, 4)
                ItemsScale.Scale = 0.72
                Arrow.Text = "-"

                -- Let UIListLayout refresh once, then animate the true content
                -- height. This makes the SECTION itself open smoothly.
                task.defer(function()
                    if section.AnimationToken ~= token or not section.Open or not Items.Parent then
                        return
                    end

                    local targetHeight = contentHeight()

                    TweenService:Create(
                        Items,
                        TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
                        {
                            Size = UDim2.new(1, 0, 0, targetHeight),
                            GroupTransparency = 0,
                            Position = UDim2.fromOffset(0, 44),
                        }
                    ):Play()

                    TweenService:Create(
                        ItemsScale,
                        TweenInfo.new(duration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                        {Scale = 1}
                    ):Play()

                    Library:Animate(HeaderStroke, duration * 0.75, {Transparency = 0.12})

                    -- Each function arrives separately. The bigger stagger is
                    -- intentional so large sections visually "build" themselves.
                    for index, control in ipairs(self.Controls) do
                        if control.MotionScale and control.MotionScale.Parent then
                            control.MotionScale.Scale = 0.78

                            task.delay(math.min((index - 1) * 0.060, 0.48), function()
                                if section.AnimationToken == token
                                    and section.Open
                                    and control.MotionScale
                                    and control.MotionScale.Parent
                                then
                                    TweenService:Create(
                                        control.MotionScale,
                                        TweenInfo.new(duration * 0.88, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                                        {Scale = 1}
                                    ):Play()
                                end
                            end)
                        end
                    end

                    task.delay(duration + 0.04, function()
                        if section.AnimationToken == token and section.Open and Items.Parent then
                            Items.AutomaticSize = Enum.AutomaticSize.Y
                            Items.Size = UDim2.new(1, 0, 0, 0)
                            Items.Position = UDim2.fromOffset(0, 44)
                            ItemsScale.Scale = 1
                        end
                    end)
                end)
            else
                Arrow.Text = "+"

                -- Freeze the current automatic height first so it can tween down
                -- to zero instead of disappearing in one frame.
                local currentHeight = math.max(Items.AbsoluteSize.Y, contentHeight())
                Items.AutomaticSize = Enum.AutomaticSize.None
                Items.Size = UDim2.new(1, 0, 0, currentHeight)

                TweenService:Create(
                    Items,
                    TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                    {
                        Size = UDim2.new(1, 0, 0, 0),
                        GroupTransparency = 1,
                        Position = UDim2.fromOffset(0, 18),
                    }
                ):Play()

                -- Keep child controls at full scale while closing.
                -- Height + opacity do the closing animation, so rows do not
                -- synchronously collapse into the upper-left corner.
                ItemsScale.Scale = 1

                Library:Animate(HeaderStroke, duration * 0.72, {Transparency = 0.24})

                task.delay(duration + 0.04, function()
                    if section.AnimationToken == token and not section.Open and Items.Parent then
                        Items.Visible = false
                        Items.AutomaticSize = Enum.AutomaticSize.None
                        Items.Size = UDim2.new(1, 0, 0, 0)
                        Items.Position = UDim2.fromOffset(0, 44)
                    end
                end)
            end
        end

        Header.MouseButton1Click:Connect(function()
            section:SetOpen(not section.Open)
        end)

        -- GROUP SEPARATOR
        -- Use this BETWEEN unrelated groups of controls. Related controls
        -- intentionally have no divider between them.
        function section:AddSeparator(opts)
            opts = opts or {}

            local Wrap = Create("Frame", {
                Parent = Items,
                Size = UDim2.new(1, 0, 0, opts.Height or 10),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ZIndex = 15,
            })

            local Line = Create("Frame", {
                Parent = Wrap,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.new(opts.WidthScale or 0.80, 0, 0, opts.Thickness or 2),
                BorderSizePixel = 0,
                BackgroundTransparency = opts.Transparency or 0.24,
                ZIndex = 16,
            })
            Library:BindTheme(Line, "BackgroundColor3", opts.ThemeKey or "Outline")

            return Line
        end

        -- BUTTON
        function section:AddButton(opts)
            opts = opts or {}
            local Holder, control = newBaseControl(Items, opts.Name or "Button", opts.RequiredGraphics, 42, opts)

            local Button = Create("TextButton", {
                Parent = Holder,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -10, 0.5, 0),
                Size = UDim2.fromOffset(88, 26),
                BorderSizePixel = 0,
                Text = opts.ButtonText or "Run",
                TextSize = 11,
                AutoButtonColor = false,
                ZIndex = 17,
            })
            Library:BindTheme(Button, "BackgroundColor3", "Control2")
            Library:BindTheme(Button, "TextColor3", "Text")
            Library:RegisterFont(Button, true)
            if opts.ButtonLocaleKey then
                Library:BindLocaleText(Button, opts.ButtonLocaleKey)
            end
            Library:AdaptiveCorner(Button, -2)

            Button.MouseButton1Click:Connect(function()
                if control.Locked then return end
                safeCallback(opts.Callback)
            end)

            return control
        end

        -- TOGGLE
        function section:AddToggle(opts)
            opts = opts or {}
            local state = opts.Default == true
            local Holder, control = newBaseControl(Items, opts.Name or "Toggle", opts.RequiredGraphics, 42, opts)

            control.Requirement.Position = UDim2.new(1, -60, 0.5, 0)

            local Switch = Create("Frame", {
                Parent = Holder,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -10, 0.5, 0),
                Size = UDim2.fromOffset(38, 20),
                BorderSizePixel = 0,
                ZIndex = 17,
            })
            Create("UICorner", {Parent = Switch, CornerRadius = UDim.new(1, 0)})

            local Dot = Create("Frame", {
                Parent = Switch,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0, 10, 0.5, 0),
                Size = UDim2.fromOffset(14, 14),
                BackgroundColor3 = Color3.fromRGB(245, 245, 250),
                BorderSizePixel = 0,
                ZIndex = 18,
            })
            Create("UICorner", {Parent = Dot, CornerRadius = UDim.new(1, 0)})

            local Click = Create("TextButton", {
                Parent = Holder,
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Text = "",
                ZIndex = 19,
            })

            control.IsToggle = true

            function control:RefreshStyle()
                control:RefreshGate()
                Switch.BackgroundColor3 = state and Library.Theme.Accent or Library.Theme.Control2
                Switch.BackgroundTransparency = self.Locked and 0.5 or 0
                Dot.BackgroundTransparency = self.Locked and 0.35 or 0
            end

            function control:Set(value, silent)
                local nextState = value == true
                if nextState and self.Locked then
                    nextState = false
                end

                state = nextState
                if self.Flag then Library.Flags[self.Flag] = state end

                Library:AnimateControl(Dot, 0.12, {
                    Position = state and UDim2.new(1, -10, 0.5, 0) or UDim2.new(0, 10, 0.5, 0),
                })
                self:RefreshStyle()

                if not silent then
                    safeCallback(opts.Callback, state)
                end
            end

            function control:OnGraphicsLocked()
                if state then
                    self:Set(false, false)
                end
            end

            function control:Get()
                return state
            end

            Click.MouseButton1Click:Connect(function()
                if control.Locked then return end
                control:Set(not state)
            end)

