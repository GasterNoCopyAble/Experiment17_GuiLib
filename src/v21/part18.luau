                if not open then return end
                open = false
                dropdownToken += 1
                local token = dropdownToken
                local duration = math.max(0.12, (Library.Settings.AnimationSpeed or 0.18) * 0.75)

                Select.Text = tostring(value) .. "  v"
                Library:Animate(OptionsFrame, duration, {
                    GroupTransparency = 1,
                    Position = UDim2.fromOffset(10, CLOSED_HEIGHT + 7),
                })
                Library:Animate(OptionsScale, duration, {Scale = 0.92})
                Library:Animate(Holder, duration, {
                    Size = UDim2.new(Library:GetFunctionDPIScale(), 0, 0, CLOSED_HEIGHT),
                })

                task.delay(duration + 0.02, function()
                    if dropdownToken == token and not open and OptionsFrame.Parent then
                        OptionsFrame.Visible = false
                        OptionsScale.Scale = 1
                    end
                end)

                if Library.ActiveDropdown == self then
                    Library.ActiveDropdown = nil
                end
            end

            function control:OpenDropdown()
                if self.Locked or open then return end

                if Library.ActiveDropdown and Library.ActiveDropdown ~= self and Library.ActiveDropdown.CloseDropdown then
                    Library.ActiveDropdown:CloseDropdown()
                end

                open = true
                dropdownToken += 1
                Library.ActiveDropdown = self
                OptionsFrame.Visible = true
                OptionsFrame.GroupTransparency = 1
                OptionsFrame.Position = UDim2.fromOffset(10, CLOSED_HEIGHT + 18)
                OptionsScale.Scale = 0.88
                Select.Text = tostring(value) .. "  ^"

                local duration = math.max(0.14, (Library.Settings.AnimationSpeed or 0.18) * 0.90)
                Library:Animate(Holder, duration, {
                    Size = UDim2.new(Library:GetFunctionDPIScale(), 0, 0, CLOSED_HEIGHT + optionsHeight),
                })
                Library:Animate(OptionsFrame, duration, {
                    GroupTransparency = 0,
                    Position = UDim2.fromOffset(10, CLOSED_HEIGHT),
                })
                Library:Animate(OptionsScale, duration, {Scale = 1})
            end

            local function rebuildOptions()
                for _, item in ipairs(optionButtons) do
                    if item.Button and item.Button.Parent then
                        item.Button:Destroy()
                    end
                end
                table.clear(optionButtons)

                optionsHeight = (#values * OPTION_HEIGHT) + OPTIONS_PADDING * 2
                OptionsFrame.Size = UDim2.new(1, -20, 0, math.max(OPTION_HEIGHT, optionsHeight - 6))

                for _, optionValue in ipairs(values) do
                    local option = optionValue
                    local OptionButton = Create("TextButton", {
                        Parent = OptionsInner,
                        Size = UDim2.new(1, 0, 0, OPTION_HEIGHT),
                        BackgroundTransparency = 1,
                        BorderSizePixel = 0,
                        Text = tostring(option),
                        TextSize = 11,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        AutoButtonColor = false,
                        ZIndex = 32,
                    })
                    Library:BindTheme(OptionButton, "TextColor3", "Text")
                    Library:RegisterFont(OptionButton)
                    Library:AdaptiveCorner(OptionButton, -4)

                    Create("UIPadding", {
                        Parent = OptionButton,
                        PaddingLeft = UDim.new(0, 9),
                    })

                    table.insert(optionButtons, {
                        Button = OptionButton,
                        Value = option,
                    })

                    OptionButton.MouseButton1Click:Connect(function()
                        if control.Locked then return end
                        control:Set(option)
                        control:CloseDropdown()
                    end)

                    OptionButton.MouseEnter:Connect(function()
                        if option ~= value then
                            OptionButton.BackgroundTransparency = 0.65
                        end
                    end)

                    OptionButton.MouseLeave:Connect(function()
                        refreshOptionStyles()
                    end)
                end

                refreshOptionStyles()
            end

            function control:SetValues(newValues, keepValue)
                if type(newValues) ~= "table" or #newValues == 0 then
                    newValues = {"None"}
                end

                values = {}
                for _, item in ipairs(newValues) do
                    table.insert(values, item)
                end

                if not keepValue or not table.find(values, value) then
                    value = values[1]
                end

                rebuildOptions()
                self:Set(value, true)
            end

            function control:GetValues()
                local copy = {}
                for _, item in ipairs(values) do
                    table.insert(copy, item)
                end
                return copy
            end

            rebuildOptions()

            Select.MouseButton1Click:Connect(function()
                if control.Locked then return end
                if open then
                    control:CloseDropdown()
                else
                    control:OpenDropdown()
                end
            end)

            registerFlag(control, opts.Flag, value)
            control:Set(value, true)
            return control
        end

        -- KEYBIND
        function section:AddKeybind(opts)
            opts = opts or {}
            local value = tostring(opts.Default or "RightShift")
            if not Enum.KeyCode[value] then
                value = "RightShift"
            end

            local listening = false
            local mode = tostring(opts.Mode or "Press")
            local Holder, control = newBaseControl(Items, opts.Name or "Keybind", opts.RequiredGraphics, 42, opts)
            control.Requirement.Position = UDim2.new(1, -150, 0.5, 0)

            local BindButton = Create("TextButton", {
                Parent = Holder,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -10, 0.5, 0),
                Size = UDim2.fromOffset(128, 26),
                BorderSizePixel = 0,
                TextSize = 11,
                AutoButtonColor = false,
                ZIndex = 19,
            })
            Library:BindTheme(BindButton, "BackgroundColor3", "Control2")
            Library:BindTheme(BindButton, "TextColor3", "Text")
            Library:RegisterFont(BindButton, true)
            Library:AdaptiveCorner(BindButton, -2)

            function control:RefreshStyle()
                control:RefreshGate()
                BindButton.BackgroundTransparency = self.Locked and 0.45 or 0
                BindButton.TextTransparency = self.Locked and 0.45 or 0
            end

            function control:Set(v, silent)
                local keyName
                if typeof(v) == "EnumItem" and v.EnumType == Enum.KeyCode then
                    keyName = v.Name
                else
                    keyName = tostring(v)
                end

                if not Enum.KeyCode[keyName] or Enum.KeyCode[keyName] == Enum.KeyCode.Unknown then
                    return
                end

                value = keyName
                BindButton.Text = value
                if self.Flag then Library.Flags[self.Flag] = value end
                if not silent then safeCallback(opts.Callback, value, Enum.KeyCode[value]) end
                Library:QueueDependencyRefresh()
            end

            function control:Get()
                return value
            end

            local function stopListening(cancelled)
                listening = false
                if Library.BindingKey == control then
                    Library.BindingKey = nil
                end
                BindButton.Text = value
                if not cancelled then
                    Library.SuppressMenuKey = true
                    task.delay(0.18, function()
                        Library.SuppressMenuKey = false
                    end)
                end
            end

            BindButton.MouseButton1Click:Connect(function()
                if control.Locked then return end
                if Library.ActiveDropdown and Library.ActiveDropdown.CloseDropdown then
                    Library.ActiveDropdown:CloseDropdown()
                end
                listening = true
                Library.BindingKey = control
                BindButton.Text = "press key..."
            end)

            UIS.InputBegan:Connect(function(input)
                if Library.Unloaded then return end
                if not listening or Library.BindingKey ~= control then return end
                if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
                if input.KeyCode == Enum.KeyCode.Unknown then return end

                if input.KeyCode == Enum.KeyCode.Escape then
                    stopListening(true)
                    return
                end

                local keyName = input.KeyCode.Name
                control:Set(keyName)
                stopListening(false)
            end)

            registerFlag(control, opts.Flag, value)
            control:Set(value, true)

            local registryEntry = Library:CreateKeybind({
                Name = opts.Name or "Keybind",
                Key = value,
                Mode = mode,
                Callback = function(...)
                    safeCallback(opts.OnTriggered or opts.Action, ...)
                end,
            })
            control.RegistryEntry = registryEntry

            local baseSet = control.Set
            function control:Set(v, silent)
                baseSet(self, v, silent)
                registryEntry:SetKey(value)
                Library:RefreshKeybindList()
            end

            function control:SetMode(newMode)
                mode = tostring(newMode or "Press")
                registryEntry.Mode = mode
                Library:RefreshKeybindList()
            end

            function control:GetMode()
                return mode
            end

            return control
        end

        -- INPUT
        function section:AddInput(opts)
            opts = opts or {}
            local value = tostring(opts.Default or "")
            local Holder, control = newBaseControl(Items, opts.Name or "Input", opts.RequiredGraphics, 42, opts)
            control.Requirement.Position = UDim2.new(1, -175, 0.5, 0)

            local Box = Create("TextBox", {
                Parent = Holder,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -10, 0.5, 0),
                Size = UDim2.fromOffset(155, 26),
                BorderSizePixel = 0,
                Text = value,
                PlaceholderText = opts.Placeholder or "...",
                ClearTextOnFocus = false,
