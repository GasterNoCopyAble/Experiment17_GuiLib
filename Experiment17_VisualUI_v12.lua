--[[
    Experiment 17 [Visuals] - UI Library v12
    Single-file LocalScript / client-side UI framework.

    Features:
      • Loading screen + particles + dim background
      • Left tabs + top breadcrumb
      • Collapsible sections
      • Toggle / Slider / Dropdown / Keybind / Input / Button / ColorPicker
      • Graphics gates: Low, LM, Medium, MH, High, HE, Epic
      • Locked controls are darker and cannot be used
      • Smooth / Stepped control motion for toggles and sliders
      • Menu opening animations
      • Blur + background dim settings
      • Theme presets + live HSV palette color editing
      • Font selection
      • DPI presets + optional automatic display fitting
      • Config save/load/autoload when filesystem APIs exist
      • Watermark controls + unload/minimize sidebar buttons
      • Draggable watermark + ping + OS time
      • Global text scale + separate function/control scale
      • Group separators live BETWEEN related control groups
      • Sections start collapsed by default
      • Animated tab/page, section, dropdown and color-picker transitions
      • Smooth/direct window dragging with configurable follow speed
      • Minimum 5-second loader window before the UI opens
      • RobloxLocaleId language auto-detection + manual language selector
      • Opaque black animation shell (background never fades during menu motion)
      • Extreme menu motion: 4000px slide + stronger scale animation
      • Slow smooth section expansion + staggered function appearance
      • Startup question / confirm modal API
      • Improved loader entrance, progress percentage and transitions
      • Optional queue_on_teleport loader hook

    Default font: Oswald
    Default menu key: RightShift (rebindable in Settings)
]]

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local LocalizationService = game:GetService("LocalizationService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--============================================================
-- SETTINGS / CONSTANTS
--============================================================

local GRAPHICS_ORDER = {
    Low = 1,
    LM = 2,
    Medium = 3,
    MH = 4,
    High = 5,
    HE = 6,
    Epic = 7,
}

local GRAPHICS_LIST = {"Low", "LM", "Medium", "MH", "High", "HE", "Epic"}

local FONT_MAP = {
    Oswald = Enum.Font.Oswald,
    Gotham = Enum.Font.Gotham,
    GothamMedium = Enum.Font.GothamMedium,
    GothamBold = Enum.Font.GothamBold,
    Code = Enum.Font.Code,
    RobotoMono = Enum.Font.RobotoMono,
    SourceSans = Enum.Font.SourceSans,
}

local FONT_LIST = {"Oswald", "Gotham", "GothamMedium", "Code", "RobotoMono", "SourceSans"}

-- 100% is intentionally 1.15x larger than the old v2 window.
-- Higher/lower presets are relative to that new 100% baseline.
local DPI_BASE_SCALE = 1.15
local DPI_VALUES = {
    ["175%"] = 175,
    ["150%"] = 150,
    ["125%"] = 125,
    ["100%"] = 100,
    ["75%"] = 75,
    ["50%"] = 50,
    ["25%"] = 25,
    ["5%"] = 5,
}
local DPI_LIST = {"175%", "150%", "125%", "100%", "75%", "50%", "25%", "5%"}
local DPI_FIT_ORDER = {175, 150, 125, 100, 75, 50, 25, 5}
local BASE_WINDOW_SIZE = Vector2.new(780, 500)
local DPI_SCREEN_MARGIN = Vector2.new(34, 34)

-- Controls can be visually smaller than their section header.
-- This is intentionally independent from the whole-window DPI.
local FUNCTION_DPI_VALUES = {
    ["100%"] = 100,
    ["95%"] = 95,
    ["90%"] = 90,
    ["85%"] = 85,
    ["80%"] = 80,
    ["75%"] = 75,
    ["50%"] = 50,
    ["25%"] = 25,
}
local FUNCTION_DPI_LIST = {"100%", "95%", "90%", "85%", "80%", "75%", "50%", "25%"}

local THEMES = {
    Violet = {
        Background = Color3.fromRGB(8, 8, 11),
        Panel = Color3.fromRGB(13, 13, 18),
        Control = Color3.fromRGB(19, 19, 26),
        Control2 = Color3.fromRGB(27, 27, 36),
        Accent = Color3.fromRGB(139, 92, 246),
        Outline = Color3.fromRGB(116, 72, 205),
        Text = Color3.fromRGB(239, 237, 245),
        SubText = Color3.fromRGB(150, 146, 162),
    },

    Mono = {
        Background = Color3.fromRGB(7, 7, 7),
        Panel = Color3.fromRGB(14, 14, 14),
        Control = Color3.fromRGB(20, 20, 20),
        Control2 = Color3.fromRGB(28, 28, 28),
        Accent = Color3.fromRGB(210, 210, 210),
        Outline = Color3.fromRGB(90, 90, 90),
        Text = Color3.fromRGB(245, 245, 245),
        SubText = Color3.fromRGB(145, 145, 145),
    },

    Crimson = {
        Background = Color3.fromRGB(10, 7, 8),
        Panel = Color3.fromRGB(18, 11, 13),
        Control = Color3.fromRGB(27, 15, 18),
        Control2 = Color3.fromRGB(38, 20, 24),
        Accent = Color3.fromRGB(225, 65, 95),
        Outline = Color3.fromRGB(170, 42, 65),
        Text = Color3.fromRGB(245, 236, 239),
        SubText = Color3.fromRGB(165, 138, 145),
    },

    Emerald = {
        Background = Color3.fromRGB(6, 10, 9),
        Panel = Color3.fromRGB(10, 18, 15),
        Control = Color3.fromRGB(15, 27, 23),
        Control2 = Color3.fromRGB(21, 38, 32),
        Accent = Color3.fromRGB(52, 211, 153),
        Outline = Color3.fromRGB(35, 150, 110),
        Text = Color3.fromRGB(235, 245, 241),
        SubText = Color3.fromRGB(136, 163, 152),
    },
}

local THEME_LIST = {"Violet", "Mono", "Crimson", "Emerald"}


--============================================================
-- LOCALIZATION
--============================================================

-- Auto follows the language selected in Roblox through
-- LocalizationService.RobloxLocaleId. Unsupported locales use English.
local LANGUAGE_CHOICES = {
    "Auto (Roblox)",
    "English",
    "Русский",
    "Українська",
    "Español",
    "Deutsch",
    "Français",
    "Português",
    "Polski",
    "Türkçe",
}

local LANGUAGE_DISPLAY_TO_CODE = {
    ["Auto (Roblox)"] = "Auto",
    ["English"] = "en",
    ["Русский"] = "ru",
    ["Українська"] = "uk",
    ["Español"] = "es",
    ["Deutsch"] = "de",
    ["Français"] = "fr",
    ["Português"] = "pt",
    ["Polski"] = "pl",
    ["Türkçe"] = "tr",
}

local LANGUAGE_CODE_TO_DISPLAY = {
    Auto = "Auto (Roblox)",
    en = "English",
    ru = "Русский",
    uk = "Українська",
    es = "Español",
    de = "Deutsch",
    fr = "Français",
    pt = "Português",
    pl = "Polski",
    tr = "Türkçe",
}

local LOCALE_PREFIX_MAP = {
    en = "en", ru = "ru", uk = "uk", es = "es", de = "de",
    fr = "fr", pt = "pt", pl = "pl", tr = "tr",
}

local LOCALIZATION = {
    en = {
        Settings="Settings", Interface="Interface", Animations="Animations", Tooltips="Tooltips",
        Theme="Theme", Watermarks="Watermarks", Configs="Configs", Home="Home",
        Language="Language", GraphicsLevel="Graphics Level", Font="Font", TextSize="Text Size",
        DPIScale="DPI Scale", AutoFitToDisplay="Auto Fit To Display", FunctionDPI="Function DPI",
        MenuKeybind="Menu Keybind", CornerRadius="Corner Radius", BackgroundBlur="Background Blur",
        BlurStrength="Blur Strength", BackgroundDim="Background Dim", DimAmount="Dim Amount",
        ControlMotion="Control Motion", OpenAnimation="Open Animation", AnimationSpeed="Animation Speed",
        WindowDragging="Window Dragging", DragFollowSpeed="Drag Follow Speed",
        FunctionTooltips="Function Tooltips", TooltipDelay="Tooltip Delay", TooltipFollowSpeed="Tooltip Follow Speed",
        ThemePreset="Theme Preset", Accent="Accent", Background="Background", Outline="Outline",
        ControlBackground="Control Background", EnableWatermark="Enable Watermark", WatermarkText="Watermark Text",
        ShowGraphicsLevel="Show Graphics Level", ShowFPS="Show FPS", ShowPing="Show Ping",
        ShowOSTime="Show OS Time", DraggableWatermark="Draggable Watermark",
        ResetWatermarkPosition="Reset Watermark Position", ConfigName="Config Name",
        SaveCurrentConfig="Save Current Config", LoadConfig="Load Config", AutoloadConfig="Autoload Config",
        SetAsAutoload="Set As Autoload", QueueOnTeleport="Queue On Teleport",
        Reset="Reset", Save="Save", Load="Load", Set="Set", Queue="Queue",
        NoDescription="No description provided.", NotSpecified="not specified",
        Graphics="Graphics", Locked="LOCKED", Available="AVAILABLE",
        FPSImpact="FPS impact", PingImpact="Ping impact",
        TooltipDesc="Shows the function description and estimated FPS / ping impact while hovering a row.",
        TooltipDelayDesc="Delay before a hover tooltip appears. Value is stored as hundredths of a second.",
        TooltipFollowDesc="How quickly the tooltip catches up with the mouse. Lower values create more visible lag.",
        GreetingNight="Good night.", GreetingWhyAwake="Why are you still awake?",
        GreetingEarly="Did you wake up early or not sleep?", GreetingMorning="Good morning.",
        GreetingEvening="Good evening.", GreetingSleepSoon="You should probably sleep soon.",
        HelloUser="Hello, %s. %s",
        LoadingInterface="Loading interface...", LoadingModules="Loading modules...",
        PreparingInterface="Preparing interface...", ApplyingConfiguration="Applying configuration...",
        Finalizing="Finalizing...", Ready="Ready",
        Question="Question", Confirmation="Confirmation", Yes="Yes", No="No", Continue="Continue",
    },

    ru = {
        Settings="Настройки", Interface="Интерфейс", Animations="Анимации", Tooltips="Подсказки",
        Theme="Тема", Watermarks="Вотермарки", Configs="Конфиги", Home="Главная",
        Language="Язык", GraphicsLevel="Уровень графики", Font="Шрифт", TextSize="Размер текста",
        DPIScale="Масштаб DPI", AutoFitToDisplay="Автоподгон под экран", FunctionDPI="DPI функций",
        MenuKeybind="Клавиша меню", CornerRadius="Скругление", BackgroundBlur="Размытие фона",
        BlurStrength="Сила размытия", BackgroundDim="Затемнение фона", DimAmount="Сила затемнения",
        ControlMotion="Движение элементов", OpenAnimation="Анимация меню", AnimationSpeed="Скорость анимаций",
        WindowDragging="Перетаскивание окна", DragFollowSpeed="Скорость следования",
        FunctionTooltips="Подсказки функций", TooltipDelay="Задержка подсказки", TooltipFollowSpeed="Скорость подсказки",
        ThemePreset="Пресет темы", Accent="Акцент", Background="Фон", Outline="Обводка",
        ControlBackground="Фон функций", EnableWatermark="Включить вотермарк", WatermarkText="Текст вотермарка",
        ShowGraphicsLevel="Показывать графику", ShowFPS="Показывать FPS", ShowPing="Показывать пинг",
        ShowOSTime="Показывать время ОС", DraggableWatermark="Перетаскиваемый вотермарк",
        ResetWatermarkPosition="Сбросить позицию вотермарка", ConfigName="Имя конфига",
        SaveCurrentConfig="Сохранить конфиг", LoadConfig="Загрузить конфиг", AutoloadConfig="Автозагрузка конфига",
        SetAsAutoload="Сделать автозагрузкой", QueueOnTeleport="Запуск после телепорта",
        Reset="Сброс", Save="Сохранить", Load="Загрузить", Set="Установить", Queue="Добавить",
        NoDescription="Описание не указано.", NotSpecified="не указано",
        Graphics="Графика", Locked="НЕДОСТУПНО", Available="ДОСТУПНО",
        FPSImpact="Влияние на FPS", PingImpact="Влияние на пинг",
        TooltipDesc="Показывает описание функции и примерное влияние на FPS и пинг при наведении.",
        TooltipDelayDesc="Задержка перед появлением подсказки. Значение хранится в сотых долях секунды.",
        TooltipFollowDesc="Насколько быстро подсказка догоняет мышь. Меньшее значение даёт большее отставание.",
        GreetingNight="Доброй ночи.", GreetingWhyAwake="Почему не спишь?",
        GreetingEarly="Ты проснулся рано или не спал?", GreetingMorning="Доброе утро.",
        GreetingEvening="Доброго вечера.", GreetingSleepSoon="Тебе скоро спать.",
        HelloUser="Привет, %s. %s",
        LoadingInterface="Загрузка интерфейса...", LoadingModules="Загрузка модулей...",
        PreparingInterface="Подготовка интерфейса...", ApplyingConfiguration="Применение конфигурации...",
        Finalizing="Завершение...", Ready="Готово",
        Question="Вопрос", Confirmation="Подтверждение", Yes="Да", No="Нет", Continue="Продолжить",
    },

    uk = {
        Settings="Налаштування", Interface="Інтерфейс", Animations="Анімації", Tooltips="Підказки",
        Theme="Тема", Watermarks="Вотермарки", Configs="Конфіги", Home="Головна",
        Language="Мова", GraphicsLevel="Рівень графіки", Font="Шрифт", TextSize="Розмір тексту",
        DPIScale="Масштаб DPI", AutoFitToDisplay="Автопідгонка під екран", FunctionDPI="DPI функцій",
        MenuKeybind="Клавіша меню", CornerRadius="Заокруглення", BackgroundBlur="Розмиття фону",
        BlurStrength="Сила розмиття", BackgroundDim="Затемнення фону", DimAmount="Сила затемнення",
        ControlMotion="Рух елементів", OpenAnimation="Анімація меню", AnimationSpeed="Швидкість анімацій",
        WindowDragging="Перетягування вікна", DragFollowSpeed="Швидкість слідування",
        FunctionTooltips="Підказки функцій", TooltipDelay="Затримка підказки", TooltipFollowSpeed="Швидкість підказки",
        ThemePreset="Пресет теми", Accent="Акцент", Background="Фон", Outline="Обводка",
        ControlBackground="Фон функцій", EnableWatermark="Увімкнути вотермарк", WatermarkText="Текст вотермарка",
        ShowGraphicsLevel="Показувати графіку", ShowFPS="Показувати FPS", ShowPing="Показувати пінг",
        ShowOSTime="Показувати час ОС", DraggableWatermark="Перетягуваний вотермарк",
        ResetWatermarkPosition="Скинути позицію вотермарка", ConfigName="Назва конфіга",
        SaveCurrentConfig="Зберегти конфіг", LoadConfig="Завантажити конфіг", AutoloadConfig="Автозавантаження конфіга",
        SetAsAutoload="Зробити автозавантаженням", QueueOnTeleport="Запуск після телепорту",
        Reset="Скинути", Save="Зберегти", Load="Завантажити", Set="Встановити", Queue="Додати",
        NoDescription="Опис не вказано.", NotSpecified="не вказано",
        Graphics="Графіка", Locked="НЕДОСТУПНО", Available="ДОСТУПНО",
        FPSImpact="Вплив на FPS", PingImpact="Вплив на пінг",
        TooltipDesc="Показує опис функції та приблизний вплив на FPS і пінг при наведенні.",
        TooltipDelayDesc="Затримка перед появою підказки. Значення зберігається у сотих частках секунди.",
        TooltipFollowDesc="Наскільки швидко підказка наздоганяє мишу. Менше значення дає більше відставання.",
        GreetingNight="Доброї ночі.", GreetingWhyAwake="Чому не спиш?",
        GreetingEarly="Ти прокинувся рано чи не спав?", GreetingMorning="Доброго ранку.",
        GreetingEvening="Доброго вечора.", GreetingSleepSoon="Тобі скоро спати.",
        HelloUser="Привіт, %s. %s",
        LoadingInterface="Завантаження інтерфейсу...", LoadingModules="Завантаження модулів...",
        PreparingInterface="Підготовка інтерфейсу...", ApplyingConfiguration="Застосування конфігурації...",
        Finalizing="Завершення...", Ready="Готово",
        Question="Питання", Confirmation="Підтвердження", Yes="Так", No="Ні", Continue="Продовжити",
    },

    es = {
        Settings="Ajustes", Interface="Interfaz", Animations="Animaciones", Tooltips="Ayudas",
        Theme="Tema", Watermarks="Marcas de agua", Configs="Configuraciones", Home="Inicio",
        Language="Idioma", GraphicsLevel="Nivel gráfico", Font="Fuente", TextSize="Tamaño del texto",
        DPIScale="Escala DPI", AutoFitToDisplay="Ajustar a pantalla", FunctionDPI="DPI de funciones",
        MenuKeybind="Tecla del menú", CornerRadius="Radio de esquinas", BackgroundBlur="Desenfoque de fondo",
        BlurStrength="Intensidad de desenfoque", BackgroundDim="Oscurecer fondo", DimAmount="Nivel de oscurecimiento",
        ControlMotion="Movimiento de controles", OpenAnimation="Animación del menú", AnimationSpeed="Velocidad de animación",
        WindowDragging="Arrastre de ventana", DragFollowSpeed="Velocidad de seguimiento",
        FunctionTooltips="Ayudas de funciones", TooltipDelay="Retardo de ayuda", TooltipFollowSpeed="Seguimiento de ayuda",
        ThemePreset="Preajuste de tema", Accent="Acento", Background="Fondo", Outline="Contorno",
        ControlBackground="Fondo de controles", EnableWatermark="Activar marca de agua", WatermarkText="Texto de marca",
        ShowGraphicsLevel="Mostrar nivel gráfico", ShowFPS="Mostrar FPS", ShowPing="Mostrar ping",
        ShowOSTime="Mostrar hora del sistema", DraggableWatermark="Marca de agua movible",
        ResetWatermarkPosition="Restablecer posición", ConfigName="Nombre de configuración",
        SaveCurrentConfig="Guardar configuración", LoadConfig="Cargar configuración", AutoloadConfig="Carga automática",
        SetAsAutoload="Usar como carga automática", QueueOnTeleport="Cargar tras teletransporte",
        Reset="Restablecer", Save="Guardar", Load="Cargar", Set="Establecer", Queue="Añadir",
        NoDescription="Sin descripción.", NotSpecified="no especificado", Graphics="Gráficos",
        Locked="BLOQUEADO", Available="DISPONIBLE", FPSImpact="Impacto en FPS", PingImpact="Impacto en ping",
        TooltipDesc="Muestra la descripción de la función y el impacto estimado en FPS y ping al pasar el cursor.",
        TooltipDelayDesc="Retardo antes de mostrar la ayuda. El valor se guarda en centésimas de segundo.",
        TooltipFollowDesc="Qué tan rápido la ayuda sigue al ratón. Los valores bajos crean más retraso.",
        GreetingNight="Buenas noches.", GreetingWhyAwake="¿Por qué sigues despierto?",
        GreetingEarly="¿Te levantaste temprano o no dormiste?", GreetingMorning="Buenos días.",
        GreetingEvening="Buenas tardes.", GreetingSleepSoon="Pronto deberías dormir.",
        HelloUser="Hola, %s. %s",
        LoadingInterface="Cargando interfaz...", LoadingModules="Cargando módulos...",
        PreparingInterface="Preparando interfaz...", ApplyingConfiguration="Aplicando configuración...",
        Finalizing="Finalizando...", Ready="Listo",
        Question="Pregunta", Confirmation="Confirmación", Yes="Sí", No="No", Continue="Continuar",
    },

    de = {
        Settings="Einstellungen", Interface="Oberfläche", Animations="Animationen", Tooltips="Tooltips",
        Theme="Design", Watermarks="Wasserzeichen", Configs="Konfigurationen", Home="Start",
        Language="Sprache", GraphicsLevel="Grafikstufe", Font="Schriftart", TextSize="Textgröße",
        DPIScale="DPI-Skalierung", AutoFitToDisplay="An Bildschirm anpassen", FunctionDPI="Funktions-DPI",
        MenuKeybind="Menütaste", CornerRadius="Eckenradius", BackgroundBlur="Hintergrundunschärfe",
        BlurStrength="Unschärfestärke", BackgroundDim="Hintergrund abdunkeln", DimAmount="Abdunkelungsstärke",
        ControlMotion="Steuerungsbewegung", OpenAnimation="Menüanimation", AnimationSpeed="Animationsgeschwindigkeit",
        WindowDragging="Fenster ziehen", DragFollowSpeed="Folgegeschwindigkeit",
        FunctionTooltips="Funktions-Tooltips", TooltipDelay="Tooltip-Verzögerung", TooltipFollowSpeed="Tooltip-Folgegeschwindigkeit",
        ThemePreset="Design-Voreinstellung", Accent="Akzent", Background="Hintergrund", Outline="Umrandung",
        ControlBackground="Steuerungshintergrund", EnableWatermark="Wasserzeichen aktivieren", WatermarkText="Wasserzeichentext",
        ShowGraphicsLevel="Grafikstufe anzeigen", ShowFPS="FPS anzeigen", ShowPing="Ping anzeigen",
        ShowOSTime="Systemzeit anzeigen", DraggableWatermark="Wasserzeichen verschiebbar",
        ResetWatermarkPosition="Position zurücksetzen", ConfigName="Konfigurationsname",
        SaveCurrentConfig="Konfiguration speichern", LoadConfig="Konfiguration laden", AutoloadConfig="Automatisch laden",
        SetAsAutoload="Als Autoload setzen", QueueOnTeleport="Nach Teleport laden",
        Reset="Zurücksetzen", Save="Speichern", Load="Laden", Set="Setzen", Queue="Einreihen",
        NoDescription="Keine Beschreibung vorhanden.", NotSpecified="nicht angegeben", Graphics="Grafik",
        Locked="GESPERRT", Available="VERFÜGBAR", FPSImpact="FPS-Einfluss", PingImpact="Ping-Einfluss",
        TooltipDesc="Zeigt beim Darüberfahren die Funktionsbeschreibung sowie geschätzte FPS- und Ping-Auswirkungen.",
        TooltipDelayDesc="Verzögerung bis der Tooltip erscheint. Der Wert wird in Hundertstelsekunden gespeichert.",
        TooltipFollowDesc="Wie schnell der Tooltip der Maus folgt. Niedrige Werte erzeugen mehr Verzögerung.",
        GreetingNight="Gute Nacht.", GreetingWhyAwake="Warum bist du noch wach?",
        GreetingEarly="Bist du früh aufgestanden oder hast du nicht geschlafen?", GreetingMorning="Guten Morgen.",
        GreetingEvening="Guten Abend.", GreetingSleepSoon="Du solltest bald schlafen.",
        HelloUser="Hallo, %s. %s",
        LoadingInterface="Oberfläche wird geladen...", LoadingModules="Module werden geladen...",
        PreparingInterface="Oberfläche wird vorbereitet...", ApplyingConfiguration="Konfiguration wird angewendet...",
        Finalizing="Abschluss...", Ready="Bereit",
        Question="Frage", Confirmation="Bestätigung", Yes="Ja", No="Nein", Continue="Weiter",
    },

    fr = {
        Settings="Paramètres", Interface="Interface", Animations="Animations", Tooltips="Infobulles",
        Theme="Thème", Watermarks="Filigranes", Configs="Configurations", Home="Accueil",
        Language="Langue", GraphicsLevel="Niveau graphique", Font="Police", TextSize="Taille du texte",
        DPIScale="Échelle DPI", AutoFitToDisplay="Adapter à l’écran", FunctionDPI="DPI des fonctions",
        MenuKeybind="Touche du menu", CornerRadius="Arrondi des coins", BackgroundBlur="Flou d’arrière-plan",
        BlurStrength="Intensité du flou", BackgroundDim="Assombrir l’arrière-plan", DimAmount="Niveau d’assombrissement",
        ControlMotion="Mouvement des contrôles", OpenAnimation="Animation du menu", AnimationSpeed="Vitesse d’animation",
        WindowDragging="Déplacement de fenêtre", DragFollowSpeed="Vitesse de suivi",
        FunctionTooltips="Infobulles des fonctions", TooltipDelay="Délai d’infobulle", TooltipFollowSpeed="Vitesse de suivi",
        ThemePreset="Préréglage du thème", Accent="Accent", Background="Arrière-plan", Outline="Contour",
        ControlBackground="Fond des contrôles", EnableWatermark="Activer le filigrane", WatermarkText="Texte du filigrane",
        ShowGraphicsLevel="Afficher le niveau graphique", ShowFPS="Afficher les FPS", ShowPing="Afficher le ping",
        ShowOSTime="Afficher l’heure système", DraggableWatermark="Filigrane déplaçable",
        ResetWatermarkPosition="Réinitialiser la position", ConfigName="Nom de configuration",
        SaveCurrentConfig="Enregistrer la configuration", LoadConfig="Charger la configuration",
        AutoloadConfig="Chargement automatique", SetAsAutoload="Définir en chargement auto",
        QueueOnTeleport="Charger après téléportation", Reset="Réinitialiser", Save="Enregistrer",
        Load="Charger", Set="Définir", Queue="Ajouter",
        NoDescription="Aucune description.", NotSpecified="non spécifié", Graphics="Graphismes",
        Locked="VERROUILLÉ", Available="DISPONIBLE", FPSImpact="Impact FPS", PingImpact="Impact ping",
        TooltipDesc="Affiche la description de la fonction et l’impact estimé sur les FPS et le ping au survol.",
        TooltipDelayDesc="Délai avant l’apparition de l’infobulle. La valeur est stockée en centièmes de seconde.",
        TooltipFollowDesc="Vitesse à laquelle l’infobulle suit la souris. Une valeur basse augmente le retard.",
        GreetingNight="Bonne nuit.", GreetingWhyAwake="Pourquoi tu ne dors pas ?",
        GreetingEarly="Tu t’es levé tôt ou tu n’as pas dormi ?", GreetingMorning="Bonjour.",
        GreetingEvening="Bonsoir.", GreetingSleepSoon="Tu devrais bientôt dormir.",
        HelloUser="Salut, %s. %s",
        LoadingInterface="Chargement de l’interface...", LoadingModules="Chargement des modules...",
        PreparingInterface="Préparation de l’interface...", ApplyingConfiguration="Application de la configuration...",
        Finalizing="Finalisation...", Ready="Prêt",
        Question="Question", Confirmation="Confirmation", Yes="Oui", No="Non", Continue="Continuer",
    },

    pt = {
        Settings="Configurações", Interface="Interface", Animations="Animações", Tooltips="Dicas",
        Theme="Tema", Watermarks="Marcas d'água", Configs="Configurações salvas", Home="Início",
        Language="Idioma", GraphicsLevel="Nível gráfico", Font="Fonte", TextSize="Tamanho do texto",
        DPIScale="Escala DPI", AutoFitToDisplay="Ajustar à tela", FunctionDPI="DPI das funções",
        MenuKeybind="Tecla do menu", CornerRadius="Raio dos cantos", BackgroundBlur="Desfoque do fundo",
        BlurStrength="Força do desfoque", BackgroundDim="Escurecer fundo", DimAmount="Nível de escurecimento",
        ControlMotion="Movimento dos controles", OpenAnimation="Animação do menu", AnimationSpeed="Velocidade da animação",
        WindowDragging="Arrastar janela", DragFollowSpeed="Velocidade de seguimento",
        FunctionTooltips="Dicas das funções", TooltipDelay="Atraso da dica", TooltipFollowSpeed="Velocidade da dica",
        ThemePreset="Predefinição do tema", Accent="Destaque", Background="Fundo", Outline="Contorno",
        ControlBackground="Fundo dos controles", EnableWatermark="Ativar marca d'água", WatermarkText="Texto da marca",
        ShowGraphicsLevel="Mostrar nível gráfico", ShowFPS="Mostrar FPS", ShowPing="Mostrar ping",
        ShowOSTime="Mostrar hora do sistema", DraggableWatermark="Marca d'água arrastável",
        ResetWatermarkPosition="Redefinir posição", ConfigName="Nome da configuração",
        SaveCurrentConfig="Salvar configuração", LoadConfig="Carregar configuração", AutoloadConfig="Carregamento automático",
        SetAsAutoload="Definir como automático", QueueOnTeleport="Carregar após teleporte",
        Reset="Redefinir", Save="Salvar", Load="Carregar", Set="Definir", Queue="Adicionar",
        NoDescription="Sem descrição.", NotSpecified="não especificado", Graphics="Gráficos",
        Locked="BLOQUEADO", Available="DISPONÍVEL", FPSImpact="Impacto no FPS", PingImpact="Impacto no ping",
        TooltipDesc="Mostra a descrição da função e o impacto estimado no FPS e ping ao passar o mouse.",
        TooltipDelayDesc="Atraso antes da dica aparecer. O valor é armazenado em centésimos de segundo.",
        TooltipFollowDesc="Velocidade com que a dica segue o mouse. Valores menores criam mais atraso.",
        GreetingNight="Boa noite.", GreetingWhyAwake="Por que você ainda está acordado?",
        GreetingEarly="Você acordou cedo ou não dormiu?", GreetingMorning="Bom dia.",
        GreetingEvening="Boa noite.", GreetingSleepSoon="Você deveria dormir em breve.",
        HelloUser="Olá, %s. %s",
        LoadingInterface="Carregando interface...", LoadingModules="Carregando módulos...",
        PreparingInterface="Preparando interface...", ApplyingConfiguration="Aplicando configuração...",
        Finalizing="Finalizando...", Ready="Pronto",
        Question="Pergunta", Confirmation="Confirmação", Yes="Sim", No="Não", Continue="Continuar",
    },

    pl = {
        Settings="Ustawienia", Interface="Interfejs", Animations="Animacje", Tooltips="Podpowiedzi",
        Theme="Motyw", Watermarks="Znaki wodne", Configs="Konfiguracje", Home="Start",
        Language="Język", GraphicsLevel="Poziom grafiki", Font="Czcionka", TextSize="Rozmiar tekstu",
        DPIScale="Skala DPI", AutoFitToDisplay="Dopasuj do ekranu", FunctionDPI="DPI funkcji",
        MenuKeybind="Klawisz menu", CornerRadius="Zaokrąglenie", BackgroundBlur="Rozmycie tła",
        BlurStrength="Siła rozmycia", BackgroundDim="Przyciemnienie tła", DimAmount="Poziom przyciemnienia",
        ControlMotion="Ruch elementów", OpenAnimation="Animacja menu", AnimationSpeed="Szybkość animacji",
        WindowDragging="Przeciąganie okna", DragFollowSpeed="Szybkość podążania",
        FunctionTooltips="Podpowiedzi funkcji", TooltipDelay="Opóźnienie podpowiedzi", TooltipFollowSpeed="Szybkość podpowiedzi",
        ThemePreset="Preset motywu", Accent="Akcent", Background="Tło", Outline="Obrys",
        ControlBackground="Tło elementów", EnableWatermark="Włącz znak wodny", WatermarkText="Tekst znaku wodnego",
        ShowGraphicsLevel="Pokaż poziom grafiki", ShowFPS="Pokaż FPS", ShowPing="Pokaż ping",
        ShowOSTime="Pokaż czas systemu", DraggableWatermark="Przesuwalny znak wodny",
        ResetWatermarkPosition="Resetuj pozycję", ConfigName="Nazwa konfiguracji",
        SaveCurrentConfig="Zapisz konfigurację", LoadConfig="Wczytaj konfigurację", AutoloadConfig="Automatyczne wczytywanie",
        SetAsAutoload="Ustaw jako autoload", QueueOnTeleport="Wczytaj po teleportacji",
        Reset="Resetuj", Save="Zapisz", Load="Wczytaj", Set="Ustaw", Queue="Dodaj",
        NoDescription="Brak opisu.", NotSpecified="nie podano", Graphics="Grafika",
        Locked="ZABLOKOWANE", Available="DOSTĘPNE", FPSImpact="Wpływ na FPS", PingImpact="Wpływ na ping",
        TooltipDesc="Pokazuje opis funkcji i szacowany wpływ na FPS oraz ping po najechaniu.",
        TooltipDelayDesc="Opóźnienie przed pojawieniem się podpowiedzi. Wartość jest w setnych sekundy.",
        TooltipFollowDesc="Jak szybko podpowiedź podąża za myszą. Niższe wartości dają większe opóźnienie.",
        GreetingNight="Dobranoc.", GreetingWhyAwake="Dlaczego jeszcze nie śpisz?",
        GreetingEarly="Wstałeś wcześnie czy nie spałeś?", GreetingMorning="Dzień dobry.",
        GreetingEvening="Dobry wieczór.", GreetingSleepSoon="Niedługo powinieneś iść spać.",
        HelloUser="Cześć, %s. %s",
        LoadingInterface="Ładowanie interfejsu...", LoadingModules="Ładowanie modułów...",
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
        TextScale = 100,
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
            value[code]
            or value.en
            or value.default
            or value[1]

        if resolved ~= nil then
            return tostring(resolved)
        end
    elseif value ~= nil then
        return tostring(value)
    end

    if fallback ~= nil then
        return tostring(fallback)
    end

    return ""
end

function Library:BindLocaleText(object, key, property)
    if not object or not key then
        return
    end

    property = property or "Text"
    object[property] = self:L(key)
    table.insert(self.LocalizationBindings, {
        Object = object,
        Key = key,
        Property = property,
    })
end

function Library:RefreshLocalization()
    for _, binding in ipairs(self.LocalizationBindings) do
        local object = binding.Object
        if object and object.Parent then
            object[binding.Property] = self:L(binding.Key)
        end
    end

    for _, tab in ipairs(self.Tabs or {}) do
        if tab.LocaleKey then
            tab.Name = self:L(tab.LocaleKey)
            if tab.TabText and tab.TabText.Parent then
                tab.TabText.Text = tab.Name
            end
        end
    end

    for _, control in ipairs(self.Controls or {}) do
        if control.LocaleKey then
            control.DisplayName = self:L(control.LocaleKey)
            if control.Label and control.Label.Parent then
                control.Label.Text = control.DisplayName
            end
        end
        if control.DescriptionKey then
            control.Description = self:L(control.DescriptionKey)
        end
    end

    if self.CurrentTab and self.Breadcrumb and self.Breadcrumb.Parent then
        self.Breadcrumb.Text = self.CurrentTab.LocaleKey and self:L(self.CurrentTab.LocaleKey) or self.CurrentTab.Name
    elseif self.Breadcrumb and self.Breadcrumb.Parent then
        self.Breadcrumb.Text = self:L("Home")
    end

    if self.LanguageChoiceControl and self.LanguageChoiceControl.Set then
        local display = self:GetLanguageDisplay(self.Settings.Language)
        if self.LanguageChoiceControl:Get() ~= display then
            self.LanguageChoiceControl:Set(display, true)
        end
    end

    if self.RefreshWatermark then
        self:RefreshWatermark()
    end
end

function Library:SetLanguage(selection)
    local raw = tostring(selection or "Auto")
    local code = LANGUAGE_DISPLAY_TO_CODE[raw] or raw

    if code ~= "Auto" and not LOCALIZATION[code] then
        code = "en"
    end

    self.Settings.Language = code
    self:RefreshLocalization()
    return code
end

pcall(function()
    LocalizationService:GetPropertyChangedSignal("RobloxLocaleId"):Connect(function()
        if not Library.Unloaded and Library.Settings.Language == "Auto" then
            Library:RefreshLocalization()
        end
    end)
end)

--============================================================
-- THEME / FONT / CORNERS
--============================================================

function Library:BindTheme(object, property, key)
    object[property] = self.Theme[key]
    table.insert(self.ThemeBindings, {
        Object = object,
        Property = property,
        Key = key,
    })
end

function Library:RegisterFont(object, bold)
    local baseTextSize = tonumber(object.TextSize) or 12

    table.insert(self.FontObjects, {
        Object = object,
        Bold = bold == true,
        BaseTextSize = baseTextSize,
    })

    -- Keep one visual font family across the whole interface.
    -- Some legacy Enum.Font families (including Oswald) do not expose
    -- a separate Bold enum, so headings use the same family as controls.
    object.Font = FONT_MAP[self.Settings.Font] or Enum.Font.Oswald
    object.TextSize = math.max(6, math.floor(baseTextSize * ((self.Settings.TextScale or 100) / 100) + 0.5))
end

function Library:SetTextScale(percent)
    percent = math.clamp(tonumber(percent) or 100, 50, 200)
    self.Settings.TextScale = percent

    for _, item in ipairs(self.FontObjects) do
        if item.Object and item.Object.Parent then
            local base = item.BaseTextSize or 12
            item.Object.TextSize = math.max(6, math.floor(base * (percent / 100) + 0.5))
        end
    end

    if self.RefreshWatermark then
        self:RefreshWatermark()
    end
end

function Library:GetFunctionDPIScale()
    return (FUNCTION_DPI_VALUES[self.Settings.FunctionDPIPreset] or 95) / 100
end

function Library:ApplyFunctionDPIScale()
    local scale = self:GetFunctionDPIScale()

    for _, item in ipairs(self.ControlFrames) do
        local object = item.Object
        if object and object.Parent then
            local current = object.Size
            object.Size = UDim2.new(scale, 0, current.Y.Scale, current.Y.Offset)

            if item.ManualCenter then
                object.Position = UDim2.new((1 - scale) * 0.5, 0, object.Position.Y.Scale, object.Position.Y.Offset)
            end
        end
    end
end

function Library:SetFunctionDPIPreset(preset)
    preset = tostring(preset or "95%")
    if not FUNCTION_DPI_VALUES[preset] then
        return
    end

    self.Settings.FunctionDPIPreset = preset
    self:ApplyFunctionDPIScale()
end

function Library:AdaptiveCorner(object, radiusOffset)
    local corner = Create("UICorner", {
        Parent = object,
        CornerRadius = UDim.new(0, math.max(0, self.Settings.CornerRadius + (radiusOffset or 0))),
    })

    table.insert(self.AdaptiveCorners, {
        Corner = corner,
        Offset = radiusOffset or 0,
    })

    return corner
end

function Library:SetCornerRadius(radius)
    radius = math.clamp(tonumber(radius) or 8, 0, 24)
    self.Settings.CornerRadius = radius

    for _, item in ipairs(self.AdaptiveCorners) do
        if item.Corner and item.Corner.Parent then
            item.Corner.CornerRadius = UDim.new(0, math.max(0, radius + item.Offset))
        end
    end
end

function Library:SetFont(fontName)
    if not FONT_MAP[fontName] then
        return
    end

    self.Settings.Font = fontName

    for _, item in ipairs(self.FontObjects) do
        if item.Object and item.Object.Parent then
            item.Object.Font = FONT_MAP[fontName]
        end
    end
end

function Library:GetRequestedDPIPercent()
    return DPI_VALUES[self.Settings.DPIPreset] or 100
end

function Library:GetFitDPIPercent()
    if not self.Settings.AutoFitDPI then
        return self:GetRequestedDPIPercent()
    end

    local camera = workspace.CurrentCamera
    if not camera then
        return self:GetRequestedDPIPercent()
    end

    local viewport = camera.ViewportSize
    if viewport.X <= 0 or viewport.Y <= 0 then
        return self:GetRequestedDPIPercent()
    end

    local usableX = math.max(1, viewport.X - DPI_SCREEN_MARGIN.X)
    local usableY = math.max(1, viewport.Y - DPI_SCREEN_MARGIN.Y)
    local maxScale = math.min(usableX / BASE_WINDOW_SIZE.X, usableY / BASE_WINDOW_SIZE.Y)
    local maxPercent = (maxScale / DPI_BASE_SCALE) * 100
    local requested = self:GetRequestedDPIPercent()

    if requested <= maxPercent then
        return requested
    end

    -- Snap down only to one of the exposed presets. 5% is the emergency floor.
    for _, percent in ipairs(DPI_FIT_ORDER) do
        if percent <= requested and percent <= maxPercent then
            return percent
        end
    end

    return 5
end

function Library:ApplyDPIScale()
    local effectivePercent = self:GetFitDPIPercent()
    local scale = DPI_BASE_SCALE * (effectivePercent / 100)
    self.EffectiveDPIPercent = effectivePercent
    self.CurrentDPIScale = scale

    if self.MainScale and self.MainScale.Parent then
        self.MainScale.Scale = scale
    end

    if self.LoaderScale and self.LoaderScale.Parent then
        -- Loader follows the interface scale, but never becomes microscopic.
        self.LoaderScale.Scale = math.max(0.45, scale)
    end
end

function Library:SetDPIPreset(preset)
    preset = tostring(preset or "100%")
    if not DPI_VALUES[preset] then
        return
    end
    self.Settings.DPIPreset = preset
    self:ApplyDPIScale()
end

function Library:SyncThemeColorPickers()
    for _, item in ipairs(self.ThemeColorControls) do
        local control = item.Control
        local color = self.Theme[item.Key]
        if control and control.Set and typeof(color) == "Color3" then
            control:Set(color, true)
        end
    end
end

function Library:RefreshTheme()
    for _, binding in ipairs(self.ThemeBindings) do
        local obj = binding.Object
        if obj and obj.Parent and self.Theme[binding.Key] ~= nil then
            obj[binding.Property] = self.Theme[binding.Key]
        end
    end

    for _, control in ipairs(self.Controls) do
        if control.RefreshStyle then
            control:RefreshStyle()
        end
    end

    -- Theme editor swatches/palettes must follow preset changes too.
    self:SyncThemeColorPickers()
end

function Library:SetThemeColor(key, color)
    if self.Theme[key] and typeof(color) == "Color3" then
        self.Theme[key] = color
        self:RefreshTheme()
    end
end

function Library:ApplyThemePreset(name)
    if not THEMES[name] then
        return
    end

    self.ThemeName = name
    self.Theme = cloneTable(THEMES[name])
    self:RefreshTheme()
end

--============================================================
-- ANIMATION ENGINE
--============================================================

-- Structural/window animations always stay smooth. The Smooth/Stepped
-- setting below is intentionally reserved for interactive controls.
function Library:Animate(object, duration, properties)
    duration = duration or self.Settings.AnimationSpeed

    local tween = TweenService:Create(
        object,
        TweenInfo.new(duration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        properties
    )
    tween:Play()
    return tween
end

function Library:AnimateControl(object, duration, properties)
    duration = duration or 0.12

    if self.Settings.AnimationMode == "Smooth" then
        local tween = TweenService:Create(
            object,
            TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            properties
        )
        tween:Play()
        return tween
    end

    -- Stepped = visible discrete movement instead of easing.
    local steps = 5
    local starts = {}
    for property in pairs(properties) do
        starts[property] = object[property]
    end

    task.spawn(function()
        for i = 1, steps do
            if not object or not object.Parent or Library.Unloaded then
                return
            end

            local alpha = i / steps
            for property, target in pairs(properties) do
                object[property] = lerpValue(starts[property], target, alpha)
            end
            task.wait(duration / steps)
        end
    end)
end

--============================================================
-- GRAPHICS GATING
--============================================================

function Library:IsGraphicsAllowed(required)
    required = required or "Low"
    return (GRAPHICS_ORDER[self.Settings.GraphicsLevel] or 1) >= (GRAPHICS_ORDER[required] or 1)
end

function Library:SetGraphicsLevel(level)
    if not GRAPHICS_ORDER[level] then
        return
    end

    self.Settings.GraphicsLevel = level

    if self.LevelText and self.LevelText.Parent then
        self.LevelText.Text = level
    end

    for _, control in ipairs(self.GatedControls) do
        if control.RefreshGate then
            control:RefreshGate()
        end
    end

    if self.RefreshWatermark then
        self:RefreshWatermark()
    end
end

--============================================================
-- CONFIG SYSTEM
--============================================================

function Library:ExportConfig()
    local result = {
        version = 12,
        flags = {},
        settings = {
            Language = self.Settings.Language,
            GraphicsLevel = self.Settings.GraphicsLevel,
            Font = self.Settings.Font,
            MenuKey = self.Settings.MenuKey,
            DPIPreset = self.Settings.DPIPreset,
            AutoFitDPI = self.Settings.AutoFitDPI,
            FunctionDPIPreset = self.Settings.FunctionDPIPreset,
            TextScale = self.Settings.TextScale,
            CornerRadius = self.Settings.CornerRadius,
            BlurEnabled = self.Settings.BlurEnabled,
            BlurSize = self.Settings.BlurSize,
            DimEnabled = self.Settings.DimEnabled,
            DimTransparency = self.Settings.DimTransparency,
            AnimationMode = self.Settings.AnimationMode,
            OpenAnimation = self.Settings.OpenAnimation,
            AnimationSpeed = self.Settings.AnimationSpeed,
            DragMode = self.Settings.DragMode,
            DragSmoothness = self.Settings.DragSmoothness,
            TooltipsEnabled = self.Settings.TooltipsEnabled,
            TooltipDelay = self.Settings.TooltipDelay,
            TooltipFollowSpeed = self.Settings.TooltipFollowSpeed,
            ThemeName = self.ThemeName,
            WatermarkEnabled = self.Settings.WatermarkEnabled,
            WatermarkText = self.Settings.WatermarkText,
            WatermarkShowGraphics = self.Settings.WatermarkShowGraphics,
            WatermarkShowFPS = self.Settings.WatermarkShowFPS,
            WatermarkShowPing = self.Settings.WatermarkShowPing,
            WatermarkShowTime = self.Settings.WatermarkShowTime,
            WatermarkDraggable = self.Settings.WatermarkDraggable,
            WatermarkX = self.Settings.WatermarkX,
            WatermarkY = self.Settings.WatermarkY,
        },
        theme = {},
    }

    for flag, value in pairs(self.Flags) do
        result.flags[flag] = encodeValue(value)
    end

    for key, value in pairs(self.Theme) do
        result.theme[key] = encodeValue(value)
    end

    return result
end

function Library:ImportConfig(data)
    if type(data) ~= "table" then
        return false
    end

    local settings = data.settings or {}

    if settings.Language ~= nil then
        self:SetLanguage(settings.Language)
    end

    if settings.ThemeName and THEMES[settings.ThemeName] then
        self:ApplyThemePreset(settings.ThemeName)
    end

    if type(data.theme) == "table" then
        for key, value in pairs(data.theme) do
            local decoded = decodeValue(value)
            if self.Theme[key] and typeof(decoded) == "Color3" then
                self.Theme[key] = decoded
            end
        end
        self:RefreshTheme()
    end

    if settings.Font then
        self:SetFont(settings.Font)
    end
    if settings.MenuKey and Enum.KeyCode[tostring(settings.MenuKey)] then
        self.Settings.MenuKey = tostring(settings.MenuKey)
    end
    if settings.AutoFitDPI ~= nil then
        self.Settings.AutoFitDPI = settings.AutoFitDPI == true
    end
    if settings.FunctionDPIPreset and FUNCTION_DPI_VALUES[tostring(settings.FunctionDPIPreset)] then
        self.Settings.FunctionDPIPreset = tostring(settings.FunctionDPIPreset)
    end
    if settings.TextScale ~= nil then
        self.Settings.TextScale = math.clamp(tonumber(settings.TextScale) or 100, 50, 200)
    end
    if settings.DPIPreset and DPI_VALUES[tostring(settings.DPIPreset)] then
        self:SetDPIPreset(tostring(settings.DPIPreset))
    else
        self:ApplyDPIScale()
    end
    self:ApplyFunctionDPIScale()
    self:SetTextScale(self.Settings.TextScale)
    if settings.CornerRadius ~= nil then
        self:SetCornerRadius(settings.CornerRadius)
    end
    if settings.GraphicsLevel then
        self:SetGraphicsLevel(settings.GraphicsLevel)
    end

    if settings.BlurEnabled ~= nil then self.Settings.BlurEnabled = settings.BlurEnabled end
    if settings.BlurSize ~= nil then self.Settings.BlurSize = settings.BlurSize end
    if settings.DimEnabled ~= nil then self.Settings.DimEnabled = settings.DimEnabled end
    if settings.DimTransparency ~= nil then self.Settings.DimTransparency = settings.DimTransparency end
    if settings.AnimationMode then self.Settings.AnimationMode = settings.AnimationMode end
    if settings.OpenAnimation then self.Settings.OpenAnimation = settings.OpenAnimation end
    if settings.AnimationSpeed then self.Settings.AnimationSpeed = settings.AnimationSpeed end
    if settings.DragMode == "Smooth" or settings.DragMode == "Direct" then self.Settings.DragMode = settings.DragMode end
    if settings.DragSmoothness ~= nil then self.Settings.DragSmoothness = math.clamp(tonumber(settings.DragSmoothness) or 16, 5, 40) end
    if settings.TooltipsEnabled ~= nil then self.Settings.TooltipsEnabled = settings.TooltipsEnabled == true end
    if settings.TooltipDelay ~= nil then self.Settings.TooltipDelay = math.clamp(tonumber(settings.TooltipDelay) or 0.12, 0, 1) end
    if settings.TooltipFollowSpeed ~= nil then self.Settings.TooltipFollowSpeed = math.clamp(tonumber(settings.TooltipFollowSpeed) or 22, 5, 50) end
    if settings.WatermarkEnabled ~= nil then self.Settings.WatermarkEnabled = settings.WatermarkEnabled == true end
    if settings.WatermarkText ~= nil then self.Settings.WatermarkText = tostring(settings.WatermarkText) end
    if settings.WatermarkShowGraphics ~= nil then self.Settings.WatermarkShowGraphics = settings.WatermarkShowGraphics == true end
    if settings.WatermarkShowFPS ~= nil then self.Settings.WatermarkShowFPS = settings.WatermarkShowFPS == true end
    if settings.WatermarkShowPing ~= nil then self.Settings.WatermarkShowPing = settings.WatermarkShowPing == true end
    if settings.WatermarkShowTime ~= nil then self.Settings.WatermarkShowTime = settings.WatermarkShowTime == true end
    if settings.WatermarkDraggable ~= nil then self.Settings.WatermarkDraggable = settings.WatermarkDraggable == true end
    if settings.WatermarkX ~= nil then self.Settings.WatermarkX = tonumber(settings.WatermarkX) or -1 end
    if settings.WatermarkY ~= nil then self.Settings.WatermarkY = tonumber(settings.WatermarkY) or 16 end

    for flag, encoded in pairs(data.flags or {}) do
        local control = self.ControlsByFlag and self.ControlsByFlag[flag]
        if control and control.Set then
            control:Set(decodeValue(encoded), true)
        else
            self.Flags[flag] = decodeValue(encoded)
        end
    end

    self:RefreshBackdrop()
    if self.RefreshWatermark then self:RefreshWatermark() end
    return true
end

function Library:SaveConfig(name)
    name = sanitizeName(name or self.CurrentConfigName)
    self.CurrentConfigName = name

    if not FS_AVAILABLE then
        warn("[Experiment17 UI] writefile/readfile are unavailable; config kept only in memory.")
        return false
    end

    ensureFolders()
    local path = CONFIG_SUBFOLDER .. "/" .. name .. ".json"

    local ok, encoded = pcall(function()
        return HttpService:JSONEncode(self:ExportConfig())
    end)

    if not ok then
        warn("[Experiment17 UI] JSON encode failed:", encoded)
        return false
    end

    local success, err = pcall(function()
        writefileFn(path, encoded)
    end)

    if not success then
        warn("[Experiment17 UI] Save failed:", err)
        return false
    end

    return true
end

function Library:LoadConfig(name)
    name = sanitizeName(name or self.CurrentConfigName)
    self.CurrentConfigName = name

    if not FS_AVAILABLE then
        return false
    end

    local path = CONFIG_SUBFOLDER .. "/" .. name .. ".json"
    if not isfileFn(path) then
        return false
    end

    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfileFn(path))
    end)

    if not ok then
        warn("[Experiment17 UI] Load failed:", data)
        return false
    end

    return self:ImportConfig(data)
end

function Library:SetAutoload(name, enabled)
    self.Settings.AutoloadConfig = enabled == true
    name = sanitizeName(name or self.CurrentConfigName)

    if not FS_AVAILABLE then
        return
    end

    ensureFolders()

    pcall(function()
        if enabled then
            writefileFn(AUTOLOAD_FILE, name)
        else
            writefileFn(AUTOLOAD_FILE, "")
        end
    end)
end

function Library:TryAutoload()
    if not FS_AVAILABLE or not isfileFn(AUTOLOAD_FILE) then
        return false
    end

    local ok, name = pcall(function()
        return readfileFn(AUTOLOAD_FILE)
    end)

    if not ok or not name or name == "" then
        return false
    end

    self.CurrentConfigName = sanitizeName(name)
    return self:LoadConfig(self.CurrentConfigName)
end

-- Optional cross-place restart hook.
-- Save this complete script as Experiment17/visuals.lua if your environment
-- supports readfile + loadstring + queue_on_teleport.
function Library:EnableTeleportAutoload()
    if not queueTeleportFn then
        return false
    end

    local code = self.TeleportLoader

    if not code and readfileFn and isfileFn and isfileFn(DEFAULT_TELEPORT_SCRIPT) then
        code = [[
            task.wait(1)
            if readfile and loadstring and isfile and isfile("Experiment17/visuals.lua") then
                loadstring(readfile("Experiment17/visuals.lua"))()
            end
        ]]
    end

    if not code then
        return false
    end

    local ok = pcall(function()
        queueTeleportFn(code)
    end)

    return ok
end

--============================================================
-- GUI ROOT / BACKDROP / BLUR
--============================================================

local old = PlayerGui:FindFirstChild("Experiment17_VisualUI")
if old then
    old:Destroy()
end

local oldBlur = Lighting:FindFirstChild("Experiment17_MenuBlur")
if oldBlur then
    oldBlur:Destroy()
end

local Root = Create("ScreenGui", {
    Name = "Experiment17_VisualUI",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    DisplayOrder = 999999,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
})

local guiParent = PlayerGui
pcall(function()
    if gethui then
        guiParent = gethui()
    end
end)

Root.Parent = guiParent
Library.Root = Root

--============================================================
-- FUNCTION TOOLTIP / PERFORMANCE HINTS
--============================================================

local function formatImpact(value, unit)
    if value == nil then
        return Library:L("NotSpecified")
    end

    if type(value) == "number" then
        local prefix = value > 0 and "+" or ""
        return prefix .. tostring(value) .. " " .. unit
    end

    if type(value) == "table" then
        local minValue = value.Min or value.min or value[1]
        local maxValue = value.Max or value.max or value[2]
        if tonumber(minValue) and tonumber(maxValue) then
            local function signed(n)
                n = tonumber(n) or 0
                return (n > 0 and "+" or "") .. tostring(n)
            end
            return signed(minValue) .. " .. " .. signed(maxValue) .. " " .. unit
        end
    end

    return tostring(value)
end

local Tooltip = Create("CanvasGroup", {
    Name = "FunctionTooltip",
    Parent = Root,
    Position = UDim2.fromOffset(0, 0),
    Size = UDim2.fromOffset(330, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 0,
    BorderSizePixel = 0,
    GroupTransparency = 1,
    Visible = false,
    ZIndex = 500,
})
Library:BindTheme(Tooltip, "BackgroundColor3", "Control")
Library:AdaptiveCorner(Tooltip, 0)

local TooltipStroke = Create("UIStroke", {
    Parent = Tooltip,
    Thickness = 1.35,
    Transparency = 0.08,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
})
Library:BindTheme(TooltipStroke, "Color", "Outline")

local TooltipAccent = Create("Frame", {
    Parent = Tooltip,
    Size = UDim2.new(1, 0, 0, 2),
    BackgroundTransparency = 0,
    BorderSizePixel = 0,
    ZIndex = 501,
})
Library:BindTheme(TooltipAccent, "BackgroundColor3", "Accent")

Create("UIPadding", {
    Parent = Tooltip,
    PaddingLeft = UDim.new(0, 12),
    PaddingRight = UDim.new(0, 12),
    PaddingTop = UDim.new(0, 10),
    PaddingBottom = UDim.new(0, 10),
})

Create("UIListLayout", {
    Parent = Tooltip,
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding = UDim.new(0, 5),
})

local TooltipTitle = Create("TextLabel", {
    Parent = Tooltip,
    Size = UDim2.new(1, 0, 0, 20),
    BackgroundTransparency = 1,
    Text = "",
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Center,
    LayoutOrder = 1,
    ZIndex = 502,
})
Library:BindTheme(TooltipTitle, "TextColor3", "Text")
Library:RegisterFont(TooltipTitle, true)

local TooltipDescription = Create("TextLabel", {
    Parent = Tooltip,
    Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
    Text = "",
    TextWrapped = true,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    LayoutOrder = 2,
    ZIndex = 502,
})
Library:BindTheme(TooltipDescription, "TextColor3", "SubText")
Library:RegisterFont(TooltipDescription)

local TooltipDivider = Create("Frame", {
    Parent = Tooltip,
    Size = UDim2.new(1, 0, 0, 1),
    BackgroundTransparency = 0.36,
    BorderSizePixel = 0,
    LayoutOrder = 3,
    ZIndex = 502,
})
Library:BindTheme(TooltipDivider, "BackgroundColor3", "Outline")

local TooltipGraphics = Create("TextLabel", {
    Parent = Tooltip,
    Size = UDim2.new(1, 0, 0, 16),
    BackgroundTransparency = 1,
    Text = "",
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    LayoutOrder = 4,
    ZIndex = 502,
})
Library:BindTheme(TooltipGraphics, "TextColor3", "Accent")
Library:RegisterFont(TooltipGraphics, true)

local TooltipPerformance = Create("TextLabel", {
    Parent = Tooltip,
    Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1,
    Text = "",
    TextWrapped = true,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    LayoutOrder = 5,
    ZIndex = 502,
})
Library:BindTheme(TooltipPerformance, "TextColor3", "Text")
Library:RegisterFont(TooltipPerformance)

Library.Tooltip = Tooltip
Library.TooltipHoverToken = 0
Library.TooltipCurrentPosition = Vector2.new(0, 0)

function Library:HideControlTooltip(immediate)
    self.TooltipHoverToken += 1
    if not Tooltip.Visible then
        return
    end

    if immediate then
        Tooltip.Visible = false
        Tooltip.GroupTransparency = 1
        return
    end

    self:Animate(Tooltip, 0.09, {GroupTransparency = 1})
    local token = self.TooltipHoverToken
    task.delay(0.10, function()
        if self.TooltipHoverToken == token and Tooltip.Parent then
            Tooltip.Visible = false
        end
    end)
end

function Library:ShowControlTooltip(control)
    if self.Unloaded or not self.Settings.TooltipsEnabled or not control or control.TooltipEnabled == false then
        return
    end

    self.TooltipHoverToken += 1
    local token = self.TooltipHoverToken

    task.delay(math.max(0, tonumber(self.Settings.TooltipDelay) or 0.12), function()
        if self.Unloaded or self.TooltipHoverToken ~= token or not control.Hovering or not self.Settings.TooltipsEnabled then
            return
        end

        TooltipTitle.Text = tostring(control.DisplayName or control.Label and control.Label.Text or "Function")
        TooltipDescription.Text = tostring(control.Description or Library:L("NoDescription"))
        TooltipGraphics.Text =
            Library:L("Graphics") .. ": " .. tostring(control.RequiredGraphics or "Low") .. "+"
            .. (control.Locked
                and ("   [" .. Library:L("Locked") .. "]")
                or ("   [" .. Library:L("Available") .. "]"))
        TooltipPerformance.Text =
            Library:L("FPSImpact") .. ": " .. formatImpact(control.FPSImpact, "FPS")
            .. "    |    " .. Library:L("PingImpact") .. ": " .. formatImpact(control.PingImpact, "ms")

        local mouse = UIS:GetMouseLocation()
        self.TooltipCurrentPosition = mouse + Vector2.new(18, 18)
        Tooltip.Position = UDim2.fromOffset(self.TooltipCurrentPosition.X, self.TooltipCurrentPosition.Y)
        Tooltip.GroupTransparency = 1
        Tooltip.Visible = true
        self:Animate(Tooltip, 0.11, {GroupTransparency = 0})
    end)
end

RunService.RenderStepped:Connect(function(dt)
    if Library.Unloaded or not Tooltip.Visible then
        return
    end

    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
    local mouse = UIS:GetMouseLocation()
    local size = Tooltip.AbsoluteSize
    if size.X <= 0 or size.Y <= 0 then
        size = Vector2.new(330, 110)
    end

    local target = mouse + Vector2.new(18, 18)
    if target.X + size.X > viewport.X - 8 then
        target = Vector2.new(math.max(8, mouse.X - size.X - 18), target.Y)
    end
    if target.Y + size.Y > viewport.Y - 8 then
        target = Vector2.new(target.X, math.max(8, viewport.Y - size.Y - 8))
    end

    local follow = math.clamp(tonumber(Library.Settings.TooltipFollowSpeed) or 22, 5, 50)
    local alpha = 1 - math.exp(-follow * dt)
    Library.TooltipCurrentPosition = Library.TooltipCurrentPosition:Lerp(target, alpha)
    Tooltip.Position = UDim2.fromOffset(
        Library.TooltipCurrentPosition.X,
        Library.TooltipCurrentPosition.Y
    )
end)

local Blur = Create("BlurEffect", {
    Name = "Experiment17_MenuBlur",
    Size = 0,
    Parent = Lighting,
})
Library.Blur = Blur

local Dim = Create("Frame", {
    Name = "Dim",
    Parent = Root,
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Color3.new(0, 0, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ZIndex = 1,
})
Library.Dim = Dim

function Library:RefreshBackdrop()
    if not self.MenuVisible then
        return
    end

    Blur.Size = self.Settings.BlurEnabled and self.Settings.BlurSize or 0
    Dim.BackgroundTransparency = self.Settings.DimEnabled and self.Settings.DimTransparency or 1
end

--============================================================
-- LOADER GREETING
--============================================================

local function getLocalHour()
    -- os.date("*t") uses the local OS clock exposed to the Luau environment.
    local ok, dateTable = pcall(function()
        return os.date("*t")
    end)

    if ok and type(dateTable) == "table" and tonumber(dateTable.hour) then
        return tonumber(dateTable.hour)
    end

    -- Fallback for environments where os.date is restricted.
    local okDateTime, hour = pcall(function()
        return DateTime.now():ToLocalTime().Hour
    end)

    if okDateTime and tonumber(hour) then
        return tonumber(hour)
    end

    return 12
end

local function getTimeGreeting()
    local hour = getLocalHour()

    if hour >= 22 then
        return Library:L("GreetingSleepSoon")
    elseif hour >= 18 then
        return Library:L("GreetingEvening")
    elseif hour >= 10 then
        return Library:L("GreetingMorning")
    elseif hour >= 8 then
        return Library:L("GreetingEarly")
    elseif hour >= 2 then
        return Library:L("GreetingWhyAwake")
    end

    return Library:L("GreetingNight")
end

local function getLocalizedGreeting()
    return string.format(
        Library:L("HelloUser"),
        tostring(LocalPlayer.Name),
        getTimeGreeting()
    )
end

--============================================================
-- LOADING SCREEN
--============================================================

local Loader = Create("Frame", {
    Parent = Root,
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Color3.new(0, 0, 0),
    BackgroundTransparency = 0.2,
    BorderSizePixel = 0,
    ZIndex = 100,
})

local ParticleLayer = Create("Frame", {
    Parent = Loader,
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    ZIndex = 101,
})

for i = 1, 26 do
    local size = math.random(2, 5)
    local dot = Create("Frame", {
        Parent = ParticleLayer,
        Size = UDim2.fromOffset(size, size),
        Position = UDim2.fromScale(math.random(), math.random()),
        BackgroundColor3 = Library.Theme.Accent,
        BackgroundTransparency = math.random(20, 70) / 100,
        BorderSizePixel = 0,
        ZIndex = 101,
    })
    Create("UICorner", {Parent = dot, CornerRadius = UDim.new(1, 0)})

    task.spawn(function()
        while dot.Parent do
            local tween = TweenService:Create(
                dot,
                TweenInfo.new(math.random(12, 28) / 10, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                {
                    Position = UDim2.fromScale(math.random(), math.random()),
                    BackgroundTransparency = math.random(20, 75) / 100,
                }
            )
            tween:Play()
            tween.Completed:Wait()
        end
    end)
end

local LoaderBox = Create("Frame", {
    Parent = Loader,
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),

    -- v10: loader itself is 25% larger than the original 360x116 layout.
    Size = UDim2.fromOffset(450, 145),

    BackgroundColor3 = Library.Theme.Background,
    BorderSizePixel = 0,
    ZIndex = 102,
})
Library:AdaptiveCorner(LoaderBox, 4)

local LoaderScale = Create("UIScale", {
    Parent = LoaderBox,
    Scale = DPI_BASE_SCALE,
})
Library.LoaderScale = LoaderScale

local LoaderStroke = Create("UIStroke", {
    Parent = LoaderBox,
    Color = Library.Theme.Outline,
    Thickness = 1.25,
    Transparency = 0.12,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
})

-- The old top accent strip was intentionally removed in v10.

local LoaderTitle = Create("TextLabel", {
    Parent = LoaderBox,
    Position = UDim2.fromOffset(23, 18),
    Size = UDim2.new(1, -46, 0, 30),
    BackgroundTransparency = 1,
    Text = "Experiment 17 [Visuals]",
    TextColor3 = Library.Theme.Text,

    -- 18 -> ~23 (+25%)
    TextSize = 23,

    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 103,
})
Library:RegisterFont(LoaderTitle, true)

local LoaderGreeting = Create("TextLabel", {
    Parent = LoaderBox,
    Position = UDim2.fromOffset(23, 51),
    Size = UDim2.new(1, -46, 0, 26),
    BackgroundTransparency = 1,

    Text = getLocalizedGreeting(),
    TextColor3 = Library.Theme.Text,
    TextSize = 17,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
    ZIndex = 103,
})
Library:RegisterFont(LoaderGreeting, true)

local LoaderStatus = Create("TextLabel", {
    Parent = LoaderBox,
    Position = UDim2.fromOffset(23, 79),
    Size = UDim2.new(1, -118, 0, 20),
    BackgroundTransparency = 1,
    Text = Library:L("LoadingInterface"),
    TextColor3 = Library.Theme.SubText,

    -- 12 -> 15 (+25%)
    TextSize = 15,

    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 103,
})
Library:RegisterFont(LoaderStatus)

local LoaderPercent = Create("TextLabel", {
    Parent = LoaderBox,
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -23, 0, 79),
    Size = UDim2.fromOffset(64, 20),
    BackgroundTransparency = 1,
    Text = "0%",
    TextColor3 = Library.Theme.Accent,
    TextSize = 15,
    TextXAlignment = Enum.TextXAlignment.Right,
    ZIndex = 103,
})
Library:RegisterFont(LoaderPercent, true)

local LoaderBar = Create("Frame", {
    Parent = LoaderBox,
    Position = UDim2.new(0, 23, 1, -27),
    Size = UDim2.new(1, -46, 0, 6),
    BackgroundColor3 = Library.Theme.Control2,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    ZIndex = 103,
})
Create("UICorner", {Parent = LoaderBar, CornerRadius = UDim.new(1, 0)})

local LoaderFill = Create("Frame", {
    Parent = LoaderBar,
    Size = UDim2.fromScale(0, 1),
    BackgroundColor3 = Library.Theme.Accent,
    BorderSizePixel = 0,
    ZIndex = 104,
})
Create("UICorner", {Parent = LoaderFill, CornerRadius = UDim.new(1, 0)})

local LoaderGlow = Create("Frame", {
    Parent = LoaderFill,
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, 0, 0, 0),
    Size = UDim2.fromOffset(30, 6),
    BackgroundColor3 = Color3.new(1, 1, 1),
    BackgroundTransparency = 0.72,
    BorderSizePixel = 0,
    ZIndex = 105,
})
Create("UICorner", {Parent = LoaderGlow, CornerRadius = UDim.new(1, 0)})

--============================================================
-- MAIN WINDOW
--============================================================

local Main = Create("Frame", {
    Parent = Root,
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(780, 500),
    BackgroundTransparency = 0,
    BorderSizePixel = 0,
    ClipsDescendants = true, -- clips sidebar/topbar to the rounded outer silhouette
    Visible = false,
    ZIndex = 10,
})
Library:BindTheme(Main, "BackgroundColor3", "Background")
Library:AdaptiveCorner(Main, 4)
Library.Main = Main

-- Keep the black shell separate from animated content. In v7 the whole
-- window was a CanvasGroup, so GroupTransparency also faded the black
-- background and could make the GUI look transparent during Scale/Fade.
-- v8 keeps Main permanently opaque and fades/moves only this child group.
local MainVisual = Create("CanvasGroup", {
    Parent = Main,
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    GroupTransparency = 0,
    ClipsDescendants = true,
    ZIndex = 10,
})
Library.MainVisual = MainVisual

local MainScale = Create("UIScale", {
    Parent = Main,
    Scale = DPI_BASE_SCALE,
})
Library.MainScale = MainScale
Library:ApplyDPIScale()

-- v12 loader entrance: the panel rises into place and grows from a compact
-- state instead of simply appearing in the middle of the screen.
do
    local targetLoaderScale = math.max(0.45, Library.CurrentDPIScale or DPI_BASE_SCALE)

    LoaderBox.Position = UDim2.new(0.5, 0, 0.5, 46)
    LoaderScale.Scale = targetLoaderScale * 0.70

    LoaderTitle.TextTransparency = 1
    LoaderGreeting.TextTransparency = 1
    LoaderStatus.TextTransparency = 1
    LoaderPercent.TextTransparency = 1
    LoaderBar.BackgroundTransparency = 1
    LoaderFill.BackgroundTransparency = 1

    TweenService:Create(
        LoaderBox,
        TweenInfo.new(0.72, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        {Position = UDim2.fromScale(0.5, 0.5)}
    ):Play()

    TweenService:Create(
        LoaderScale,
        TweenInfo.new(0.78, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        {Scale = targetLoaderScale}
    ):Play()

    task.delay(0.10, function()
        if not LoaderBox.Parent then return end
        TweenService:Create(LoaderTitle, TweenInfo.new(0.42), {TextTransparency = 0}):Play()
    end)

    task.delay(0.20, function()
        if not LoaderBox.Parent then return end
        TweenService:Create(LoaderGreeting, TweenInfo.new(0.48), {TextTransparency = 0}):Play()
    end)

    task.delay(0.30, function()
        if not LoaderBox.Parent then return end
        TweenService:Create(LoaderStatus, TweenInfo.new(0.48), {TextTransparency = 0}):Play()
        TweenService:Create(LoaderPercent, TweenInfo.new(0.48), {TextTransparency = 0}):Play()
        TweenService:Create(LoaderBar, TweenInfo.new(0.48), {BackgroundTransparency = 0}):Play()
        TweenService:Create(LoaderFill, TweenInfo.new(0.48), {BackgroundTransparency = 0}):Play()
    end)
end

local MainStroke = Create("UIStroke", {
    Parent = Main,
    Thickness = 1.35,
    Transparency = 0.01,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
})
Library:BindTheme(MainStroke, "Color", "Outline")

local Topbar = Create("Frame", {
    Parent = MainVisual,
    Size = UDim2.new(1, 0, 0, 52),
    BorderSizePixel = 0,
    ZIndex = 11,
})
Library:BindTheme(Topbar, "BackgroundColor3", "Panel")
Library:AdaptiveCorner(Topbar, 4)

local TopbarSquare = Create("Frame", {
    Parent = Topbar,
    Position = UDim2.new(0, 0, 1, -10),
    Size = UDim2.new(1, 0, 0, 10),
    BorderSizePixel = 0,
    ZIndex = 11,
})
Library:BindTheme(TopbarSquare, "BackgroundColor3", "Panel")

local PathBar = Create("Frame", {
    Parent = Topbar,
    Position = UDim2.fromOffset(18, 0),
    Size = UDim2.new(1, -150, 1, 0),
    BackgroundTransparency = 1,
    ZIndex = 12,
})

Create("UIListLayout", {
    Parent = PathBar,
    FillDirection = Enum.FillDirection.Horizontal,
    VerticalAlignment = Enum.VerticalAlignment.Center,
    HorizontalAlignment = Enum.HorizontalAlignment.Left,
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
})

local Title = Create("TextLabel", {
    Parent = PathBar,
    Size = UDim2.fromOffset(0, 52),
    AutomaticSize = Enum.AutomaticSize.X,
    BackgroundTransparency = 1,
    Text = "Experiment 17 [Visuals]",
    TextSize = 16,
    TextXAlignment = Enum.TextXAlignment.Left,
    LayoutOrder = 1,
    ZIndex = 12,
})
Library:BindTheme(Title, "TextColor3", "Text")
Library:RegisterFont(Title, true)

local BreadcrumbArrow = Create("TextLabel", {
    Parent = PathBar,
    Size = UDim2.fromOffset(12, 52),
    BackgroundTransparency = 1,
    Text = ">",
    TextSize = 16,
    LayoutOrder = 2,
    ZIndex = 12,
})
Library:BindTheme(BreadcrumbArrow, "TextColor3", "Accent")
Library:RegisterFont(BreadcrumbArrow, true)

local Breadcrumb = Create("TextLabel", {
    Parent = PathBar,
    Size = UDim2.fromOffset(0, 52),
    AutomaticSize = Enum.AutomaticSize.X,
    BackgroundTransparency = 1,
    Text = Library:L("Home"),
    TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left,
    LayoutOrder = 3,
    ZIndex = 12,
})
Library:BindTheme(Breadcrumb, "TextColor3", "SubText")
Library:RegisterFont(Breadcrumb)
Library.Breadcrumb = Breadcrumb

local LevelText = Create("TextLabel", {
    Parent = Topbar,
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -15, 0, 0),
    Size = UDim2.fromOffset(105, 52),
    BackgroundTransparency = 1,
    Text = "Epic",
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Right,
    ZIndex = 12,
})
Library:BindTheme(LevelText, "TextColor3", "Accent")
Library:RegisterFont(LevelText, true)
Library.LevelText = LevelText

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
Library:BindTheme(Sidebar, "BackgroundColor3", "Panel")
Library:AdaptiveCorner(Sidebar, 4)

-- UICorner rounds every sidebar corner. These masks restore the two internal
-- square corners while leaving the actual bottom-left outer corner rounded.
local SidebarTopMask = Create("Frame", {
    Parent = Sidebar,
    Position = UDim2.fromOffset(0, 0),
    Size = UDim2.new(1, 0, 0, 14),
    BorderSizePixel = 0,
    ZIndex = 11,
})
Library:BindTheme(SidebarTopMask, "BackgroundColor3", "Panel")

local SidebarBottomRightMask = Create("Frame", {
    Parent = Sidebar,
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.fromScale(1, 1),
    Size = UDim2.fromOffset(14, 14),
    BorderSizePixel = 0,
    ZIndex = 11,
})
Library:BindTheme(SidebarBottomRightMask, "BackgroundColor3", "Panel")

local Divider = Create("Frame", {
    Parent = Sidebar,
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, 0, 0, 0),
    Size = UDim2.new(0, 1, 1, 0),
    BorderSizePixel = 0,
    ZIndex = 12,
})
Library:BindTheme(Divider, "BackgroundColor3", "Outline")

local TabList = Create("ScrollingFrame", {
    Parent = Sidebar,
    Position = UDim2.fromOffset(9, 9),
    Size = UDim2.new(1, -18, 1, -68),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 0,
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    CanvasSize = UDim2.new(),
    ClipsDescendants = true,
    ZIndex = 12,
})
-- Keep selected-tab UIStroke fully inside the scrolling viewport.
Create("UIPadding", {
    Parent = TabList,
    PaddingTop = UDim.new(0, 3),
    PaddingBottom = UDim.new(0, 3),
    PaddingLeft = UDim.new(0, 2),
    PaddingRight = UDim.new(0, 2),
})
Create("UIListLayout", {
    Parent = TabList,
    Padding = UDim.new(0, 5),
    SortOrder = Enum.SortOrder.LayoutOrder,
    HorizontalAlignment = Enum.HorizontalAlignment.Center,
})

-- Bottom-left actions: unload (X) and hide (_).
local SidebarActions = Create("Frame", {
    Parent = Sidebar,
    Position = UDim2.new(0, 10, 1, -48),
    Size = UDim2.fromOffset(78, 38),
    BackgroundTransparency = 1,
    ZIndex = 14,
})

local function makeSidebarAction(text, x)
    local button = Create("TextButton", {
        Parent = SidebarActions,
        Position = UDim2.fromOffset(x, 2),
        Size = UDim2.fromOffset(34, 34),
        BorderSizePixel = 0,
        Text = text,
        TextSize = 16,
        AutoButtonColor = false,
        ZIndex = 15,
    })
    Library:BindTheme(button, "BackgroundColor3", "Control2")
    Library:BindTheme(button, "TextColor3", "Text")
    Library:RegisterFont(button, true)
    Library:AdaptiveCorner(button, -2)

    local stroke = Create("UIStroke", {
        Parent = button,
        Thickness = 1.1,
        Transparency = 0.22,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
    Library:BindTheme(stroke, "Color", "Outline")

    return button
end

local UnloadButton = makeSidebarAction("X", 0)
local HideButton = makeSidebarAction("_", 42)

local Content = Create("Frame", {
    Parent = MainVisual,
    Position = UDim2.fromOffset(172, 52),
    Size = UDim2.new(1, -172, 1, -52),
    BackgroundTransparency = 1,
    ZIndex = 11,
})

Library.TabList = TabList
Library.Content = Content
Library.Tabs = {}
Library.ControlsByFlag = {}

local viewportConnection
local function hookViewport(camera)
    if viewportConnection then
        viewportConnection:Disconnect()
        viewportConnection = nil
    end
    if camera then
        viewportConnection = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            Library:ApplyDPIScale()
        end)
    end
    Library:ApplyDPIScale()
end

hookViewport(workspace.CurrentCamera)
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
    if Library.Unloaded then return end
    hookViewport(workspace.CurrentCamera)
end)

--============================================================
-- DRAGGING
--============================================================

local dragging = false
local dragSettling = false
local dragStart = nil
local startPos = nil
local dragTarget = Main.Position

local function positionDistance(a, b)
    return math.abs(a.X.Offset - b.X.Offset) + math.abs(a.Y.Offset - b.Y.Offset)
end

Topbar.InputBegan:Connect(function(input)
    if Library.Unloaded then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragSettling = false
        dragStart = input.Position
        startPos = Main.Position
        dragTarget = Main.Position
    end
end)

UIS.InputChanged:Connect(function(input)
    if Library.Unloaded then return end
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        dragTarget = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )

        if Library.Settings.DragMode == "Direct" then
            Main.Position = dragTarget
        end
    end
end)

RunService.RenderStepped:Connect(function(dt)
    if Library.Unloaded then return end
    if Library.Settings.DragMode ~= "Smooth" then return end
    if not dragging and not dragSettling then return end

    -- Exponential follow gives the window a small, controllable lag behind
    -- the cursor without becoming frame-rate dependent.
    local speed = math.clamp(tonumber(Library.Settings.DragSmoothness) or 16, 5, 40)
    local alpha = 1 - math.exp(-speed * dt)
    Main.Position = Main.Position:Lerp(dragTarget, alpha)

    if not dragging and positionDistance(Main.Position, dragTarget) < 0.6 then
        Main.Position = dragTarget
        dragSettling = false
        Library.WindowPosition = dragTarget
    end
end)

UIS.InputEnded:Connect(function(input)
    if Library.Unloaded then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 and dragging then
        dragging = false
        if Library.Settings.DragMode == "Smooth" then
            dragSettling = true
        else
            Library.WindowPosition = Main.Position
        end
    end
end)

--============================================================
-- MENU OPEN / CLOSE
--============================================================

function Library:SetMenuVisible(visible, instant)
    if self.Unloaded then return end

    self.MenuVisible = visible == true
    self:HideControlTooltip(true)

    local duration = math.max(0.26, tonumber(self.Settings.AnimationSpeed) or 0.18)
    local basePos = self.WindowPosition or UDim2.fromScale(0.5, 0.5)
    local baseScale = self.CurrentDPIScale or (self.MainScale and self.MainScale.Scale) or DPI_BASE_SCALE

    -- HARD RULE: the black shell never fades. Only MainVisual is allowed to
    -- change GroupTransparency. This prevents the "transparent GUI" bug.
    Main.BackgroundTransparency = 0

    if self.MenuVisible then
        Main.Visible = true
        Main.Size = UDim2.fromOffset(780, 500)
        Main.BackgroundTransparency = 0
        self:RefreshBackdrop()

        if instant or self.Settings.OpenAnimation == "None" then
            Main.Position = basePos
            MainScale.Scale = baseScale
            MainVisual.GroupTransparency = 0
            return
        end

        if self.Settings.OpenAnimation == "Scale" then
            -- v8: ~200% stronger scale travel than v7.
            Main.Position = basePos
            MainScale.Scale = baseScale * 0.12
            MainVisual.GroupTransparency = 0.06

            self:Animate(MainScale, duration * 1.08, {
                Scale = baseScale,
            })
            self:Animate(MainVisual, duration * 0.82, {
                GroupTransparency = 0,
            })

        elseif self.Settings.OpenAnimation == "Slide" then
            -- Roughly double the old travel distance.
            Main.Position = UDim2.new(
                basePos.X.Scale,
                basePos.X.Offset,
                basePos.Y.Scale,
                basePos.Y.Offset + 4000
            )
            MainScale.Scale = baseScale * 0.82
            MainVisual.GroupTransparency = 0.08

            self:Animate(Main, duration * 1.35, {
                Position = basePos,
            })
            self:Animate(MainScale, duration, {
                Scale = baseScale,
            })
            self:Animate(MainVisual, duration * 0.80, {
                GroupTransparency = 0,
            })

        elseif self.Settings.OpenAnimation == "Fade" then
            -- The contents fade in, but the black window shell stays black.
            Main.Position = UDim2.new(
                basePos.X.Scale,
                basePos.X.Offset,
                basePos.Y.Scale,
                basePos.Y.Offset + 220
            )
            MainScale.Scale = baseScale * 0.82
            MainVisual.GroupTransparency = 1

            self:Animate(MainScale, duration * 1.05, {
                Scale = baseScale,
            })
            self:Animate(Main, duration * 1.05, {
                Position = basePos,
            })
            self:Animate(MainVisual, duration, {
                GroupTransparency = 0,
            })
        end
    else
        self.WindowPosition = Main.Position
        basePos = self.WindowPosition

        if instant or self.Settings.OpenAnimation == "None" then
            Main.Visible = false
            Main.Position = basePos
            MainScale.Scale = baseScale
            MainVisual.GroupTransparency = 0
            Main.BackgroundTransparency = 0
            Blur.Size = 0
            Dim.BackgroundTransparency = 1
            return
        end

        -- Backdrop follows the window animation instead of disappearing early.
        self:Animate(Blur, duration, {Size = 0})
        self:Animate(Dim, duration, {BackgroundTransparency = 1})

        if self.Settings.OpenAnimation == "Scale" then
            self:Animate(MainScale, duration * 1.08, {
                Scale = baseScale * 0.10,
            })
            self:Animate(MainVisual, duration * 0.88, {
                GroupTransparency = 0.08,
            })

        elseif self.Settings.OpenAnimation == "Slide" then
            self:Animate(Main, duration * 1.35, {
                Position = UDim2.new(
                    basePos.X.Scale,
                    basePos.X.Offset,
                    basePos.Y.Scale,
                    basePos.Y.Offset + 4000
                ),
            })
            self:Animate(MainScale, duration, {
                Scale = baseScale * 0.82,
            })
            self:Animate(MainVisual, duration * 0.88, {
                GroupTransparency = 0.08,
            })

        elseif self.Settings.OpenAnimation == "Fade" then
            self:Animate(MainScale, duration * 1.05, {
                Scale = baseScale * 0.82,
            })
            self:Animate(Main, duration * 1.05, {
                Position = UDim2.new(
                    basePos.X.Scale,
                    basePos.X.Offset,
                    basePos.Y.Scale,
                    basePos.Y.Offset + 220
                ),
            })
            self:Animate(MainVisual, duration, {
                GroupTransparency = 1,
            })
        end

        task.delay(duration * 1.42 + 0.06, function()
            if not self.MenuVisible and Main.Parent then
                Main.Visible = false
                Main.Position = basePos
                MainScale.Scale = baseScale
                MainVisual.GroupTransparency = 0
                Main.BackgroundTransparency = 0
                Blur.Size = 0
                Dim.BackgroundTransparency = 1
            end
        end)
    end
end

function Library:Unload()
    if self.Unloaded then
        return
    end

    self.Unloaded = true
    self.MenuVisible = false

    if self.ActivePromptOverlay and self.ActivePromptOverlay.Parent then
        self.ActivePromptOverlay:Destroy()
        self.ActivePromptOverlay = nil
        self.PromptBusy = false
    end

    if self.ActiveDropdown and self.ActiveDropdown.CloseDropdown then
        pcall(function()
            self.ActiveDropdown:CloseDropdown()
        end)
    end

    -- Turn active toggles off so their callbacks can clean up visual effects.
    for _, control in ipairs(self.Controls) do
        if control.IsToggle and control.Get and control.Set then
            local ok, enabled = pcall(function() return control:Get() end)
            if ok and enabled then
                pcall(function() control:Set(false, false) end)
            end
        end
    end

    if self.Blur and self.Blur.Parent then
        self.Blur:Destroy()
    end

    if self.Root and self.Root.Parent then
        self.Root:Destroy()
    end
end

UnloadButton.MouseButton1Click:Connect(function()
    Library:Unload()
end)

HideButton.MouseButton1Click:Connect(function()
    if not Library.Unloaded then
        Library:SetMenuVisible(false)
    end
end)

--============================================================
-- CONTROL BASE
--============================================================

local function newBaseControl(parent, titleText, required, height, opts)
    opts = opts or {}
    required = required or "Low"

    local functionScale = Library:GetFunctionDPIScale()
    local hasLayout = parent:FindFirstChildOfClass("UIListLayout") ~= nil

    local Holder = Create("Frame", {
        Parent = parent,
        Size = UDim2.new(functionScale, 0, 0, height or 42),
        BorderSizePixel = 0,
        ZIndex = 15,
    })

    if not hasLayout then
        Holder.Position = UDim2.new((1 - functionScale) * 0.5, 0, 0, 0)
    end

    table.insert(Library.ControlFrames, {
        Object = Holder,
        ManualCenter = not hasLayout,
    })

    -- v8 uses an INSIDE border instead of UIStroke for function rows.
    -- UIStroke extends outside the GuiObject and gets clipped by CanvasGroup /
    -- ScrollingFrame boundaries, which is what caused the first control in a
    -- section to lose parts of its purple outline.
    Library:BindTheme(Holder, "BackgroundColor3", "Outline")
    Library:AdaptiveCorner(Holder, 0)

    local Surface = Create("Frame", {
        Parent = Holder,
        Position = UDim2.fromOffset(1, 1),
        Size = UDim2.new(1, -2, 1, -2),
        BorderSizePixel = 0,
        ZIndex = 15,
    })
    Library:BindTheme(Surface, "BackgroundColor3", "Control")
    Library:AdaptiveCorner(Surface, -1)

    -- Local visual scale used by section open/close animations. Because it
    -- lives on the row itself, the row, its text, toggle, slider and outline
    -- all animate together instead of only the section container moving.
    local MotionScale = Create("UIScale", {
        Parent = Holder,
        Scale = 1,
    })

    local Label = Create("TextLabel", {
        Parent = Holder,
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(1, -145, 1, 0),
        BackgroundTransparency = 1,
        Text = opts.LocaleKey and Library:L(opts.LocaleKey) or titleText,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 16,
    })
    Library:BindTheme(Label, "TextColor3", "Text")
    Library:RegisterFont(Label)

    local Requirement = Create("TextLabel", {
        Parent = Holder,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(72, 20),
        BackgroundTransparency = 1,
        Text = required == "Low" and "" or (required .. "+"),
        TextSize = 10,
        TextXAlignment = Enum.TextXAlignment.Right,
        ZIndex = 16,
    })
    Library:BindTheme(Requirement, "TextColor3", "SubText")
    Library:RegisterFont(Requirement, true)

    local performance = opts.Performance or opts.PerformanceImpact or {}

    local Control = {
        Holder = Holder,
        Surface = Surface,
        MotionScale = MotionScale,
        Label = Label,
        Requirement = Requirement,
        DisplayName = opts.LocaleKey and Library:L(opts.LocaleKey) or titleText,
        LocaleKey = opts.LocaleKey,
        DescriptionKey = opts.DescriptionKey,
        Description = opts.DescriptionKey and Library:L(opts.DescriptionKey) or opts.Description or Library:L("NoDescription"),
        FPSImpact = opts.FPSImpact ~= nil and opts.FPSImpact
            or opts.EstimatedFPS ~= nil and opts.EstimatedFPS
            or performance.FPS,
        PingImpact = opts.PingImpact ~= nil and opts.PingImpact
            or opts.EstimatedPing ~= nil and opts.EstimatedPing
            or performance.Ping,
        TooltipEnabled = opts.Tooltip ~= false,
        RequiredGraphics = required,
        Locked = false,
        Hovering = false,
    }

    function Control:RefreshGate()
        local wasLocked = self.Locked
        self.Locked = not Library:IsGraphicsAllowed(self.RequiredGraphics)

        -- Both border and surface dim together, while the border always stays
        -- inside the row bounds so it cannot be clipped.
        self.Holder.BackgroundTransparency = self.Locked and 0.58 or 0
        self.Surface.BackgroundTransparency = self.Locked and 0.42 or 0
        self.Label.TextTransparency = self.Locked and 0.55 or 0
        self.Requirement.TextTransparency = self.Locked and 0.35 or 0

        if self.Locked and not wasLocked and self.OnGraphicsLocked then
            self:OnGraphicsLocked()
        end
    end

    function Control:RefreshStyle()
        self:RefreshGate()
    end

    Holder.MouseEnter:Connect(function()
        if Library.Unloaded then return end
        Control.Hovering = true
        Library:ShowControlTooltip(Control)
    end)

    Holder.MouseLeave:Connect(function()
        Control.Hovering = false
        Library:HideControlTooltip(false)
    end)

    table.insert(Library.Controls, Control)
    table.insert(Library.GatedControls, Control)

    -- Find the section owning this row, including wrapped controls such as
    -- color pickers, and register the row for staggered section animation.
    local ownerNode = parent
    while ownerNode and not Library.SectionByItems[ownerNode] do
        ownerNode = ownerNode.Parent
    end
    if ownerNode then
        local ownerSection = Library.SectionByItems[ownerNode]
        ownerSection.Controls = ownerSection.Controls or {}
        table.insert(ownerSection.Controls, Control)
    end

    Control:RefreshGate()

    return Holder, Control
end

local function registerFlag(control, flag, default)
    if not flag then
        return
    end
    control.Flag = flag
    Library.Flags[flag] = default
    Library.ControlsByFlag[flag] = control
end

--============================================================
-- TAB / SECTION API
--============================================================

function Library:CreateTab(name, localeKey)
    local tab = {
        Name = localeKey and self:L(localeKey) or name,
        LocaleKey = localeKey,
        Sections = {},
    }

    local Button = Create("TextButton", {
        Parent = TabList,
        Size = UDim2.new(1, -6, 0, 38),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 13,
    })
    Library:AdaptiveCorner(Button, -2)

    local TabStroke = Create("UIStroke", {
        Parent = Button,
        Thickness = 1.35,
        Transparency = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
    Library:BindTheme(TabStroke, "Color", "Outline")

    local TabText = Create("TextLabel", {
        Parent = Button,
        Position = UDim2.fromOffset(18, 0),
        Size = UDim2.new(1, -28, 1, 0),
        BackgroundTransparency = 1,
        Text = localeKey and Library:L(localeKey) or name,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 14,
    })
    Library:BindTheme(TabText, "TextColor3", "SubText")
    Library:RegisterFont(TabText)

    local Indicator = Create("Frame", {
        Parent = Button,
        Position = UDim2.new(0, 5, 0.5, -10),
        Size = UDim2.fromOffset(3, 20),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 15,
    })
    Library:BindTheme(Indicator, "BackgroundColor3", "Accent")
    Create("UICorner", {Parent = Indicator, CornerRadius = UDim.new(1, 0)})

    local PageGroup = Create("CanvasGroup", {
        Parent = Content,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        GroupTransparency = 1,
        Visible = false,
        ZIndex = 14,
    })

    local PageScale = Create("UIScale", {
        Parent = PageGroup,
        Scale = 1,
    })

    local Page = Create("ScrollingFrame", {
        Parent = PageGroup,
        Position = UDim2.fromOffset(15, 14),
        Size = UDim2.new(1, -26, 1, -28),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(),
        Visible = true,
        ZIndex = 14,
    })
    Library:BindTheme(Page, "ScrollBarImageColor3", "Accent")

    Create("UIPadding", {
        Parent = Page,
        PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 10),
        PaddingTop = UDim.new(0, 4),
        PaddingBottom = UDim.new(0, 10),
    })

    Create("UIListLayout", {
        Parent = Page,
        Padding = UDim.new(0, 9),
        SortOrder = Enum.SortOrder.LayoutOrder,
    })

    tab.Button = Button
    tab.TabText = TabText
    tab.TabStroke = TabStroke
    tab.Indicator = Indicator
    tab.Page = Page
    tab.PageGroup = PageGroup
    tab.PageScale = PageScale

    function tab:Select()
        if Library.ActiveDropdown and Library.ActiveDropdown.CloseDropdown then
            Library.ActiveDropdown:CloseDropdown()
        end

        if Library.CurrentTab == self then
            return
        end

        local oldTab = Library.CurrentTab
        local duration = math.max(0.12, (Library.Settings.AnimationSpeed or 0.18) * 0.85)

        for _, other in ipairs(Library.Tabs) do
            if other ~= self then
                Library:Animate(other.Button, duration, {
                    BackgroundTransparency = 1,
                })
                Library:Animate(other.Indicator, duration, {
                    BackgroundTransparency = 1,
                    Size = UDim2.fromOffset(3, 6),
                })
                Library:Animate(other.TabStroke, duration, {Transparency = 1})
                Library:Animate(other.TabText, duration, {TextColor3 = Library.Theme.SubText})
            end
        end

        if oldTab and oldTab.PageGroup and oldTab.PageGroup.Visible then
            local oldGroup = oldTab.PageGroup
            Library:Animate(oldGroup, duration, {
                GroupTransparency = 1,
                Position = UDim2.fromOffset(-44, 0),
            })
            if oldTab.PageScale then
                Library:Animate(oldTab.PageScale, duration, {Scale = 0.94})
            end
            task.delay(duration + 0.02, function()
                if Library.CurrentTab ~= oldTab and oldGroup.Parent then
                    oldGroup.Visible = false
                    oldGroup.Position = UDim2.fromOffset(0, 0)
                    if oldTab.PageScale then
                        oldTab.PageScale.Scale = 1
                    end
                end
            end)
        end

        self.PageGroup.Visible = true
        self.PageGroup.Position = UDim2.fromOffset(48, 0)
        self.PageGroup.GroupTransparency = 1
        if self.PageScale then
            self.PageScale.Scale = 0.93
        end
        Library:Animate(self.PageGroup, duration, {
            Position = UDim2.fromOffset(0, 0),
            GroupTransparency = 0,
        })
        if self.PageScale then
            Library:Animate(self.PageScale, duration, {Scale = 1})
        end

        self.Button.BackgroundColor3 = Library.Theme.Control2
        Library:Animate(self.Button, duration, {BackgroundTransparency = 0.08})
        Library:Animate(self.TabStroke, duration, {Transparency = 0.12})
        Library:Animate(self.TabText, duration, {TextColor3 = Library.Theme.Text})
        self.Indicator.Size = UDim2.fromOffset(3, 6)
        Library:Animate(self.Indicator, duration, {
            BackgroundTransparency = 0,
            Size = UDim2.fromOffset(3, 20),
        })

        Library.CurrentTab = self
        Library.Breadcrumb.Text = self.LocaleKey and Library:L(self.LocaleKey) or self.Name
    end

    Button.MouseButton1Click:Connect(function()
        tab:Select()
    end)

    function tab:CreateSection(title, defaultOpen, localeKey)
        local section = {
            LocaleKey = localeKey,
            -- Closed unless a caller explicitly opts in with true.
            Open = defaultOpen == true,
            Controls = {},
        }

        local SectionFrame = Create("Frame", {
            Parent = Page,
            Size = UDim2.new(1, -2, 0, 42),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AutomaticSize = Enum.AutomaticSize.Y,
            ZIndex = 14,
        })

        local Header = Create("TextButton", {
            Parent = SectionFrame,
            Size = UDim2.new(1, 0, 0, 38),
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            ZIndex = 15,
        })
        Library:BindTheme(Header, "BackgroundColor3", "Panel")
        Library:AdaptiveCorner(Header, 0)

        local HeaderStroke = Create("UIStroke", {
            Parent = Header,
            Thickness = 1.2,
            Transparency = 0.24,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        })
        Library:BindTheme(HeaderStroke, "Color", "Outline")

        local HeaderText = Create("TextLabel", {
            Parent = Header,
            Position = UDim2.fromOffset(12, 0),
            Size = UDim2.new(1, -48, 1, 0),
            BackgroundTransparency = 1,
            Text = localeKey and Library:L(localeKey) or title,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 16,
        })
        Library:BindTheme(HeaderText, "TextColor3", "Text")
        Library:RegisterFont(HeaderText, true)

        local Arrow = Create("TextLabel", {
            Parent = Header,
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -12, 0.5, 0),
            Size = UDim2.fromOffset(24, 24),
            BackgroundTransparency = 1,
            Text = section.Open and "-" or "+",
            TextSize = 18,
            ZIndex = 16,
        })
        Library:BindTheme(Arrow, "TextColor3", "Accent")
        Library:RegisterFont(Arrow, true)

        local Items = Create("CanvasGroup", {
            Parent = SectionFrame,
            Position = UDim2.fromOffset(0, 44),
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            GroupTransparency = section.Open and 0 or 1,
            Visible = section.Open,
            ZIndex = 15,
        })

        local ItemsScale = Create("UIScale", {
            Parent = Items,
            Scale = section.Open and 1 or 0.90,
        })

        -- CanvasGroup can clip the first child's outside stroke at its own top
        -- edge. Even though v7 uses an inset border for rows, this padding also
        -- gives dropdowns/pickers and future custom controls safe breathing room.
        Create("UIPadding", {
            Parent = Items,
            PaddingLeft = UDim.new(0, 3),
            PaddingRight = UDim.new(0, 3),
            PaddingTop = UDim.new(0, 4),
            PaddingBottom = UDim.new(0, 4),
        })

        local ItemsLayout = Create("UIListLayout", {
            Parent = Items,
            Padding = UDim.new(0, 6),
            SortOrder = Enum.SortOrder.LayoutOrder,
            HorizontalAlignment = Enum.HorizontalAlignment.Center,
        })

        section.Frame = SectionFrame
        section.Header = Header
        section.Items = Items
        section.ItemsLayout = ItemsLayout
        section.AnimationToken = 0
        Library.SectionByItems[Items] = section

        function section:SetOpen(state, instant)
            if not state and Library.ActiveDropdown and Library.ActiveDropdown.CloseDropdown then
                Library.ActiveDropdown:CloseDropdown()
            end

            state = state == true
            if self.Open == state and not instant then
                return
            end

            self.Open = state
            self.AnimationToken += 1
            local token = self.AnimationToken

            -- Deliberately slower than the rest of the UI. Section expansion is
            -- structural and should feel like content unfolding, not popping in.
            local duration = math.max(0.34, (Library.Settings.AnimationSpeed or 0.18) * 1.85)

            local function contentHeight()
                local h = ItemsLayout.AbsoluteContentSize.Y + 8
                return math.max(8, h)
            end

            if instant then
                Items.Visible = state
                Items.GroupTransparency = state and 0 or 1
                Items.Position = UDim2.fromOffset(0, 44)
                ItemsScale.Scale = state and 1 or 0.72
                HeaderStroke.Transparency = state and 0.12 or 0.24
                Arrow.Text = state and "-" or "+"

                if state then
                    Items.AutomaticSize = Enum.AutomaticSize.Y
                    Items.Size = UDim2.new(1, 0, 0, 0)
                else
                    Items.AutomaticSize = Enum.AutomaticSize.None
                    Items.Size = UDim2.new(1, 0, 0, 0)
                end

                for _, control in ipairs(self.Controls) do
                    if control.MotionScale and control.MotionScale.Parent then
                        control.MotionScale.Scale = 1
                    end
                end
                return
            end

            if state then
                Items.Visible = true
                Items.AutomaticSize = Enum.AutomaticSize.None
                Items.Size = UDim2.new(1, 0, 0, 0)
                Items.GroupTransparency = 1
                Items.Position = UDim2.fromOffset(0, 4)
                ItemsScale.Scale = 0.72
                Arrow.Text = "-"

                -- Let UIListLayout refresh once, then animate the true content
                -- height. This makes the SECTION itself open smoothly.
                task.defer(function()
                    if section.AnimationToken ~= token or not section.Open or not Items.Parent then
                        return
                    end

                    local targetHeight = contentHeight()

                    TweenService:Create(
                        Items,
                        TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
                        {
                            Size = UDim2.new(1, 0, 0, targetHeight),
                            GroupTransparency = 0,
                            Position = UDim2.fromOffset(0, 44),
                        }
                    ):Play()

                    TweenService:Create(
                        ItemsScale,
                        TweenInfo.new(duration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                        {Scale = 1}
                    ):Play()

                    Library:Animate(HeaderStroke, duration * 0.75, {Transparency = 0.12})

                    -- Each function arrives separately. The bigger stagger is
                    -- intentional so large sections visually "build" themselves.
                    for index, control in ipairs(self.Controls) do
                        if control.MotionScale and control.MotionScale.Parent then
                            control.MotionScale.Scale = 0.78

                            task.delay(math.min((index - 1) * 0.060, 0.48), function()
                                if section.AnimationToken == token
                                    and section.Open
                                    and control.MotionScale
                                    and control.MotionScale.Parent
                                then
                                    TweenService:Create(
                                        control.MotionScale,
                                        TweenInfo.new(duration * 0.88, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                                        {Scale = 1}
                                    ):Play()
                                end
                            end)
                        end
                    end

                    task.delay(duration + 0.04, function()
                        if section.AnimationToken == token and section.Open and Items.Parent then
                            Items.AutomaticSize = Enum.AutomaticSize.Y
                            Items.Size = UDim2.new(1, 0, 0, 0)
                            Items.Position = UDim2.fromOffset(0, 44)
                            ItemsScale.Scale = 1
                        end
                    end)
                end)
            else
                Arrow.Text = "+"

                -- Freeze the current automatic height first so it can tween down
                -- to zero instead of disappearing in one frame.
                local currentHeight = math.max(Items.AbsoluteSize.Y, contentHeight())
                Items.AutomaticSize = Enum.AutomaticSize.None
                Items.Size = UDim2.new(1, 0, 0, currentHeight)

                for _, control in ipairs(self.Controls) do
                    if control.MotionScale and control.MotionScale.Parent then
                        TweenService:Create(
                            control.MotionScale,
                            TweenInfo.new(duration * 0.72, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                            {Scale = 0.80}
                        ):Play()
                    end
                end

                TweenService:Create(
                    Items,
                    TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                    {
                        Size = UDim2.new(1, 0, 0, 0),
                        GroupTransparency = 1,
                        Position = UDim2.fromOffset(0, 18),
                    }
                ):Play()

                TweenService:Create(
                    ItemsScale,
                    TweenInfo.new(duration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                    {Scale = 0.72}
                ):Play()

                Library:Animate(HeaderStroke, duration * 0.72, {Transparency = 0.24})

                task.delay(duration + 0.04, function()
                    if section.AnimationToken == token and not section.Open and Items.Parent then
                        Items.Visible = false
                        Items.AutomaticSize = Enum.AutomaticSize.None
                        Items.Size = UDim2.new(1, 0, 0, 0)
                        Items.Position = UDim2.fromOffset(0, 44)
                    end
                end)
            end
        end

        Header.MouseButton1Click:Connect(function()
            section:SetOpen(not section.Open)
        end)

        -- GROUP SEPARATOR
        -- Use this BETWEEN unrelated groups of controls. Related controls
        -- intentionally have no divider between them.
        function section:AddSeparator(opts)
            opts = opts or {}

            local Wrap = Create("Frame", {
                Parent = Items,
                Size = UDim2.new(1, 0, 0, opts.Height or 10),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ZIndex = 15,
            })

            local Line = Create("Frame", {
                Parent = Wrap,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.new(opts.WidthScale or 0.80, 0, 0, opts.Thickness or 2),
                BorderSizePixel = 0,
                BackgroundTransparency = opts.Transparency or 0.24,
                ZIndex = 16,
            })
            Library:BindTheme(Line, "BackgroundColor3", opts.ThemeKey or "Outline")

            return Line
        end

        -- BUTTON
        function section:AddButton(opts)
            opts = opts or {}
            local Holder, control = newBaseControl(Items, opts.Name or "Button", opts.RequiredGraphics, 42, opts)

            local Button = Create("TextButton", {
                Parent = Holder,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -10, 0.5, 0),
                Size = UDim2.fromOffset(88, 26),
                BorderSizePixel = 0,
                Text = opts.ButtonText or "Run",
                TextSize = 11,
                AutoButtonColor = false,
                ZIndex = 17,
            })
            Library:BindTheme(Button, "BackgroundColor3", "Control2")
            Library:BindTheme(Button, "TextColor3", "Text")
            Library:RegisterFont(Button, true)
            if opts.ButtonLocaleKey then
                Library:BindLocaleText(Button, opts.ButtonLocaleKey)
            end
            Library:AdaptiveCorner(Button, -2)

            Button.MouseButton1Click:Connect(function()
                if control.Locked then return end
                safeCallback(opts.Callback)
            end)

            return control
        end

        -- TOGGLE
        function section:AddToggle(opts)
            opts = opts or {}
            local state = opts.Default == true
            local Holder, control = newBaseControl(Items, opts.Name or "Toggle", opts.RequiredGraphics, 42, opts)

            control.Requirement.Position = UDim2.new(1, -60, 0.5, 0)

            local Switch = Create("Frame", {
                Parent = Holder,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -10, 0.5, 0),
                Size = UDim2.fromOffset(38, 20),
                BorderSizePixel = 0,
                ZIndex = 17,
            })
            Create("UICorner", {Parent = Switch, CornerRadius = UDim.new(1, 0)})

            local Dot = Create("Frame", {
                Parent = Switch,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0, 10, 0.5, 0),
                Size = UDim2.fromOffset(14, 14),
                BackgroundColor3 = Color3.fromRGB(245, 245, 250),
                BorderSizePixel = 0,
                ZIndex = 18,
            })
            Create("UICorner", {Parent = Dot, CornerRadius = UDim.new(1, 0)})

            local Click = Create("TextButton", {
                Parent = Holder,
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Text = "",
                ZIndex = 19,
            })

            control.IsToggle = true

            function control:RefreshStyle()
                control:RefreshGate()
                Switch.BackgroundColor3 = state and Library.Theme.Accent or Library.Theme.Control2
                Switch.BackgroundTransparency = self.Locked and 0.5 or 0
                Dot.BackgroundTransparency = self.Locked and 0.35 or 0
            end

            function control:Set(value, silent)
                local nextState = value == true
                if nextState and self.Locked then
                    nextState = false
                end

                state = nextState
                if self.Flag then Library.Flags[self.Flag] = state end

                Library:AnimateControl(Dot, 0.12, {
                    Position = state and UDim2.new(1, -10, 0.5, 0) or UDim2.new(0, 10, 0.5, 0),
                })
                self:RefreshStyle()

                if not silent then
                    safeCallback(opts.Callback, state)
                end
            end

            function control:OnGraphicsLocked()
                if state then
                    self:Set(false, false)
                end
            end

            function control:Get()
                return state
            end

            Click.MouseButton1Click:Connect(function()
                if control.Locked then return end
                control:Set(not state)
            end)

            registerFlag(control, opts.Flag, state)
            control:Set(state, true)
            return control
        end

        -- SLIDER
        function section:AddSlider(opts)
            opts = opts or {}
            local min = tonumber(opts.Min) or 0
            local max = tonumber(opts.Max) or 100
            local value = math.clamp(tonumber(opts.Default) or min, min, max)
            local decimals = tonumber(opts.Decimals) or 0

            local Holder, control = newBaseControl(Items, opts.Name or "Slider", opts.RequiredGraphics, 58, opts)
            control.Label.Size = UDim2.new(1, -160, 0, 32)
            control.Requirement.Position = UDim2.new(1, -75, 0, 16)

            local ValueLabel = Create("TextLabel", {
                Parent = Holder,
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -10, 0, 5),
                Size = UDim2.fromOffset(62, 22),
                BackgroundTransparency = 1,
                TextSize = 11,
                TextXAlignment = Enum.TextXAlignment.Right,
                ZIndex = 17,
            })
            Library:BindTheme(ValueLabel, "TextColor3", "SubText")
            Library:RegisterFont(ValueLabel, true)

            local Bar = Create("Frame", {
                Parent = Holder,
                Position = UDim2.new(0, 12, 1, -17),
                Size = UDim2.new(1, -24, 0, 5),
                BorderSizePixel = 0,
                ZIndex = 17,
            })
            Library:BindTheme(Bar, "BackgroundColor3", "Control2")
            Create("UICorner", {Parent = Bar, CornerRadius = UDim.new(1, 0)})

            local Fill = Create("Frame", {
                Parent = Bar,
                Size = UDim2.fromScale(0, 1),
                BorderSizePixel = 0,
                ZIndex = 18,
            })
            Library:BindTheme(Fill, "BackgroundColor3", "Accent")
            Create("UICorner", {Parent = Fill, CornerRadius = UDim.new(1, 0)})

            local draggingSlider = false

            local function round(n)
                local m = 10 ^ decimals
                return math.floor(n * m + 0.5) / m
            end

            local function fromX(x)
                if control.Locked then return end
                local p = math.clamp((x - Bar.AbsolutePosition.X) / math.max(1, Bar.AbsoluteSize.X), 0, 1)

                -- Stepped mode snaps the visual/input position into deliberate
                -- chunks. Smooth mode tracks the mouse continuously.
                if Library.Settings.AnimationMode == "Stepped" then
                    local visualSteps = tonumber(opts.VisualSteps) or 20
                    p = math.floor(p * visualSteps + 0.5) / visualSteps
                end

                control:Set(round(min + (max - min) * p))
            end

            function control:RefreshStyle()
                control:RefreshGate()
                Fill.BackgroundTransparency = self.Locked and 0.58 or 0
                Bar.BackgroundTransparency = self.Locked and 0.35 or 0
                ValueLabel.TextTransparency = self.Locked and 0.5 or 0
            end

            function control:Set(v, silent)
                value = math.clamp(tonumber(v) or min, min, max)
                value = round(value)

                local p = (value - min) / math.max(0.0001, max - min)
                ValueLabel.Text = tostring(value)

                if silent then
                    Fill.Size = UDim2.fromScale(p, 1)
                elseif Library.Settings.AnimationMode == "Smooth" then
                    Library:AnimateControl(Fill, 0.07, {Size = UDim2.fromScale(p, 1)})
                else
                    -- In Stepped mode fromX already quantizes p, so snap to
                    -- that step instead of easing between positions.
                    Fill.Size = UDim2.fromScale(p, 1)
                end

                if self.Flag then Library.Flags[self.Flag] = value end
                if not silent then safeCallback(opts.Callback, value) end
            end

            function control:Get()
                return value
            end

            Bar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 and not control.Locked then
                    draggingSlider = true
                    fromX(input.Position.X)
                end
            end)

            UIS.InputChanged:Connect(function(input)
                if Library.Unloaded then return end
                if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
                    fromX(input.Position.X)
                end
            end)

            UIS.InputEnded:Connect(function(input)
                if Library.Unloaded then return end
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    draggingSlider = false
                end
            end)

            registerFlag(control, opts.Flag, value)
            control:Set(value, true)
            return control
        end

        -- CHOICE / REAL DROPDOWN
        -- Clicking the value opens a panel below the control with every option.
        function section:AddChoice(opts)
            opts = opts or {}
            local values = opts.Values or {"None"}
            local value = opts.Default or values[1]
            local open = false

            local CLOSED_HEIGHT = 42
            local OPTION_HEIGHT = 28
            local OPTIONS_PADDING = 6
            local optionsHeight = (#values * OPTION_HEIGHT) + OPTIONS_PADDING * 2

            local Holder, control = newBaseControl(Items, opts.Name or "Choice", opts.RequiredGraphics, CLOSED_HEIGHT, opts)
            Holder.ClipsDescendants = true
            control.Requirement.Position = UDim2.new(1, -150, 0.5, 0)

            local Select = Create("TextButton", {
                Parent = Holder,
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -10, 0, 8),
                Size = UDim2.fromOffset(128, 26),
                BorderSizePixel = 0,
                TextSize = 11,
                AutoButtonColor = false,
                ZIndex = 19,
            })
            Library:BindTheme(Select, "BackgroundColor3", "Control2")
            Library:BindTheme(Select, "TextColor3", "Text")
            Library:RegisterFont(Select, true)
            Library:AdaptiveCorner(Select, -2)

            local OptionsFrame = Create("CanvasGroup", {
                Parent = Holder,
                Position = UDim2.fromOffset(10, CLOSED_HEIGHT + 7),
                Size = UDim2.new(1, -20, 0, optionsHeight - 6),
                BorderSizePixel = 0,
                BackgroundTransparency = 0,
                GroupTransparency = 1,
                Visible = false,
                ZIndex = 30,
            })
            Library:BindTheme(OptionsFrame, "BackgroundColor3", "Panel")
            Library:AdaptiveCorner(OptionsFrame, -2)

            local OptionsScale = Create("UIScale", {
                Parent = OptionsFrame,
                Scale = 1,
            })

            local OptionsStroke = Create("UIStroke", {
                Parent = OptionsFrame,
                Thickness = 1.2,
                Transparency = 0.20,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            })
            Library:BindTheme(OptionsStroke, "Color", "Outline")

            local OptionsInner = Create("Frame", {
                Parent = OptionsFrame,
                Position = UDim2.fromOffset(6, 6),
                Size = UDim2.new(1, -12, 1, -12),
                BackgroundTransparency = 1,
                ZIndex = 31,
            })

            Create("UIListLayout", {
                Parent = OptionsInner,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 0),
            })

            local optionButtons = {}

            local function refreshOptionStyles()
                for _, item in ipairs(optionButtons) do
                    local selected = item.Value == value
                    item.Button.BackgroundTransparency = selected and 0.08 or 1
                    item.Button.TextColor3 = selected and Library.Theme.Accent or Library.Theme.Text
                end
            end

            function control:RefreshStyle()
                control:RefreshGate()
                Select.BackgroundTransparency = self.Locked and 0.45 or 0
                Select.TextTransparency = self.Locked and 0.45 or 0
                OptionsFrame.BackgroundTransparency = self.Locked and 0.35 or 0
                refreshOptionStyles()
            end

            function control:Set(v, silent)
                if table.find(values, v) then
                    value = v
                else
                    value = values[1]
                end

                Select.Text = tostring(value) .. (open and "  ^" or "  v")
                if self.Flag then Library.Flags[self.Flag] = value end
                refreshOptionStyles()
                if not silent then safeCallback(opts.Callback, value) end
            end

            function control:Get()
                return value
            end

            local dropdownToken = 0

            function control:CloseDropdown()
                if not open then return end
                open = false
                dropdownToken += 1
                local token = dropdownToken
                local duration = math.max(0.12, (Library.Settings.AnimationSpeed or 0.18) * 0.75)

                Select.Text = tostring(value) .. "  v"
                Library:Animate(OptionsFrame, duration, {
                    GroupTransparency = 1,
                    Position = UDim2.fromOffset(10, CLOSED_HEIGHT + 7),
                })
                Library:Animate(OptionsScale, duration, {Scale = 0.92})
                Library:Animate(Holder, duration, {
                    Size = UDim2.new(Library:GetFunctionDPIScale(), 0, 0, CLOSED_HEIGHT),
                })

                task.delay(duration + 0.02, function()
                    if dropdownToken == token and not open and OptionsFrame.Parent then
                        OptionsFrame.Visible = false
                        OptionsScale.Scale = 1
                    end
                end)

                if Library.ActiveDropdown == self then
                    Library.ActiveDropdown = nil
                end
            end

            function control:OpenDropdown()
                if self.Locked or open then return end

                if Library.ActiveDropdown and Library.ActiveDropdown ~= self and Library.ActiveDropdown.CloseDropdown then
                    Library.ActiveDropdown:CloseDropdown()
                end

                open = true
                dropdownToken += 1
                Library.ActiveDropdown = self
                OptionsFrame.Visible = true
                OptionsFrame.GroupTransparency = 1
                OptionsFrame.Position = UDim2.fromOffset(10, CLOSED_HEIGHT + 18)
                OptionsScale.Scale = 0.88
                Select.Text = tostring(value) .. "  ^"

                local duration = math.max(0.14, (Library.Settings.AnimationSpeed or 0.18) * 0.90)
                Library:Animate(Holder, duration, {
                    Size = UDim2.new(Library:GetFunctionDPIScale(), 0, 0, CLOSED_HEIGHT + optionsHeight),
                })
                Library:Animate(OptionsFrame, duration, {
                    GroupTransparency = 0,
                    Position = UDim2.fromOffset(10, CLOSED_HEIGHT),
                })
                Library:Animate(OptionsScale, duration, {Scale = 1})
            end

            for _, optionValue in ipairs(values) do
                local option = optionValue
                local OptionButton = Create("TextButton", {
                    Parent = OptionsInner,
                    Size = UDim2.new(1, 0, 0, OPTION_HEIGHT),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Text = tostring(option),
                    TextSize = 11,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    AutoButtonColor = false,
                    ZIndex = 32,
                })
                Library:BindTheme(OptionButton, "TextColor3", "Text")
                Library:RegisterFont(OptionButton)
                Library:AdaptiveCorner(OptionButton, -4)

                local pad = Create("UIPadding", {
                    Parent = OptionButton,
                    PaddingLeft = UDim.new(0, 9),
                })

                table.insert(optionButtons, {
                    Button = OptionButton,
                    Value = option,
                })

                OptionButton.MouseButton1Click:Connect(function()
                    if control.Locked then return end
                    control:Set(option)
                    control:CloseDropdown()
                end)

                OptionButton.MouseEnter:Connect(function()
                    if option ~= value then
                        OptionButton.BackgroundTransparency = 0.65
                    end
                end)

                OptionButton.MouseLeave:Connect(function()
                    refreshOptionStyles()
                end)
            end

            Select.MouseButton1Click:Connect(function()
                if control.Locked then return end
                if open then
                    control:CloseDropdown()
                else
                    control:OpenDropdown()
                end
            end)

            registerFlag(control, opts.Flag, value)
            control:Set(value, true)
            return control
        end

        -- KEYBIND
        function section:AddKeybind(opts)
            opts = opts or {}
            local value = tostring(opts.Default or "RightShift")
            if not Enum.KeyCode[value] then
                value = "RightShift"
            end

            local listening = false
            local Holder, control = newBaseControl(Items, opts.Name or "Keybind", opts.RequiredGraphics, 42, opts)
            control.Requirement.Position = UDim2.new(1, -150, 0.5, 0)

            local BindButton = Create("TextButton", {
                Parent = Holder,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -10, 0.5, 0),
                Size = UDim2.fromOffset(128, 26),
                BorderSizePixel = 0,
                TextSize = 11,
                AutoButtonColor = false,
                ZIndex = 19,
            })
            Library:BindTheme(BindButton, "BackgroundColor3", "Control2")
            Library:BindTheme(BindButton, "TextColor3", "Text")
            Library:RegisterFont(BindButton, true)
            Library:AdaptiveCorner(BindButton, -2)

            function control:RefreshStyle()
                control:RefreshGate()
                BindButton.BackgroundTransparency = self.Locked and 0.45 or 0
                BindButton.TextTransparency = self.Locked and 0.45 or 0
            end

            function control:Set(v, silent)
                local keyName
                if typeof(v) == "EnumItem" and v.EnumType == Enum.KeyCode then
                    keyName = v.Name
                else
                    keyName = tostring(v)
                end

                if not Enum.KeyCode[keyName] or Enum.KeyCode[keyName] == Enum.KeyCode.Unknown then
                    return
                end

                value = keyName
                BindButton.Text = value
                if self.Flag then Library.Flags[self.Flag] = value end
                if not silent then safeCallback(opts.Callback, value, Enum.KeyCode[value]) end
            end

            function control:Get()
                return value
            end

            local function stopListening(cancelled)
                listening = false
                if Library.BindingKey == control then
                    Library.BindingKey = nil
                end
                BindButton.Text = value
                if not cancelled then
                    Library.SuppressMenuKey = true
                    task.delay(0.18, function()
                        Library.SuppressMenuKey = false
                    end)
                end
            end

            BindButton.MouseButton1Click:Connect(function()
                if control.Locked then return end
                if Library.ActiveDropdown and Library.ActiveDropdown.CloseDropdown then
                    Library.ActiveDropdown:CloseDropdown()
                end
                listening = true
                Library.BindingKey = control
                BindButton.Text = "press key..."
            end)

            UIS.InputBegan:Connect(function(input)
                if Library.Unloaded then return end
                if not listening or Library.BindingKey ~= control then return end
                if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
                if input.KeyCode == Enum.KeyCode.Unknown then return end

                if input.KeyCode == Enum.KeyCode.Escape then
                    stopListening(true)
                    return
                end

                local keyName = input.KeyCode.Name
                control:Set(keyName)
                stopListening(false)
            end)

            registerFlag(control, opts.Flag, value)
            control:Set(value, true)
            return control
        end

        -- INPUT
        function section:AddInput(opts)
            opts = opts or {}
            local value = tostring(opts.Default or "")
            local Holder, control = newBaseControl(Items, opts.Name or "Input", opts.RequiredGraphics, 42, opts)
            control.Requirement.Position = UDim2.new(1, -175, 0.5, 0)

            local Box = Create("TextBox", {
                Parent = Holder,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -10, 0.5, 0),
                Size = UDim2.fromOffset(155, 26),
                BorderSizePixel = 0,
                Text = value,
                PlaceholderText = opts.Placeholder or "...",
                ClearTextOnFocus = false,
                TextSize = 11,
                ZIndex = 17,
            })
            Library:BindTheme(Box, "BackgroundColor3", "Control2")
            Library:BindTheme(Box, "TextColor3", "Text")
            Library:BindTheme(Box, "PlaceholderColor3", "SubText")
            Library:RegisterFont(Box)
            if opts.PlaceholderKey then
                Library:BindLocaleText(Box, opts.PlaceholderKey, "PlaceholderText")
            end
            Library:AdaptiveCorner(Box, -2)

            function control:RefreshStyle()
                control:RefreshGate()
                Box.BackgroundTransparency = self.Locked and 0.45 or 0
                Box.TextTransparency = self.Locked and 0.45 or 0
                Box.TextEditable = not self.Locked
            end

            function control:Set(v, silent)
                value = tostring(v or "")
                Box.Text = value
                if self.Flag then Library.Flags[self.Flag] = value end
                if not silent then safeCallback(opts.Callback, value) end
            end

            function control:Get()
                return value
            end

            Box.FocusLost:Connect(function()
                if control.Locked then return end
                control:Set(Box.Text)
            end)

            registerFlag(control, opts.Flag, value)
            control:Set(value, true)
            return control
        end

        -- COLOR PICKER (Linoria-style HSV palette)
        function section:AddColorPicker(opts)
            opts = opts or {}
            local themeKey = opts.ThemeKey
            local color = (themeKey and Library.Theme[themeKey]) or opts.Default or Color3.new(1, 1, 1)
            local hue, saturation, brightness = Color3.toHSV(color)
            local expanded = false
            local draggingSV = false
            local draggingHue = false

            local Wrapper = Create("Frame", {
                Parent = Items,
                Size = UDim2.new(1, 0, 0, 42),
                BackgroundTransparency = 1,
                ZIndex = 15,
            })

            local Holder, control = newBaseControl(Wrapper, opts.Name or "Color", opts.RequiredGraphics, 42, opts)

            local Preview = Create("TextButton", {
                Parent = Holder,
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -10, 0.5, 0),
                Size = UDim2.fromOffset(62, 24),
                BackgroundColor3 = color,
                BorderSizePixel = 0,
                Text = "",
                ZIndex = 17,
            })
            Library:AdaptiveCorner(Preview, -3)

            local PreviewStroke = Create("UIStroke", {
                Parent = Preview,
                Thickness = 1,
                Transparency = 0.18,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            })
            Library:BindTheme(PreviewStroke, "Color", "Outline")

            local editorScale = Library:GetFunctionDPIScale()
            local Editor = Create("CanvasGroup", {
                Parent = Wrapper,
                Position = UDim2.new((1 - editorScale) * 0.5, 0, 0, 54),
                Size = UDim2.new(editorScale, 0, 0, 154),
                BorderSizePixel = 0,
                BackgroundTransparency = 0,
                GroupTransparency = 1,
                Visible = false,
                ZIndex = 25,
            })
            table.insert(Library.ControlFrames, {
                Object = Editor,
                ManualCenter = true,
            })
            Library:BindTheme(Editor, "BackgroundColor3", "Control")
            Library:AdaptiveCorner(Editor, -1)
            local PickerScale = Create("UIScale", {
                Parent = Editor,
                Scale = 0.975,
            })

            local EditorStroke = Create("UIStroke", {
                Parent = Editor,
                Thickness = 1.15,
                Transparency = 0.20,
                ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            })
            Library:BindTheme(EditorStroke, "Color", "Outline")

            local Palette = Create("Frame", {
                Parent = Editor,
                Position = UDim2.fromOffset(10, 10),
                Size = UDim2.new(1, -54, 0, 134),
                BackgroundColor3 = Color3.fromHSV(hue, 1, 1),
                BorderSizePixel = 0,
                ClipsDescendants = true,
                ZIndex = 26,
            })
            Library:AdaptiveCorner(Palette, -3)

            local WhiteLayer = Create("Frame", {
                Parent = Palette,
                Size = UDim2.fromScale(1, 1),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0,
                ZIndex = 27,
            })
            Create("UIGradient", {
                Parent = WhiteLayer,
                Rotation = 0,
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(1, 1),
                }),
            })

            local BlackLayer = Create("Frame", {
                Parent = Palette,
                Size = UDim2.fromScale(1, 1),
                BackgroundColor3 = Color3.new(0, 0, 0),
                BorderSizePixel = 0,
                ZIndex = 28,
            })
            Create("UIGradient", {
                Parent = BlackLayer,
                Rotation = 90,
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(1, 0),
                }),
            })

            local SVHit = Create("TextButton", {
                Parent = Palette,
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Text = "",
                AutoButtonColor = false,
                ZIndex = 30,
            })

            local SVCursor = Create("Frame", {
                Parent = Palette,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(saturation, 1 - brightness),
                Size = UDim2.fromOffset(8, 8),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0,
                ZIndex = 31,
            })
            Create("UICorner", {Parent = SVCursor, CornerRadius = UDim.new(1, 0)})
            Create("UIStroke", {Parent = SVCursor, Color = Color3.new(0, 0, 0), Thickness = 1})

            local HueBar = Create("Frame", {
                Parent = Editor,
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -10, 0, 10),
                Size = UDim2.fromOffset(24, 134),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0,
                ClipsDescendants = false,
                ZIndex = 26,
            })
            Library:AdaptiveCorner(HueBar, -3)
            Create("UIGradient", {
                Parent = HueBar,
                Rotation = 90,
                Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
                    ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
                    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
                    ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
                    ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
                    ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
                    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
                }),
            })

            local HueHit = Create("TextButton", {
                Parent = HueBar,
                Size = UDim2.fromScale(1, 1),
                BackgroundTransparency = 1,
                Text = "",
                AutoButtonColor = false,
                ZIndex = 30,
            })

            local HueCursor = Create("Frame", {
                Parent = HueBar,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, 0, hue, 0),
                Size = UDim2.new(1, 6, 0, 3),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0,
                ZIndex = 31,
            })
            Create("UICorner", {Parent = HueCursor, CornerRadius = UDim.new(1, 0)})
            Create("UIStroke", {Parent = HueCursor, Color = Color3.new(0, 0, 0), Thickness = 1})

            local function refreshVisuals()
                Palette.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
                Preview.BackgroundColor3 = color
                SVCursor.Position = UDim2.fromScale(saturation, 1 - brightness)
                HueCursor.Position = UDim2.new(0.5, 0, hue, 0)
            end

            local function commit(silent)
                color = Color3.fromHSV(hue, saturation, brightness)
                refreshVisuals()
                if control.Flag then Library.Flags[control.Flag] = color end
                if not silent then safeCallback(opts.Callback, color) end
            end

            local function updateSV(inputPosition)
                if control.Locked then return end
                saturation = math.clamp((inputPosition.X - Palette.AbsolutePosition.X) / math.max(1, Palette.AbsoluteSize.X), 0, 1)
                brightness = 1 - math.clamp((inputPosition.Y - Palette.AbsolutePosition.Y) / math.max(1, Palette.AbsoluteSize.Y), 0, 1)
                commit(false)
            end

            local function updateHue(inputPosition)
                if control.Locked then return end
                hue = math.clamp((inputPosition.Y - HueBar.AbsolutePosition.Y) / math.max(1, HueBar.AbsoluteSize.Y), 0, 1)
                commit(false)
            end

            function control:RefreshStyle()
                control:RefreshGate()
                Preview.BackgroundTransparency = self.Locked and 0.55 or 0
                Editor.BackgroundTransparency = self.Locked and 0.35 or 0
            end

            function control:Set(v, silent)
                if typeof(v) ~= "Color3" then return end
                color = v
                hue, saturation, brightness = Color3.toHSV(color)
                refreshVisuals()
                if self.Flag then Library.Flags[self.Flag] = color end
                if not silent then safeCallback(opts.Callback, color) end
            end

            function control:Get()
                return color
            end

            local pickerToken = 0

            function control:ClosePicker()
                if not expanded then return end
                expanded = false
                pickerToken += 1
                local token = pickerToken
                local duration = math.max(0.12, (Library.Settings.AnimationSpeed or 0.18) * 0.8)

                Library:Animate(Editor, duration, {
                    GroupTransparency = 1,
                    Position = UDim2.new(Editor.Position.X.Scale, Editor.Position.X.Offset, 0, 60),
                })
                Library:Animate(PickerScale, duration, {Scale = 0.95})
                Library:Animate(Wrapper, duration, {Size = UDim2.new(1, 0, 0, 42)})

                task.delay(duration + 0.02, function()
                    if pickerToken == token and not expanded and Editor.Parent then
                        Editor.Visible = false
                    end
                end)
            end

            local function openPicker()
                if control.Locked or expanded then return end
                expanded = true
                pickerToken += 1
                Editor.Visible = true
                Editor.GroupTransparency = 1
                Editor.Position = UDim2.new(Editor.Position.X.Scale, Editor.Position.X.Offset, 0, 54)
                PickerScale.Scale = 0.95

                local duration = math.max(0.12, (Library.Settings.AnimationSpeed or 0.18) * 0.8)
                Library:Animate(Wrapper, duration, {Size = UDim2.new(1, 0, 0, 202)})
                Library:Animate(Editor, duration, {
                    GroupTransparency = 0,
                    Position = UDim2.new(Editor.Position.X.Scale, Editor.Position.X.Offset, 0, 48),
                })
                Library:Animate(PickerScale, duration, {Scale = 1})
            end

            Preview.MouseButton1Click:Connect(function()
                if control.Locked then return end
                if expanded then
                    control:ClosePicker()
                else
                    openPicker()
                end
            end)

            SVHit.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 and not control.Locked then
                    draggingSV = true
                    updateSV(input.Position)
                end
            end)

            HueHit.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 and not control.Locked then
                    draggingHue = true
                    updateHue(input.Position)
                end
            end)

            UIS.InputChanged:Connect(function(input)
                if Library.Unloaded then return end
                if input.UserInputType == Enum.UserInputType.MouseMovement then
                    if draggingSV then
                        updateSV(input.Position)
                    elseif draggingHue then
                        updateHue(input.Position)
                    end
                end
            end)

            UIS.InputEnded:Connect(function(input)
                if Library.Unloaded then return end
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    draggingSV = false
                    draggingHue = false
                end
            end)

            registerFlag(control, opts.Flag, color)
            control:Set(color, true)
            if themeKey and Library.Theme[themeKey] then
                table.insert(Library.ThemeColorControls, {
                    Key = themeKey,
                    Control = control,
                })
                control:Set(Library.Theme[themeKey], true)
            end
            return control
        end

        table.insert(tab.Sections, section)
        return section
    end

    table.insert(self.Tabs, tab)
    if #self.Tabs == 1 then
        tab:Select()
    end

    return tab
