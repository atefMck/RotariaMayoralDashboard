-- Network Communication Module
local Network = {}

-- Load configuration first to set global constants
require("config")

local modem = peripheral.find("modem") or error("No modem attached", 0)

-- Open both channels - server channel for sending requests, client channel for receiving responses
modem.open(SERVER_CHANNEL)
modem.open(CLIENT_CHANNEL)

function Network.sendRequest(requestType, data, timeout)
    timeout = timeout or 5
    local request = {
        type = requestType
    }
    
    -- Merge data into request
    for k, v in pairs(data) do
        request[k] = v
    end
    
    -- Send request
    modem.transmit(SERVER_CHANNEL, CLIENT_CHANNEL, request)
    
    -- Wait for response with timeout
    local startTime = os.clock()
    local event, side, channel, replyChannel, message, distance
    
    while true do
        local elapsed = os.clock() - startTime
        if elapsed > timeout then
            return nil, "Request timeout"
        end
        
        event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
        
        if channel == CLIENT_CHANNEL then
            return message, nil
        end
    end
end

function Network.createAccount(username, password, accountType)
    local response, err = Network.sendRequest("create_account", {
        username = username,
        password = password,
        accountType = accountType or "citizen"
    })
    
    if err then
        return false, tostring(err)
    end
    
    if not response then
        return false, "No response from server"
    end
    
    if response.success then
        return true, response.account
    else
        return false, response.message or "Unknown error"
    end
end

function Network.login(username, password)
    local response, err = Network.sendRequest("login", {
        username = username,
        password = password
    })
    
    if err then
        return false, tostring(err)
    end
    
    if not response then
        return false, "No response from server"
    end
    
    if response.success then
        return true, response.account
    else
        return false, response.message or "Unknown error"
    end
end

function Network.getAllUsers(accountId)
    local response, err = Network.sendRequest("get_all_users", {
        accountId = accountId
    })
    
    if err then
        return false, tostring(err)
    end
    
    if not response then
        return false, "No response from server"
    end
    
    if response.success then
        return true, response.users or {}
    else
        return false, response.message or "Unknown error"
    end
end

function Network.createPlotApplication(accountId, inGameName, plotNumber, buildDescription, estimatedSize, reason)
    local response, err = Network.sendRequest("create_plot_application", {
        accountId = accountId,
        inGameName = inGameName,
        plotNumber = plotNumber,
        buildDescription = buildDescription,
        estimatedSize = estimatedSize,
        reason = reason
    })
    
    if err then
        return false, tostring(err)
    end
    
    if not response then
        return false, "No response from server"
    end
    
    if response.success then
        return true, response.plot
    else
        return false, response.message or "Unknown error"
    end
end

function Network.getPlotApplications(accountId)
    local response, err = Network.sendRequest("get_plot_applications", {
        accountId = accountId
    })
    
    if err then
        return false, tostring(err)
    end
    
    if not response then
        return false, "No response from server"
    end
    
    if response.success then
        return true, response.plots or {}
    else
        return false, response.message or "Unknown error"
    end
end

function Network.getMyPlots(accountId)
    local response, err = Network.sendRequest("get_my_plots", {
        accountId = accountId
    })
    
    if err then
        return false, tostring(err)
    end
    
    if not response then
        return false, "No response from server"
    end
    
    if response.success then
        return true, response.plots or {}
    else
        return false, response.message or "Unknown error"
    end
end

function Network.updatePlotStatus(accountId, plotId, status)
    local response, err = Network.sendRequest("update_plot_status", {
        accountId = accountId,
        plotId = plotId,
        status = status
    })
    
    if err then
        return false, tostring(err)
    end
    
    if not response then
        return false, "No response from server"
    end
    
    if response.success then
        return true, response.plot
    else
        return false, response.message or "Unknown error"
    end
end

function Network.getCityInfo(accountId)
    local response, err = Network.sendRequest("get_city_info", {
        accountId = accountId
    })
    
    if err then
        return false, tostring(err)
    end
    
    if not response then
        return false, "No response from server"
    end
    
    if response.success then
        return true, response.cityInfo
    else
        return false, response.message or "Unknown error"
    end
end

function Network.updateCityInfo(accountId, title, content)
    local response, err = Network.sendRequest("update_city_info", {
        accountId = accountId,
        title = title,
        content = content
    })
    
    if err then
        return false, tostring(err)
    end
    
    if not response then
        return false, "No response from server"
    end
    
    if response.success then
        return true, response.cityInfo
    else
        return false, response.message or "Unknown error"
    end
end

function Network.changeAccountType(accountId, targetAccountId, newType)
    local response, err = Network.sendRequest("change_account_type", {
        accountId = accountId,
        targetAccountId = targetAccountId,
        newType = newType
    })
    
    if err then
        return false, tostring(err)
    end
    
    if not response then
        return false, "No response from server"
    end
    
    if response.success then
        return true, response.account
    else
        return false, response.message or "Unknown error"
    end
end

function Network.deleteAccount(accountId, targetAccountId)
    local response, err = Network.sendRequest("delete_account", {
        accountId = accountId,
        targetAccountId = targetAccountId
    })
    
    if err then
        return false, tostring(err)
    end
    
    if not response then
        return false, "No response from server"
    end
    
    if response.success then
        return true
    else
        return false, response.message or "Unknown error"
    end
end

function Network.getAllInfoTabs(accountId)
    local response, err = Network.sendRequest("get_all_info_tabs", {
        accountId = accountId
    })
    
    if err then
        return false, tostring(err)
    end
    
    if not response then
        return false, "No response from server"
    end
    
    if response.success then
        return true, response.tabs or {}
    else
        return false, response.message or "Unknown error"
    end
end

function Network.createInfoTab(accountId, title, content)
    local response, err = Network.sendRequest("create_info_tab", {
        accountId = accountId,
        title = title,
        content = content
    })
    
    if err then
        return false, tostring(err)
    end
    
    if not response then
        return false, "No response from server"
    end
    
    if response.success then
        return true, response.tab
    else
        return false, response.message or "Unknown error"
    end
end

function Network.updateInfoTab(accountId, tabId, title, content)
    local response, err = Network.sendRequest("update_info_tab", {
        accountId = accountId,
        tabId = tabId,
        title = title,
        content = content
    })
    
    if err then
        return false, tostring(err)
    end
    
    if not response then
        return false, "No response from server"
    end
    
    if response.success then
        return true, response.tab
    else
        return false, response.message or "Unknown error"
    end
end

function Network.deleteInfoTab(accountId, tabId)
    local response, err = Network.sendRequest("delete_info_tab", {
        accountId = accountId,
        tabId = tabId
    })
    
    if err then
        return false, tostring(err)
    end
    
    if not response then
        return false, "No response from server"
    end
    
    if response.success then
        return true
    else
        return false, response.message or "Unknown error"
    end
end

return Network
