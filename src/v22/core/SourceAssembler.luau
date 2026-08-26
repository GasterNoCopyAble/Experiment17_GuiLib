-- Experiment 17 v22 core source assembler
-- v22 keeps the stable base engine as internal source windows under core/source/.
-- Windows overlap for compatibility with the historical source snapshot, but
-- there is no v21 runtime path or version dependency anymore.

return function()
    local BASE = "https://raw.githubusercontent.com/GasterNoCopyAble/Experiment17_GuiLib/main/src/v22/core/source/window"
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
                firstError = ok and ("empty core window " .. tostring(suffix)) or result
            end

            finished += 1
        end)
    end

    while finished < #PARTS do
        task.wait()
    end

    if firstError then
        error("[Experiment17] Failed to download v22 core: " .. tostring(firstError))
    end

    local function normalizeNewlines(value)
        return tostring(value or ""):gsub("\r\n", "\n"):gsub("\r", "\n")
    end

    local function splitLines(value)
        value = normalizeNewlines(value)
        local out = {}
        for line in (value .. "\n"):gmatch("(.-)\n") do
            out[#out + 1] = line
        end
        if out[#out] == "" then out[#out] = nil end
        return out
    end

    local function trim(line)
        return tostring(line or ""):match("^%s*(.-)%s*$") or ""
    end

    local function equivalent(a, b)
        return trim(a) == trim(b)
    end

    local function findLineOverlap(left, right)
        local maxOverlap = math.min(#left, #right)
        if maxOverlap <= 0 then return 0, 0 end

        local minOverlap = math.min(6, maxOverlap)
        for amount = maxOverlap, minOverlap, -1 do
            local mismatches = 0
            local compared = 0
            local allowed = math.max(1, math.floor(amount * 0.08 + 0.5))

            for offset = 1, amount do
                local a = left[#left - amount + offset]
                local b = right[offset]
                if not equivalent(a, b) then
                    mismatches += 1
                    if mismatches > allowed then break end
                end
                compared += 1
            end

            if compared == amount and mismatches <= allowed then
                local firstOK = equivalent(left[#left - amount + 1], right[1])
                    or (amount >= 2 and equivalent(left[#left - amount + 2], right[2]))
                local lastOK = equivalent(left[#left], right[amount])
                    or (amount >= 2 and equivalent(left[#left - 1], right[amount - 1]))

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
                removedLines += overlap
                if mismatches > 0 then fuzzyBoundaries += 1 end
                for lineIndex = overlap + 1, #nextLines do
                    merged[#merged + 1] = nextLines[lineIndex]
                end
            else
                merged[#merged + 1] = ""
                for lineIndex = 1, #nextLines do
                    merged[#merged + 1] = nextLines[lineIndex]
                end
                warn(string.format("[Experiment17] v22 core: no overlap at window %02d", index))
            end
        end

        return table.concat(merged, "\n"), removedLines, fuzzyBoundaries
    end

    local source, removedLines, fuzzyBoundaries = mergeParts(sourceParts)

    -- Promote the stable base snapshot to the current v22 schema before compile.
    source = source:gsub("Experiment 17 %[Visuals%] %- UI Library v21", "Experiment 17 [Visuals] - UI Library v22", 1)
    source = source:gsub("version = 21,", "version = 22,", 1)
    source = source:gsub("while version < 21 and guard < 32 do", "while version < 22 and guard < 32 do", 1)

    print(string.format(
        "[Experiment17] v22 core merged; removed %d overlap lines (%d fuzzy boundaries)",
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
                context[#context + 1] = string.format(
                    "%s%05d | %s",
                    i == lineNumber and ">> " or "   ",
                    i,
                    lines[i]
                )
            end

            error(
                "[Experiment17] Failed to compile v22 core: " .. errorText
                .. "\n[Experiment17] Source context:\n"
                .. table.concat(context, "\n")
            )
        end

        error("[Experiment17] Failed to compile v22 core: " .. errorText)
    end

    local Library = chunk()
    if type(Library) ~= "table" then
        error("[Experiment17] v22 core did not return Library")
    end

    return Library
end
