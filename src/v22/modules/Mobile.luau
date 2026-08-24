-- Experiment 17 v22 - mobile presentation fixes

return function(Library)
    local UIS = game:GetService("UserInputService")

    if not Library.Watermark or not Library.WatermarkLabel or type(Library.RefreshWatermark) ~= "function" then
        return
    end

    local rawRefreshWatermark = Library.RefreshWatermark
    local label = Library.WatermarkLabel
    local watermark = Library.Watermark
    local accent = watermark:FindFirstChildWhichIsA("Frame")
    local connections = {}

    local function applyMobileMetrics()
        if UIS.TouchEnabled then
            label.TextSize = 9
            label.Position = UDim2.fromOffset(11, 0)
            label.Size = UDim2.new(1, -18, 1, 0)
            watermark.Size = UDim2.new(watermark.Size.X.Scale, watermark.Size.X.Offset, 0, 24)

            if accent and accent ~= label then
                accent.Position = UDim2.fromOffset(4, 5)
                accent.Size = UDim2.fromOffset(3, 14)
            end
        else
            label.TextSize = 12
            label.Position = UDim2.fromOffset(13, 0)
            label.Size = UDim2.new(1, -21, 1, 0)
        end
    end

    function Library:RefreshWatermark(...)
        applyMobileMetrics()
        local result = rawRefreshWatermark(self, ...)

        if UIS.TouchEnabled and self.Watermark and self.Watermark.Parent then
            self.Watermark.Size = UDim2.new(self.Watermark.Size.X.Scale, self.Watermark.Size.X.Offset, 0, 24)
            if type(self.ApplyWatermarkPosition) == "function" then
                self:ApplyWatermarkPosition()
            end
        end

        return result
    end

    connections[#connections + 1] = label:GetPropertyChangedSignal("TextSize"):Connect(function()
        if UIS.TouchEnabled and label.TextSize ~= 9 then
            label.TextSize = 9
        end
    end)

    Library:RefreshWatermark()

    return function()
        for _, connection in ipairs(connections) do
            pcall(function() connection:Disconnect() end)
        end
        Library.RefreshWatermark = rawRefreshWatermark
    end
end
