-- Experiment 17 UI Library stable loader
-- Current implementation: v22

local URL = "https://raw.githubusercontent.com/GasterNoCopyAble/Experiment17_GuiLib/main/src/v22/core/Main.luau"
local compiler = loadstring or (getgenv and getgenv().loadstring)

if type(compiler) ~= "function" then
    error("[Experiment17] loadstring is unavailable in this environment")
end

local ok, source = pcall(function()
    return game:HttpGet(URL)
end)

if not ok or type(source) ~= "string" or #source == 0 then
    error("[Experiment17] Failed to download v22 core: " .. tostring(source))
end

local chunk, compileError = compiler(source)
if not chunk then
    error("[Experiment17] Failed to compile v22 core: " .. tostring(compileError))
end

return chunk()
