-- Experiment 17 Legacy v22 - paired theme + gradient system
-- Every public theme has one gradient preset with the same name.
-- Selecting either side keeps the pair synchronized; Custom remains independent.

return function(Library)
    local rawApplyThemePreset = Library.ApplyThemePreset
    local rawGetGradientColors = Library.GetGradientColors
    if type(rawApplyThemePreset) ~= "function" then
        return
    end

    Library.Settings = Library.Settings or {}

    local ORDER = {
        "Violet", "Mono", "Crimson", "Emerald", "Azure", "Gold", "Rose",
        "Ocean", "Midnight", "Sakura", "Arctic", "Sunset", "Cyber", "RGB",
    }

    local PAIRS = {
        Violet = {
            Theme = {
                Background=Color3.fromRGB(7,6,12), Panel=Color3.fromRGB(13,10,23),
                Control=Color3.fromRGB(22,16,37), Control2=Color3.fromRGB(32,22,52),
                Accent=Color3.fromRGB(145,84,255), Outline=Color3.fromRGB(104,61,194),
                Hover=Color3.fromRGB(193,145,255), Text=Color3.fromRGB(244,240,255),
                SubText=Color3.fromRGB(154,145,177),
            },
            Gradient = {
                Color3.fromRGB(89,46,208), Color3.fromRGB(150,82,255), Color3.fromRGB(214,153,255),
            },
        },
        Mono = {
            Theme = {
                Background=Color3.fromRGB(5,5,5), Panel=Color3.fromRGB(11,11,11),
                Control=Color3.fromRGB(20,20,20), Control2=Color3.fromRGB(31,31,31),
                Accent=Color3.fromRGB(232,232,232), Outline=Color3.fromRGB(83,83,83),
                Hover=Color3.fromRGB(180,180,180), Text=Color3.fromRGB(250,250,250),
                SubText=Color3.fromRGB(142,142,142),
            },
            Gradient = {
                Color3.fromRGB(78,78,78), Color3.fromRGB(238,238,238), Color3.fromRGB(122,122,122),
            },
        },
        Crimson = {
            Theme = {
                Background=Color3.fromRGB(13,4,7), Panel=Color3.fromRGB(27,7,12),
                Control=Color3.fromRGB(42,10,18), Control2=Color3.fromRGB(60,14,25),
                Accent=Color3.fromRGB(244,48,82), Outline=Color3.fromRGB(175,27,54),
                Hover=Color3.fromRGB(255,104,127), Text=Color3.fromRGB(255,239,243),
                SubText=Color3.fromRGB(180,130,142),
            },
            Gradient = {
                Color3.fromRGB(112,8,32), Color3.fromRGB(245,40,78), Color3.fromRGB(255,126,142),
            },
        },
        Emerald = {
            Theme = {
                Background=Color3.fromRGB(3,11,8), Panel=Color3.fromRGB(5,24,17),
                Control=Color3.fromRGB(8,37,26), Control2=Color3.fromRGB(10,52,36),
                Accent=Color3.fromRGB(45,224,151), Outline=Color3.fromRGB(24,145,96),
                Hover=Color3.fromRGB(116,244,194), Text=Color3.fromRGB(235,255,247),
                SubText=Color3.fromRGB(126,171,151),
            },
            Gradient = {
                Color3.fromRGB(5,88,61), Color3.fromRGB(38,218,145), Color3.fromRGB(128,255,201),
            },
        },
        Azure = {
            Theme = {
                Background=Color3.fromRGB(4,8,19), Panel=Color3.fromRGB(7,16,35),
                Control=Color3.fromRGB(10,27,55), Control2=Color3.fromRGB(14,40,78),
                Accent=Color3.fromRGB(55,132,255), Outline=Color3.fromRGB(34,86,189),
                Hover=Color3.fromRGB(111,176,255), Text=Color3.fromRGB(237,246,255),
                SubText=Color3.fromRGB(129,151,183),
            },
            Gradient = {
                Color3.fromRGB(20,67,184), Color3.fromRGB(54,132,255), Color3.fromRGB(82,219,255),
            },
        },
        Gold = {
            Theme = {
                Background=Color3.fromRGB(14,9,2), Panel=Color3.fromRGB(28,18,4),
                Control=Color3.fromRGB(43,28,7), Control2=Color3.fromRGB(61,40,10),
                Accent=Color3.fromRGB(255,193,53), Outline=Color3.fromRGB(181,126,24),
                Hover=Color3.fromRGB(255,224,128), Text=Color3.fromRGB(255,249,226),
                SubText=Color3.fromRGB(184,159,105),
            },
            Gradient = {
                Color3.fromRGB(104,63,9), Color3.fromRGB(238,158,27), Color3.fromRGB(255,205,82), Color3.fromRGB(255,238,161),
            },
        },
        Rose = {
            Theme = {
                Background=Color3.fromRGB(13,4,12), Panel=Color3.fromRGB(27,8,23),
                Control=Color3.fromRGB(43,12,36), Control2=Color3.fromRGB(61,17,49),
                Accent=Color3.fromRGB(248,85,177), Outline=Color3.fromRGB(180,50,123),
                Hover=Color3.fromRGB(255,151,207), Text=Color3.fromRGB(255,240,249),
                SubText=Color3.fromRGB(181,132,159),
            },
            Gradient = {
                Color3.fromRGB(126,24,99), Color3.fromRGB(246,81,174), Color3.fromRGB(255,166,220),
            },
        },
        Ocean = {
            Theme = {
                Background=Color3.fromRGB(2,12,15), Panel=Color3.fromRGB(4,24,29),
                Control=Color3.fromRGB(6,37,45), Control2=Color3.fromRGB(8,53,63),
                Accent=Color3.fromRGB(21,220,235), Outline=Color3.fromRGB(12,141,158),
                Hover=Color3.fromRGB(104,241,249), Text=Color3.fromRGB(232,254,255),
                SubText=Color3.fromRGB(117,166,171),
            },
            Gradient = {
                Color3.fromRGB(0,72,92), Color3.fromRGB(14,188,210), Color3.fromRGB(39,232,239), Color3.fromRGB(123,250,255),
            },
        },
        Midnight = {
            Theme = {
                Background=Color3.fromRGB(3,3,10), Panel=Color3.fromRGB(7,7,22),
                Control=Color3.fromRGB(12,12,37), Control2=Color3.fromRGB(20,19,55),
                Accent=Color3.fromRGB(112,91,255), Outline=Color3.fromRGB(69,58,191),
                Hover=Color3.fromRGB(157,145,255), Text=Color3.fromRGB(241,240,255),
                SubText=Color3.fromRGB(134,132,172),
            },
            Gradient = {
                Color3.fromRGB(30,27,101), Color3.fromRGB(72,61,201), Color3.fromRGB(126,106,255), Color3.fromRGB(66,46,153),
            },
        },
        Sakura = {
            Theme = {
                Background=Color3.fromRGB(18,10,14), Panel=Color3.fromRGB(31,16,23),
                Control=Color3.fromRGB(46,23,33), Control2=Color3.fromRGB(63,31,44),
                Accent=Color3.fromRGB(255,126,151), Outline=Color3.fromRGB(197,77,107),
                Hover=Color3.fromRGB(255,185,198), Text=Color3.fromRGB(255,243,246),
                SubText=Color3.fromRGB(190,149,159),
            },
            Gradient = {
                Color3.fromRGB(176,69,98), Color3.fromRGB(255,122,149), Color3.fromRGB(255,204,217),
            },
        },
        Arctic = {
            Theme = {
                Background=Color3.fromRGB(7,13,18), Panel=Color3.fromRGB(13,24,32),
                Control=Color3.fromRGB(20,36,47), Control2=Color3.fromRGB(28,50,64),
                Accent=Color3.fromRGB(150,224,255), Outline=Color3.fromRGB(73,165,205),
                Hover=Color3.fromRGB(211,245,255), Text=Color3.fromRGB(243,251,255),
                SubText=Color3.fromRGB(145,173,187),
            },
            Gradient = {
                Color3.fromRGB(65,145,192), Color3.fromRGB(143,222,255), Color3.fromRGB(226,249,255),
            },
        },
        Sunset = {
            Theme = {
                Background=Color3.fromRGB(15,6,17), Panel=Color3.fromRGB(29,10,29),
                Control=Color3.fromRGB(44,15,38), Control2=Color3.fromRGB(62,21,48),
                Accent=Color3.fromRGB(255,112,45), Outline=Color3.fromRGB(191,68,45),
                Hover=Color3.fromRGB(255,172,95), Text=Color3.fromRGB(255,242,233),
                SubText=Color3.fromRGB(185,137,137),
            },
            Gradient = {
                Color3.fromRGB(132,31,103), Color3.fromRGB(226,61,93), Color3.fromRGB(255,112,39), Color3.fromRGB(255,193,87),
            },
        },
        Cyber = {
            Theme = {
                Background=Color3.fromRGB(2,8,7), Panel=Color3.fromRGB(4,17,15),
                Control=Color3.fromRGB(6,27,24), Control2=Color3.fromRGB(8,39,34),
                Accent=Color3.fromRGB(0,255,174), Outline=Color3.fromRGB(0,165,118),
                Hover=Color3.fromRGB(86,255,211), Text=Color3.fromRGB(231,255,248),
                SubText=Color3.fromRGB(111,170,153),
            },
            Gradient = {
                Color3.fromRGB(0,92,68), Color3.fromRGB(0,244,160), Color3.fromRGB(68,255,211), Color3.fromRGB(0,193,228),
            },
        },
        RGB = {
            Theme = {
                Background=Color3.fromRGB(6,6,9), Panel=Color3.fromRGB(11,11,16),
                Control=Color3.fromRGB(18,18,25), Control2=Color3.fromRGB(27,27,36),
                Accent=Color3.fromRGB(255,70,70), Outline=Color3.fromRGB(220,48,48),
                Hover=Color3.fromRGB(255,125,125), Text=Color3.fromRGB(245,245,249),
                SubText=Color3.fromRGB(150,150,164),
            },
            Gradient = {
                Color3.fromRGB(255,62,62), Color3.fromRGB(255,221,61), Color3.fromRGB(61,255,126),
                Color3.fromRGB(61,233,255), Color3.fromRGB(91,92,255), Color3.fromRGB(239,72,255), Color3.fromRGB(255,62,62),
            },
        },
    }

    Library.LegacyThemeOrder = ORDER
    Library.LegacyThemePairs = PAIRS

    local themeControl = Library.ControlsByFlag and Library.ControlsByFlag.UI_ThemePreset
    local gradientControl = Library.ControlsByFlag and Library.ControlsByFlag.UI_GradientPreset
    local colorAControl = Library.ControlsByFlag and Library.ControlsByFlag.UI_GradientColorA
    local colorBControl = Library.ControlsByFlag and Library.ControlsByFlag.UI_GradientColorB

    local rawThemeControlSet = themeControl and themeControl.Set
    local rawGradientControlSet = gradientControl and gradientControl.Set
    local syncing = false

    local function copyTheme(target, source)
        for key, value in pairs(source) do
            target[key] = value
        end
    end

    local function setPickerValue(control, value)
        if control and type(control.Set) == "function" and typeof(value) == "Color3" then
            control:Set(value, true)
        end
    end

    local function syncGradientPair(name, refresh)
        local pair = PAIRS[name]
        if not pair then return end

        Library.Settings.GradientPreset = name
        Library.Settings.GradientColorA = pair.Gradient[1]
        Library.Settings.GradientColorB = pair.Gradient[#pair.Gradient]

        if gradientControl and type(rawGradientControlSet) == "function" then
            rawGradientControlSet(gradientControl, name, true)
        end
        setPickerValue(colorAControl, Library.Settings.GradientColorA)
        setPickerValue(colorBControl, Library.Settings.GradientColorB)

        if refresh and type(Library.RefreshGradients) == "function" then
            Library:RefreshGradients()
        end
    end

    function Library:GetGradientColors()
        local presetName = tostring(self.Settings.GradientPreset or "Violet")
        if presetName == "Custom" then
            return {
                self.Settings.GradientColorA or self.Theme.Accent,
                self.Settings.GradientColorB or self.Theme.Hover,
            }
        end

        local pair = PAIRS[presetName]
        if pair then
            return pair.Gradient
        end

        if type(rawGetGradientColors) == "function" then
            return rawGetGradientColors(self)
        end

        return PAIRS.Violet.Gradient
    end

    function Library:ApplyThemePreset(name)
        name = tostring(name or "Violet")
        local pair = PAIRS[name]
        if not pair then
            return rawApplyThemePreset(self, name)
        end

        -- Keep the base engine's internal bookkeeping/localized controls valid,
        -- then overwrite it with the more separated Legacy palette.
        rawApplyThemePreset(self, name)
        self.Theme = self.Theme or {}
        copyTheme(self.Theme, pair.Theme)
        self.ThemeName = name
        self.Settings.RGBMenuStyle = name == "RGB"

        if themeControl and type(rawThemeControlSet) == "function" then
            rawThemeControlSet(themeControl, name, true)
        end

        if not syncing then
            syncGradientPair(name, false)
        end

        if type(self.RefreshTheme) == "function" then
            self:RefreshTheme()
        end
        if type(self.RefreshGradients) == "function" then
            self:RefreshGradients()
        end
    end

    if themeControl and type(themeControl.SetValues) == "function" then
        themeControl:SetValues(ORDER, true)
    end

    local gradientValues = {}
    for _, name in ipairs(ORDER) do
        gradientValues[#gradientValues + 1] = name
    end
    gradientValues[#gradientValues + 1] = "Custom"

    if gradientControl and type(gradientControl.SetValues) == "function" then
        gradientControl:SetValues(gradientValues, false)
        rawGradientControlSet = gradientControl.Set

        function gradientControl:Set(value, silent)
            local result = rawGradientControlSet(self, value, silent)
            value = tostring(value)

            if not silent and not syncing and PAIRS[value] then
                syncing = true
                Library:ApplyThemePreset(value)
                syncing = false
                syncGradientPair(value, true)
            end

            return result
        end
    end

    -- Migrate the old 30-preset list into the new 1:1 pair model.
    local currentTheme = tostring(Library.ThemeName or "Violet")
    if not PAIRS[currentTheme] then currentTheme = "Violet" end
    Library:ApplyThemePreset(currentTheme)

    return function()
        Library.ApplyThemePreset = rawApplyThemePreset
        Library.GetGradientColors = rawGetGradientColors
        if gradientControl and rawGradientControlSet then
            gradientControl.Set = rawGradientControlSet
        end
    end
end
