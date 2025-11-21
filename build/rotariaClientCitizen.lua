-- Bundled Rotaria City Citizen Client
-- This file contains all citizen client modules bundled together

-- Version Information
local CLIENT_VERSION = "1.0.0"

-- ============================================================================
-- Utils Module
-- ============================================================================
local Utils = {}

-- Get terminal size
function Utils.getTerminalSize()
    local termObj = term.current()
    if termObj and termObj.getSize then
        return termObj.getSize()
    end
    -- Fallback to default size if term.current() doesn't work
    return 51, 19
end

-- Calculate responsive positions and sizes
function Utils.getResponsiveLayout()
    local width, height = Utils.getTerminalSize()
    
    return {
        width = width,
        height = height,
        -- Common spacing
        margin = 2,
        -- Button dimensions
        buttonHeight = math.max(1, math.floor(height / 15)),
        buttonWidth = math.max(10, math.floor(width / 3)),
        -- Input dimensions
        inputWidth = math.max(20, width - 4),
        inputHeight = 1,
        -- Label spacing
        labelSpacing = math.max(2, math.floor(height / 12)),
        -- Status label position
        statusY = math.max(10, height - 5),
        -- Button row position
        buttonY = math.max(12, height - 3)
    }
end

-- ============================================================================
-- Network Module
-- ============================================================================
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

-- ============================================================================
-- InfoTabDetail Screen
-- ============================================================================
local InfoTabDetail = {}
-- Utils module loaded above

function InfoTabDetail.create(mainFrame, tab, onBack)
    local layout = Utils.getResponsiveLayout()
    local screen = mainFrame:addFrame()
        :setSize("{parent.width}", "{parent.height}")
        :setPosition(1, 1)
        :setBackground(colors.black)
    
    -- Simple header
    screen:addLabel()
        :setText("Rotaria City")
        :setPosition(2, 1)
        :setForeground(colors.orange)
    
    screen:addLabel()
        :setText("powered by CogCorp")
        :setPosition(2, 2)
        :setForeground(colors.lightGray)
    
    -- Content area (scrollable)
    local content = screen:addScrollFrame()
        :setSize("{parent.width}", "{parent.height - 3}")
        :setPosition(1, 4)
        :setBackground(colors.black)
        :setScrollBarBackgroundColor(colors.gray)
        :setScrollBarColor(colors.lightGray)
    
    local yPos = 2
    
    -- Title
    local titleLabel = content:addLabel()
        :setText(tab.title or "City Information")
        :setPosition(layout.margin, yPos)
        :setForeground(colors.orange)
    yPos = yPos + 2
    
    -- Content text (with wrapping and scrolling)
    local contentLabel = content:addLabel()
        :setText(tab.content or "No information available.")
        :setPosition(layout.margin, yPos)
        :setSize(layout.width - 4, 1)
        :setForeground(colors.white)
        :setAutoSize(false)  -- Wrap text and expand vertically
    
    -- Back button (positioned dynamically after text)
    local backBtn = content:addButton()
        :setText("Back")
        :setPosition(layout.margin, yPos + 10)  -- Initial position, will be updated
        :setSize(layout.buttonWidth, layout.buttonHeight)
        :setBackground(colors.gray)
        :setForeground(colors.white)
        :onClick(function()
            if screen and screen.destroy then
                screen:destroy()
            end
            if onBack then
                onBack()
            end
            return true
        end)
    
    -- Update back button position based on text height
    local basalt = require("basalt")
    basalt.schedule(function()
        local wrappedLines = contentLabel:getWrappedText()
        local textHeight = #wrappedLines
        backBtn:setPosition(layout.margin, yPos + textHeight + 2)
    end)
    
    return screen
end

-- ============================================================================
-- Info Screen
-- ============================================================================
local Info = {}
-- Network, Utils, InfoTabDetail modules loaded above

