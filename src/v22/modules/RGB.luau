-- Experiment 17 v22 - optimized RGB theme propagation
-- The base core already advances RGB hue on a small timer. This module only
-- propagates the current accent to cached toggle visuals, and does no per-frame
-- scanning/calculation of its own.

return function(Library)
    local rawRefreshDynamicAccent = Library.RefreshDynamicAccent
    if type(rawRefreshDynamicAccent) ~= "function" then
        return
    end

    local toggleCache = {}
    local cachedControlCount = -1

    local function rescanToggles()
        table.clear(toggleCache)

        for _, control in pairs(Library.Controls or {}) do
            if control and control.IsToggle and type(control.RefreshStyle) == "function" then
                toggleCache[#toggleCache + 1] = control
            end
        end

        cachedControlCount = #(Library.Controls or {})
    end

    local function refreshActiveToggles()
        local controls = Library.Controls or {}
        if #controls ~= cachedControlCount then
            rescanToggles()
        end

        for _, control in ipairs(toggleCache) do
            if control and type(control.Get) == "function" then
                local ok, enabled = pcall(function()
                    return control:Get()
                end)

                if ok and enabled == true then
                    pcall(function()
                        control:RefreshStyle()
                    end)
                end
            end
        end
    end

    rescanToggles()

    function Library:RefreshDynamicAccent(...)
        if self.Unloaded then
            return
        end

        -- The GUI itself is not visible when MenuVisible is false. Skipping
        -- all binding/toggle propagation here removes the expensive RGB work
        -- while the player is actually playing with the menu closed.
        if not self.MenuVisible then
            return
        end

        local result = rawRefreshDynamicAccent(self, ...)
        refreshActiveToggles()
        return result
    end

    return function()
        Library.RefreshDynamicAccent = rawRefreshDynamicAccent
        table.clear(toggleCache)
    end
end
