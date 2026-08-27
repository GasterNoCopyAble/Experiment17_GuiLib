-- Experiment 17 v22 - redesigned direct tab tile pages
-- Tile pages are tab-level content with top/bottom separators, image tiles,
-- captions below each tile, and compact centered pagination.

return function(Library)
    local TweenService = game:GetService("TweenService")
    local decoratedTabs = setmetatable({}, {__mode="k"})
    local decoratedSections = setmetatable({}, {__mode="k"})

    Library.Settings = Library.Settings or {}
    Library.Settings.DefaultTilesPerPage = tonumber(Library.Settings.DefaultTilesPerPage) or 8

    local function bind(object, property, key)
        if type(Library.BindTheme) == "function" then
            Library:BindTheme(object, property, key)
        else
            object[property] = Library.Theme[key]
        end
    end

    local function corner(object, radius)
        if type(Library.AdaptiveCorner) == "function" then
            Library:AdaptiveCorner(object, radius or -2)
        else
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, 5)
            c.Parent = object
        end
    end

    local function font(object, bold)
        if type(Library.RegisterFont) == "function" then
            Library:RegisterFont(object, bold == true)
        end
    end

    local function normalizeTile(info, index)
        info = type(info) == "table" and info or {Text=tostring(info)}
        return {
            Text = tostring(info.Text or info.Name or ("Tile " .. index)),
            Image = tostring(info.Image or info.Icon or ""),
            Value = info.Value,
            Callback = info.Callback,
            ImageColor3 = typeof(info.ImageColor3) == "Color3" and info.ImageColor3 or Color3.new(1,1,1),
        }
    end

    local function createSeparator(parent, y, name)
        local line = Instance.new("Frame")
        line.Name = name
        line.Parent = parent
        line.AnchorPoint = Vector2.new(0.5,0)
        line.Position = UDim2.new(0.5,0,0,y)
        line.Size = UDim2.new(1,-18,0,1)
        line.BorderSizePixel = 0
        line.BackgroundTransparency = 0.24
        line.ZIndex = 16
        bind(line,"BackgroundColor3","Outline")
        return line
    end

    local function createNavButton(parent, text)
        local button = Instance.new("TextButton")
        button.Parent = parent
        button.Size = UDim2.fromOffset(32,24)
        button.BackgroundTransparency = 0
        button.BorderSizePixel = 0
        button.Text = text
        button.TextSize = 13
        button.AutoButtonColor = false
        button.ZIndex = 19
        bind(button,"BackgroundColor3","Control2")
        bind(button,"TextColor3","Text")
        corner(button,-2)
        font(button,true)

        local stroke = Instance.new("UIStroke")
        stroke.Parent = button
        stroke.Thickness = 1
        stroke.Transparency = 0.42
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        bind(stroke,"Color","Outline")
        return button
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
            TilesPerPage = math.clamp(math.floor(tonumber(options.TilesPerPage) or Library.Settings.DefaultTilesPerPage or 8),1,30),
            Columns = math.clamp(math.floor(tonumber(options.Columns) or 4),1,8),
            TileSize = math.clamp(math.floor(tonumber(options.TileSize) or 78),52,132),
            Gap = math.clamp(math.floor(tonumber(options.Gap) or 12),4,26),
        }

        for index, info in ipairs(options.Tiles or options.Buttons or {}) do
            pageObject.Tiles[#pageObject.Tiles+1] = normalizeTile(info,index)
        end

        local Container = Instance.new("Frame")
        Container.Name = "E17_TilePage"
        Container.Parent = Page
        Container.Size = UDim2.new(1,-4,0,0)
        Container.BackgroundTransparency = 1
        Container.BorderSizePixel = 0
        Container.ZIndex = 15

        local TopLine = createSeparator(Container,0,"E17_TilePageTopLine")

        local Header = Instance.new("Frame")
        Header.Parent = Container
        Header.Position = UDim2.fromOffset(6,8)
        Header.Size = UDim2.new(1,-12,0,28)
        Header.BackgroundTransparency = 1
        Header.BorderSizePixel = 0
        Header.ZIndex = 16

        local Title = Instance.new("TextLabel")
        Title.Parent = Header
        Title.Size = UDim2.new(1,-100,1,0)
        Title.BackgroundTransparency = 1
        Title.Text = tostring(options.Name or options.Title or "Tiles")
        Title.TextSize = 13
        Title.TextXAlignment = Enum.TextXAlignment.Left
        Title.ZIndex = 17
        bind(Title,"TextColor3","Text")
        font(Title,true)

        local HeaderPage = Instance.new("TextLabel")
        HeaderPage.Parent = Header
        HeaderPage.AnchorPoint = Vector2.new(1,0)
        HeaderPage.Position = UDim2.new(1,0,0,0)
        HeaderPage.Size = UDim2.fromOffset(92,28)
        HeaderPage.BackgroundTransparency = 1
        HeaderPage.TextSize = 10
        HeaderPage.TextXAlignment = Enum.TextXAlignment.Right
        HeaderPage.ZIndex = 17
        bind(HeaderPage,"TextColor3","SubText")
        font(HeaderPage,true)

        local Grid = Instance.new("Frame")
        Grid.Parent = Container
        Grid.Position = UDim2.fromOffset(0,42)
        Grid.Size = UDim2.new(1,0,0,0)
        Grid.BackgroundTransparency = 1
        Grid.BorderSizePixel = 0
        Grid.ZIndex = 15

        local GridLayout = Instance.new("UIGridLayout")
        GridLayout.Parent = Grid
        GridLayout.CellPadding = UDim2.fromOffset(pageObject.Gap,pageObject.Gap)
        GridLayout.CellSize = UDim2.fromOffset(pageObject.TileSize,pageObject.TileSize+25)
        GridLayout.FillDirection = Enum.FillDirection.Horizontal
        GridLayout.FillDirectionMaxCells = pageObject.Columns
        GridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        GridLayout.SortOrder = Enum.SortOrder.LayoutOrder

        local BottomLine = createSeparator(Container,0,"E17_TilePageBottomLine")

        local Footer = Instance.new("Frame")
        Footer.Parent = Container
        Footer.Size = UDim2.new(1,-12,0,32)
        Footer.AnchorPoint = Vector2.new(0.5,0)
        Footer.Position = UDim2.new(0.5,0,0,0)
        Footer.BackgroundTransparency = 1
        Footer.BorderSizePixel = 0
        Footer.ZIndex = 17

        local Nav = Instance.new("Frame")
        Nav.Parent = Footer
        Nav.AnchorPoint = Vector2.new(0.5,0.5)
        Nav.Position = UDim2.fromScale(0.5,0.5)
        Nav.Size = UDim2.fromOffset(126,26)
        Nav.BackgroundTransparency = 1
        Nav.BorderSizePixel = 0
        Nav.ZIndex = 18

        local Prev = createNavButton(Nav,"‹")
        Prev.AnchorPoint = Vector2.new(0,0.5)
        Prev.Position = UDim2.new(0,0,0.5,0)

        local Next = createNavButton(Nav,"›")
        Next.AnchorPoint = Vector2.new(1,0.5)
        Next.Position = UDim2.new(1,0,0.5,0)

        local PageLabel = Instance.new("TextLabel")
        PageLabel.Parent = Nav
        PageLabel.AnchorPoint = Vector2.new(0.5,0.5)
        PageLabel.Position = UDim2.fromScale(0.5,0.5)
        PageLabel.Size = UDim2.fromOffset(54,24)
        PageLabel.BackgroundTransparency = 1
        PageLabel.TextSize = 11
        PageLabel.ZIndex = 19
        bind(PageLabel,"TextColor3","Text")
        font(PageLabel,true)

        local spawned = {}
        local function clearTiles()
            for _, object in ipairs(spawned) do
                if object and object.Parent then object:Destroy() end
            end
            table.clear(spawned)
        end

        local function createTile(tile,index)
            local Cell = Instance.new("Frame")
            Cell.Parent = Grid
            Cell.Size = UDim2.fromOffset(pageObject.TileSize,pageObject.TileSize+25)
            Cell.BackgroundTransparency = 1
            Cell.BorderSizePixel = 0
            Cell.LayoutOrder = index
            Cell.ZIndex = 16

            local Button = Instance.new("ImageButton")
            Button.Parent = Cell
            Button.Size = UDim2.fromOffset(pageObject.TileSize,pageObject.TileSize)
            Button.BackgroundTransparency = 0
            Button.BorderSizePixel = 0
            Button.Image = ""
            Button.AutoButtonColor = false
            Button.ZIndex = 17
            bind(Button,"BackgroundColor3","Control")
            corner(Button,0)

            local Scale = Instance.new("UIScale")
            Scale.Parent = Button
            Scale.Scale = 1

            local Stroke = Instance.new("UIStroke")
            Stroke.Parent = Button
            Stroke.Thickness = 1.05
            Stroke.Transparency = 0.34
            Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            bind(Stroke,"Color","Outline")

            local Image = Instance.new("ImageLabel")
            Image.Parent = Button
            Image.AnchorPoint = Vector2.new(0.5,0.5)
            Image.Position = UDim2.fromScale(0.5,0.5)
            Image.Size = UDim2.new(1,-18,1,-18)
            Image.BackgroundTransparency = 1
            Image.Image = tile.Image
            Image.ImageColor3 = tile.ImageColor3
            Image.ScaleType = Enum.ScaleType.Fit
            Image.Visible = tile.Image ~= ""
            Image.ZIndex = 18

            local Fallback = Instance.new("TextLabel")
            Fallback.Parent = Button
            Fallback.Size = UDim2.fromScale(1,1)
            Fallback.BackgroundTransparency = 1
            Fallback.Text = tile.Text:sub(1,1):upper()
            Fallback.TextSize = math.max(17,math.floor(pageObject.TileSize*0.27))
            Fallback.Visible = tile.Image == ""
            Fallback.ZIndex = 18
            bind(Fallback,"TextColor3","Accent")
            font(Fallback,true)

            local Label = Instance.new("TextLabel")
            Label.Parent = Cell
            Label.Position = UDim2.new(0,-3,0,pageObject.TileSize+5)
            Label.Size = UDim2.new(1,6,0,18)
            Label.BackgroundTransparency = 1
            Label.Text = tile.Text
            Label.TextSize = 10
            Label.TextTruncate = Enum.TextTruncate.AtEnd
            Label.ZIndex = 17
            bind(Label,"TextColor3","Text")
            font(Label,true)

            Button.MouseEnter:Connect(function()
                if Library.Unloaded then return end
                TweenService:Create(Scale,TweenInfo.new(0.12,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Scale=1.035}):Play()
                Stroke.Transparency = 0.12
            end)
            Button.MouseLeave:Connect(function()
                if Library.Unloaded then return end
                TweenService:Create(Scale,TweenInfo.new(0.12,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Scale=1}):Play()
                Stroke.Transparency = 0.34
            end)
            Button.Activated:Connect(function()
                Scale.Scale = 0.965
                TweenService:Create(Scale,TweenInfo.new(0.13,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1}):Play()
                if type(tile.Callback)=="function" then
                    local ok,err = pcall(tile.Callback,tile.Value,tile,index)
                    if not ok then warn("[Experiment17] Tile callback error: "..tostring(err)) end
                end
            end)

            spawned[#spawned+1] = Cell
        end

        function pageObject:GetPageCount()
            return math.max(1,math.ceil(#self.Tiles/math.max(1,self.TilesPerPage)))
        end

        function pageObject:Refresh()
            clearTiles()
            local pages = self:GetPageCount()
            self.CurrentPage = math.clamp(self.CurrentPage,1,pages)

            local firstIndex = (self.CurrentPage-1)*self.TilesPerPage+1
            local lastIndex = math.min(#self.Tiles,firstIndex+self.TilesPerPage-1)
            local count = math.max(0,lastIndex-firstIndex+1)
            for index=firstIndex,lastIndex do createTile(self.Tiles[index],index) end

            GridLayout.CellPadding = UDim2.fromOffset(self.Gap,self.Gap)
            GridLayout.CellSize = UDim2.fromOffset(self.TileSize,self.TileSize+25)
            GridLayout.FillDirectionMaxCells = self.Columns

            local rows = math.max(1,math.ceil(math.max(1,count)/self.Columns))
            local gridHeight = rows*(self.TileSize+25)+math.max(0,rows-1)*self.Gap
            Grid.Position = UDim2.fromOffset(0,42)
            Grid.Size = UDim2.new(1,0,0,gridHeight)

            local separatorY = 42+gridHeight+9
            BottomLine.Position = UDim2.new(0.5,0,0,separatorY)
            Footer.Position = UDim2.new(0.5,0,0,separatorY+5)
            Container.Size = UDim2.new(1,-4,0,separatorY+42)

            HeaderPage.Text = string.format("PAGE %d / %d",self.CurrentPage,pages)
            PageLabel.Text = string.format("%d / %d",self.CurrentPage,pages)
            Prev.Visible = pages>1
            Next.Visible = pages>1
            Nav.Visible = pages>1
        end

        function pageObject:SetPage(page)
            self.CurrentPage = math.clamp(math.floor(tonumber(page) or 1),1,self:GetPageCount())
            self:Refresh()
        end
        function pageObject:SetTilesPerPage(amount)
            self.TilesPerPage = math.clamp(math.floor(tonumber(amount) or self.TilesPerPage),1,30)
            self.CurrentPage = 1
            self:Refresh()
        end
        function pageObject:SetTiles(tiles)
            table.clear(self.Tiles)
            for index,info in ipairs(tiles or {}) do
                self.Tiles[#self.Tiles+1] = normalizeTile(info,index)
            end
            self.CurrentPage = 1
            self:Refresh()
        end
        function pageObject:Destroy()
            clearTiles()
            if Container.Parent then Container:Destroy() end
        end

        Prev.Activated:Connect(function() pageObject:SetPage(pageObject.CurrentPage-1) end)
        Next.Activated:Connect(function() pageObject:SetPage(pageObject.CurrentPage+1) end)

        pageObject.Container = Container
        pageObject.Grid = Grid
        pageObject.TopSeparator = TopLine
        pageObject.BottomSeparator = BottomLine
        pageObject:Refresh()
        return pageObject
    end

    local function decorateSection(section)
        if not section or decoratedSections[section] then return section end
        decoratedSections[section]=true
        function section:AddTileButtons(options)
            options=options or {}
            local tiles={}
            for _,info in ipairs(options.Tiles or options.Buttons or {}) do
                tiles[#tiles+1]={Text=info.Text or info.Name,Image=info.Image or info.Icon,Value=info.Value,Callback=info.Callback,ImageColor3=info.ImageColor3}
            end
            options.Tiles=tiles
            return self.Tab:AddTilePage(options)
        end
        function section:AddTileButton(options)
            options=options or {}
            return self.Tab:AddTilePage({Name=options.GroupName or options.Name or "",TilesPerPage=1,Columns=1,TileSize=options.TileSize,Tiles={{Text=options.Text or options.ButtonText or options.Name or "Tile",Image=options.Image or options.Icon,Value=options.Value,Callback=options.Callback,ImageColor3=options.ImageColor3}}})
        end
        return section
    end

    local function decorateTab(tab)
        if not tab or decoratedTabs[tab] then return tab end
        decoratedTabs[tab]=true
        function tab:AddTilePage(options) return addTilePage(self,options) end
        tab.CreateTilePage=tab.AddTilePage
        if type(tab.CreateSection)=="function" then
            local rawCreateSection=tab.CreateSection
            function tab:CreateSection(...) return decorateSection(rawCreateSection(self,...)) end
        end
        for _,section in ipairs(tab.Sections or {}) do decorateSection(section) end
        return tab
    end

    if type(Library.CreateTab)=="function" then
        local rawCreateTab=Library.CreateTab
        function Library:CreateTab(...) return decorateTab(rawCreateTab(self,...)) end
    end
    for _,tab in ipairs(Library.Tabs or {}) do decorateTab(tab) end
    Library.DecorateTileSection=decorateSection

    local settingsTab=Library.SettingsTab
    if settingsTab then
        local interfaceSection=nil
        for _,section in ipairs(settingsTab.Sections or {}) do
            if section.LocaleKey=="Interface" then interfaceSection=section break end
        end
        if interfaceSection and type(interfaceSection.AddSlider)=="function" then
            interfaceSection:AddSlider({
                Name="Default Tiles Per Page", Flag="UI_DefaultTilesPerPage",
                Min=1, Max=24, Default=Library.Settings.DefaultTilesPerPage,
                RequiredGraphics="Low",
                Callback=function(value) Library.Settings.DefaultTilesPerPage=value end,
            })
        end
    end

    return function() end
end
