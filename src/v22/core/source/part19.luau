                TextSize = 11,
                ZIndex = 17,
            })
            Library:BindTheme(Box, "BackgroundColor3", "Control2")
            Library:BindTheme(Box, "TextColor3", "Text")
            Library:BindTheme(Box, "PlaceholderColor3", "SubText")
            Library:RegisterFont(Box)
            if opts.PlaceholderKey then
                Library:BindLocaleText(Box, opts.PlaceholderKey, "PlaceholderText")
            end
            Library:AdaptiveCorner(Box, -2)

            function control:RefreshStyle()
                control:RefreshGate()
                Box.BackgroundTransparency = self.Locked and 0.45 or 0
                Box.TextTransparency = self.Locked and 0.45 or 0
                Box.TextEditable = not self.Locked
            end

            function control:Set(v, silent)
                value = tostring(v or "")
                Box.Text = value
                if self.Flag then Library.Flags[self.Flag] = value end
                if not silent then safeCallback(opts.Callback, value) end
                Library:QueueDependencyRefresh()
            end

            function control:Get()
                return value
            end

            Box.FocusLost:Connect(function()
                if control.Locked then return end
                control:Set(Box.Text)
            end)

            registerFlag(control, opts.Flag, value)
            control:Set(value, true)
            return control
        end

        -- COLOR PICKER (Linoria-style HSV palette)
        function section:AddColorPicker(opts)
            opts = opts or {}
            local themeKey = opts.ThemeKey
            local color = (themeKey and Library.Theme[themeKey]) or opts.Default or Color3.new(1, 1, 1)
            local hue, saturation, brightness = Color3.toHSV(color)
            local expanded = false
            local draggingSV = false
            local draggingHue = false

            local Wrapper = Create("Frame", {
                Parent = Items,
                Size = UDim2.new(1, 0, 0, 42),
                BackgroundTransparency = 1,
                ZIndex = 15,
            })

            local Holder, control = newBaseControl(Wrapper, opts.Name or "Color", opts.RequiredGraphics, 42, opts)

            local Preview = Create("TextButton", {
                Parent = Holder,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -10, 0.5, 0),
                Size = UDim2.fromOffset(62, 24),
                BackgroundColor3 = color,
                BorderSizePixel = 0,
                Text = "",
                ZIndex = 17,
            })
            Library:AdaptiveCorner(Preview, -3)

            local PreviewStroke = Create("UIStroke", {
                Parent = Preview,
                Thickness = 1,
                Transparency = 0.18,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            })
            Library:BindTheme(PreviewStroke, "Color", "Outline")

            local editorScale = Library:GetFunctionDPIScale()
            local Editor = Create("CanvasGroup", {
                Parent = Wrapper,
                Position = UDim2.new((1 - editorScale) * 0.5, 0, 0, 54),
                Size = UDim2.new(editorScale, 0, 0, 154),
                BorderSizePixel = 0,
                BackgroundTransparency = 0,
                GroupTransparency = 1,
                Visible = false,
                ZIndex = 25,
            })
            table.insert(Library.ControlFrames, {
                Object = Editor,
                ManualCenter = true,
            })
            Library:BindTheme(Editor, "BackgroundColor3", "Control")
            Library:AdaptiveCorner(Editor, -1)
            local PickerScale = Create("UIScale", {
                Parent = Editor,
                Scale = 0.975,
            })

            local EditorStroke = Create("UIStroke", {
                Parent = Editor,
                Thickness = 1.15,
                Transparency = 0.20,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            })
            Library:BindTheme(EditorStroke, "Color", "Outline")

            local Palette = Create("Frame", {
                Parent = Editor,
                Position = UDim2.fromOffset(10, 10),
                Size = UDim2.new(1, -54, 0, 134),
                BackgroundColor3 = Color3.fromHSV(hue, 1, 1),
                BorderSizePixel = 0,
                ClipsDescendants = true,
                ZIndex = 26,
            })
            Library:AdaptiveCorner(Palette, -3)

            local WhiteLayer = Create("Frame", {
                Parent = Palette,
                Size = UDim2.fromScale(1, 1),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0,
                ZIndex = 27,
            })
            Create("UIGradient", {
                Parent = WhiteLayer,
                Rotation = 0,
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(1, 1),
                }),
            })

            local BlackLayer = Create("Frame", {
                Parent = Palette,
                Size = UDim2.fromScale(1, 1),
                BackgroundColor3 = Color3.new(0, 0, 0),
                BorderSizePixel = 0,
                ZIndex = 28,
            })
            Create("UIGradient", {
                Parent = BlackLayer,
                Rotation = 90,
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(1, 0),
                }),
            })

            local SVHit = Create("TextButton", {
                Parent = Palette,
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Text = "",
                AutoButtonColor = false,
                ZIndex = 30,
            })

            local SVCursor = Create("Frame", {
                Parent = Palette,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(saturation, 1 - brightness),
                Size = UDim2.fromOffset(8, 8),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0,
                ZIndex = 31,
            })
            Create("UICorner", {Parent = SVCursor, CornerRadius = UDim.new(1, 0)})
            Create("UIStroke", {Parent = SVCursor, Color = Color3.new(0, 0, 0), Thickness = 1})

            local HueBar = Create("Frame", {
                Parent = Editor,
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -10, 0, 10),
                Size = UDim2.fromOffset(24, 134),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0,
                ClipsDescendants = false,
                ZIndex = 26,
            })
            Library:AdaptiveCorner(HueBar, -3)
            Create("UIGradient", {
                Parent = HueBar,
                Rotation = 90,
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
                    ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
                    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                    ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
                    ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
                    ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
                    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
                }),
            })

            local HueHit = Create("TextButton", {
                Parent = HueBar,
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Text = "",
                AutoButtonColor = false,
                ZIndex = 30,
            })

            local HueCursor = Create("Frame", {
                Parent = HueBar,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, hue, 0),
                Size = UDim2.new(1, 6, 0, 3),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0,
                ZIndex = 31,
            })
            Create("UICorner", {Parent = HueCursor, CornerRadius = UDim.new(1, 0)})
            Create("UIStroke", {Parent = HueCursor, Color = Color3.new(0, 0, 0), Thickness = 1})

            local function refreshVisuals()
                Palette.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
                Preview.BackgroundColor3 = color
                SVCursor.Position = UDim2.fromScale(saturation, 1 - brightness)
                HueCursor.Position = UDim2.new(0.5, 0, hue, 0)
            end

            local function commit(silent)
                color = Color3.fromHSV(hue, saturation, brightness)
                refreshVisuals()
                if control.Flag then Library.Flags[control.Flag] = color end
                if not silent then safeCallback(opts.Callback, color) end
                Library:QueueDependencyRefresh()
            end

            local function updateSV(inputPosition)
                if control.Locked then return end
                saturation = math.clamp((inputPosition.X - Palette.AbsolutePosition.X) / math.max(1, Palette.AbsoluteSize.X), 0, 1)
                brightness = 1 - math.clamp((inputPosition.Y - Palette.AbsolutePosition.Y) / math.max(1, Palette.AbsoluteSize.Y), 0, 1)
                commit(false)
            end

            local function updateHue(inputPosition)
                if control.Locked then return end
                hue = math.clamp((inputPosition.Y - HueBar.AbsolutePosition.Y) / math.max(1, HueBar.AbsoluteSize.Y), 0, 1)
                commit(false)
            end

            function control:RefreshStyle()
                control:RefreshGate()
                Preview.BackgroundTransparency = self.Locked and 0.55 or 0
                Editor.BackgroundTransparency = self.Locked and 0.35 or 0
            end

            function control:Set(v, silent)
                if typeof(v) ~= "Color3" then return end
                color = v
                hue, saturation, brightness = Color3.toHSV(color)
                refreshVisuals()
                if self.Flag then Library.Flags[self.Flag] = color end
                if not silent then safeCallback(opts.Callback, color) end
                Library:QueueDependencyRefresh()
            end

            function control:Get()
                return color
            end

            local pickerToken = 0

            function control:ClosePicker()
                if not expanded then return end
                expanded = false
                pickerToken += 1
                local token = pickerToken
                local duration = math.max(0.12, (Library.Settings.AnimationSpeed or 0.18) * 0.8)

                Library:Animate(Editor, duration, {
                    GroupTransparency = 1,
                    Position = UDim2.new(Editor.Position.X.Scale, Editor.Position.X.Offset, 0, 60),
                })
                Library:Animate(PickerScale, duration, {Scale = 0.95})
                Library:Animate(Wrapper, duration, {Size = UDim2.new(1, 0, 0, 42)})

                task.delay(duration + 0.02, function()
