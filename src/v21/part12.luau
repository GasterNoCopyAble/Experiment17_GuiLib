Library:RegisterFont(FavoritesButton, true)
Library:AdaptiveCorner(FavoritesButton, -2)

local FavoritesPanel = Create("Frame", {
    Parent = Root,
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -288, 1, 3),
    Size = UDim2.fromOffset(250, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundColor3 = Library.Theme.Panel,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 610,
})
Library:AdaptiveCorner(FavoritesPanel, -2)
Create("UIStroke", {
    Parent = FavoritesPanel,
    Thickness = 1.1,
    Transparency = 0.12,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    Color = Library.Theme.Outline,
})

local FavoritesInner = Create("Frame", {
    Parent = FavoritesPanel,
    Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
    ZIndex = 611,
})
Create("UIPadding", {
    Parent = FavoritesInner,
    PaddingTop = UDim.new(0, 6),
    PaddingBottom = UDim.new(0, 6),
    PaddingLeft = UDim.new(0, 6),
    PaddingRight = UDim.new(0, 6),
})
Create("UIListLayout", {
    Parent = FavoritesInner,
    Padding = UDim.new(0, 3),
    SortOrder = Enum.SortOrder.LayoutOrder,
})

local TOPBAR_POPUP_GAP_Y = 76
local SEARCH_POPUP_SHIFT_X = 38
local FAVORITES_POPUP_SHIFT_X = 70

local function updateTopbarPopupPositions()
    if SearchBox and SearchBox.Parent then
        local p = SearchBox.AbsolutePosition
        local s = SearchBox.AbsoluteSize

        SearchResultsFrame.AnchorPoint = Vector2.new(1, 0)
        SearchResultsFrame.Position = UDim2.fromOffset(
            p.X + s.X + SEARCH_POPUP_SHIFT_X,
            p.Y + s.Y + TOPBAR_POPUP_GAP_Y
        )

        SearchResultsFrame.Size = UDim2.fromOffset(
            math.max(235, s.X + 72),
            0
        )
    end

    if FavoritesButton and FavoritesButton.Parent then
        local p = FavoritesButton.AbsolutePosition
        local s = FavoritesButton.AbsoluteSize

        FavoritesPanel.AnchorPoint = Vector2.new(1, 0)
        FavoritesPanel.Position = UDim2.fromOffset(
            p.X + s.X + FAVORITES_POPUP_SHIFT_X,
            p.Y + s.Y + TOPBAR_POPUP_GAP_Y
        )
    end
end

RunService.RenderStepped:Connect(function()
    if Library.Unloaded then return end

    if SearchResultsFrame.Visible or FavoritesPanel.Visible then
        updateTopbarPopupPositions()
    end
end)

