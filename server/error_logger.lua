-- Error Logger Utility
local ErrorLogger = {}

local ERROR_LOG_FILE = "error_log.txt"

-- Helper function to serialize a value safely
local function serializeValue(value, depth)
    depth = depth or 0
    if depth > 3 then
        return "[Max depth reached]"
    end
    
    local valueType = type(value)
    if valueType == "nil" then
        return "nil"
    elseif valueType == "boolean" then
        return tostring(value)
    elseif valueType == "number" then
        return tostring(value)
    elseif valueType == "string" then
        if #value > 100 then
            return "\"" .. value:sub(1, 100) .. "...\" [truncated]"
        end
        return "\"" .. value .. "\""
    elseif valueType == "function" then
        return "[function]"
    elseif valueType == "table" then
        local result = "{"
        local count = 0
        for k, v in pairs(value) do
            if count < 20 then
                local keyStr = type(k) == "string" and ("\"" .. k .. "\"") or tostring(k)
                result = result .. "\n  " .. keyStr .. " = " .. serializeValue(v, depth + 1)
                count = count + 1
            else
                result = result .. "\n  ... [more entries]"
                break
            end
        end
        result = result .. "\n}"
        return result
    else
        return "[" .. valueType .. "]"
    end
end

-- Dump all variables from a given level
local function dumpVariables(level)
    level = level or 1
    local vars = {}
    local i = 1
    while true do
        local name, value = debug.getlocal(level + 1, i)
        if not name then break end
        vars[name] = value
        i = i + 1
    end
    
    -- Get upvalues if available
    local func = debug.getinfo(level + 1, "f").func
    if func then
        i = 1
        while true do
            local name, value = debug.getupvalue(func, i)
            if not name then break end
            vars["[upvalue]" .. name] = value
            i = i + 1
        end
    end
    
    return vars
end

-- Write error to file with all variables
function ErrorLogger.logError(errorMsg, stackTrace, level)
    level = level or 1
    local file = fs.open(ERROR_LOG_FILE, "a")
    if file then
        local timestamp = os.date("%Y-%m-%d %H:%M:%S")
        file.writeLine("=" .. string.rep("=", 60))
        file.writeLine("ERROR at " .. timestamp)
        file.writeLine("=" .. string.rep("=", 60))
        file.writeLine("")
        file.writeLine("Error Message:")
        file.writeLine(tostring(errorMsg))
        file.writeLine("")
        if stackTrace then
            file.writeLine("Stack Trace:")
            file.writeLine(tostring(stackTrace))
            file.writeLine("")
        end
        
        -- Dump local variables
        file.writeLine("Local Variables:")
        file.writeLine(string.rep("-", 60))
        local success, vars = pcall(dumpVariables, level + 1)
        if success and vars then
            for name, value in pairs(vars) do
                file.writeLine(name .. " = " .. serializeValue(value))
            end
        else
            file.writeLine("Could not retrieve local variables")
        end
        file.writeLine("")
        
        -- Dump global variables (common ones)
        file.writeLine("Global Variables (selected):")
        file.writeLine(string.rep("-", 60))
        local globalVars = {
            "modem", "SERVER_CHANNEL", "CLIENT_CHANNEL", "Accounts", "Plots", "CityInfo", "Protocol"
        }
        for _, varName in ipairs(globalVars) do
            local varValue = _G[varName]
            if varValue ~= nil then
                file.writeLine(varName .. " = " .. serializeValue(varValue))
            end
        end
        file.writeLine("")
        
        file.writeLine(string.rep("=", 62))
        file.writeLine("")
        file.close()
        return true
    end
    return false
end

-- Wrap a function with error handling
function ErrorLogger.wrapFunction(func, funcName)
    return function(...)
        local success, result = pcall(func, ...)
        if not success then
            local errorMsg = tostring(result)
            local stackTrace = debug.traceback(result, 2)
            ErrorLogger.logError(errorMsg, stackTrace, 2)
            print("Error logged to " .. ERROR_LOG_FILE)
            error(result, 0) -- Re-throw the error
        end
        return result
    end
end

-- Set up global error handler
function ErrorLogger.setupGlobalErrorHandler()
    local originalError = error
    error = function(msg, level)
        local errorMsg = tostring(msg)
        local stackTrace = debug.traceback(msg, (level or 1) + 1)
        ErrorLogger.logError(errorMsg, stackTrace, (level or 1) + 1)
        print("Error logged to " .. ERROR_LOG_FILE)
        return originalError(msg, level)
    end
end

-- Clear error log
function ErrorLogger.clearLog()
    if fs.exists(ERROR_LOG_FILE) then
        fs.delete(ERROR_LOG_FILE)
    end
end

return ErrorLogger

