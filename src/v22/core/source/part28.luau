            Title = "Teleport",
            Text = ok and "Queued" or "Unavailable",
            Type = ok and "Success" or "Error",
        })
    end,
})

--============================================================
-- HOTKEY
--============================================================

UIS.InputBegan:Connect(function(input, processed)
    if Library.Unloaded then return end
    if Library.BindingKey or Library.SuppressMenuKey then return end
    if processed then return end
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

    local menuKey = Enum.KeyCode[Library.Settings.MenuKey] or Enum.KeyCode.RightShift
    if input.KeyCode == menuKey then
        if Library.PromptBusy then
            return
        end

        SearchResultsFrame.Visible = false
        FavoritesPanel.Visible = false
        ContextMenu.Visible = false

        if Library.ActiveDropdown and Library.ActiveDropdown.CloseDropdown then
            Library.ActiveDropdown:CloseDropdown()
        end
        Library:SetMenuVisible(not Library.MenuVisible)
    end
end)

-- Apply the current independent control width/DPI after all default controls exist.
Library:ApplyFunctionDPIScale()
Library:SetTextScale(Library.Settings.TextScale)
Library:RefreshDependencies()
Library:RefreshKeybindList()
Library:RefreshGradients()
Library:RefreshMobileButton()

--============================================================
-- LOADER SEQUENCE / AUTOLOAD
--============================================================

