-- Experiment 17 v22 - direct tab tile pages
-- Tiles are direct tab content, not controls stuffed into a section row.

return function(Library)
    local decoratedTabs = setmetatable({}, {__mode = "k"})
    local decoratedSections = setmetatable({}, {__mode = "k"})
    local connections = {}

    Library.Settings = Library.Settings or {}
    Library.Settings.DefaultTilesPerPage = tonumber(Library.Settings.DefaultTilesPerPage) or 8

    local function corner(object, radius)
        if type(Library.AdaptiveCorner) == "function" then
            Library:AdaptiveCorner(object, radius or -2)
        else
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, 5)
            c.Parent = object
        end
    end

    local function bind(object, property, key)
        if type(Library.BindTheme) == "function" then
            Library:BindTheme(object, property, key)
        else
            object[property] = Library.Theme[key]
        end
    end

    local function font(object, bold)
        if type(Library.RegisterFont) == "function" then
            Library:RegisterFont(object, bold == true)
        end
    end

    local function normalizeTile(info, index)
        info = type(info) == "table" and info or {Text = tostring(info)}
        return {
            Text = tostring(info.Text or info.Name or ("Tile " .. tostring(index))),
            Image = tostring(info.Image or info.Icon or ""),
            Value = info.Value,
            Callback = info.Callback,
            ImageColor3 = typeof(info.ImageColor3) == "Color3" and info.ImageColor3 or Color3.new(1, 1, 1),
        }
    end

    local function addTilePage(tab, options)
        options = options or {}
        local Page = tab.Page
        if not Page then
            error("[Experiment17] AddTilePage requires a normal Experiment17 tab")
        end

        local pageObject = {
            Tab = tab,
            Tiles = {},
            CurrentPage = 1,
            TilesPerPage = math.clamp(math.floor(tonumber(options.TilesPerPage) or Library.Settings.DefaultTilesPerPage or 8), 1, 30),
            Columns = math.clamp(math.floor(tonumber(options.Columns) or 4), 1, 8),
            TileSize = math.clamp(math.floor(tonumber(options.TileSize) or 82), 52, 140),
            Gap = math.clamp(math.floor(tonumber(options.Gap) or 10), 2, 24),
        }

        for index, info in ipairs(options.Tiles or options.Buttons or {}) do
            pageObject.Tiles[#pageObject.Tiles + 1] = normalizeTile(info, index)
        end

        local Container = Instance.new("Frame")
        Container.Name = "E17_TilePage"
        Container.Parent = Page
        Container.Size = UDim2.new(1, -2, 0, 0)
        Container.BackgroundTransparency = 1
        Container.BorderSizePixel = 0
        Container.AutomaticSize = Enum.AutomaticSize.None
        Container.ZIndex = 15

        local Title = Instance.new("TextLabel")
        Title.Parent = Container
        Title.Position = UDim2.fromOffset(2, 0)
        Title.Size = UDim2.new(1, -4, 0, 24)
        Title.BackgroundTransparency = 1
        Title.Text = tostring(options.Name or options.Title or "")
        Title.TextSize = 13
        Title.TextXAlignment = Enum.TextXAlignment.Left
        Title.Visible = Title.Text ~= ""
        Title.ZIndex = 16
        bind(Title, "TextColor3", "Text")
        font(Title, true)

        local Grid = Instance.new("Frame")
        Grid.Parent = Container
        Grid.Position = UDim2.fromOffset(0, Title.Visible and 30 or 0)
        Grid.Size = UDim2.new(1, 0, 0, 0)
        Grid.BackgroundTransparency = 1
        Grid.BorderSizePixel = 0
        Grid.ZIndex = 15

        local GridLayout = Instance.new("UIGridLayout")
        GridLayout.Parent = Grid
        GridLayout.CellPadding = UDim2.fromOffset(pageObject.Gap, pageObject.Gap)
        GridLayout.CellSize = UDim2.fromOffset(pageObject.TileSize, pageObject.TileSize + 23)
        GridLayout.FillDirection = Enum.FillDirection.Horizontal
        GridLayout.FillDirectionMaxCells = pageObject.Columns
        GridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        GridLayout.SortOrder = Enum.SortOrder.LayoutOrder

        local Footer = Instance.new("Frame")
        Footer.Parent = Container
        Footer.Size = UDim2.new(1, 0, 0, 28)
        Footer.BackgroundTransparency = 1
        Footer.BorderSizePixel = 0
        Footer.ZIndex = 16

        local Prev = Instance.new("TextButton")
        Prev.Parent = Footer
        Prev.AnchorPoint = Vector2.new(0, 0.5)
        Prev.Position = UDim2.new(0, 2, 0.5, 0)
        Prev.Size = UDim2.fromOffset(52, 24)
        Prev.BorderSizePixel = 0
        Prev.Text = "<"
        Prev.TextSize = 12
        Prev.AutoButtonColor = false
        Prev.ZIndex = 17
        bind(Prev, "BackgroundColor3", "Control2")
        bind(Prev, "TextColor3", "Text")
        corner(Prev, -2)
        font(Prev, true)

        local Next = Prev:Clone()
        Next.Parent = Footer
        Next.AnchorPoint = Vector2.new(1, 0.5)
        Next.Position = UDim2.new(1, -2, 0.5, 0)
        Next.Text = ">"
        bind(Next, "BackgroundColor3", "Control2")
        bind(Next, "TextColor3", "Text")

        local PageLabel = Instance.new("TextLabel")
        PageLabel.Parent = Footer
        PageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
        PageLabel.Position = UDim2.fromScale(0.5, 0.5)
        PageLabel.Size = UDim2.fromOffset(120, 22)
        PageLabel.BackgroundTransparency = 1
        PageLabel.TextSize = 11
        PageLabel.ZIndex = 17
        bind(PageLabel, "TextColor3", "SubText")
        font(PageLabel, true)

        local spawned = {}

        local function clearTiles()
            for _, object in ipairs(spawned) do
                if object and object.Parent then
                    object:Destroy()
                end
            end
            table.clear(spawned)
        end

        local function createTile(tile, index)
            local Cell = Instance.new("Frame")
            Cell.Parent = Grid
            Cell.Size = UDim2.fromOffset(pageObject.TileSize, pageObject.TileSize + 23)
            Cell.BackgroundTransparency = 1
            Cell.BorderSizePixel = 0
            Cell.LayoutOrder = index
            Cell.ZIndex = 16

            local Button = Instance.new("ImageButton")
            Button.Parent = Cell
            Button.Size = UDim2.fromOffset(pageObject.TileSize, pageObject.TileSize)
            Button.BackgroundTransparency = 0
            Button.BorderSizePixel = 0
            Button.Image = ""
            Button.AutoButtonColor = false
            Button.ZIndex = 17
            bind(Button, "BackgroundColor3", "Control")
            corner(Button, 1)

            local Stroke = Instance.new("UIStroke")
            Stroke.Parent = Button
            Stroke.Thickness = 1.15
            Stroke.Transparency = 0.16
            Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            bind(Stroke, "Color", "Outline")

            local Image = Instance.new("ImageLabel")
            Image.Parent = Button
            Image.AnchorPoint = Vector2.new(0.5, 0.5)
            Image.Position = UDim2.fromScale(0.5, 0.5)
            Image.Size = UDim2.new(1, -14, 1, -14)
            Image.BackgroundTransparency = 1
            Image.Image = tile.Image
            Image.ImageColor3 = tile.ImageColor3
            Image.ScaleType = Enum.ScaleType.Fit
            Image.Visible = tile.Image ~= ""
            Image.ZIndex = 18

            local Fallback = Instance.new("TextLabel")
            Fallback.Parent = Button
            Fallback.Size = UDim2.fromScale(1, 1)
            Fallback.BackgroundTransparency = 1
            Fallback.Text = tile.Text:sub(1, 1):upper()
            Fallback.TextSize = math.max(18, math.floor(pageObject.TileSize * 0.28))
            Fallback.Visible = tile.Image == ""
            Fallback.ZIndex = 18
            bind(Fallback, "TextColor3", "Accent")
            font(Fallback, true)

            local Label = Instance.new("TextLabel")
            Label.Parent = Cell
            Label.Position = UDim2.new(0, -4, 0, pageObject.TileSize + 4)
            Label.Size = UDim2.new(1, 8, 0, 18)
            Label.BackgroundTransparency = 1
            Label.Text = tile.Text
            Label.TextSize = 10
            Label.TextWrapped = false
            Label.TextTruncate = Enum.TextTruncate.AtEnd
            Label.ZIndex = 17
            bind(Label, "TextColor3", "Text")
            font(Label, true)

            Button.Activated:Connect(function()
                if type(tile.Callback) == "function" then
                    local ok, err = pcall(tile.Callback, tile.Value, tile, index)
                    if not ok then
                        warn("[Experiment17] Tile callback error: " .. tostring(err))
                    end
                end
            end)

            spawned[#spawned + 1] = Cell
        end

        function pageObject:GetPageCount()
            return math.max(1, math.ceil(#self.Tiles / math.max(1, self.TilesPerPage)))
        end

        function pageObject:Refresh()
            clearTiles()

            local pages = self:GetPageCount()
            self.CurrentPage = math.clamp(self.CurrentPage, 1, pages)

            local firstIndex = (self.CurrentPage - 1) * self.TilesPerPage + 1
            local lastIndex = math.min(#self.Tiles, firstIndex + self.TilesPerPage - 1)
            local count = math.max(0, lastIndex - firstIndex + 1)

            for index = firstIndex, lastIndex do
                createTile(self.Tiles[index], index)
            end

            GridLayout.CellPadding = UDim2.fromOffset(self.Gap, self.Gap)
            GridLayout.CellSize = UDim2.fromOffset(self.TileSize, self.TileSize + 23)
            GridLayout.FillDirectionMaxCells = self.Columns

            local rows = math.max(1, math.ceil(math.max(1, count) / self.Columns))
            local gridHeight = rows * (self.TileSize + 23) + math.max(0, rows - 1) * self.Gap
            local top = Title.Visible and 30 or 0

            Grid.Position = UDim2.fromOffset(0, top)
            Grid.Size = UDim2.new(1, 0, 0, gridHeight)
            Footer.Position = UDim2.fromOffset(0, top + gridHeight + 7)
            Container.Size = UDim2.new(1, -2, 0, top + gridHeight + 39)

            PageLabel.Text = string.format("%d / %d", self.CurrentPage, pages)
            Prev.Visible = pages > 1
            Next.Visible = pages > 1
        end

        function pageObject:SetPage(page)
            self.CurrentPage = math.clamp(math.floor(tonumber(page) or 1), 1, self:GetPageCount())
            self:Refresh()
        end

        function pageObject:SetTilesPerPage(amount)
            self.TilesPerPage = math.clamp(math.floor(tonumber(amount) or self.TilesPerPage), 1, 30)
            self.CurrentPage = 1
            self:Refresh()
        end

        function pageObject:SetTiles(tiles)
            table.clear(self.Tiles)
            for index, info in ipairs(tiles or {}) do
                self.Tiles[#self.Tiles + 1] = normalizeTile(info, index)
            end
            self.CurrentPage = 1
            self:Refresh()
        end

        function pageObject:Destroy()
            clearTiles()
            if Container.Parent then Container:Destroy() end
        end

        Prev.Activated:Connect(function()
            pageObject:SetPage(pageObject.CurrentPage - 1)
        end)
        Next.Activated:Connect(function()
            pageObject:SetPage(pageObject.CurrentPage + 1)
        end)

        pageObject.Container = Container
        pageObject.Grid = Grid
        pageObject:Refresh()
        return pageObject
    end

    local function decorateSection(section)
        if not section or decoratedSections[section] then return section end
        decoratedSections[section] = true

        function section:AddTileButtons(options)
            options = options or {}
            local tiles = {}
            for _, info in ipairs(options.Tiles or options.Buttons or {}) do
                tiles[#tiles + 1] = {
                    Text = info.Text or info.Name,
                    Image = info.Image or info.Icon,
                    Value = info.Value,
                    Callback = info.Callback,
                }
            end
            options.Tiles = tiles
            return self.Tab:AddTilePage(options)
        end

        function section:AddTileButton(options)
            options = options or {}
            return self.Tab:AddTilePage({
                Name = options.GroupName or options.Name or "",
                TilesPerPage = 1,
                Columns = 1,
                TileSize = options.TileSize,
                Tiles = {{
                    Text = options.Text or options.ButtonText or options.Name or "Tile",
                    Image = options.Image or options.Icon,
                    Value = options.Value,
                    Callback = options.Callback,
                }},
            })
        end

        return section
    end

    local function decorateTab(tab)
        if not tab or decoratedTabs[tab] then return tab end
        decoratedTabs[tab] = true

        function tab:AddTilePage(options)
            return addTilePage(self, options)
        end
        tab.CreateTilePage = tab.AddTilePage

        if type(tab.CreateSection) == "function" then
            local rawCreateSection = tab.CreateSection
            function tab:CreateSection(...)
                return decorateSection(rawCreateSection(self, ...))
            end
        end

        for _, section in ipairs(tab.Sections or {}) do
            decorateSection(section)
        end

        return tab
    end

    if type(Library.CreateTab) == "function" then
        local rawCreateTab = Library.CreateTab
        function Library:CreateTab(...)
            return decorateTab(rawCreateTab(self, ...))
        end
    end

    for _, tab in ipairs(Library.Tabs or {}) do
        decorateTab(tab)
    end

    Library.DecorateTileSection = decorateSection

    local settingsTab = Library.SettingsTab
    if settingsTab and type(settingsTab.CreateSection) == "function" then
        local section = settingsTab:CreateSection("Tile Pages", false)
        if section and type(section.AddSlider) == "function" then
            local defaultTilesControl = section:AddSlider({
                Name = "Default Tiles Per Page",
                Flag = "UI_DefaultTilesPerPage",
                Min = 1,
                Max = 24,
                Default = Library.Settings.DefaultTilesPerPage,
                RequiredGraphics = "Low",
                Callback = function(value)
                    Library.Settings.DefaultTilesPerPage = value
                end,
            })

            if defaultTilesControl and type(defaultTilesControl.Set) == "function" then
                local rawSet = defaultTilesControl.Set
                function defaultTilesControl:Set(value, silent)
                    rawSet(self, value, silent)
                    if type(self.Get) == "function" then
                        Library.Settings.DefaultTilesPerPage = self:Get()
                    end
                end
            end
        end
    end

    return function()
        for _, connection in ipairs(connections) do
            pcall(function() connection:Disconnect() end)
        end
    end
end
