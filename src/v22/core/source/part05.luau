        PreparingInterface="Przygotowywanie interfejsu...", ApplyingConfiguration="Stosowanie konfiguracji...",
        Finalizing="Finalizowanie...", Ready="Gotowe",
        Question="Pytanie", Confirmation="Potwierdzenie", Yes="Tak", No="Nie", Continue="Dalej",
    },

    tr = {
        Settings="Ayarlar", Interface="Arayüz", Animations="Animasyonlar", Tooltips="İpuçları",
        Theme="Tema", Watermarks="Filigranlar", Configs="Yapılandırmalar", Home="Ana Sayfa",
        Language="Dil", GraphicsLevel="Grafik seviyesi", Font="Yazı tipi", TextSize="Yazı boyutu",
        DPIScale="DPI ölçeği", AutoFitToDisplay="Ekrana otomatik sığdır", FunctionDPI="Fonksiyon DPI",
        MenuKeybind="Menü tuşu", CornerRadius="Köşe yuvarlaklığı", BackgroundBlur="Arka plan bulanıklığı",
        BlurStrength="Bulanıklık gücü", BackgroundDim="Arka plan karartma", DimAmount="Karartma miktarı",
        ControlMotion="Kontrol hareketi", OpenAnimation="Menü animasyonu", AnimationSpeed="Animasyon hızı",
        WindowDragging="Pencere sürükleme", DragFollowSpeed="Takip hızı",
        FunctionTooltips="Fonksiyon ipuçları", TooltipDelay="İpucu gecikmesi", TooltipFollowSpeed="İpucu takip hızı",
        ThemePreset="Tema ön ayarı", Accent="Vurgu", Background="Arka plan", Outline="Çerçeve",
        ControlBackground="Kontrol arka planı", EnableWatermark="Filigranı aç", WatermarkText="Filigran metni",
        ShowGraphicsLevel="Grafik seviyesini göster", ShowFPS="FPS göster", ShowPing="Ping göster",
        ShowOSTime="Sistem saatini göster", DraggableWatermark="Sürüklenebilir filigran",
        ResetWatermarkPosition="Konumu sıfırla", ConfigName="Yapılandırma adı",
        SaveCurrentConfig="Yapılandırmayı kaydet", LoadConfig="Yapılandırmayı yükle", AutoloadConfig="Otomatik yükleme",
        SetAsAutoload="Otomatik yükleme yap", QueueOnTeleport="Işınlanma sonrası yükle",
        Reset="Sıfırla", Save="Kaydet", Load="Yükle", Set="Ayarla", Queue="Ekle",
        NoDescription="Açıklama yok.", NotSpecified="belirtilmedi", Graphics="Grafik",
        Locked="KİLİTLİ", Available="KULLANILABİLİR", FPSImpact="FPS etkisi", PingImpact="Ping etkisi",
        TooltipDesc="Üzerine gelindiğinde fonksiyon açıklamasını ve tahmini FPS/ping etkisini gösterir.",
        TooltipDelayDesc="İpucunun görünmeden önceki gecikmesi. Değer saniyenin yüzde biri olarak tutulur.",
        TooltipFollowDesc="İpucunun fareyi ne kadar hızlı takip ettiği. Düşük değerler daha fazla gecikme oluşturur.",
        GreetingNight="İyi geceler.", GreetingWhyAwake="Neden hâlâ uyumadın?",
        GreetingEarly="Erken mi uyandın yoksa hiç uyumadın mı?", GreetingMorning="Günaydın.",
        GreetingEvening="İyi akşamlar.", GreetingSleepSoon="Yakında uyumalısın.",
        HelloUser="Merhaba, %s. %s",
        LoadingInterface="Arayüz yükleniyor...", LoadingModules="Modüller yükleniyor...",
        PreparingInterface="Arayüz hazırlanıyor...", ApplyingConfiguration="Yapılandırma uygulanıyor...",
        Finalizing="Tamamlanıyor...", Ready="Hazır",
        Question="Soru", Confirmation="Onay", Yes="Evet", No="Hayır", Continue="Devam",
    },
}

