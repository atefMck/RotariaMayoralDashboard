-- Network Communication Module
local Network = {}

local modem = peripheral.find("modem") or error("No modem attached", 0)
local SERVER_CHANNEL = 100
local CLIENT_CHANNEL = 200

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

-- Public method to get city info (no auth required)
function Network.getCityInfoPublic()
    local response, err = Network.sendRequest("get_city_info_public", {})
    
    if err then
        return false, tostring(err)
    end
    
    if not response then
        return false, "No response from server"
    end
    
    -- Handle both response types - now returns tabs array
    if response.type == "get_city_info_public_response" or response.success then
        return true, response.tabs or (response.cityInfo and {response.cityInfo} or {})
    else
        return false, response.message or "Unknown error"
    end
end

-- Public method to create plot application (no auth required)
function Network.createPlotApplicationPublic(inGameName, plotNumber, buildDescription, estimatedSize, reason)
    local response, err = Network.sendRequest("create_plot_application_public", {
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
    
    -- Handle both response types
    if response.type == "create_plot_application_public_response" or response.success then
        return true, response.plot
    else
        return false, response.message or "Unknown error"
    end
end

return Network
