-- Experiment 17 v22 - smooth RGB theme propagation
-- The legacy theme changed Accent, but active toggle switches cached that color.

return function(Library)
    local RunService = game:GetService("RunService")
    local connections = {}
    local toggleCache = {}
    local rescanTimer = 0

    local function rescanToggles()
        table.clear(toggleCache)
        for _, control in pairs(Library.Controls or {}) do
            if control and control.IsToggle and type(control.RefreshStyle) == "function" then
                toggleCache[#toggleCache + 1] = control
            end
        end
    end

    rescanToggles()

    connections[#connections + 1] = RunService.RenderStepped:Connect(function(dt)
        if Library.Unloaded or not Library.Settings or not Library.Settings.RGBMenuStyle then
            return
        end

        rescanTimer = rescanTimer + dt
        if rescanTimer >= 0.35 then
            rescanTimer = 0
            rescanToggles()
        end

        local speed = math.clamp(tonumber(Library.Settings.RGBSpeed) or 0.12, 0.02, 1)
        local hue = (os.clock() * speed) % 1

        Library.Theme.Accent = Color3.fromHSV(hue, 0.82, 1)
        Library.Theme.Outline = Color3.fromHSV((hue + 0.035) % 1, 0.72, 0.82)
        Library.Theme.Hover = Color3.fromHSV((hue + 0.065) % 1, 0.64, 1)

        if type(Library.RefreshDynamicAccent) == "function" then
            Library:RefreshDynamicAccent()
        end

        for _, control in ipairs(toggleCache) do
            if control and type(control.Get) == "function" then
                local ok, enabled = pcall(function() return control:Get() end)
                if ok and enabled == true then
                    pcall(function() control:RefreshStyle() end)
                end
            end
        end
    end)

    return function()
        for _, connection in ipairs(connections) do
            pcall(function() connection:Disconnect() end)
        end
    end
end
