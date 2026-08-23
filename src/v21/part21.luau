                    GroupTransparency = 0,
                    Position = UDim2.fromOffset(10, CLOSED_HEIGHT),
                })
                Library:Animate(OptionsScale, duration, {Scale = 1})
            end

            for _, optionValue in ipairs(values) do
                local option = optionValue

                local Button = Create("TextButton", {
                    Parent = OptionsInner,
                    Size = UDim2.new(1, 0, 0, OPTION_HEIGHT),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Text = tostring(option),
                    TextColor3 = Library.Theme.Text,
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    AutoButtonColor = false,
                    ZIndex = 32,
                })
                Library:RegisterFont(Button)

                Create("UIPadding", {
                    Parent = Button,
                    PaddingLeft = UDim.new(0, 32),
                })

                local Check = Create("TextLabel", {
                    Parent = Button,
                    Position = UDim2.fromOffset(5, 5),
                    Size = UDim2.fromOffset(18, 18),
                    BackgroundColor3 = Library.Theme.Control2,
                    BorderSizePixel = 0,
                    Text = "",
                    TextColor3 = Library.Theme.Text,
                    TextSize = 10,
                    ZIndex = 33,
                })
                Library:RegisterFont(Check, true)
                Library:AdaptiveCorner(Check, -5)

                table.insert(optionRows, {
                    Button = Button,
                    Check = Check,
                    Value = option,
                })

                Button.MouseButton1Click:Connect(function()
                    if control.Locked then return end
                    selected[option] = not selected[option]
                    control:Set(getArray())
                end)

                Button.MouseEnter:Connect(function()
                    if not selected[option] then
                        Button.BackgroundTransparency = 0.66
                    end
                end)

                Button.MouseLeave:Connect(function()
                    refreshRows()
                end)
            end

            Select.MouseButton1Click:Connect(function()
                if control.Locked then return end
                if open then
                    control:CloseDropdown()
                else
                    control:OpenDropdown()
                end
            end)

            registerFlag(control, opts.Flag, getArray())
            control:Set(default, true)
            return control
        end

        section.AddMultiDropdown = section.AddMultiChoice

        -- RANGE SLIDER
        function section:AddRangeSlider(opts)
            opts = opts or {}

            local min = tonumber(opts.Min) or 0
            local max = tonumber(opts.Max) or 100
            local default = opts.Default or {min, max}
            local low = math.clamp(tonumber(default[1]) or min, min, max)
            local high = math.clamp(tonumber(default[2]) or max, min, max)

            if low > high then
                low, high = high, low
            end

            local Holder, control = newBaseControl(
                Items,
                opts.Name or "Range",
                opts.RequiredGraphics,
                42,
                opts
            )

            control.Requirement.Position = UDim2.new(1, -242, 0.5, 0)

            local ValueLabel = Create("TextLabel", {
                Parent = Holder,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -10, 0.5, -9),
                Size = UDim2.fromOffset(112, 16),
                BackgroundTransparency = 1,
                Text = "",
                TextColor3 = Library.Theme.Text,
                TextSize = 10,
                TextXAlignment = Enum.TextXAlignment.Right,
                ZIndex = 19,
            })
            Library:RegisterFont(ValueLabel, true)

            local Bar = Create("Frame", {
                Parent = Holder,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -10, 0.5, 8),
                Size = UDim2.fromOffset(210, 6),
                BackgroundColor3 = Library.Theme.Control2,
                BorderSizePixel = 0,
                ZIndex = 18,
            })
            Library:AdaptiveCorner(Bar, -4)

            local RangeHitbox = Create("TextButton", {
                Parent = Holder,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -10, 0.5, 8),
                Size = UDim2.fromOffset(220, 30),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false,
                Active = true,
                ZIndex = 22,
            })

            local Fill = Create("Frame", {
                Parent = Bar,
                Position = UDim2.fromScale(0, 0),
                Size = UDim2.fromScale(1, 1),
                BackgroundColor3 = Library.Theme.Accent,
                BorderSizePixel = 0,
                ZIndex = 19,
            })
            Library:AdaptiveCorner(Fill, -4)

            local LowKnob = Create("Frame", {
                Parent = Bar,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0, 0.5),
                Size = UDim2.fromOffset(12, 12),
                BackgroundColor3 = Library.Theme.Accent,
                BorderSizePixel = 0,
                ZIndex = 20,
            })
            Create("UICorner", {Parent = LowKnob, CornerRadius = UDim.new(1, 0)})

            local HighKnob = Create("Frame", {
                Parent = Bar,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(1, 0.5),
                Size = UDim2.fromOffset(12, 12),
                BackgroundColor3 = Library.Theme.Accent,
                BorderSizePixel = 0,
                ZIndex = 20,
            })
            Create("UICorner", {Parent = HighKnob, CornerRadius = UDim.new(1, 0)})

            local dragging = nil

            local function alphaFor(v)
                if max == min then return 0 end
                return math.clamp((v - min) / (max - min), 0, 1)
            end

            local function valueFromX(x)
                local width = math.max(1, Bar.AbsoluteSize.X)
                local alpha = math.clamp((x - Bar.AbsolutePosition.X) / width, 0, 1)
                local raw = min + (max - min) * alpha

                if opts.Decimals and tonumber(opts.Decimals) then
                    local decimals = math.max(0, math.floor(tonumber(opts.Decimals)))
                    local power = 10 ^ decimals
                    raw = math.floor(raw * power + 0.5) / power
                else
                    raw = math.floor(raw + 0.5)
                end

                return math.clamp(raw, min, max)
            end

            local function refresh(animated)
                local lowA = alphaFor(low)
                local highA = alphaFor(high)

                ValueLabel.Text = tostring(low) .. " - " .. tostring(high)

                local lowPos = UDim2.fromScale(lowA, 0.5)
                local highPos = UDim2.fromScale(highA, 0.5)
                local fillPos = UDim2.fromScale(lowA, 0)
                local fillSize = UDim2.new(highA - lowA, 0, 1, 0)

                if animated and Library.Settings.AnimationMode == "Smooth" then
                    Library:AnimateControl(LowKnob, 0.08, {Position = lowPos})
                    Library:AnimateControl(HighKnob, 0.08, {Position = highPos})
                    Library:AnimateControl(Fill, 0.08, {
                        Position = fillPos,
                        Size = fillSize,
                    })
                else
                    LowKnob.Position = lowPos
                    HighKnob.Position = highPos
                    Fill.Position = fillPos
                    Fill.Size = fillSize
                end
            end

            function control:Set(v, silent)
                if type(v) == "table" then
                    low = math.clamp(tonumber(v[1]) or low, min, max)
                    high = math.clamp(tonumber(v[2]) or high, min, max)

                    if low > high then
                        low, high = high, low
                    end
                end

                refresh(not silent)

                local result = {low, high}
                if self.Flag then
                    Library.Flags[self.Flag] = result
                end

                if not silent then
                    safeCallback(opts.Callback, result, low, high)
                end

                Library:QueueDependencyRefresh()
            end

            function control:Get()
                return {low, high}
            end

            local function updateFromMouse(x)
                local newValue = valueFromX(x)

                if dragging == "Low" then
                    low = math.min(newValue, high)
                elseif dragging == "High" then
                    high = math.max(newValue, low)
                end

                control:Set({low, high})
            end

            local rangeInputType = nil
            Bar.Active = true

            RangeHitbox.InputBegan:Connect(function(input)
                if control.Locked then return end

                if input.UserInputType ~= Enum.UserInputType.MouseButton1
                    and input.UserInputType ~= Enum.UserInputType.Touch
                then
                    return
                end

                rangeInputType = input.UserInputType
                local x = input.Position.X
                local candidate = valueFromX(x)

                if math.abs(candidate - low) <= math.abs(candidate - high) then
                    dragging = "Low"
                else
                    dragging = "High"
                end

                updateFromMouse(x)
            end)

            UIS.InputChanged:Connect(function(input)
                if Library.Unloaded or not dragging then return end

                local valid =
                    (rangeInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement)
                    or
                    (rangeInputType == Enum.UserInputType.Touch and input.UserInputType == Enum.UserInputType.Touch)

                if valid then
                    updateFromMouse(input.Position.X)
                end
            end)

            UIS.InputEnded:Connect(function(input)
                if not dragging then return end

                local valid =
                    (rangeInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseButton1)
                    or
                    (rangeInputType == Enum.UserInputType.Touch and input.UserInputType == Enum.UserInputType.Touch)

                if valid then
                    dragging = nil
                    rangeInputType = nil
                end
            end)

            registerFlag(control, opts.Flag, {low, high})
            control:Set({low, high}, true)
            return control
        end

        -- NUMBER INPUT
