-- Experiment 17 UI Library v22
-- Logical bootstrap: core builds the base GUI, modules install optional/settings features.

local REPO = "https://raw.githubusercontent.com/GasterNoCopyAble/Experiment17_GuiLib/main/src/v22/"
local compiler = loadstring or (getgenv and getgenv().loadstring)

if type(compiler) ~= "function" then
    error("[Experiment17] loadstring is unavailable in this environment")
end

local function loadRemote(path)
    local ok, source = pcall(function()
        return game:HttpGet(REPO .. path)
    end)

    if not ok or type(source) ~= "string" or #source == 0 then
        error("[Experiment17] Failed to download v22 module " .. tostring(path) .. ": " .. tostring(source))
    end

    local chunk, compileError = compiler(source)
    if not chunk then
        error("[Experiment17] Failed to compile v22 module " .. tostring(path) .. ": " .. tostring(compileError))
    end

    return chunk()
end

local assembleLegacy = loadRemote("core/LegacyAssembler.luau")
if type(assembleLegacy) ~= "function" then
    error("[Experiment17] LegacyAssembler did not return a bootstrap function")
end

local Library = assembleLegacy()
if type(Library) ~= "table" then
    error("[Experiment17] Core did not return Library")
end

Library.Version = "v22"
Library.ModuleVersion = 22
Library.Modules = Library.Modules or {}
Library.__E17ModuleCleanups = Library.__E17ModuleCleanups or {}

local MODULES = {
    "Mobile",
    "Sliders",
    "RGB",
    "Gradients",
    "Tiles",
}

for _, moduleName in ipairs(MODULES) do
    local installer = loadRemote("modules/" .. moduleName .. ".luau")
    if type(installer) ~= "function" then
        error("[Experiment17] Module " .. moduleName .. " did not return an installer")
    end

    local ok, cleanup = pcall(installer, Library)
    if not ok then
        error("[Experiment17] Module " .. moduleName .. " failed: " .. tostring(cleanup))
    end

    Library.Modules[moduleName] = true
    if type(cleanup) == "function" then
        table.insert(Library.__E17ModuleCleanups, cleanup)
    end
end

local rawUnload = Library.Unload
if type(rawUnload) == "function" and not Library.__E17V22UnloadWrapped then
    Library.__E17V22UnloadWrapped = true

    function Library:Unload(...)
        for index = #self.__E17ModuleCleanups, 1, -1 do
            pcall(self.__E17ModuleCleanups[index])
        end
        table.clear(self.__E17ModuleCleanups)
        return rawUnload(self, ...)
    end
end

return Library
