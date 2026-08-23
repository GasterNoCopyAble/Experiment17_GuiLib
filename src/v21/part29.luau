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
