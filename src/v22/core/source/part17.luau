            registerFlag(control, opts.Flag, state)
            control:Set(state, true)
            return control
        end

        -- SLIDER
        function section:AddSlider(opts)
            opts = opts or {}
            local min = tonumber(opts.Min) or 0
            local max = tonumber(opts.Max) or 100
            local value = math.clamp(tonumber(opts.Default) or min, min, max)
            local decimals = tonumber(opts.Decimals) or 0

            local Holder, control = newBaseControl(Items, opts.Name or "Slider", opts.RequiredGraphics, 58, opts)
            control.Label.Size = UDim2.new(1, -160, 0, 32)
            control.Requirement.Position = UDim2.new(1, -75, 0, 16)

            local ValueLabel = Create("TextLabel", {
                Parent = Holder,
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -10, 0, 5),
                Size = UDim2.fromOffset(62, 22),
                BackgroundTransparency = 1,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Right,
                ZIndex = 17,
            })
            Library:BindTheme(ValueLabel, "TextColor3", "SubText")
            Library:RegisterFont(ValueLabel, true)

            local Bar = Create("Frame", {
                Parent = Holder,
                Position = UDim2.new(0, 12, 1, -17),
                Size = UDim2.new(1, -24, 0, 5),
                BorderSizePixel = 0,
                ZIndex = 17,
            })
            Library:BindTheme(Bar, "BackgroundColor3", "Control2")
            Create("UICorner", {Parent = Bar, CornerRadius = UDim.new(1, 0)})

            local SliderHitbox = Create("TextButton", {
                Parent = Holder,
                Position = UDim2.new(0, 12, 1, -29),
                Size = UDim2.new(1, -24, 0, 28),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false,
                Active = true,
                ZIndex = 21,
            })

            local Fill = Create("Frame", {
                Parent = Bar,
                Size = UDim2.fromScale(0, 1),
                BorderSizePixel = 0,
                ZIndex = 18,
            })
            Library:BindTheme(Fill, "BackgroundColor3", "Accent")
            Create("UICorner", {Parent = Fill, CornerRadius = UDim.new(1, 0)})

            local Knob = Create("Frame", {
                Parent = Bar,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0, 0.5),
                Size = UDim2.fromOffset(14, 14),
                BorderSizePixel = 0,
                ZIndex = 20,
            })
            Library:BindTheme(Knob, "BackgroundColor3", "Accent")
            Create("UICorner", {Parent = Knob, CornerRadius = UDim.new(1, 0)})
            Create("UIStroke", {
                Parent = Knob,
                Thickness = 1,
                Transparency = 0.18,
                Color = Color3.fromRGB(255, 255, 255),
            })

            Bar.Active = true

            local draggingSlider = false
            local sliderInputType = nil

            local function round(n)
                local m = 10 ^ decimals
                return math.floor(n * m + 0.5) / m
            end

            local function fromX(x)
                if control.Locked then return end
                local p = math.clamp((x - Bar.AbsolutePosition.X) / math.max(1, Bar.AbsoluteSize.X), 0, 1)

                -- Stepped mode snaps the visual/input position into deliberate
                -- chunks. Smooth mode tracks the mouse continuously.
                if Library.Settings.AnimationMode == "Stepped" then
                    local visualSteps = tonumber(opts.VisualSteps) or 20
                    p = math.floor(p * visualSteps + 0.5) / visualSteps
                end

                control:Set(round(min + (max - min) * p))
            end

            function control:RefreshStyle()
                control:RefreshGate()
                Fill.BackgroundTransparency = self.Locked and 0.58 or 0
                Knob.BackgroundTransparency = self.Locked and 0.55 or 0
                Bar.BackgroundTransparency = self.Locked and 0.35 or 0
                ValueLabel.TextTransparency = self.Locked and 0.5 or 0
            end

            function control:Set(v, silent)
                value = math.clamp(tonumber(v) or min, min, max)
                value = round(value)

                local p = (value - min) / math.max(0.0001, max - min)
                ValueLabel.Text = tostring(value)

                local knobPosition = UDim2.fromScale(p, 0.5)

                if silent then
                    Fill.Size = UDim2.fromScale(p, 1)
                    Knob.Position = knobPosition
                elseif Library.Settings.AnimationMode == "Smooth" then
                    Library:AnimateControl(Fill, 0.07, {Size = UDim2.fromScale(p, 1)})
                    Library:AnimateControl(Knob, 0.07, {Position = knobPosition})
                else
                    Fill.Size = UDim2.fromScale(p, 1)
                    Knob.Position = knobPosition
                end

                if self.Flag then Library.Flags[self.Flag] = value end
                if not silent then safeCallback(opts.Callback, value) end
                Library:QueueDependencyRefresh()
            end

            function control:Get()
                return value
            end

            SliderHitbox.InputBegan:Connect(function(input)
                if control.Locked then return end

                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch
                then
                    draggingSlider = true
                    sliderInputType = input.UserInputType
                    fromX(input.Position.X)
                end
            end)

            UIS.InputChanged:Connect(function(input)
                if Library.Unloaded or not draggingSlider then return end

                local valid =
                    (sliderInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement)
                    or
                    (sliderInputType == Enum.UserInputType.Touch and input.UserInputType == Enum.UserInputType.Touch)

                if valid then
                    fromX(input.Position.X)
                end
            end)

            UIS.InputEnded:Connect(function(input)
                if Library.Unloaded or not draggingSlider then return end

                local valid =
                    (sliderInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseButton1)
                    or
                    (sliderInputType == Enum.UserInputType.Touch and input.UserInputType == Enum.UserInputType.Touch)

                if valid then
                    draggingSlider = false
                    sliderInputType = nil
                end
            end)

            registerFlag(control, opts.Flag, value)
            control:Set(value, true)
            return control
        end

        -- CHOICE / REAL DROPDOWN
        -- Clicking the value opens a panel below the control with every option.
        function section:AddChoice(opts)
            opts = opts or {}
            local values = opts.Values or {"None"}
            local value = opts.Default or values[1]
            local open = false

            local CLOSED_HEIGHT = 42
            local OPTION_HEIGHT = 28
            local OPTIONS_PADDING = 6
            local optionsHeight = (#values * OPTION_HEIGHT) + OPTIONS_PADDING * 2

            local Holder, control = newBaseControl(Items, opts.Name or "Choice", opts.RequiredGraphics, CLOSED_HEIGHT, opts)
            Holder.ClipsDescendants = true
            control.Requirement.Position = UDim2.new(1, -150, 0.5, 0)

            local Select = Create("TextButton", {
                Parent = Holder,
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -10, 0, 8),
                Size = UDim2.fromOffset(128, 26),
                BorderSizePixel = 0,
                TextSize = 11,
                AutoButtonColor = false,
                ZIndex = 19,
            })
            Library:BindTheme(Select, "BackgroundColor3", "Control2")
            Library:BindTheme(Select, "TextColor3", "Text")
            Library:RegisterFont(Select, true)
            Library:AdaptiveCorner(Select, -2)

            local OptionsFrame = Create("CanvasGroup", {
                Parent = Holder,
                Position = UDim2.fromOffset(10, CLOSED_HEIGHT + 7),
                Size = UDim2.new(1, -20, 0, optionsHeight - 6),
                BorderSizePixel = 0,
                BackgroundTransparency = 0,
                GroupTransparency = 1,
                Visible = false,
                ZIndex = 30,
            })
            Library:BindTheme(OptionsFrame, "BackgroundColor3", "Panel")
            Library:AdaptiveCorner(OptionsFrame, -2)

            local OptionsScale = Create("UIScale", {
                Parent = OptionsFrame,
                Scale = 1,
            })

            local OptionsStroke = Create("UIStroke", {
                Parent = OptionsFrame,
                Thickness = 1.2,
                Transparency = 0.20,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            })
            Library:BindTheme(OptionsStroke, "Color", "Outline")

            local OptionsInner = Create("Frame", {
                Parent = OptionsFrame,
                Position = UDim2.fromOffset(6, 6),
                Size = UDim2.new(1, -12, 1, -12),
                BackgroundTransparency = 1,
                ZIndex = 31,
            })

            Create("UIListLayout", {
                Parent = OptionsInner,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 0),
            })

            local optionButtons = {}

            local function refreshOptionStyles()
                for _, item in ipairs(optionButtons) do
                    local selected = item.Value == value
                    item.Button.BackgroundTransparency = selected and 0.08 or 1
                    item.Button.TextColor3 = selected and Library.Theme.Accent or Library.Theme.Text
                end
            end

            function control:RefreshStyle()
                control:RefreshGate()
                Select.BackgroundTransparency = self.Locked and 0.45 or 0
                Select.TextTransparency = self.Locked and 0.45 or 0
                OptionsFrame.BackgroundTransparency = self.Locked and 0.35 or 0
                refreshOptionStyles()
            end

            function control:Set(v, silent)
                if table.find(values, v) then
                    value = v
                else
                    value = values[1]
                end

                Select.Text = tostring(value) .. (open and "  ^" or "  v")
                if self.Flag then Library.Flags[self.Flag] = value end
                refreshOptionStyles()
                if not silent then safeCallback(opts.Callback, value) end
                Library:QueueDependencyRefresh()
            end

            function control:Get()
                return value
            end

            local dropdownToken = 0

            function control:CloseDropdown()
