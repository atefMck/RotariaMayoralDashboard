-- Citizen Client Main File (No Login Required)

local basalt = require("basalt")

-- Check if basalt is available
if not basalt then
    error("Basalt library not found. Please install Basalt2.")
end

local Network = require("network")
local Info = require("screens/info")
local PlotApplication = require("screens/plot_application")

-- Create main frame for terminal
local main = basalt.getMainFrame()
    :setBackground(colors.black)

local currentScreen = nil
local dashboardScreen = nil

-- Create simple dashboard without header (no logout needed)
local function createDashboard()
    local layout = require("utils").getResponsiveLayout()
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

