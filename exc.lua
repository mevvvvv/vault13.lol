return function()
    local result = {name = "Unknown", version = "Unknown"}
    
    -- Quick executor detection
    if type(identifyexecutor) == "function" then
        result.name = identifyexecutor() or result.name
    elseif type(getexecutorname) == "function" then
        result.name = getexecutorname() or result.name
    elseif type(getexecutor) == "function" then
        result.name = getexecutor() or result.name
    elseif type(syn) == "table" then
        result.name = "Synapse X"
    elseif type(KRNL) == "table" then
        result.name = "KRNL"
    elseif type(Fluxus) == "table" then
        result.name = "Fluxus"
    end
    
    -- Version detection
    if type(identifyexecutorversion) == "function" then
        result.version = identifyexecutorversion() or result.version
    elseif type(getexecutorversion) == "function" then
        result.version = getexecutorversion() or result.version
    elseif type(syn) == "table" and type(syn.get_version) == "function" then
        result.version = syn.get_version() or result.version
    end
    
    return result
end
