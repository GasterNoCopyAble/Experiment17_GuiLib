-- Experiment 17 v22 - stronger, clearly separated theme presets
-- Keeps the public theme names/API from Engine but replaces near-duplicate palettes.

return function(Library)
    local rawApplyThemePreset = Library.ApplyThemePreset
    if type(rawApplyThemePreset) ~= "function" then
        return
    end

    local PRESETS = {
        Violet = {
            Background=Color3.fromRGB(7,6,12), Panel=Color3.fromRGB(13,10,23),
            Control=Color3.fromRGB(22,16,37), Control2=Color3.fromRGB(32,22,52),
            Accent=Color3.fromRGB(145,84,255), Outline=Color3.fromRGB(104,61,194),
            Hover=Color3.fromRGB(193,145,255), Text=Color3.fromRGB(244,240,255),
            SubText=Color3.fromRGB(154,145,177),
        },
        Mono = {
            Background=Color3.fromRGB(5,5,5), Panel=Color3.fromRGB(11,11,11),
            Control=Color3.fromRGB(20,20,20), Control2=Color3.fromRGB(31,31,31),
            Accent=Color3.fromRGB(232,232,232), Outline=Color3.fromRGB(83,83,83),
            Hover=Color3.fromRGB(180,180,180), Text=Color3.fromRGB(250,250,250),
            SubText=Color3.fromRGB(142,142,142),
        },
        Crimson = {
            Background=Color3.fromRGB(13,4,7), Panel=Color3.fromRGB(27,7,12),
            Control=Color3.fromRGB(42,10,18), Control2=Color3.fromRGB(60,14,25),
            Accent=Color3.fromRGB(244,48,82), Outline=Color3.fromRGB(175,27,54),
            Hover=Color3.fromRGB(255,104,127), Text=Color3.fromRGB(255,239,243),
            SubText=Color3.fromRGB(180,130,142),
        },
        Emerald = {
            Background=Color3.fromRGB(3,11,8), Panel=Color3.fromRGB(5,24,17),
            Control=Color3.fromRGB(8,37,26), Control2=Color3.fromRGB(10,52,36),
            Accent=Color3.fromRGB(45,224,151), Outline=Color3.fromRGB(24,145,96),
            Hover=Color3.fromRGB(116,244,194), Text=Color3.fromRGB(235,255,247),
            SubText=Color3.fromRGB(126,171,151),
        },
        Azure = {
            Background=Color3.fromRGB(4,8,19), Panel=Color3.fromRGB(7,16,35),
            Control=Color3.fromRGB(10,27,55), Control2=Color3.fromRGB(14,40,78),
            Accent=Color3.fromRGB(55,132,255), Outline=Color3.fromRGB(34,86,189),
            Hover=Color3.fromRGB(111,176,255), Text=Color3.fromRGB(237,246,255),
            SubText=Color3.fromRGB(129,151,183),
        },
        Gold = {
            Background=Color3.fromRGB(14,9,2), Panel=Color3.fromRGB(28,18,4),
            Control=Color3.fromRGB(43,28,7), Control2=Color3.fromRGB(61,40,10),
            Accent=Color3.fromRGB(255,193,53), Outline=Color3.fromRGB(181,126,24),
            Hover=Color3.fromRGB(255,224,128), Text=Color3.fromRGB(255,249,226),
            SubText=Color3.fromRGB(184,159,105),
        },
        Rose = {
            Background=Color3.fromRGB(13,4,12), Panel=Color3.fromRGB(27,8,23),
            Control=Color3.fromRGB(43,12,36), Control2=Color3.fromRGB(61,17,49),
            Accent=Color3.fromRGB(248,85,177), Outline=Color3.fromRGB(180,50,123),
            Hover=Color3.fromRGB(255,151,207), Text=Color3.fromRGB(255,240,249),
            SubText=Color3.fromRGB(181,132,159),
        },
        Ocean = {
            Background=Color3.fromRGB(2,12,15), Panel=Color3.fromRGB(4,24,29),
            Control=Color3.fromRGB(6,37,45), Control2=Color3.fromRGB(8,53,63),
            Accent=Color3.fromRGB(21,220,235), Outline=Color3.fromRGB(12,141,158),
            Hover=Color3.fromRGB(104,241,249), Text=Color3.fromRGB(232,254,255),
            SubText=Color3.fromRGB(117,166,171),
        },
        Midnight = {
            Background=Color3.fromRGB(3,3,10), Panel=Color3.fromRGB(7,7,22),
            Control=Color3.fromRGB(12,12,37), Control2=Color3.fromRGB(20,19,55),
            Accent=Color3.fromRGB(112,91,255), Outline=Color3.fromRGB(69,58,191),
            Hover=Color3.fromRGB(157,145,255), Text=Color3.fromRGB(241,240,255),
            SubText=Color3.fromRGB(134,132,172),
        },
        Sakura = {
            Background=Color3.fromRGB(18,10,14), Panel=Color3.fromRGB(31,16,23),
            Control=Color3.fromRGB(46,23,33), Control2=Color3.fromRGB(63,31,44),
            Accent=Color3.fromRGB(255,126,151), Outline=Color3.fromRGB(197,77,107),
            Hover=Color3.fromRGB(255,185,198), Text=Color3.fromRGB(255,243,246),
            SubText=Color3.fromRGB(190,149,159),
        },
        Arctic = {
            Background=Color3.fromRGB(7,13,18), Panel=Color3.fromRGB(13,24,32),
            Control=Color3.fromRGB(20,36,47), Control2=Color3.fromRGB(28,50,64),
            Accent=Color3.fromRGB(150,224,255), Outline=Color3.fromRGB(73,165,205),
            Hover=Color3.fromRGB(211,245,255), Text=Color3.fromRGB(243,251,255),
            SubText=Color3.fromRGB(145,173,187),
        },
        Sunset = {
            Background=Color3.fromRGB(15,6,17), Panel=Color3.fromRGB(29,10,29),
            Control=Color3.fromRGB(44,15,38), Control2=Color3.fromRGB(62,21,48),
            Accent=Color3.fromRGB(255,112,45), Outline=Color3.fromRGB(191,68,45),
            Hover=Color3.fromRGB(255,172,95), Text=Color3.fromRGB(255,242,233),
            SubText=Color3.fromRGB(185,137,137),
        },
        Cyber = {
            Background=Color3.fromRGB(2,8,7), Panel=Color3.fromRGB(4,17,15),
            Control=Color3.fromRGB(6,27,24), Control2=Color3.fromRGB(8,39,34),
            Accent=Color3.fromRGB(0,255,174), Outline=Color3.fromRGB(0,165,118),
            Hover=Color3.fromRGB(86,255,211), Text=Color3.fromRGB(231,255,248),
            SubText=Color3.fromRGB(111,170,153),
        },
        RGB = {
            Background=Color3.fromRGB(6,6,9), Panel=Color3.fromRGB(11,11,16),
            Control=Color3.fromRGB(18,18,25), Control2=Color3.fromRGB(27,27,36),
            Accent=Color3.fromRGB(255,70,70), Outline=Color3.fromRGB(220,48,48),
            Hover=Color3.fromRGB(255,125,125), Text=Color3.fromRGB(245,245,249),
            SubText=Color3.fromRGB(150,150,164),
        },
    }

    local function applyOverride(self, name)
        local preset = PRESETS[name]
        if not preset then return end
        self.Theme = self.Theme or {}
        for key, value in pairs(preset) do
            self.Theme[key] = value
        end
        self.ThemeName = name
        if type(self.RefreshTheme) == "function" then
            self:RefreshTheme()
        end
    end

    function Library:ApplyThemePreset(name)
        local result = rawApplyThemePreset(self, name)
        applyOverride(self, name)
        return result
    end

    applyOverride(Library, Library.ThemeName or "Violet")

    return function()
        Library.ApplyThemePreset = rawApplyThemePreset
    end
end
