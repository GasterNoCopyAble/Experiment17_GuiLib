-- Experiment 17 UI Library stable loader
-- Current implementation: v21
-- Repository: GasterNoCopyAble/Experiment17_GuiLib

local BASE = "https://raw.githubusercontent.com/GasterNoCopyAble/Experiment17_GuiLib/main/src/v21/part"
local PARTS = {
    "01",
    "02",
    "03",
    "04",
    "05",
    "06",
    "07",
    "08",
    "09",
    "10",
    "11",
    "12",
    "13",
    "14",
    "15",
    "16",
    "17",
    "18",
    "19",
    "20",
    "21",
    "22",
    "23",
    "24",
    "25",
    "26",
    "27",
    "28",
    "29",
}

local sourceParts = table.create(#PARTS)
local finished = 0
local firstError = nil

for index, suffix in ipairs(PARTS) do
    task.spawn(function()
        local ok, result = pcall(function()
            return game:HttpGet(BASE .. suffix .. ".luau")
        end)

        if ok then
            sourceParts[index] = result
        elseif not firstError then
            firstError = result
        end

        finished += 1
    end)
end

while finished < #PARTS do
    task.wait()
end

if firstError then
    error("[Experiment17] Failed to download library source: " .. tostring(firstError))
end

local source = table.concat(sourceParts)
local compiler = loadstring or (getgenv and getgenv().loadstring)

if type(compiler) ~= "function" then
    error("[Experiment17] loadstring is unavailable in this environment")
end

local chunk, compileError = compiler(source)
if not chunk then
    error("[Experiment17] Failed to compile library: " .. tostring(compileError))
end

return chunk()