function Info.create(mainFrame, account, onBack)
    local layout = Utils.getResponsiveLayout()
    local screen = mainFrame:addFrame()
        :setSize("{parent.width}", "{parent.height}")
        :setPosition(1, 1)
        :setBackground(colors.black)
    
    -- Simple header (no logout for citizen client)
    screen:addLabel()
        :setText("Rotaria City")
        :setPosition(2, 1)
        :setForeground(colors.orange)
    
    screen:addLabel()
        :setText("powered by CogCorp")
        :setPosition(2, 2)
        :setForeground(colors.lightGray)
    
    -- Content area (scrollable)
    local content = screen:addScrollFrame()
        :setSize("{parent.width}", "{parent.height - 3}")
        :setPosition(1, 4)
        :setBackground(colors.black)
        :setScrollBarBackgroundColor(colors.gray)
        :setScrollBarColor(colors.lightGray)
    
    local yPos = 2
    
    -- Title
    local titleLabel = content:addLabel()
        :setText("City Information")
        :setPosition(layout.margin, yPos)
        :setForeground(colors.orange)
    yPos = yPos + 2
    
    -- Status label
    local statusLabel = content:addLabel()
        :setText("Loading tabs...")
        :setPosition(layout.margin, yPos)
        :setForeground(colors.yellow)
    yPos = yPos + 2
    
    local tabs = {}
    local tabButtons = {}
    local backBtn = nil
    
    -- Function to create tab buttons
    local function createTabButtons()
        -- Clear existing buttons
        for _, btn in ipairs(tabButtons) do
            if btn and btn.destroy then
                btn:destroy()
            end
        end
        tabButtons = {}
        
        -- Destroy back button if it exists
        if backBtn and backBtn.destroy then
            backBtn:destroy()
            backBtn = nil
        end
        
        if #tabs == 0 then
            statusLabel:setText("No information tabs available")
                :setForeground(colors.red)
            -- Create back button
            backBtn = content:addButton()
                :setText("Back")
                :setPosition(layout.margin, yPos + 2)
                :setSize(layout.buttonWidth, layout.buttonHeight)
                :setBackground(colors.gray)
                :setForeground(colors.white)
                :onClick(function()
                    if screen and screen.destroy then
                        screen:destroy()
                    end
                    if onBack then
                        onBack()
                    end
                    return true
                end)
            return
        end
        
        statusLabel:setText("Select an information tab:")
            :setForeground(colors.lightGray)
        
        local buttonY = yPos
        local buttonHeight = 3
        local buttonSpacing = 2
        
        for i, tab in ipairs(tabs) do
            local btn = content:addButton()
                :setText(tab.title or "Untitled")
                :setPosition(layout.margin, buttonY)
                :setSize(layout.width - 4, buttonHeight)
                :setBackground(colors.blue)
                :setForeground(colors.white)
                :onClick(function()
                    -- Open tab detail screen
                    if screen and screen.destroy then
                        screen:destroy()
                    end
                    local detailScreen = InfoTabDetail.create(mainFrame, tab, function()
                        -- Recreate info screen when going back
                        if detailScreen and detailScreen.destroy then
                            detailScreen:destroy()
                        end
                        local newScreen = Info.create(mainFrame, account, onBack)
                        if newScreen then
                            screen = newScreen
                        end
                    end)
                    return true
                end)
            
            table.insert(tabButtons, btn)
            buttonY = buttonY + buttonHeight + buttonSpacing
        end
        
        -- Create back button after all tab buttons
        backBtn = content:addButton()
            :setText("Back")
            :setPosition(layout.margin, buttonY)
            :setSize(layout.buttonWidth, layout.buttonHeight)
            :setBackground(colors.gray)
            :setForeground(colors.white)
            :onClick(function()
                if screen and screen.destroy then
                    screen:destroy()
                end
                if onBack then
                    onBack()
                end
                return true
            end)
    end
    
    -- Function to reload tabs
    local function reloadTabs()
        local basalt = require("basalt")
        basalt.schedule(function()
            local success, tabsData = Network.getCityInfoPublic()
            
            if success and tabsData and #tabsData > 0 then
                tabs = tabsData
                createTabButtons()
            else
                statusLabel:setText("Failed to load city information. Please try again later.")
                    :setForeground(colors.red)
            end
        end)
    end
    
    -- Load city info tabs (no auth required)
    reloadTabs()
    
    return screen
end

-- ============================================================================
-- PlotApplication Screen
-- ============================================================================
local PlotApplication = {}
-- Network, Utils modules loaded above

