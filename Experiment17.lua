-- Experiment 17 UI Library stable loader
-- Current implementation: v21
-- Repository: GasterNoCopyAble/Experiment17_GuiLib
--
-- v21 source parts intentionally/accidentally contain overlapping source
-- at their boundaries. Do not use a raw table.concat here: repeated chunks
-- produce invalid Lua/Luau (for example an unexpected `}` around line 491).
-- mergeWithOverlap() removes only an EXACT suffix/prefix duplicate.

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

        if ok and type(result) == "string" and #result > 0 then
            sourceParts[index] = result
        elseif not firstError then
            firstError = ok and ("empty source part " .. tostring(suffix)) or result
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

-- Returns the number of bytes shared by the exact suffix of `left`
-- and exact prefix of `right`.
local function findExactOverlap(left, right)
    local maxOverlap = math.min(#left, #right)
    if maxOverlap <= 0 then
        return 0
    end

    -- For very small boundaries brute force is cheap and avoids requiring
    -- a fixed-size probe longer than the actual overlap.
    if maxOverlap < 64 then
        for amount = maxOverlap, 1, -1 do
            if left:sub(#left - amount + 1) == right:sub(1, amount) then
                return amount
            end
        end
        return 0
    end

    -- All current v21 overlaps are large. A 64-byte exact probe makes
    -- accidental matches extremely unlikely while keeping this fast even
    -- when the assembled source is already large.
    local probe = right:sub(1, 64)
    local searchFrom = math.max(1, #left - maxOverlap + 1)
    local best = 0
    local position = string.find(left, probe, searchFrom, true)

    while position do
        local amount = #left - position + 1
        if amount <= #right and amount > best then
            if left:sub(position) == right:sub(1, amount) then
                best = amount
            end
        end
        position = string.find(left, probe, position + 1, true)
    end

    -- Rare fallback for an overlap shorter than the 64-byte probe.
    if best == 0 then
        for amount = math.min(63, maxOverlap), 1, -1 do
            if left:sub(#left - amount + 1) == right:sub(1, amount) then
                best = amount
                break
            end
        end
    end

    return best
end

local function mergeWithOverlap(parts)
    local merged = parts[1] or ""
    local removedBytes = 0

    for index = 2, #parts do
        local nextPart = parts[index] or ""
        local overlap = findExactOverlap(merged, nextPart)

        if overlap > 0 then
            removedBytes += overlap
            nextPart = nextPart:sub(overlap + 1)
        end

        -- Always add a newline separator when neither side has one. This is
        -- harmless for Lua and protects boundaries such as `end` + `local`.
        if #merged > 0 and #nextPart > 0 then
            local last = merged:sub(-1)
            local first = nextPart:sub(1, 1)
            if last ~= "\n" and last ~= "\r" and first ~= "\n" and first ~= "\r" then
                merged ..= "\n"
            end
        end

        merged ..= nextPart
    end

    return merged, removedBytes
end

local source, removedBytes = mergeWithOverlap(sourceParts)

if removedBytes > 0 then
    print(string.format("[Experiment17] GuiLib v21 merged; removed %d duplicated overlap bytes", removedBytes))
end

local compiler = loadstring or (getgenv and getgenv().loadstring)

if type(compiler) ~= "function" then
    error("[Experiment17] loadstring is unavailable in this environment")
end

local chunk, compileError = compiler(source)
if not chunk then
    error("[Experiment17] Failed to compile library: " .. tostring(compileError))
end

return chunk()
