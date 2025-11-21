-- Error Logger Utility
local ErrorLogger = {}

local ERROR_LOG_FILE = "error_log.txt"

-- Write error to file
function ErrorLogger.logError(errorMsg, stackTrace)
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
            ErrorLogger.logError(errorMsg, stackTrace)
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
        ErrorLogger.logError(errorMsg, stackTrace)
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