function PlotApplication.create(mainFrame, account, onBack)
    local layout = Utils.getResponsiveLayout()
    local screen = mainFrame:addFrame()
        :setSize("{parent.width}", "{parent.height}")
        :setPosition(1, 1)
        :setBackground(colors.black)
    
    -- Simple header (no logout for citizen client)
    screen:addLabel()
        :setText("Rotaria City")
        :setPosition(2, 1)
        :setForeground(colors.orange)
    
    screen:addLabel()
        :setText("powered by CogCorp")
        :setPosition(2, 2)
        :setForeground(colors.lightGray)
    
    -- Content area (scrollable)
    local content = screen:addScrollFrame()
        :setSize("{parent.width}", "{parent.height - 3}")
        :setPosition(1, 4)
        :setBackground(colors.black)
        :setScrollBarBackgroundColor(colors.gray)
        :setScrollBarColor(colors.lightGray)
    
    local yPos = 2
    
    -- Title
    content:addLabel()
        :setText("Plot Application Form")
        :setPosition(layout.margin, yPos)
        :setForeground(colors.orange)
    yPos = yPos + 2
    
    -- In-game name
    content:addLabel()
        :setText("In-game name:")
        :setPosition(layout.margin, yPos)
        :setForeground(colors.orange)
    yPos = yPos + 1
    local inGameNameInput = content:addInput()
        :setPosition(layout.margin, yPos)
        :setSize(layout.inputWidth, 1)
        :setBackground(colors.gray)
        :setForeground(colors.white)
    yPos = yPos + 2
    
    -- Plot number/location
    content:addLabel()
        :setText("Plot number / location:")
        :setPosition(layout.margin, yPos)
        :setForeground(colors.orange)
    yPos = yPos + 1
    local plotNumberInput = content:addInput()
        :setPosition(layout.margin, yPos)
        :setSize(layout.inputWidth, 1)
        :setBackground(colors.gray)
        :setForeground(colors.white)
    yPos = yPos + 2
    
    -- What the build will be
    content:addLabel()
        :setText("What the build will be:")
        :setPosition(layout.margin, yPos)
        :setForeground(colors.orange)
    yPos = yPos + 1
    local buildDescriptionInput = content:addTextBox()
        :setPosition(layout.margin, yPos)
        :setSize(layout.inputWidth, 3)
        :setBackground(colors.gray)
        :setForeground(colors.white)
    yPos = yPos + 4
    
    -- Estimated size & style
    content:addLabel()
        :setText("Estimated size & style:")
        :setPosition(layout.margin, yPos)
        :setForeground(colors.orange)
    yPos = yPos + 1
    local estimatedSizeInput = content:addTextBox()
        :setPosition(layout.margin, yPos)
        :setSize(layout.inputWidth, 2)
        :setBackground(colors.gray)
        :setForeground(colors.white)
    yPos = yPos + 3
    
    -- Why they want that specific plot
    content:addLabel()
        :setText("Why you want that specific plot:")
        :setPosition(layout.margin, yPos)
        :setForeground(colors.orange)
    yPos = yPos + 1
    local reasonInput = content:addTextBox()
        :setPosition(layout.margin, yPos)
        :setSize(layout.inputWidth, 3)
        :setBackground(colors.gray)
        :setForeground(colors.white)
    yPos = yPos + 4
    
    -- Status label
    local statusLabel = content:addLabel()
        :setText("")
        :setPosition(layout.margin, yPos)
        :setSize(layout.inputWidth, 1)
        :setForeground(colors.red)
    yPos = yPos + 2
    
    -- Submit button
    local submitBtn = content:addButton()
        :setText("Submit Application")
        :setPosition(layout.margin, yPos)
        :setSize(layout.buttonWidth, layout.buttonHeight)
        :setBackground(colors.green)
        :setForeground(colors.white)
        :onClick(function()
            local inGameName = inGameNameInput:getText() or ""
            local plotNumber = plotNumberInput:getText() or ""
            local buildDescription = buildDescriptionInput:getText() or ""
            local estimatedSize = estimatedSizeInput:getText() or ""
            local reason = reasonInput:getText() or ""
            
            if not inGameName or inGameName == "" then
                statusLabel:setText("In-game name cannot be empty")
                    :setForeground(colors.red)
                return
            end
            
            if not plotNumber or plotNumber == "" then
                statusLabel:setText("Plot number/location cannot be empty")
                    :setForeground(colors.red)
                return
            end
            
            statusLabel:setText("Submitting application...")
                :setForeground(colors.yellow)
            
            local basalt = require("basalt")
            basalt.schedule(function()
                -- No authentication required for citizen plot applications
                local success, result = Network.createPlotApplicationPublic(
                    inGameName,
                    plotNumber,
                    buildDescription,
                    estimatedSize,
                    reason
                )
                
                if success then
                    statusLabel:setText("Application submitted successfully!")
                        :setForeground(colors.green)
                    sleep(2)
                    if screen and screen.destroy then
                        screen:destroy()
                    end
                    if onBack then
                        onBack()
                    end
                else
                    local errorMsg = tostring(result or "Unknown error")
                    statusLabel:setText("Error: " .. errorMsg)
                        :setForeground(colors.red)
                end
            end)
        end)
    
    -- Back button
    local backBtn = content:addButton()
        :setText("Back")
        :setPosition(layout.margin + layout.buttonWidth + 2, yPos)
        :setSize(layout.buttonWidth, layout.buttonHeight)
        :setBackground(colors.gray)
        :setForeground(colors.white)
        :onClick(function()
            if screen and screen.destroy then
                screen:destroy()
            end
            if onBack then
                onBack()
            end
        end)
    
    return screen