local CONFIG_FOLDER = "Experiment17"
local CONFIG_SUBFOLDER = CONFIG_FOLDER .. "/configs"
local AUTOLOAD_FILE = CONFIG_FOLDER .. "/autoload.txt"
local DEFAULT_TELEPORT_SCRIPT = CONFIG_FOLDER .. "/visuals.lua"

--============================================================
-- ENVIRONMENT COMPATIBILITY
--============================================================

local function globalFunction(name)
    local ok, value = pcall(function()
        if getgenv then
            return getgenv()[name]
        end
        return _G[name]
    end)
    if ok and type(value) == "function" then
        return value
    end
    return nil
end

local writefileFn = globalFunction("writefile")
local readfileFn = globalFunction("readfile")
local isfileFn = globalFunction("isfile")
local makefolderFn = globalFunction("makefolder")
local isfolderFn = globalFunction("isfolder")
local listfilesFn = globalFunction("listfiles")
local delfileFn = globalFunction("delfile")
local setclipboardFn = globalFunction("setclipboard") or globalFunction("toclipboard")
local loadstringFn = globalFunction("loadstring") or loadstring

local queueTeleportFn = globalFunction("queue_on_teleport")
if not queueTeleportFn then
    pcall(function()
        if syn and syn.queue_on_teleport then
            queueTeleportFn = syn.queue_on_teleport
        end
    end)
end

local FS_AVAILABLE = writefileFn and readfileFn and isfileFn

local function ensureFolders()
    if not FS_AVAILABLE then
        return
    end

    if makefolderFn then
        pcall(function()
            if not isfolderFn or not isfolderFn(CONFIG_FOLDER) then
                makefolderFn(CONFIG_FOLDER)
            end
        end)
        pcall(function()
            if not isfolderFn or not isfolderFn(CONFIG_SUBFOLDER) then
                makefolderFn(CONFIG_SUBFOLDER)
            end
        end)
    end
end

ensureFolders()

--============================================================
-- BASIC HELPERS
--============================================================

local function Create(className, props)
    local obj = Instance.new(className)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    return obj
end

local function safeCallback(callback, ...)
    if not callback then
        return
    end

    local ok, err = pcall(callback, ...)
    if not ok then
        warn("[Experiment17 UI] Callback error:", err)
    end
end

local function cloneTable(t)
    local result = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            result[k] = cloneTable(v)
        else
            result[k] = v
        end
    end
    return result
end

local function lerpValue(a, b, alpha)
    local typeA = typeof(a)
    if typeA == "number" then
        return a + (b - a) * alpha
    elseif typeA == "Color3" then
        return a:Lerp(b, alpha)
    elseif typeA == "UDim2" then
        return a:Lerp(b, alpha)
    elseif typeA == "Vector2" then
        return a:Lerp(b, alpha)
    end
    return b
end

local function colorToTable(color)
    return {
        __type = "Color3",
        r = math.floor(color.R * 255 + 0.5),
        g = math.floor(color.G * 255 + 0.5),
        b = math.floor(color.B * 255 + 0.5),
    }
end

local function encodeValue(value)
    if typeof(value) == "Color3" then
        return colorToTable(value)
    end
    return value
end

local function decodeValue(value)
    if type(value) == "table" and value.__type == "Color3" then
        return Color3.fromRGB(value.r or 255, value.g or 255, value.b or 255)
    end
    return value
end

local function sanitizeName(name)
    name = tostring(name or "default")
    name = name:gsub("[^%w%-%_ ]", "")
    name = name:gsub("%s+", "_")
    if name == "" then
        name = "default"
    end
    return name
end

--============================================================
-- LIBRARY
--============================================================

