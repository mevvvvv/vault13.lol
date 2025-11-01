-- detect_executor.lua
local function safeCall(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, res = pcall(fn, ...)
    return ok and res or nil
end

local function detectExecutor()
    local result = {
        name = nil,
        version = nil,
        found_by = nil -- which check produced the info
    }

    -- 1) Explicit name/version functions
    if not result.name and type(identifyexecutor) == "function" then
        result.name = safeCall(identifyexecutor)
        if result.name then result.found_by = "identifyexecutor()" end
    end
    if not result.version and type(identifyexecutorversion) == "function" then
        result.version = safeCall(identifyexecutorversion)
        if result.version and not result.found_by then result.found_by = "identifyexecutorversion()" end
    end

    -- 2) Alternative common function names
    if not result.name and type(getexecutorname) == "function" then
        result.name = safeCall(getexecutorname)
        result.found_by = result.found_by or "getexecutorname()"
    end
    if not result.version and type(getexecutorversion) == "function" then
        result.version = safeCall(getexecutorversion)
        result.found_by = result.found_by or "getexecutorversion()"
    end
    if not result.name and type(getexecutor) == "function" then
        result.name = safeCall(getexecutor)
        result.found_by = result.found_by or "getexecutor()"
    end

    -- 3) Info-returning functions (tables)
    if type(getexecutorinfo) == "function" and not (result.name and result.version) then
        local info = safeCall(getexecutorinfo)
        if type(info) == "table" then
            result.name = result.name or info.Name or info.name or info.executor
            result.version = result.version or info.Version or info.version or info.ver
            result.found_by = result.found_by or "getexecutorinfo()"
        end
    end

    -- 4) Known global tables (Synapse, KRNL, etc.)
    if not (result.name and result.version) then
        if type(syn) == "table" then
            -- syn.info is common in Synapse-like environments
            if type(syn.info) == "table" then
                result.name = result.name or "Synapse X"
                result.version = result.version or syn.info.version or syn.info.build or syn.info.cli_version
                result.found_by = result.found_by or "syn.info"
            end
            -- some syn variants may expose a version directly
            if not result.version and type(syn.get_version) == "function" then
                result.version = safeCall(syn.get_version)
                result.found_by = result.found_by or "syn.get_version()"
            end
        end

        if not result.name and type(KRNL) == "table" then
            result.name = result.name or "KRNL"
            result.version = result.version or KRNL.VERSION or KRNL.version
            result.found_by = result.found_by or "KRNL global"
        end

        -- Example for other known tables (placeholders, safe checks)
        if not result.name and type(Fluxus) == "table" then
            result.name = result.name or "Fluxus"
            result.version = result.version or Fluxus.Version or Fluxus.version
            result.found_by = result.found_by or "Fluxus global"
        end
    end

    -- 5) Fallback: try calling identifyexecutor to get name, then try parsing version from other globals
    if not (result.name or result.version) then
        -- try any "version" global fields that some runners set
        local possible_version_globals = {
            "VERSION", "Version", "version", "_VERSION",
            "executor_version", "EXECUTOR_VERSION"
        }
        for _, gname in ipairs(possible_version_globals) do
            local ok, val = pcall(function() return _G[gname] end)
            if ok and val and not result.version then
                result.version = val
                result.found_by = result.found_by or ("_G['" .. gname .. "']")
            end
        end
    end

    -- Final clean up: normalize to strings or "Unknown"
    result.name = (result.name and tostring(result.name)) or "Unknown"
    result.version = (result.version and tostring(result.version)) or "Unknown"
    result.found_by = result.found_by or "none"

    return result
end