local function finishLoader()
    LoaderGreeting.Text = getLocalizedGreeting()

    local loaderStarted = os.clock()
    local minimumLoaderTime = 5

    local function setStage(statusKey, progress, tweenTime)
        if not Loader.Parent then
            return
        end

        progress = math.clamp(progress or 0, 0, 1)
        LoaderStatus.Text = Library:L(statusKey)
        LoaderPercent.Text = tostring(math.floor(progress * 100 + 0.5)) .. "%"

        TweenService:Create(
            LoaderFill,
            TweenInfo.new(tweenTime or 0.70, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
            {Size = UDim2.fromScale(progress, 1)}
        ):Play()
    end

    setStage("LoadingModules", 0.24, 0.72)
    task.wait(1.05)

    setStage("PreparingInterface", 0.52, 0.82)
    task.wait(1.20)

    LoaderStatus.Text = Library:L("ApplyingConfiguration")
    LoaderPercent.Text = "72%"

    Library:TryAutoload()
    Library:RefreshLocalization()
    LoaderGreeting.Text = getLocalizedGreeting()
    Library.LevelText.Text = Library.Settings.GraphicsLevel
    Library:ApplyFunctionDPIScale()
    Library:SetTextScale(Library.Settings.TextScale)
    Library:RefreshGradients()
    Library:RefreshMobileButton()

    setStage("ApplyingConfiguration", 0.82, 0.78)
    task.wait(1.05)

    setStage("Finalizing", 1.00, 0.68)

    -- Keep the deliberate five-second startup rhythm.
    local fadeDuration = 0.32
    local remaining = minimumLoaderTime - (os.clock() - loaderStarted) - fadeDuration
    if remaining > 0 then
        task.wait(remaining)
    end

    LoaderStatus.Text = Library:L("Ready")
    LoaderPercent.Text = "100%"

    -- Loader exits upward/away before a startup question appears.
    TweenService:Create(
        LoaderScale,
        TweenInfo.new(fadeDuration, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
        {Scale = math.max(0.45, (Library.CurrentDPIScale or DPI_BASE_SCALE) * 0.78)}
    ):Play()

    TweenService:Create(
        LoaderBox,
        TweenInfo.new(fadeDuration, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
        {
            Position = UDim2.new(0.5, 0, 0.5, -38),
            BackgroundTransparency = 1,
        }
    ):Play()

    TweenService:Create(LoaderTitle, TweenInfo.new(fadeDuration * 0.75), {TextTransparency = 1}):Play()
    TweenService:Create(LoaderGreeting, TweenInfo.new(fadeDuration * 0.75), {TextTransparency = 1}):Play()
    TweenService:Create(LoaderStatus, TweenInfo.new(fadeDuration * 0.75), {TextTransparency = 1}):Play()
    TweenService:Create(LoaderPercent, TweenInfo.new(fadeDuration * 0.75), {TextTransparency = 1}):Play()
    TweenService:Create(LoaderBar, TweenInfo.new(fadeDuration * 0.75), {BackgroundTransparency = 1}):Play()
    TweenService:Create(LoaderFill, TweenInfo.new(fadeDuration * 0.75), {BackgroundTransparency = 1}):Play()
    TweenService:Create(Loader, TweenInfo.new(fadeDuration), {BackgroundTransparency = 1}):Play()

    task.wait(fadeDuration)

    if Loader.Parent then
        Loader:Destroy()
    end

    -- Anything queued by the script during the five-second loader is shown now,
    -- one modal at a time. Only after the final answer does the main UI open.
    Library:RunStartupPrompts()

    if not Library.Unloaded then
        Library:RefreshMobileButton()
        Library:SetMenuVisible(true)
    end
end

--============================================================
-- BUILT-IN STARTUP WIZARD
--============================================================

-- v19: the question system existed before, but only the public API example
-- queued questions. The library now ships with a small default wizard so the
-- user is actually asked after the loader disappears and before the main GUI
-- opens.
Library:QueueStartupQuestion({
    Title = {
        en = "Visual profile",
        ru = "Профиль визуалов",
        uk = "Профіль візуалів",
        de = "Visuelles Profil",
        fr = "Profil visuel",
        es = "Perfil visual",
        pt = "Perfil visual",
        pl = "Profil wizualny",
        tr = "Görsel profil",
    },

    Question = {
        en = "What do you want from the visuals?",
        ru = "Чего вы добиваетесь визуалами?",
        uk = "Чого ви хочете від візуалів?",
        de = "Was möchtest du mit den Visuals erreichen?",
        fr = "Que recherchez-vous avec les visuels ?",
        es = "¿Qué buscas con los visuales?",
        pt = "O que você busca com os visuais?",
        pl = "Czego oczekujesz od efektów wizualnych?",
        tr = "Görsellerden ne bekliyorsun?",
    },

    Options = {
        {
            Text = {
                en = "Balance",
                ru = "Баланс",
                uk = "Баланс",
                de = "Balance",
                fr = "Équilibre",
                es = "Equilibrio",
                pt = "Equilíbrio",
                pl = "Balans",
                tr = "Denge",
            },
            Value = "Balanced",
        },
        {
            Text = {
                en = "Performance",
                ru = "Производительность",
                uk = "Продуктивність",
                de = "Leistung",
                fr = "Performance",
                es = "Rendimiento",
                pt = "Desempenho",
                pl = "Wydajność",
                tr = "Performans",
            },
            Value = "Performance",
        },
        {
            Text = {
                en = "Beauty",
                ru = "Красота",
                uk = "Краса",
                de = "Schönheit",
                fr = "Beauté",
                es = "Belleza",
                pt = "Beleza",
                pl = "Wygląd",
                tr = "Görsellik",
            },
            Value = "Beauty",
        },
    },

    Flag = "VisualProfile",

    Condition = function()
        return Library.Settings.StartupWizardEnabled == true
    end,

    ApplyProfile = function(answer)
        if answer == "Balanced" then
            return "Balanced"
        elseif answer == "Performance" then
            return "Performance"
        elseif answer == "Beauty" then
            return "Beauty"
        end
    end,
})

Library:QueueStartupConfirm({
    Title = {
        en = "Optimization",
        ru = "Оптимизация",
        uk = "Оптимізація",
        de = "Optimierung",
        fr = "Optimisation",
        es = "Optimización",
        pt = "Otimização",
        pl = "Optymalizacja",
        tr = "Optimizasyon",
    },

    Question = {
        en = "Enable aggressive optimization?",
        ru = "Включить жесткую оптимизацию?",
        uk = "Увімкнути жорстку оптимізацію?",
        de = "Aggressive Optimierung aktivieren?",
        fr = "Activer l’optimisation agressive ?",
        es = "¿Activar la optimización agresiva?",
        pt = "Ativar otimização agressiva?",
        pl = "Włączyć agresywną optymalizację?",
        tr = "Agresif optimizasyon açılsın mı?",
    },

    Flag = "AggressiveOptimization",

    Condition = function(answers)
        return Library.Settings.StartupWizardEnabled == true
            and answers.VisualProfile == "Performance"
    end,
})

task.spawn(finishLoader)

-- Pre-queue if supported. It only works if the local source exists at
-- Experiment17/visuals.lua or Library.TeleportLoader is provided.
Library:EnableTeleportAutoload()

--============================================================
-- PUBLIC API EXAMPLE
--============================================================
--[[
    -- Queue these immediately after loading the library. They appear after the
    -- loading window and before the main GUI.

    Library:QueueStartupQuestion({
        Title = {
            en = "Visual profile",
            ru = "Профиль визуалов",
        },

        Question = {
            en = "What do you want from the visuals?",
            ru = "Чего вы добиваетесь визуалами?",
        },

        Options = {
            {
                Text = {en = "Balance", ru = "Баланс"},
                Value = "Balance",
            },
            {
                Text = {en = "Performance", ru = "Производительность"},
                Value = "Performance",
            },
            {
                Text = {en = "Beauty", ru = "Красота"},
                Value = "Beauty",
            },
        },

        Flag = "VisualProfile",

        Callback = function(answer)
            print("Visual profile:", answer)
        end,
    })

    Library:QueueStartupConfirm({
        Title = {
            en = "Optimization",
            ru = "Оптимизация",
        },

        Question = {
            en = "Enable aggressive optimization?",
            ru = "Включить жесткую оптимизацию?",
        },

        Flag = "AggressiveOptimization",

        DependsOn = {
            VisualProfile = "Performance",
        },

        Callback = function(yes)
            print("Aggressive optimization:", yes)
        end,
    })

    local MyTab = Library:CreateTab("My Tab")
    local Section = MyTab:CreateSection("Effects", false)

    Section:AddToggle({
        Name = "Example",
        Flag = "ExampleToggle",
        Default = false,
        RequiredGraphics = "High",

        -- Hover tooltip metadata:
        Description = "What this function does and any important notes.",
        FPSImpact = {-8, -3},   -- table, number or custom string
        PingImpact = 0,        -- positive = raises ping, negative = lowers it

        Callback = function(enabled)
            print(enabled)
        end,
    })

    Section:AddSlider({
        Name = "Amount",
        Flag = "ExampleAmount",
        Min = 0,
        Max = 100,