end

--============================================================
-- QUESTION / CONFIRM MODALS
--============================================================

local function normalizePromptOption(LibraryRef, option, index)
    if type(option) == "table" then
        local rawText = option.Text or option.Name or option.Label or option.Value or ("Option " .. tostring(index))
        return {
            Text = LibraryRef:ResolveLocalizedText(rawText, "Option " .. tostring(index)),
            Value = option.Value ~= nil and option.Value or LibraryRef:ResolveLocalizedText(rawText),
        }
    end

    return {
        Text = LibraryRef:ResolveLocalizedText(option, "Option " .. tostring(index)),
        Value = option,
    }
end

function Library:_ShowPrompt(options)
    options = options or {}

    if self.Unloaded then
        return nil, nil
    end

    self:HideControlTooltip(true)

    if self.ActiveDropdown and self.ActiveDropdown.CloseDropdown then
        pcall(function()
            self.ActiveDropdown:CloseDropdown()
        end)
    end

    self.PromptBusy = true

    local optionSource = options.Options or {}
    local normalized = {}

    for index, option in ipairs(optionSource) do
        table.insert(normalized, normalizePromptOption(self, option, index))
    end

    if #normalized == 0 then
        normalized = {
            {
                Text = self:L("Continue"),
                Value = true,
            }
        }
    end

    local overlay = Create("Frame", {
        Parent = Root,
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Active = true,
        ZIndex = 220,
    })
    self.ActivePromptOverlay = overlay

    local promptBox = Create("Frame", {
        Parent = overlay,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 64),
        Size = UDim2.fromOffset(540, 220),
        BackgroundColor3 = self.Theme.Background,
        BorderSizePixel = 0,
        ZIndex = 221,
    })
    self:AdaptiveCorner(promptBox, 4)

    local promptScale = Create("UIScale", {
        Parent = promptBox,
        Scale = math.max(0.45, (self.CurrentDPIScale or DPI_BASE_SCALE) * 0.70),
    })

    local promptStroke = Create("UIStroke", {
        Parent = promptBox,
        Thickness = 1.35,
        Transparency = 0.08,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Color = self.Theme.Outline,
    })

    local title = Create("TextLabel", {
        Parent = promptBox,
        Position = UDim2.fromOffset(24, 18),
        Size = UDim2.new(1, -48, 0, 30),
        BackgroundTransparency = 1,
        Text = self:ResolveLocalizedText(options.Title, self:L("Question")),
        TextColor3 = self.Theme.Text,
        TextSize = 22,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 222,
    })
    self:RegisterFont(title, true)

    local question = Create("TextLabel", {
        Parent = promptBox,
        Position = UDim2.fromOffset(24, 54),
        Size = UDim2.new(1, -48, 0, 72),
        BackgroundTransparency = 1,
        Text = self:ResolveLocalizedText(options.Question or options.Text, ""),
        TextColor3 = self.Theme.SubText,
        TextSize = 15,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        ZIndex = 222,
    })
    self:RegisterFont(question)

    local buttons = Create("Frame", {
        Parent = promptBox,
        Position = UDim2.new(0, 24, 1, -66),
        Size = UDim2.new(1, -48, 0, 42),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 222,
    })

    local gap = 8
    Create("UIListLayout", {
        Parent = buttons,
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, gap),
        SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Center,
    })

    local resultEvent = Instance.new("BindableEvent")
    local resolved = false

    local function finish(value, index)
        if resolved then
            return
        end
        resolved = true

        if options.Flag then
            Library.Flags[tostring(options.Flag)] = value
        end

        resultEvent:Fire(value, index)

        TweenService:Create(
            overlay,
            TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
            {BackgroundTransparency = 1}
        ):Play()

        TweenService:Create(
            promptBox,
            TweenInfo.new(0.26, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
            {Position = UDim2.new(0.5, 0, 0.5, 42)}
        ):Play()

        TweenService:Create(
            promptScale,
            TweenInfo.new(0.26, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
            {Scale = math.max(0.45, (Library.CurrentDPIScale or DPI_BASE_SCALE) * 0.72)}
        ):Play()
    end

    local buttonCount = math.max(1, #normalized)
    local widthOffset = -((gap * (buttonCount - 1)) / buttonCount)

    for index, option in ipairs(normalized) do
        local button = Create("TextButton", {
            Parent = buttons,
            Size = UDim2.new(1 / buttonCount, widthOffset, 1, 0),
            BackgroundColor3 = self.Theme.Control,
            BorderSizePixel = 0,
            Text = option.Text,
            TextColor3 = self.Theme.Text,
            TextSize = 14,
            TextWrapped = true,
            AutoButtonColor = false,
            LayoutOrder = index,
            ZIndex = 223,
        })
        self:RegisterFont(button, true)
        self:AdaptiveCorner(button, -2)

        local buttonStroke = Create("UIStroke", {
            Parent = button,
            Thickness = 1.1,
            Transparency = 0.18,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Color = self.Theme.Outline,
        })

        button.MouseEnter:Connect(function()
            if resolved then return end
            self:Animate(buttonStroke, 0.18, {Transparency = 0.02})
            self:Animate(button, 0.18, {BackgroundColor3 = self.Theme.Control2})
        end)

        button.MouseLeave:Connect(function()
            if resolved then return end
            self:Animate(buttonStroke, 0.18, {Transparency = 0.18})
            self:Animate(button, 0.18, {BackgroundColor3 = self.Theme.Control})
        end)

        button.MouseButton1Click:Connect(function()
            finish(option.Value, index)
        end)
    end

    TweenService:Create(
        overlay,
        TweenInfo.new(0.30, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        {BackgroundTransparency = 0.22}
    ):Play()

    TweenService:Create(
        promptBox,
        TweenInfo.new(0.48, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        {Position = UDim2.fromScale(0.5, 0.5)}
    ):Play()

    TweenService:Create(
        promptScale,
        TweenInfo.new(0.52, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Scale = math.max(0.45, self.CurrentDPIScale or DPI_BASE_SCALE)}
    ):Play()

    local value, index = resultEvent.Event:Wait()

    task.wait(0.27)

    if overlay.Parent then
        overlay:Destroy()
    end

    resultEvent:Destroy()
    self.ActivePromptOverlay = nil
    self.PromptBusy = false

    if type(options.Callback) == "function" then
        local ok, err = pcall(options.Callback, value, index)
        if not ok then
            warn("[Experiment17] Prompt callback error:", err)
        end
    end

    return value, index
end

function Library:ShowQuestion(options)
    options = options or {}
    if options.Title == nil then
        options.Title = self:L("Question")
    end
    return self:_ShowPrompt(options)
end

function Library:ShowConfirm(options)
    options = options or {}

    local confirmOptions = {}
    for key, value in pairs(options) do
        confirmOptions[key] = value
    end

    if confirmOptions.Title == nil then
        confirmOptions.Title = self:L("Confirmation")
    end

    confirmOptions.Options = {
        {
            Text = confirmOptions.YesText or self:L("Yes"),
            Value = true,
        },
        {
            Text = confirmOptions.NoText or self:L("No"),
            Value = false,
        },
    }

    return self:_ShowPrompt(confirmOptions)
end

function Library:QueueStartupQuestion(options)
    if self.StartupCompleted then
        task.spawn(function()
            self:ShowQuestion(options)
        end)
        return self
    end

    table.insert(self.StartupPrompts, {
        Type = "Question",
        Options = options or {},
    })

    return self
end

function Library:QueueStartupConfirm(options)
    if self.StartupCompleted then
        task.spawn(function()
            self:ShowConfirm(options)
        end)
        return self
    end

    table.insert(self.StartupPrompts, {
        Type = "Confirm",
        Options = options or {},
    })

    return self
end

-- Friendly aliases for scripts that prefer "Add" terminology.
Library.AddStartupQuestion = Library.QueueStartupQuestion
Library.AddStartupConfirm = Library.QueueStartupConfirm

function Library:RunStartupPrompts()
    while #self.StartupPrompts > 0 and not self.Unloaded do
        local entry = table.remove(self.StartupPrompts, 1)

        if entry.Type == "Confirm" then
            self:ShowConfirm(entry.Options)
        else
            self:ShowQuestion(entry.Options)
        end
    end

    self.StartupCompleted = true
end

--============================================================
-- WATERMARK
--============================================================

local Watermark = Create("Frame", {
    Parent = Root,
    AnchorPoint = Vector2.new(0, 0),
    Position = UDim2.fromOffset(16, 16),
    Size = UDim2.fromOffset(250, 30),
    BackgroundTransparency = 0,
    BorderSizePixel = 0,
    Active = true,
    ZIndex = 70,
})
Library:BindTheme(Watermark, "BackgroundColor3", "Panel")
Library:AdaptiveCorner(Watermark, -2)

local WatermarkStroke = Create("UIStroke", {
    Parent = Watermark,
    Thickness = 1.1,
    Transparency = 0.10,
    ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
})
Library:BindTheme(WatermarkStroke, "Color", "Outline")

local WatermarkAccent = Create("Frame", {
    Parent = Watermark,
    -- Inset from every rounded edge. The old full-height strip could visibly
    -- poke through large corner radii.
    Position = UDim2.fromOffset(4, 5),
    Size = UDim2.fromOffset(3, 20),
    BorderSizePixel = 0,
    ZIndex = 71,
})
Library:BindTheme(WatermarkAccent, "BackgroundColor3", "Accent")
Create("UICorner", {Parent = WatermarkAccent, CornerRadius = UDim.new(1, 0)})

local WatermarkLabel = Create("TextLabel", {
    Parent = Watermark,
    Position = UDim2.fromOffset(13, 0),
    Size = UDim2.new(1, -21, 1, 0),
    BackgroundTransparency = 1,
    Text = "Experiment 17 [Visuals]",
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 71,
})
Library:BindTheme(WatermarkLabel, "TextColor3", "Text")
Library:RegisterFont(WatermarkLabel, true)

Library.Watermark = Watermark
Library.WatermarkLabel = WatermarkLabel
Library.CurrentFPS = 0
Library.CurrentPing = 0

function Library:ApplyWatermarkPosition()
    if not self.Watermark or not self.Watermark.Parent then
        return
    end

    local camera = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
    local wmSize = self.Watermark.AbsoluteSize
    if wmSize.X <= 0 then
        wmSize = Vector2.new(self.Watermark.Size.X.Offset, self.Watermark.Size.Y.Offset)
    end

    local x = tonumber(self.Settings.WatermarkX) or -1
    local y = tonumber(self.Settings.WatermarkY) or 16

    if x < 0 then
        x = viewport.X - wmSize.X - 16
    end

    x = math.clamp(x, 4, math.max(4, viewport.X - wmSize.X - 4))
    y = math.clamp(y, 4, math.max(4, viewport.Y - wmSize.Y - 4))

    self.Watermark.Position = UDim2.fromOffset(x, y)
end

function Library:ResetWatermarkPosition()
    self.Settings.WatermarkX = -1
    self.Settings.WatermarkY = 16
    self:ApplyWatermarkPosition()
end

function Library:RefreshWatermark()
    if not self.Watermark or not self.Watermark.Parent then
        return
    end

    self.Watermark.Visible = self.Settings.WatermarkEnabled == true
    if not self.Watermark.Visible then
        return
    end

    local pieces = {tostring(self.Settings.WatermarkText or "Experiment 17 [Visuals]")}

    if self.Settings.WatermarkShowGraphics then
        table.insert(pieces, self.Settings.GraphicsLevel)
    end
    if self.Settings.WatermarkShowFPS then
        table.insert(pieces, tostring(self.CurrentFPS or 0) .. " FPS")
    end
    if self.Settings.WatermarkShowPing then
        table.insert(pieces, tostring(self.CurrentPing or 0) .. " ms")
    end
    if self.Settings.WatermarkShowTime then
        table.insert(pieces, os.date("%H:%M:%S"))
    end

    local text = table.concat(pieces, "  |  ")
    self.WatermarkLabel.Text = text

    local ok, measured = pcall(function()
        return TextService:GetTextSize(
            text,
            self.WatermarkLabel.TextSize,
            self.WatermarkLabel.Font,
            Vector2.new(1600, 40)
        )
    end)

    if ok and measured then
        self.Watermark.Size = UDim2.fromOffset(math.max(110, measured.X + 30), 30)
    end

    self:ApplyWatermarkPosition()
end

-- Dragging is optional and the position is saved in the config.
local watermarkDragging = false
local watermarkDragStart = nil
local watermarkStartPos = nil

Watermark.InputBegan:Connect(function(input)
    if Library.Unloaded or not Library.Settings.WatermarkDraggable then
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        watermarkDragging = true
        watermarkDragStart = input.Position
        watermarkStartPos = Watermark.AbsolutePosition
    end
end)

UIS.InputChanged:Connect(function(input)
    if Library.Unloaded or not watermarkDragging then
        return
    end

    if input.UserInputType == Enum.UserInputType.MouseMovement then
        local camera = workspace.CurrentCamera
        local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
        local delta = input.Position - watermarkDragStart
        local wmSize = Watermark.AbsoluteSize

        local x = math.clamp(watermarkStartPos.X + delta.X, 4, math.max(4, viewport.X - wmSize.X - 4))
        local y = math.clamp(watermarkStartPos.Y + delta.Y, 4, math.max(4, viewport.Y - wmSize.Y - 4))

        Watermark.Position = UDim2.fromOffset(x, y)
        Library.Settings.WatermarkX = x
        Library.Settings.WatermarkY = y
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        watermarkDragging = false
    end
end)

local fpsFrames = 0
local fpsStarted = os.clock()
RunService.RenderStepped:Connect(function()
    if Library.Unloaded then
        return
    end

    fpsFrames += 1
    local now = os.clock()
    local elapsed = now - fpsStarted

    if elapsed >= 0.5 then
        Library.CurrentFPS = math.floor((fpsFrames / elapsed) + 0.5)
        fpsFrames = 0
        fpsStarted = now

        local ok, ping = pcall(function()
            return LocalPlayer:GetNetworkPing()
        end)
        if ok and type(ping) == "number" then
            Library.CurrentPing = math.max(0, math.floor(ping * 1000 + 0.5))
        end

        Library:RefreshWatermark()
    end
end)

Library:RefreshWatermark()

--============================================================
-- DEFAULT TABS / SETTINGS
--============================================================

-- The library itself ships only with Settings.
-- Feature tabs are created by the script that consumes the library via
-- Library:CreateTab(...), keeping this file reusable instead of acting like
-- a prebuilt Visuals/ESP/World/Player menu.
local SettingsTab = Library:CreateTab(Library:L("Settings"), "Settings")
Library.SettingsTab = SettingsTab

-- All sections start collapsed. Pass true to CreateSection only when a
-- specific custom section should intentionally start opened.

-- SETTINGS: Interface
local InterfaceSection = SettingsTab:CreateSection(Library:L("Interface"), false, "Interface")

local LanguageChoice = InterfaceSection:AddChoice({
    Name = Library:L("Language"),
    LocaleKey = "Language",
    Flag = "UI_Language",
    Values = LANGUAGE_CHOICES,
    Default = Library:GetLanguageDisplay(Library.Settings.Language),
    RequiredGraphics = "Low",
    Callback = function(v)
        Library:SetLanguage(v)
    end,
})
Library.LanguageChoiceControl = LanguageChoice

InterfaceSection:AddSeparator()

InterfaceSection:AddChoice({
    Name = Library:L("GraphicsLevel"),
    LocaleKey = "GraphicsLevel",
    Flag = "UI_GraphicsLevel",
    Values = GRAPHICS_LIST,
    Default = Library.Settings.GraphicsLevel,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library:SetGraphicsLevel(v)
        Library.LevelText.Text = v
    end,
})

-- New logical group: typography.
InterfaceSection:AddSeparator()
InterfaceSection:AddChoice({
    Name = Library:L("Font"),
    LocaleKey = "Font",
    Flag = "UI_Font",
    Values = FONT_LIST,
    Default = Library.Settings.Font,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library:SetFont(v)
    end,
})
InterfaceSection:AddSlider({
    Name = Library:L("TextSize"),
    LocaleKey = "TextSize",
    Flag = "UI_TextScale",
    Min = 50,
    Max = 180,
    Default = Library.Settings.TextScale,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library:SetTextScale(v)
    end,
})

-- New logical group: global/function scaling.
InterfaceSection:AddSeparator()
InterfaceSection:AddChoice({
    Name = Library:L("DPIScale"),
    LocaleKey = "DPIScale",
    Flag = "UI_DPIScale",
    Values = DPI_LIST,
    Default = Library.Settings.DPIPreset,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library:SetDPIPreset(v)
    end,
})
InterfaceSection:AddToggle({
    Name = Library:L("AutoFitToDisplay"),
    LocaleKey = "AutoFitToDisplay",
    Flag = "UI_AutoFitDPI",
    Default = Library.Settings.AutoFitDPI,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library.Settings.AutoFitDPI = v == true
        Library:ApplyDPIScale()
    end,
})
InterfaceSection:AddChoice({
    Name = Library:L("FunctionDPI"),
    LocaleKey = "FunctionDPI",
    Flag = "UI_FunctionDPI",
    Values = FUNCTION_DPI_LIST,
    Default = Library.Settings.FunctionDPIPreset,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library:SetFunctionDPIPreset(v)
    end,
})

-- New logical group: navigation/window shape.
InterfaceSection:AddSeparator()
InterfaceSection:AddKeybind({
    Name = Library:L("MenuKeybind"),
    LocaleKey = "MenuKeybind",
    Flag = "UI_MenuKey",
    Default = Library.Settings.MenuKey,
    RequiredGraphics = "Low",
    Callback = function(keyName)
        Library.Settings.MenuKey = keyName
    end,
})
InterfaceSection:AddSlider({
    Name = Library:L("CornerRadius"),
    LocaleKey = "CornerRadius",
    Flag = "UI_CornerRadius",
    Min = 0,
    Max = 20,
    Default = Library.Settings.CornerRadius,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library:SetCornerRadius(v)
    end,
})

-- New logical group: backdrop effects. Blur + strength and dim + amount
-- belong together, so no lines inside this group.
InterfaceSection:AddSeparator()
InterfaceSection:AddToggle({
    Name = Library:L("BackgroundBlur"),
    LocaleKey = "BackgroundBlur",
    Flag = "UI_Blur",
    Default = Library.Settings.BlurEnabled,
    RequiredGraphics = "LM",
    Callback = function(v)
        Library.Settings.BlurEnabled = v
        Library:RefreshBackdrop()
    end,
})
InterfaceSection:AddSlider({
    Name = Library:L("BlurStrength"),
    LocaleKey = "BlurStrength",
    Flag = "UI_BlurSize",
    Min = 0,
    Max = 40,
    Default = Library.Settings.BlurSize,
    RequiredGraphics = "LM",
    Callback = function(v)
        Library.Settings.BlurSize = v
        Library:RefreshBackdrop()
    end,
})
InterfaceSection:AddToggle({
    Name = Library:L("BackgroundDim"),
    LocaleKey = "BackgroundDim",
    Flag = "UI_Dim",
    Default = Library.Settings.DimEnabled,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library.Settings.DimEnabled = v
        Library:RefreshBackdrop()
    end,
})
InterfaceSection:AddSlider({
    Name = Library:L("DimAmount"),
    LocaleKey = "DimAmount",
    Flag = "UI_DimAmount",
    Min = 0,
    Max = 90,
    Default = math.floor((1 - Library.Settings.DimTransparency) * 100),
    RequiredGraphics = "Low",
    Callback = function(v)
        Library.Settings.DimTransparency = 1 - (v / 100)
        Library:RefreshBackdrop()
    end,
})

-- SETTINGS: animations
-- These controls are one related group, therefore there are no separators.
local AnimationSection = SettingsTab:CreateSection(Library:L("Animations"), false, "Animations")
AnimationSection:AddChoice({
    Name = Library:L("ControlMotion"),
    LocaleKey = "ControlMotion",
    Flag = "UI_AnimationMode",
    Values = {"Smooth", "Stepped"},
    Default = Library.Settings.AnimationMode,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library.Settings.AnimationMode = v
    end,
})
AnimationSection:AddChoice({
    Name = Library:L("OpenAnimation"),
    LocaleKey = "OpenAnimation",
    Flag = "UI_OpenAnimation",
    Values = {"Scale", "Slide", "Fade", "None"},
    Default = Library.Settings.OpenAnimation,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library.Settings.OpenAnimation = v
    end,
})
AnimationSection:AddSlider({
    Name = Library:L("AnimationSpeed"),
    LocaleKey = "AnimationSpeed",
    Flag = "UI_AnimationSpeed",
    Min = 5,
    Max = 50,
    Default = math.floor(Library.Settings.AnimationSpeed * 100),
    RequiredGraphics = "Low",
    Callback = function(v)
        Library.Settings.AnimationSpeed = v / 100
    end,
})
AnimationSection:AddSeparator()
AnimationSection:AddChoice({
    Name = Library:L("WindowDragging"),
    LocaleKey = "WindowDragging",
    Flag = "UI_DragMode",
    Values = {"Smooth", "Direct"},
    Default = Library.Settings.DragMode,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library.Settings.DragMode = v
    end,
})
AnimationSection:AddSlider({
    Name = Library:L("DragFollowSpeed"),
    LocaleKey = "DragFollowSpeed",
    Flag = "UI_DragSmoothness",
    Min = 5,
    Max = 40,
    Default = Library.Settings.DragSmoothness,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library.Settings.DragSmoothness = v
    end,
})

-- SETTINGS: tooltips
local TooltipSection = SettingsTab:CreateSection(Library:L("Tooltips"), false, "Tooltips")
TooltipSection:AddToggle({
    Name = Library:L("FunctionTooltips"),
    LocaleKey = "FunctionTooltips",
    Flag = "UI_TooltipsEnabled",
    Default = Library.Settings.TooltipsEnabled,
    RequiredGraphics = "Low",
    DescriptionKey = "TooltipDesc",
    FPSImpact = 0,
    PingImpact = 0,
    Callback = function(v)
        Library.Settings.TooltipsEnabled = v == true
        if not Library.Settings.TooltipsEnabled then
            Library:HideControlTooltip(true)
        end
    end,
})
TooltipSection:AddSlider({
    Name = Library:L("TooltipDelay"),
    LocaleKey = "TooltipDelay",
    Flag = "UI_TooltipDelay",
    Min = 0,
    Max = 100,
    Default = math.floor((Library.Settings.TooltipDelay or 0.12) * 100),
    RequiredGraphics = "Low",
    DescriptionKey = "TooltipDelayDesc",
    FPSImpact = 0,
    PingImpact = 0,
    Callback = function(v)
        Library.Settings.TooltipDelay = v / 100
    end,
})
TooltipSection:AddSlider({
    Name = Library:L("TooltipFollowSpeed"),
    LocaleKey = "TooltipFollowSpeed",
    Flag = "UI_TooltipFollowSpeed",
    Min = 5,
    Max = 50,
    Default = Library.Settings.TooltipFollowSpeed,
    RequiredGraphics = "Low",
    DescriptionKey = "TooltipFollowDesc",
    FPSImpact = 0,
    PingImpact = 0,
    Callback = function(v)
        Library.Settings.TooltipFollowSpeed = v
    end,
})

-- SETTINGS: themes
local ThemeSection = SettingsTab:CreateSection(Library:L("Theme"), false, "Theme")
ThemeSection:AddChoice({
    Name = Library:L("ThemePreset"),
    LocaleKey = "ThemePreset",
    Flag = "UI_ThemePreset",
    Values = THEME_LIST,
    Default = "Violet",
    RequiredGraphics = "Low",
    Callback = function(v)
        Library:ApplyThemePreset(v)
    end,
})
ThemeSection:AddSeparator()
ThemeSection:AddColorPicker({
    Name = Library:L("Accent"),
    LocaleKey = "Accent",
    ThemeKey = "Accent",
    Flag = "UI_AccentColor",
    Default = Library.Theme.Accent,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library:SetThemeColor("Accent", v)
    end,
})
ThemeSection:AddColorPicker({
    Name = Library:L("Background"),
    LocaleKey = "Background",
    ThemeKey = "Background",
    Flag = "UI_BackgroundColor",
    Default = Library.Theme.Background,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library:SetThemeColor("Background", v)
    end,
})
ThemeSection:AddColorPicker({
    Name = Library:L("Outline"),
    LocaleKey = "Outline",
    ThemeKey = "Outline",
    Flag = "UI_OutlineColor",
    Default = Library.Theme.Outline,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library:SetThemeColor("Outline", v)
    end,
})
ThemeSection:AddColorPicker({
    Name = Library:L("ControlBackground"),
    LocaleKey = "ControlBackground",
    ThemeKey = "Control",
    Flag = "UI_ControlColor",
    Default = Library.Theme.Control,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library:SetThemeColor("Control", v)
    end,
})

-- SETTINGS: watermarks
local WatermarkSection = SettingsTab:CreateSection(Library:L("Watermarks"), false, "Watermarks")
WatermarkSection:AddToggle({
    Name = Library:L("EnableWatermark"),
    LocaleKey = "EnableWatermark",
    Flag = "UI_WatermarkEnabled",
    Default = Library.Settings.WatermarkEnabled,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library.Settings.WatermarkEnabled = v == true
        Library:RefreshWatermark()
    end,
})
WatermarkSection:AddInput({
    Name = Library:L("WatermarkText"),
    LocaleKey = "WatermarkText",
    Flag = "UI_WatermarkText",
    Default = Library.Settings.WatermarkText,
    Placeholder = "Experiment 17 [Visuals]",
    RequiredGraphics = "Low",
    Callback = function(v)
        Library.Settings.WatermarkText = tostring(v)
        Library:RefreshWatermark()
    end,
})

-- Display fields are one related group.
WatermarkSection:AddSeparator()
WatermarkSection:AddToggle({
    Name = Library:L("ShowGraphicsLevel"),
    LocaleKey = "ShowGraphicsLevel",
    Flag = "UI_WatermarkGraphics",
    Default = Library.Settings.WatermarkShowGraphics,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library.Settings.WatermarkShowGraphics = v == true
        Library:RefreshWatermark()
    end,
})
WatermarkSection:AddToggle({
    Name = Library:L("ShowFPS"),
    LocaleKey = "ShowFPS",
    Flag = "UI_WatermarkFPS",
    Default = Library.Settings.WatermarkShowFPS,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library.Settings.WatermarkShowFPS = v == true
        Library:RefreshWatermark()
    end,
})
WatermarkSection:AddToggle({
    Name = Library:L("ShowPing"),
    LocaleKey = "ShowPing",
    Flag = "UI_WatermarkPing",
    Default = Library.Settings.WatermarkShowPing,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library.Settings.WatermarkShowPing = v == true
        Library:RefreshWatermark()
    end,
})
WatermarkSection:AddToggle({
    Name = Library:L("ShowOSTime"),
    LocaleKey = "ShowOSTime",
    Flag = "UI_WatermarkTime",
    Default = Library.Settings.WatermarkShowTime,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library.Settings.WatermarkShowTime = v == true
        Library:RefreshWatermark()
    end,
})

-- Positioning is its own group.
WatermarkSection:AddSeparator()
WatermarkSection:AddToggle({
    Name = Library:L("DraggableWatermark"),
    LocaleKey = "DraggableWatermark",
    Flag = "UI_WatermarkDraggable",
    Default = Library.Settings.WatermarkDraggable,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library.Settings.WatermarkDraggable = v == true
    end,
})
WatermarkSection:AddButton({
    Name = Library:L("ResetWatermarkPosition"),
    LocaleKey = "ResetWatermarkPosition",
    ButtonText = Library:L("Reset"),
    ButtonLocaleKey = "Reset",
    RequiredGraphics = "Low",
    Callback = function()
        Library:ResetWatermarkPosition()
    end,
})

-- SETTINGS: configs
local ConfigSection = SettingsTab:CreateSection(Library:L("Configs"), false, "Configs")
local ConfigNameInput = ConfigSection:AddInput({
    Name = Library:L("ConfigName"),
    LocaleKey = "ConfigName",
    Flag = "UI_ConfigName",
    Default = "default",
    Placeholder = "config name",
    RequiredGraphics = "Low",
    Callback = function(v)
        Library.CurrentConfigName = sanitizeName(v)
    end,
})

ConfigSection:AddSeparator()
ConfigSection:AddButton({
    Name = Library:L("SaveCurrentConfig"),
    LocaleKey = "SaveCurrentConfig",
    ButtonText = Library:L("Save"),
    ButtonLocaleKey = "Save",
    RequiredGraphics = "Low",
    Callback = function()
        Library:SaveConfig(ConfigNameInput:Get())
    end,
})
ConfigSection:AddButton({
    Name = Library:L("LoadConfig"),
    LocaleKey = "LoadConfig",
    ButtonText = Library:L("Load"),
    ButtonLocaleKey = "Load",
    RequiredGraphics = "Low",
    Callback = function()
        Library:LoadConfig(ConfigNameInput:Get())
    end,
})

ConfigSection:AddSeparator()
ConfigSection:AddToggle({
    Name = Library:L("AutoloadConfig"),
    LocaleKey = "AutoloadConfig",
    Flag = "UI_AutoloadConfig",
    Default = true,
    RequiredGraphics = "Low",
    Callback = function(v)
        Library:SetAutoload(ConfigNameInput:Get(), v)
    end,
})
ConfigSection:AddButton({
    Name = Library:L("SetAsAutoload"),
    LocaleKey = "SetAsAutoload",
    ButtonText = Library:L("Set"),
    ButtonLocaleKey = "Set",
    RequiredGraphics = "Low",
    Callback = function()
        Library:SetAutoload(ConfigNameInput:Get(), true)
    end,
})

ConfigSection:AddSeparator()
ConfigSection:AddButton({
    Name = Library:L("QueueOnTeleport"),
    LocaleKey = "QueueOnTeleport",
    ButtonText = Library:L("Queue"),
    ButtonLocaleKey = "Queue",
    RequiredGraphics = "Low",
    Callback = function()
        local ok = Library:EnableTeleportAutoload()
        print("Teleport autoload queued:", ok)
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

        if Library.ActiveDropdown and Library.ActiveDropdown.CloseDropdown then
            Library.ActiveDropdown:CloseDropdown()
        end
        Library:SetMenuVisible(not Library.MenuVisible)
    end
end)

-- Apply the current independent control width/DPI after all default controls exist.
Library:ApplyFunctionDPIScale()
Library:SetTextScale(Library.Settings.TextScale)

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
        Library:SetMenuVisible(true)
    end
end

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
        Default = 50,
        RequiredGraphics = "MH",
        Callback = function(value)
            print(value)
        end,
    })

    Section:AddColorPicker({
        Name = "Color",
        Flag = "ExampleColor",
        Default = Color3.fromRGB(170, 100, 255),
        RequiredGraphics = "Medium",
        Callback = function(color)
            print(color)
        end,
    })
]]

return Library