local Library = {
    Theme = cloneTable(THEMES.Violet),
    ThemeName = "Violet",

    Flags = {},
    Controls = {},
    GatedControls = {},
    ThemeBindings = {},
    FontObjects = {},
    AdaptiveCorners = {},
    ControlFrames = {},
    ThemeColorControls = {},
    SectionByItems = {},
    LocalizationBindings = {},
    StartupPrompts = {},
    StartupCompleted = false,
    PromptBusy = false,
    ActivePromptOverlay = nil,
    StartupAnswers = {},
    Profiles = {},
    ActiveProfile = "Custom",
    FavoriteControls = {},
    FavoriteOrder = {},
    KeybindRegistry = {},
    ConfigMigrations = {},
    MenuAnimationToken = 0,
    MenuTweens = {},
    MenuAnimating = false,
    NotificationItems = {},
    SearchResults = {},
    DependencyRefreshQueued = false,
    GradientObjects = {},
    NextTabLayoutOrder = 0,
    RGBAccumulator = 0,

    CurrentTab = nil,
    MenuVisible = false,
    ActiveDropdown = nil,
    BindingKey = nil,
    SuppressMenuKey = false,
    Unloaded = false,

    Settings = {
        Language = "Auto",
        GraphicsLevel = "Epic",
        Font = "Oswald",
        MenuKey = "RightShift",
        DPIPreset = "100%",
        AutoFitDPI = true,
        FunctionDPIPreset = "95%",
        TextScale = 150,
        CornerRadius = 8,
        BlurEnabled = true,
        BlurSize = 18,
        DimEnabled = true,
        DimTransparency = 0.35,
        AnimationMode = "Smooth",
        OpenAnimation = "Scale",
        AnimationSpeed = 0.18,
        DragMode = "Smooth",
        DragSmoothness = 16,
        TooltipsEnabled = true,
        TooltipDelay = 0.12,
        TooltipFollowSpeed = 22,
        NotificationPosition = "Bottom Right",
        NotificationDuration = 4,
        NotificationLimit = 5,
        KeybindListEnabled = true,
        KeybindListPosition = "Bottom Left",
        KeybindListCustomPosition = nil,
        StartupWizardEnabled = true,

        RGBMenuStyle = false,
        RGBSpeed = 0.12,
        GradientsEnabled = true,
        GradientPreset = "Violet Dream",
        GradientAnimated = true,
        GradientSpeed = 24,
        GradientRotation = 25,
        GradientIntensity = 28,
        GradientColorA = Color3.fromRGB(124, 58, 237),
        GradientColorB = Color3.fromRGB(34, 211, 238),

        MobileButtonEnabled = true,
        MobileButtonText = "E17",
        MobileButtonSize = 54,
        MobileButtonOpacity = 100,
        MobileButtonDraggable = true,
        MobileButtonPosition = nil,

        AutoloadConfig = true,
        WatermarkEnabled = true,
        WatermarkText = "Experiment 17 [Visuals]",
        WatermarkShowGraphics = true,
        WatermarkShowFPS = true,
        WatermarkShowPing = true,
        WatermarkShowTime = true,
        WatermarkDraggable = true,
        WatermarkX = -1, -- -1 = automatic top-right
        WatermarkY = 16,
    },

    CurrentConfigName = "default",
    TeleportLoader = nil,
    WindowPosition = UDim2.fromScale(0.5, 0.5),
}

--============================================================
-- LOCALIZATION RUNTIME
--============================================================

function Library:GetRobloxLanguageCode()
    local locale = "en-us"
    pcall(function()
        locale = tostring(LocalizationService.RobloxLocaleId or "en-us"):lower()
    end)

    locale = locale:gsub("_", "-")
    local prefix = locale:match("^([a-z][a-z])") or "en"
    return LOCALE_PREFIX_MAP[prefix] or "en"
end

function Library:GetLanguageCode()
    local selected = tostring(self.Settings.Language or "Auto")
    if selected == "Auto" then
        return self:GetRobloxLanguageCode()
    end
    return LOCALIZATION[selected] and selected or "en"
end

function Library:GetLanguageDisplay(code)
    return LANGUAGE_CODE_TO_DISPLAY[tostring(code or "Auto")] or LANGUAGE_CODE_TO_DISPLAY.Auto
end

function Library:L(key)
    local code = self:GetLanguageCode()
    local selected = LOCALIZATION[code] or LOCALIZATION.en
    if selected[key] ~= nil then
        return tostring(selected[key])
    end
    if LOCALIZATION.en[key] ~= nil then
        return tostring(LOCALIZATION.en[key])
    end
    return tostring(key)
end

function Library:ResolveLocalizedText(value, fallback)
    if type(value) == "table" then
        local code = self:GetLanguageCode()
        local resolved =
