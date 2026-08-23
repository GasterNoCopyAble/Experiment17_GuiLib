-- Experiment 17 UI Library stable loader
-- Current implementation: v21
-- Repository: GasterNoCopyAble/Experiment17_GuiLib
--
-- v21 is stored as overlapping source windows. Some overlap copies are not
-- byte-identical (for example a translated line may differ between adjacent
-- parts), so raw table.concat() and exact byte overlap are both unsafe.
-- This loader reconstructs the source using a tolerant LINE overlap matcher.

local BASE = "https://raw.githubusercontent.com/GasterNoCopyAble/Experiment17_GuiLib/main/src/v21/part"
local PARTS = {
    "01","02","03","04","05","06","07","08","09","10",
    "11","12","13","14","15","16","17","18","19","20",
    "21","22","23","24","25","26","27","28","29",
}

local sourceParts = {}
local finished = 0
local firstError = nil

for index, suffix in ipairs(PARTS) do
    task.spawn(function()
        local ok, result = pcall(function()
            return game:HttpGet(BASE .. suffix .. ".luau")
        end)

        if ok and type(result) == "string" and #result > 0 then
            sourceParts[index] = result
        elseif firstError == nil then
            firstError = ok and ("empty source part " .. tostring(suffix)) or result
        end

        finished = finished + 1
    end)
end

while finished < #PARTS do
    task.wait()
end

if firstError then
    error("[Experiment17] Failed to download library source: " .. tostring(firstError))
end

local function normalizeNewlines(text)
    return tostring(text or ""):gsub("\r\n", "\n"):gsub("\r", "\n")
end

local function splitLines(text)
    text = normalizeNewlines(text)
    local out = {}
    for line in (text .. "\n"):gmatch("(.-)\n") do
        out[#out + 1] = line
    end
    -- The artificial newline above always creates one final empty capture.
    if out[#out] == "" then
        out[#out] = nil
    end
    return out
end

local function trim(line)
    return tostring(line or ""):match("^%s*(.-)%s*$") or ""
end

local function linesEquivalent(a, b)
    a = trim(a)
    b = trim(b)
    if a == b then
        return true
    end

    -- Ignore pure whitespace/blank-line drift at generated part boundaries.
    if a == "" and b == "" then
        return true
    end

    return false
end

-- Find how many PREFIX lines from `right` already exist as the SUFFIX of
-- `left`. A tiny number of changed lines is tolerated because some generated
-- windows contain translation edits inside their duplicated overlap.
local function findLineOverlap(left, right)
    local maxOverlap = math.min(#left, #right)
    if maxOverlap <= 0 then
        return 0, 0
    end

    -- Real v21 windows overlap by many lines. Requiring >= 6 lines avoids
    -- accidentally merging two unrelated chunks that merely end/start with
    -- generic Lua lines such as `end` or `})`.
    local minOverlap = math.min(6, maxOverlap)

    for amount = maxOverlap, minOverlap, -1 do
        local mismatches = 0
        local compared = 0
        local allowed = math.max(1, math.floor(amount * 0.08 + 0.5))

        for offset = 1, amount do
            local a = left[#left - amount + offset]
            local b = right[offset]

            -- Blank-vs-nonblank is still a mismatch, but exact blank lines are
            -- cheap and common enough that they should count normally.
            if not linesEquivalent(a, b) then
                mismatches = mismatches + 1
                if mismatches > allowed then
                    break
                end
            end
            compared = compared + 1
        end

        if compared == amount and mismatches <= allowed then
            -- Extra confidence for short overlaps: at least one of the first
            -- two and one of the last two lines must match exactly after trim.
            local firstOK = linesEquivalent(left[#left - amount + 1], right[1])
                or (amount >= 2 and linesEquivalent(left[#left - amount + 2], right[2]))
            local lastOK = linesEquivalent(left[#left], right[amount])
                or (amount >= 2 and linesEquivalent(left[#left - 1], right[amount - 1]))

            if firstOK and lastOK then
                return amount, mismatches
            end
        end
    end

    return 0, 0
end

local function mergeParts(parts)
    local merged = splitLines(parts[1] or "")
    local removedLines = 0
    local fuzzyBoundaries = 0

    for index = 2, #parts do
        local nextLines = splitLines(parts[index] or "")
        local overlap, mismatches = findLineOverlap(merged, nextLines)

        if overlap > 0 then
            removedLines = removedLines + overlap
            if mismatches > 0 then
                fuzzyBoundaries = fuzzyBoundaries + 1
            end

            for lineIndex = overlap + 1, #nextLines do
                merged[#merged + 1] = nextLines[lineIndex]
            end
        else
            -- Keep the source debuggable if a generated window unexpectedly
            -- has no detectable overlap. Joining by lines is safer than
            -- inserting bytes in the middle of a token.
            merged[#merged + 1] = ""
            for lineIndex = 1, #nextLines do
                merged[#merged + 1] = nextLines[lineIndex]
            end
            warn(string.format("[Experiment17] GuiLib v21: no overlap at part %02d", index))
        end
    end

    return table.concat(merged, "\n"), removedLines, fuzzyBoundaries
end

local source, removedLines, fuzzyBoundaries = mergeParts(sourceParts)
print(string.format(
    "[Experiment17] GuiLib v21 merged; removed %d overlap lines (%d fuzzy boundaries)",
    removedLines,
    fuzzyBoundaries
))

local compiler = loadstring or (getgenv and getgenv().loadstring)
if type(compiler) ~= "function" then
    error("[Experiment17] loadstring is unavailable in this environment")
end

local chunk, compileError = compiler(source)
if not chunk then
    local errorText = tostring(compileError)
    local lineNumber = tonumber(errorText:match(":(%d+):"))

    if lineNumber then
        local lines = splitLines(source)
        local fromLine = math.max(1, lineNumber - 4)
        local toLine = math.min(#lines, lineNumber + 4)
        local context = {}

        for i = fromLine, toLine do
            context[#context + 1] = string.format("%s%05d | %s", i == lineNumber and ">> " or "   ", i, lines[i])
        end

        error(
            "[Experiment17] Failed to compile library: " .. errorText
            .. "\n[Experiment17] Source context:\n"
            .. table.concat(context, "\n")
        )
    end

    error("[Experiment17] Failed to compile library: " .. errorText)
end

return chunk()
