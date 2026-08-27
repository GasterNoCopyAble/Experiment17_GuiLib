-- Experiment 17 Legacy v22 - color picker RGB easter egg
-- Double-click / double-tap a color preview to toggle RGB mode.
-- The preview visibly cycles instead of pretending RGB is a static Color3.

return function(Library)
    local RunService = game:GetService("RunService")

    local decorated = setmetatable({}, {__mode="k"})
    local rgbControls = setmetatable({}, {__mode="k"})
    local connections = {}
    local controlCount = -1
    local phaseSeed = 0
    local accumulator = 0
    local rawApplyThemePreset = Library.ApplyThemePreset

    local THEME_FLAGS = {
        UI_AccentColor = "Accent",
        UI_BackgroundColor = "Background",
        UI_OutlineColor = "Outline",
        UI_ControlColor = "Control",
        UI_HoverColor = "Hover",
    }

    local function getColor(control)
        if not control or type(control.Get) ~= "function" then return nil end
        local ok, value = pcall(function() return control:Get() end)
        if ok and typeof(value) == "Color3" then return value end
        return nil
    end

    local function findPreview(control)
        local holder = control and control.Holder
        if not holder then return nil end

        for _, child in ipairs(holder:GetChildren()) do
            if child:IsA("TextButton") and child.Text == "" then
                return child
            end
        end
        return nil
    end

    local function decorate(control)
        if not control or decorated[control] then return end
        if not getColor(control) then return end

        local preview = findPreview(control)
        if not preview then return end

        decorated[control] = true
        phaseSeed += 0.137

        local badge = Instance.new("TextLabel")
        badge.Name = "E17_RGBBadge"
        badge.Parent = preview
        badge.Size = UDim2.fromScale(1,1)
        badge.BackgroundTransparency = 1
        badge.Text = "RGB"
        badge.TextSize = 8
        badge.TextTransparency = 0.08
        badge.Visible = false
        badge.ZIndex = preview.ZIndex + 2

        if type(Library.BindTheme) == "function" then
            Library:BindTheme(badge,"TextColor3","Text")
        else
            badge.TextColor3 = Color3.new(1,1,1)
        end
        if type(Library.RegisterFont) == "function" then
            Library:RegisterFont(badge,true)
        end

        local state = {
            Control = control,
            Preview = preview,
            Badge = badge,
            Enabled = false,
            Phase = phaseSeed % 1,
        }
        rgbControls[control] = state

        function control:SetRGBMode(enabled)
            state.Enabled = enabled == true
            state.Badge.Visible = state.Enabled
            state.Preview:SetAttribute("E17RGBColorPicker", state.Enabled)
        end

        function control:IsRGBMode()
            return state.Enabled
        end

        local lastActivation = 0
        connections[#connections+1] = preview.Activated:Connect(function()
            if Library.Unloaded or control.Locked then return end

            local now = os.clock()
            if now - lastActivation <= 0.34 then
                control:SetRGBMode(not state.Enabled)
                -- Two normal preview clicks already open then close the picker;
                -- force the hidden gesture to finish in the compact state.
                if type(control.ClosePicker) == "function" then
                    pcall(function() control:ClosePicker() end)
                end
                lastActivation = 0
            else
                lastActivation = now
            end
        end)
    end

    local function scanControls()
        local controls = Library.Controls or {}
        if #controls == controlCount then return end
        controlCount = #controls
        for _, control in ipairs(controls) do
            decorate(control)
        end
    end

    local function disableGradientPickerRGB()
        local controls = Library.ControlsByFlag or {}
        for _, flag in ipairs({"UI_GradientColorA", "UI_GradientColorB"}) do
            local control = controls[flag]
            if control and type(control.SetRGBMode) == "function" then
                control:SetRGBMode(false)
            end
        end
    end

    scanControls()

    -- A named theme/gradient pair is authoritative. If a custom gradient color
    -- was left in RGB mode, selecting a pair turns that hidden mode off instead
    -- of having it switch the gradient back to Custom on the next frame.
    if type(rawApplyThemePreset) == "function" then
        function Library:ApplyThemePreset(name, ...)
            disableGradientPickerRGB()
            return rawApplyThemePreset(self, name, ...)
        end
    end

    connections[#connections+1] = RunService.RenderStepped:Connect(function(dt)
        if Library.Unloaded then return end
        scanControls()

        accumulator += dt
        if accumulator < 0.055 then return end
        accumulator = 0

        -- Preserve the library's hidden-menu performance rule. RGB picker modes
        -- resume immediately when the Legacy GUI becomes visible again.
        if not Library.MenuVisible then return end

        local speed = math.clamp(tonumber(Library.Settings.RGBSpeed) or 0.12,0.02,1)
        local now = os.clock()
        local themeChanged = false
        local gradientChanged = false

        for control, state in pairs(rgbControls) do
            if state.Enabled and control and control.Holder and control.Holder.Parent then
                local hue = (now * speed + state.Phase) % 1
                local color = Color3.fromHSV(hue,0.90,1)
                local flag = control.Flag
                local themeKey = THEME_FLAGS[flag]

                if flag == "UI_GradientColorA" or flag == "UI_GradientColorB" then
                    control:Set(color,true)
                    if flag == "UI_GradientColorA" then
                        Library.Settings.GradientColorA = color
                    else
                        Library.Settings.GradientColorB = color
                    end
                    Library.Settings.GradientPreset = "Custom"
                    gradientChanged = true
                elseif themeKey then
                    control:Set(color,true)
                    Library.Theme[themeKey] = color
                    themeChanged = true
                else
                    -- Public/user color pickers keep their normal callback model.
                    control:Set(color,false)
                end

                state.Badge.Visible = true
            end
        end

        if themeChanged and type(Library.RefreshTheme) == "function" then
            Library:RefreshTheme()
        end
        if gradientChanged and type(Library.RefreshGradients) == "function" then
            Library:RefreshGradients()
        end
    end)

    Library.RGBColorPickers = rgbControls

    return function()
        for _, connection in ipairs(connections) do
            pcall(function() connection:Disconnect() end)
        end

        for control, state in pairs(rgbControls) do
            if control then
                control.SetRGBMode = nil
                control.IsRGBMode = nil
            end
            if state.Badge and state.Badge.Parent then
                state.Badge:Destroy()
            end
        end
        if rawApplyThemePreset then
            Library.ApplyThemePreset = rawApplyThemePreset
        end
        Library.RGBColorPickers = nil
    end
end