local ContextMenu = Create("Frame", {
    Parent = Root,
    Size = UDim2.fromOffset(190, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundColor3 = Library.Theme.Panel,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 650,
})
Library:AdaptiveCorner(ContextMenu, -2)
Create("UIStroke", {
    Parent = ContextMenu,
    Thickness = 1.1,
    Transparency = 0.10,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    Color = Library.Theme.Outline,
})

local ContextInner = Create("Frame", {
    Parent = ContextMenu,
    Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
    ZIndex = 651,
})
Create("UIPadding", {
    Parent = ContextInner,
    PaddingTop = UDim.new(0, 5),
    PaddingBottom = UDim.new(0, 5),
    PaddingLeft = UDim.new(0, 5),
    PaddingRight = UDim.new(0, 5),
})
Create("UIListLayout", {
    Parent = ContextInner,
    Padding = UDim.new(0, 2),
    SortOrder = Enum.SortOrder.LayoutOrder,
})

local function clearChildrenExceptLayouts(parent)
    for _, child in ipairs(parent:GetChildren()) do
        if not child:IsA("UIListLayout") and not child:IsA("UIPadding") then
            child:Destroy()
        end
    end
end

function Library:NavigateToControl(control)
    if not control or not control.Holder or not control.Holder.Parent then
        return
    end

    if control.Tab and control.Tab.Select then
        control.Tab:Select()
    end

    if control.Section and control.Section.SetOpen then
        control.Section:SetOpen(true)
    end

    task.delay(0.08, function()
        if not control.Holder or not control.Holder.Parent or not control.Tab or not control.Tab.Page then
            return
        end

        local page = control.Tab.Page
        local relativeY = control.Holder.AbsolutePosition.Y - page.AbsolutePosition.Y + page.CanvasPosition.Y
        page.CanvasPosition = Vector2.new(0, math.max(0, relativeY - 70))

        local original = Library.Theme.Outline
        control.Holder.BackgroundColor3 = Library.Theme.Hover or Library.Theme.Accent
        task.delay(0.55, function()
            if control.Holder and control.Holder.Parent and not control.Hovering then
                Library:Animate(control.Holder, 0.28, {BackgroundColor3 = original})
            end
        end)
    end)
end

function Library:IsFavorite(control)
    return self.FavoriteControls[control] == true
end

function Library:SetFavorite(control, state)
    if not control then return end
    state = state == true

    if state and not self.FavoriteControls[control] then
        self.FavoriteControls[control] = true
        table.insert(self.FavoriteOrder, control)
    elseif not state and self.FavoriteControls[control] then
        self.FavoriteControls[control] = nil
        local index = table.find(self.FavoriteOrder, control)
        if index then table.remove(self.FavoriteOrder, index) end
    end

    self:RefreshFavorites()
end

function Library:RefreshFavorites()
    clearChildrenExceptLayouts(FavoritesInner)

    for _, control in ipairs(self.FavoriteOrder) do
        if control and control.Holder and control.Holder.Parent then
            local button = Create("TextButton", {
                Parent = FavoritesInner,
                Size = UDim2.new(1, 0, 0, 28),
                BackgroundColor3 = self.Theme.Control2,
                BackgroundTransparency = 0.20,
                BorderSizePixel = 0,
                Text = "★  " .. tostring(control.DisplayName or "Function"),
                TextColor3 = self.Theme.Text,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Left,
                AutoButtonColor = false,
                ZIndex = 612,
            })
            self:RegisterFont(button)
            self:AdaptiveCorner(button, -4)
            Create("UIPadding", {Parent = button, PaddingLeft = UDim.new(0, 8)})

            button.MouseButton1Click:Connect(function()
                FavoritesPanel.Visible = false
                self:NavigateToControl(control)
            end)
        end
    end
end

function Library:OpenContextMenu(control)
    clearChildrenExceptLayouts(ContextInner)

    local mouse = UIS:GetMouseLocation()
    ContextMenu.Position = UDim2.fromOffset(mouse.X + 8, mouse.Y + 8)
    ContextMenu.Visible = true

    local actions = {
        {
            Text = self:IsFavorite(control) and self:L("Unfavorite") or self:L("Favorite"),
            Run = function()
                self:SetFavorite(control, not self:IsFavorite(control))
            end,
        },
        {
            Text = self:L("ResetValue"),
            Run = function()
                if control.Set and control.DefaultValue ~= nil then
                    control:Set(control.DefaultValue)
                end
            end,
        },
        {
            Text = self:L("CopyValue"),
            Run = function()
                if setclipboardFn and control.Get then
                    local ok, value = pcall(function() return control:Get() end)
                    if ok then
                        pcall(setclipboardFn, tostring(value))
                    end
                end
            end,
        },
    }

    for _, action in ipairs(actions) do
        local button = Create("TextButton", {
            Parent = ContextInner,
            Size = UDim2.new(1, 0, 0, 28),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Text = action.Text,
            TextColor3 = self.Theme.Text,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false,
            ZIndex = 652,
        })
        self:RegisterFont(button)
        Create("UIPadding", {Parent = button, PaddingLeft = UDim.new(0, 8)})

        button.MouseButton1Click:Connect(function()
            ContextMenu.Visible = false
            action.Run()
        end)
    end
end

function Library:RefreshSearch(query)
    clearChildrenExceptLayouts(SearchResultsInner)
    table.clear(self.SearchResults)

    query = tostring(query or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    if query == "" then
        SearchResultsFrame.Visible = false
        return
    end

    for _, control in ipairs(self.Controls) do
        local name = tostring(control.DisplayName or ""):lower()
        local description = tostring(control.Description or ""):lower()

        if name:find(query, 1, true) or description:find(query, 1, true) then
            table.insert(self.SearchResults, control)
            if #self.SearchResults >= 7 then break end
        end
    end

    for _, control in ipairs(self.SearchResults) do
        local button = Create("TextButton", {
            Parent = SearchResultsInner,
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundColor3 = self.Theme.Control2,
            BackgroundTransparency = 0.18,
            BorderSizePixel = 0,
            Text = tostring(control.DisplayName or "Function"),
            TextColor3 = self.Theme.Text,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false,
            ZIndex = 622,
        })
        self:RegisterFont(button)
        self:AdaptiveCorner(button, -4)
        Create("UIPadding", {Parent = button, PaddingLeft = UDim.new(0, 9)})

        button.MouseButton1Click:Connect(function()
            SearchBox.Text = ""
            SearchResultsFrame.Visible = false
            self:NavigateToControl(control)
        end)
    end

    SearchResultsFrame.Visible = #self.SearchResults > 0
    if SearchResultsFrame.Visible then
        updateTopbarPopupPositions()
    end
end

SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    Library:RefreshSearch(SearchBox.Text)
end)

FavoritesButton.MouseButton1Click:Connect(function()
    SearchResultsFrame.Visible = false
    FavoritesPanel.Visible = not FavoritesPanel.Visible
    if FavoritesPanel.Visible then
        Library:RefreshFavorites()
        updateTopbarPopupPositions()
    end
end)

UIS.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 and ContextMenu.Visible then
        local mouse = UIS:GetMouseLocation()
        local pos = ContextMenu.AbsolutePosition
        local size = ContextMenu.AbsoluteSize
        if mouse.X < pos.X or mouse.X > pos.X + size.X or mouse.Y < pos.Y or mouse.Y > pos.Y + size.Y then
            ContextMenu.Visible = false
        end
    end
end)

-- Dedicated topbar outline. This is an inset line instead of a UIStroke on
-- the edge, so Main.ClipsDescendants cannot cut it off.
local TopbarBottomOutline = Create("Frame", {
    Parent = Topbar,
    AnchorPoint = Vector2.new(0.5, 1),
    Position = UDim2.new(0.5, 0, 1, 0),
    Size = UDim2.new(1, -20, 0, 1),
    BorderSizePixel = 0,
    ZIndex = 13,
})
Library:BindTheme(TopbarBottomOutline, "BackgroundColor3", "Outline")

local Sidebar = Create("Frame", {
    Parent = MainVisual,
    Position = UDim2.fromOffset(0, 52),
    Size = UDim2.new(0, 172, 1, -52),
    BorderSizePixel = 0,
    ZIndex = 11,
})
