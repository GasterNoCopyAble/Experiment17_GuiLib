-- Experiment 17 v22 - slider visual cleanup
-- Removes the bright white ring from normal slider handles and matches range handles.

return function(Library)
    local Root = Library.Root
    if not Root then return end

    local connections = {}

    local function isNormalSliderKnob(object)
        if not object:IsA("Frame") then return false end
        local parent = object.Parent
        if not parent or not parent:IsA("Frame") then return false end

        local size = object.Size
        local parentSize = parent.Size

        return size.X.Scale == 0
            and size.Y.Scale == 0
            and size.X.Offset >= 13
            and size.X.Offset <= 15
            and size.Y.Offset >= 13
            and size.Y.Offset <= 15
            and parentSize.Y.Scale == 0
            and parentSize.Y.Offset >= 4
            and parentSize.Y.Offset <= 7
    end

    local function restyle(object)
        if not isNormalSliderKnob(object) then return end

        object.Size = UDim2.fromOffset(12, 12)
        for _, child in ipairs(object:GetChildren()) do
            if child:IsA("UIStroke") then
                child:Destroy()
            end
        end
    end

    for _, object in ipairs(Root:GetDescendants()) do
        restyle(object)
    end

    connections[#connections + 1] = Root.DescendantAdded:Connect(function(object)
        task.defer(function()
            if object and object.Parent then
                restyle(object)
                if object:IsA("UIStroke") and object.Parent then
                    restyle(object.Parent)
                end
            end
        end)
    end)

    return function()
        for _, connection in ipairs(connections) do
            pcall(function() connection:Disconnect() end)
        end
    end
end
