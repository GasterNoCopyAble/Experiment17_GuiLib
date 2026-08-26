                    if pickerToken == token and not expanded and Editor.Parent then
                        Editor.Visible = false
                    end
                end)
            end

            local function openPicker()
                if control.Locked or expanded then return end
                expanded = true
                pickerToken += 1
                Editor.Visible = true
                Editor.GroupTransparency = 1
                Editor.Position = UDim2.new(Editor.Position.X.Scale, Editor.Position.X.Offset, 0, 54)
                PickerScale.Scale = 0.95

                local duration = math.max(0.12, (Library.Settings.AnimationSpeed or 0.18) * 0.8)
                Library:Animate(Wrapper, duration, {Size = UDim2.new(1, 0, 0, 202)})
                Library:Animate(Editor, duration, {
                    GroupTransparency = 0,
                    Position = UDim2.new(Editor.Position.X.Scale, Editor.Position.X.Offset, 0, 48),
                })
                Library:Animate(PickerScale, duration, {Scale = 1})
            end

            Preview.MouseButton1Click:Connect(function()
                if control.Locked then return end
                if expanded then
                    control:ClosePicker()
                else
                    openPicker()
                end
            end)

            local pickerInputType = nil

            SVHit.InputBegan:Connect(function(input)
                if control.Locked then return end

                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch
                then
                    draggingSV = true
                    draggingHue = false
                    pickerInputType = input.UserInputType
                    updateSV(input.Position)
                end
            end)

            HueHit.InputBegan:Connect(function(input)
                if control.Locked then return end

                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch
                then
                    draggingHue = true
                    draggingSV = false
                    pickerInputType = input.UserInputType
                    updateHue(input.Position)
                end
            end)

            UIS.InputChanged:Connect(function(input)
                if Library.Unloaded or (not draggingSV and not draggingHue) then return end

                local valid =
                    (pickerInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseMovement)
                    or
                    (pickerInputType == Enum.UserInputType.Touch and input.UserInputType == Enum.UserInputType.Touch)

                if not valid then return end

                if draggingSV then
                    updateSV(input.Position)
                elseif draggingHue then
                    updateHue(input.Position)
                end
            end)

            UIS.InputEnded:Connect(function(input)
                if Library.Unloaded then return end

                local valid =
                    (pickerInputType == Enum.UserInputType.MouseButton1 and input.UserInputType == Enum.UserInputType.MouseButton1)
                    or
                    (pickerInputType == Enum.UserInputType.Touch and input.UserInputType == Enum.UserInputType.Touch)

                if valid then
                    draggingSV = false
                    draggingHue = false
                    pickerInputType = nil
                end
            end)

            registerFlag(control, opts.Flag, color)
            control:Set(color, true)
            if themeKey and Library.Theme[themeKey] then
                table.insert(Library.ThemeColorControls, {
                    Key = themeKey,
                    Control = control,
                })
                control:Set(Library.Theme[themeKey], true)
            end
            return control
        end

        -- MULTI DROPDOWN
        function section:AddMultiChoice(opts)
            opts = opts or {}

            local values = opts.Values or {"None"}
            local selected = {}
            local default = opts.Default or {}
            local open = false

            for _, item in ipairs(default) do
                if table.find(values, item) then
                    selected[item] = true
                end
            end

            local CLOSED_HEIGHT = 42
            local OPTION_HEIGHT = 28
            local OPTIONS_PADDING = 6
            local optionsHeight = (#values * OPTION_HEIGHT) + OPTIONS_PADDING * 2

            local Holder, control = newBaseControl(
                Items,
                opts.Name or "Multi Choice",
                opts.RequiredGraphics,
                CLOSED_HEIGHT,
                opts
            )

            Holder.ClipsDescendants = true
            control.Requirement.Position = UDim2.new(1, -168, 0.5, 0)

            local Select = Create("TextButton", {
                Parent = Holder,
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -10, 0, 8),
                Size = UDim2.fromOffset(148, 26),
                BackgroundColor3 = Library.Theme.Control2,
                BorderSizePixel = 0,
                TextColor3 = Library.Theme.Text,
                TextSize = 10,
                TextTruncate = Enum.TextTruncate.AtEnd,
                AutoButtonColor = false,
                ZIndex = 19,
            })
            Library:RegisterFont(Select)
            Library:AdaptiveCorner(Select, -2)

            local OptionsFrame = Create("CanvasGroup", {
                Parent = Holder,
                Position = UDim2.fromOffset(10, CLOSED_HEIGHT + 8),
                Size = UDim2.new(1, -20, 0, math.max(OPTION_HEIGHT, optionsHeight - 6)),
                BackgroundColor3 = Library.Theme.Panel,
                BorderSizePixel = 0,
                GroupTransparency = 1,
                Visible = false,
                ZIndex = 30,
            })
            Library:AdaptiveCorner(OptionsFrame, -2)

            Create("UIStroke", {
                Parent = OptionsFrame,
                Thickness = 1.1,
                Transparency = 0.18,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
                Color = Library.Theme.Outline,
            })

            local OptionsScale = Create("UIScale", {
                Parent = OptionsFrame,
                Scale = 1,
            })

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
            })

            local optionRows = {}

            local function getArray()
                local result = {}
                for _, item in ipairs(values) do
                    if selected[item] then
                        table.insert(result, item)
                    end
                end
                return result
            end

            local function refreshSelect()
                local result = getArray()
                local textValue

                if #result == 0 then
                    textValue = "None"
                elseif #result <= 2 then
                    textValue = table.concat(result, ", ")
                else
                    textValue = tostring(#result) .. " selected"
                end

                Select.Text = textValue .. (open and "  ^" or "  v")
            end

            local function refreshRows()
                for _, row in ipairs(optionRows) do
                    local active = selected[row.Value] == true
                    row.Check.Text = active and "x" or ""
                    row.Check.BackgroundColor3 = active and Library.Theme.Accent or Library.Theme.Control2
                    row.Button.TextColor3 = active and Library.Theme.Accent or Library.Theme.Text
                    row.Button.BackgroundTransparency = active and 0.12 or 1
                end
            end

            function control:Set(v, silent)
                selected = {}

                if type(v) == "table" then
                    for _, item in ipairs(v) do
                        if table.find(values, item) then
                            selected[item] = true
                        end
                    end
                end

                refreshSelect()
                refreshRows()

                local result = getArray()
                if self.Flag then
                    Library.Flags[self.Flag] = result
                end

                if not silent then
                    safeCallback(opts.Callback, result)
                end

                Library:QueueDependencyRefresh()
            end

            function control:Get()
                return getArray()
            end

            function control:CloseDropdown()
                if not open then return end
                open = false

                Select.Text = (Select.Text:gsub("%s+%^$", "")) .. "  v"

                local duration = math.max(0.14, (Library.Settings.AnimationSpeed or 0.18) * 0.85)

                Library:Animate(OptionsFrame, duration, {
                    GroupTransparency = 1,
                    Position = UDim2.fromOffset(10, CLOSED_HEIGHT + 9),
                })
                Library:Animate(OptionsScale, duration, {Scale = 0.92})
                Library:Animate(Holder, duration, {
                    Size = UDim2.new(Library:GetFunctionDPIScale(), 0, 0, CLOSED_HEIGHT),
                })

                task.delay(duration + 0.02, function()
                    if not open and OptionsFrame.Parent then
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

                if Library.ActiveDropdown
                    and Library.ActiveDropdown ~= self
                    and Library.ActiveDropdown.CloseDropdown
                then
                    Library.ActiveDropdown:CloseDropdown()
                end

                open = true
                Library.ActiveDropdown = self

                OptionsFrame.Visible = true
                OptionsFrame.GroupTransparency = 1
                OptionsFrame.Position = UDim2.fromOffset(10, CLOSED_HEIGHT + 18)
                OptionsScale.Scale = 0.88
                refreshSelect()

                local duration = math.max(0.16, (Library.Settings.AnimationSpeed or 0.18) * 0.95)

                Library:Animate(Holder, duration, {
                    Size = UDim2.new(
                        Library:GetFunctionDPIScale(),
                        0,
                        0,
                        CLOSED_HEIGHT + optionsHeight
                    ),
                })

                Library:Animate(OptionsFrame, duration, {
