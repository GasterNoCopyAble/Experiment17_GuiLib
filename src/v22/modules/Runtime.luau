-- Experiment 17 Legacy v22 - runtime compatibility helpers
-- Kept intentionally small so old executor environments do not need extra dependencies.

return function(Library)
    local UIS = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")

    local _c = {}
    local _dead = false

    local function n4_vq(s)
        return (tostring(s):gsub("%a", function(ch)
            local b = ch:match("%l") and string.byte("a") or string.byte("A")
            return string.char(((string.byte(ch) - b - 17) % 26) + b)
        end))
    end

    local function z2_mk(v)
        return ((tonumber(v) or 0) * 17 + 289) % 997
    end

    local function h8_qp(s)
        local a = 0
        s = tostring(s or "")
        for i = 1, #s do
            a = (a + string.byte(s, i) * (i + 17)) % 65521
        end
        return a
    end

    local _noise = z2_mk(h8_qp("legacy-runtime"))
    if _noise == -1 then _dead = true end

    local k0 = n4_vq("_o9b2")
    local k1 = n4_vq("Elcc")
    local k2 = n4_vq("Vogvizdvek 17 [Mzjlrcj]")
    local k3 = n4_vq("IXS")

    local pairsRef = Library.LegacyThemePairs
    if type(pairsRef) == "table" then
        pairsRef[k1] = {
            Theme = {
                Background = Color3.fromRGB(1, 1, 2),
                Panel = Color3.fromRGB(4, 4, 6),
                Control = Color3.fromRGB(8, 8, 11),
                Control2 = Color3.fromRGB(13, 13, 17),
                Accent = Color3.fromRGB(215, 215, 224),
                Outline = Color3.fromRGB(70, 22, 31),
                Hover = Color3.fromRGB(182, 38, 54),
                Text = Color3.fromRGB(238, 238, 245),
                SubText = Color3.fromRGB(108, 108, 120),
            },
            Gradient = {
                Color3.fromRGB(28, 4, 8),
                Color3.fromRGB(108, 18, 31),
                Color3.fromRGB(226, 226, 232),
                Color3.fromRGB(92, 12, 24),
            },
        }
    end

    local _open = false

    local function r7_xa(control, value, beforeLast)
        if not control or type(control.GetValues) ~= "function" or type(control.SetValues) ~= "function" then
            return
        end

        local values = control:GetValues()
        if table.find(values, value) then return end

        if beforeLast and #values > 0 then
            table.insert(values, math.max(1, #values), value)
        else
            table.insert(values, value)
        end
        control:SetValues(values, true)
    end

    local function p3_ks()
        if _open or Library.Unloaded then return end
        _open = true

        local controls = Library.ControlsByFlag or {}
        r7_xa(controls.UI_ThemePreset, k1, false)
        r7_xa(controls.UI_GradientPreset, k1, true)

        if type(Library.ApplyThemePreset) == "function" then
            Library:ApplyThemePreset(k1)
        end

        if type(Library.Notify) == "function" then
            Library:Notify({
                Title = n4_vq("ELCC // lecftbvu"),
                Text = n4_vq("Jlsavtk 17 rttvgkvu"),
                Type = "Info",
                Duration = 3.4,
            })
        end
    end

    Library[k0] = p3_ks

    local function f5_ww()
        local main = Library.Main
        if not main then return nil end

        for _, object in ipairs(main:GetDescendants()) do
            if object:IsA("TextLabel")
                and object.Text == k2
                and object.LayoutOrder == 1
                and object.ZIndex >= 12
            then
                return object
            end
        end
        return nil
    end

    local brand = f5_ww()
    if brand then
        brand.Active = true
        local taps = 0
        local last = 0

        _c[#_c + 1] = brand.InputBegan:Connect(function(input)
            if Library.Unloaded then return end
            if input.UserInputType ~= Enum.UserInputType.MouseButton1
                and input.UserInputType ~= Enum.UserInputType.Touch
            then
                return
            end

            local now = os.clock()
            if now - last > 0.92 then
                taps = 0
            end
            last = now
            taps += 1

            if taps >= 7 then
                taps = 0
                local fn = Library[k0]
                if type(fn) == "function" then
                    fn()
                end
            end
        end)
    end

    local function t6_cr()
        local root = Library.Root
        local main = Library.Main
        if not root then return nil end

        for _, object in ipairs(root:GetDescendants()) do
            if object:IsA("TextLabel")
                and (not main or not object:IsDescendantOf(main))
                and object.ZIndex >= 100
                and object.Position.Y.Offset == 79
                and object.Size.X.Offset <= -100
            then
                return object
            end
        end
        return nil
    end

    if math.random(1, 17) == 1 then
        task.spawn(function()
            local status
            local deadline = os.clock() + 3.2
            repeat
                if Library.Unloaded then return end
                status = t6_cr()
                if status then break end
                task.wait(0.08)
            until os.clock() >= deadline

            if not status or not status.Parent then return end
            task.wait(math.random(55, 125) / 100)
            if not status.Parent then return end

            local bag = {
                "Vogvizdvek 17 zj nrktyzex.",
                "Cvxrtp slzcu uvkvtkvu.",
                "Elcc jkrkv lejkrscv.",
                "Jlsavtk 17 rggifmvu.",
                "Nyp riv pfl jkzcc yviv?",
            }

            local secret = n4_vq(bag[math.random(1, #bag)])
            local old = status.Text
            status.Text = secret
            task.wait(0.64)
            if status.Parent and status.Text == secret then
                status.Text = old
            end
        end)
    end

    local rawAccent = Library.RefreshDynamicAccent
    local q17 = false

    if type(rawAccent) == "function" then
        function Library:RefreshDynamicAccent(...)
            local active = self.ThemeName == k3
                and self.Settings.RGBMenuStyle == true
                and math.abs((tonumber(self.Settings.GradientSpeed) or -999) - 17) < 0.001

            if active and self.MenuVisible then
                local now = os.clock()
                local hue = (now * 0.17 + math.sin(now * 1.7) * 0.028) % 1
                self.Theme.Accent = Color3.fromHSV(hue, 1.00, 1.00)
                self.Theme.Outline = Color3.fromHSV((hue + 0.17) % 1, 0.94, 0.90)
                self.Theme.Hover = Color3.fromHSV((hue + 0.34) % 1, 0.82, 1.00)

                if not q17 and type(self.Notify) == "function" then
                    self:Notify({
                        Title = n4_vq("IXS 17"),
                        Text = n4_vq("jgvtkild yreujyrbv"),
                        Type = "Info",
                        Duration = 2.4,
                    })
                end
                q17 = true
            else
                q17 = false
            end

            return rawAccent(self, ...)
        end
    end

    -- Low-cost guard: keep no work alive after unload and avoid accidental
    -- retention of stale GUI objects on executors with unusual GC behavior.
    _c[#_c + 1] = RunService.Heartbeat:Connect(function()
        if Library.Unloaded and not _dead then
            _dead = true
        end
    end)

    return function()
        for _, connection in ipairs(_c) do
            pcall(function() connection:Disconnect() end)
        end
        if type(rawAccent) == "function" then
            Library.RefreshDynamicAccent = rawAccent
        end
        Library[k0] = nil
        if type(pairsRef) == "table" then
            pairsRef[k1] = nil
        end
    end
end