end

-- ============================================================================
-- Main Client Entry Point
-- ============================================================================
local Client = {}

function Client.runClient()
local basalt = require("basalt")

-- Check if basalt is available
if not basalt then
    error("Basalt library not found. Please install Basalt2.")
end

-- Network, Info, PlotApplication modules loaded above

-- Create main frame for terminal
local main = basalt.getMainFrame()
    :setBackground(colors.black)

local currentScreen = nil
local dashboardScreen = nil

-- Create simple dashboard without header (no logout needed)
local function createDashboard()
    local layout = Utils.getResponsiveLayout()
    local screen = main:addFrame()
        :setSize("{parent.width}", "{parent.height}")
        :setPosition(1, 1)
        :setBackground(colors.black)
    
    -- Title
    screen:addLabel()
        :setText("Rotaria City")
        :setPosition(2, 2)
        :setForeground(colors.orange)
    
    screen:addLabel()
        :setText("powered by CogCorp")
        :setPosition(2, 3)
        :setForeground(colors.lightGray)
    
    -- Welcome message
    screen:addLabel()
        :setText("Welcome, Citizen!")
        :setPosition(layout.margin, 5)
        :setForeground(colors.lightGray)
    
    -- Buttons
    local buttonStartY = 7
    local buttonSpacing = 3
    local buttonWidth = math.max(15, math.floor(layout.width / 2) - 2)
    local buttonHeight = 3
    
    -- Info button
    local infoBtn = screen:addButton()
        :setText("Info")
        :setPosition(layout.margin, buttonStartY)
        :setSize(buttonWidth, buttonHeight)
        :setBackground(colors.blue)
        :setForeground(colors.white)
        :onClick(function()
            if dashboardScreen then
                dashboardScreen:setVisible(false)
            end
            showInfo()
        end)
    
    -- Plot Application button
    local plotBtn = screen:addButton()
        :setText("Plot Application")
        :setPosition(layout.margin, buttonStartY + buttonSpacing)
        :setSize(buttonWidth, buttonHeight)
        :setBackground(colors.green)
        :setForeground(colors.white)
        :onClick(function()
            if dashboardScreen then
                dashboardScreen:setVisible(false)
            end
            showPlotApplication()
        end)
    
    return screen
end

-- Show info screen (no auth required)
function showInfo()
    if currentScreen and currentScreen ~= dashboardScreen and currentScreen.destroy then
        currentScreen:destroy()
    end
    
    -- Create a dummy account object for the info screen (it won't use it for auth)
    local dummyAccount = { id = 0 }
    
    currentScreen = Info.create(main, dummyAccount, function()
        if dashboardScreen then
            dashboardScreen:setVisible(true)
        end
        currentScreen = dashboardScreen
    end)
end

-- Show plot application screen (no auth required)
function showPlotApplication()
    if currentScreen and currentScreen ~= dashboardScreen and currentScreen.destroy then
        currentScreen:destroy()
    end
    
    -- Create a dummy account object (won't be used for auth)
    local dummyAccount = { id = 0 }
    
    currentScreen = PlotApplication.create(main, dummyAccount, function()
        if dashboardScreen then
            dashboardScreen:setVisible(true)
        end
        currentScreen = dashboardScreen
    end)
end

-- Start with dashboard
local success, err = pcall(function()
    dashboardScreen = createDashboard()
    currentScreen = dashboardScreen
    
    -- Run the GUI
    basalt.run()
end)

if not success then
    print("Fatal error occurred: " .. tostring(err))
end

end

return Client
