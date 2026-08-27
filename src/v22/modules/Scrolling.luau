-- Experiment 17 v22 - scrollbar styling
-- Gives tab/page scrolling a subtle inset rail with more breathing room.

return function(Library)
    local Root = Library.Root
    if not Root then return end

    local connections = {}

    local function style(frame, isTabList)
        if not frame or not frame:IsA("ScrollingFrame") then return end

        frame.ScrollBarThickness = isTabList and 3 or 3
        frame.ScrollBarImageTransparency = isTabList and 0.42 or 0.52
        frame.VerticalScrollBarInset = Enum.ScrollBarInset.Always

        if type(Library.BindTheme) == "function" then
            Library:BindTheme(frame, "ScrollBarImageColor3", "Outline")
        else
            frame.ScrollBarImageColor3 = Library.Theme.Outline
        end

        local padding = frame:FindFirstChildOfClass("UIPadding")
        if padding then
            if isTabList then
                padding.PaddingRight = UDim.new(0, 12)
            else
                padding.PaddingRight = UDim.new(0, 16)
            end
        end
    end

    if Library.TabList then
        style(Library.TabList, true)
    end

    for _, tab in ipairs(Library.Tabs or {}) do
        if tab.Page then
            style(tab.Page, false)
        end
    end

    connections[#connections+1] = Root.DescendantAdded:Connect(function(object)
        if not object:IsA("ScrollingFrame") then return end
        task.defer(function()
            if not object.Parent then return end
            style(object, object == Library.TabList)
        end)
    end)

    -- Newly created tabs get their own ScrollingFrame after CreateTab returns.
    local rawCreateTab = Library.CreateTab
    if type(rawCreateTab) == "function" then
        function Library:CreateTab(...)
            local tab = rawCreateTab(self, ...)
            if tab and tab.Page then
                style(tab.Page, false)
            end
            return tab
        end
    end

    return function()
        for _, connection in ipairs(connections) do
            pcall(function() connection:Disconnect() end)
        end
        if rawCreateTab then
            Library.CreateTab = rawCreateTab
        end
    end
end
