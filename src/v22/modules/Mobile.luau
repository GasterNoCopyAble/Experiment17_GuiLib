-- Experiment 17 v22 - mobile presentation fixes
-- Mobile uses a compact watermark. Desktop keeps the normal text scale and
-- both width and height are measured dynamically from the rendered text.

return function(Library)
    local UIS = game:GetService("UserInputService")
    local TextService = game:GetService("TextService")

    if not Library.Watermark or not Library.WatermarkLabel or type(Library.RefreshWatermark) ~= "function" then
        return
    end

    local rawRefreshWatermark = Library.RefreshWatermark
    local label = Library.WatermarkLabel
    local watermark = Library.Watermark
    local accent = watermark:FindFirstChildWhichIsA("Frame")
    local connections = {}

    local function isPhoneLayout()
        if not UIS.TouchEnabled then
            return false
        end

        local camera = workspace.CurrentCamera
        local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)

        -- Touch laptops/tablets with a keyboard should keep desktop sizing.
        return (not UIS.KeyboardEnabled) or math.min(viewport.X, viewport.Y) < 700
    end

    local function applyPreRefreshMetrics()
        if isPhoneLayout() then
            label.TextSize = 9
            label.Position = UDim2.fromOffset(11, 0)
            label.Size = UDim2.new(1, -18, 1, 0)
        else
            -- Do NOT force TextSize on desktop. The global Text Scale setting
            -- owns it through RegisterFont/SetTextScale.
            label.Position = UDim2.fromOffset(13, 0)
            label.Size = UDim2.new(1, -21, 1, 0)
        end
    end

    local function resizeDesktopWatermark()
        if isPhoneLayout() then
            return
        end

        local text = tostring(label.Text or "")
        local ok, measured = pcall(function()
            return TextService:GetTextSize(
                text,
                label.TextSize,
                label.Font,
                Vector2.new(2400, 300)
            )
        end)

        if not ok or not measured then
            return
        end

        local width = math.max(110, math.ceil(measured.X + 30))
        local height = math.max(30, math.ceil(measured.Y + 12))
        watermark.Size = UDim2.fromOffset(width, height)

        if accent and accent.Parent then
            accent.Position = UDim2.fromOffset(4, 5)
            accent.Size = UDim2.fromOffset(3, math.max(14, height - 10))
        end
    end

    function Library:RefreshWatermark(...)
        applyPreRefreshMetrics()
        local result = rawRefreshWatermark(self, ...)

        if not self.Watermark or not self.Watermark.Parent then
            return result
        end

        if isPhoneLayout() then
            self.Watermark.Size = UDim2.new(
                self.Watermark.Size.X.Scale,
                self.Watermark.Size.X.Offset,
                0,
                24
            )

            if accent and accent.Parent then
                accent.Position = UDim2.fromOffset(4, 5)
                accent.Size = UDim2.fromOffset(3, 14)
            end
        else
            resizeDesktopWatermark()
        end

        if type(self.ApplyWatermarkPosition) == "function" then
            self:ApplyWatermarkPosition()
        end

        return result
    end

    connections[#connections + 1] = label:GetPropertyChangedSignal("TextSize"):Connect(function()
        if isPhoneLayout() then
            if label.TextSize ~= 9 then
                label.TextSize = 9
            end
        else
            task.defer(function()
                if not Library.Unloaded and watermark.Parent then
                    resizeDesktopWatermark()
                    if type(Library.ApplyWatermarkPosition) == "function" then
                        Library:ApplyWatermarkPosition()
                    end
                end
            end)
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
