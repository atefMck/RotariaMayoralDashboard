-- Mayor Client Main File (Login Required)

local basalt = require("basalt")

-- Check if basalt is available
if not basalt then
    error("Basalt library not found. Please install Basalt2.")
end

local Network = require("network")
local Login = require("screens/login")
local MayorDashboard = require("screens/mayor_dashboard")
local UserList = require("screens/user_list")
local PlotReview = require("screens/plot_review")
local CreateMayor = require("screens/create_mayor")
local InfoTabs = require("screens/info_tabs")

-- Create main frame for terminal
local main = basalt.getMainFrame()
    :setBackground(colors.black)

local currentAccount = nil
local currentScreen = nil
local dashboardScreen = nil

-- Forward declarations
local showLogin, showDashboard, showUserList, showPlotReview, showCreateMayor, showInfoTabs

-- Show login screen
showLogin = function()
    currentAccount = nil
    dashboardScreen = nil
    
    if currentScreen and currentScreen.destroy then
        currentScreen:destroy()
    end
    
    currentScreen = Login.create(main, function(account)
        currentAccount = account
        showDashboard()
    end, function()
        showLogin()
    end)
end

-- Show mayor dashboard
showDashboard = function()
    if not currentAccount then
        showLogin()
        return
    end
    
    -- Hide current screen
    if currentScreen and currentScreen ~= dashboardScreen and currentScreen.destroy then
        currentScreen:destroy()
    end
    
    -- Destroy old dashboard if it exists
    if dashboardScreen and dashboardScreen.destroy then
        dashboardScreen:destroy()
        dashboardScreen = nil
    end
    
    -- Create mayor dashboard with callbacks
    -- Note: We create a local variable first, then update dashboardScreen
    local newDashboard = MayorDashboard.create(
        main, 
        currentAccount, 
        function()
            showLogin()
        end,
        function()
            -- Create Mayor callback
            if newDashboard then
                newDashboard:setVisible(false)
            end
            showCreateMayor()
        end,
        function()
            -- All Mayors callback
            if newDashboard then
                newDashboard:setVisible(false)
            end
            showUserList()
        end,
        function()
            -- Plots callback
            if newDashboard then
                newDashboard:setVisible(false)
            end
            showPlotReview()
        end,
        function()
            -- Info Tabs callback
            if newDashboard then
                newDashboard:setVisible(false)
            end
            showInfoTabs()
        end
    )
    
    dashboardScreen = newDashboard
    currentScreen = dashboardScreen
end

-- Show user list screen
showUserList = function()
    if not currentAccount or currentAccount.accountType ~= "admin" then
        showLogin()
        return
    end
    
    if currentScreen and currentScreen ~= dashboardScreen and currentScreen.destroy then
        currentScreen:destroy()
    end
    
    currentScreen = UserList.create(main, currentAccount, function()
        -- Always recreate dashboard to ensure it exists
        showDashboard()
    end)
end

-- Show plot review screen
showPlotReview = function()
    if not currentAccount or currentAccount.accountType ~= "admin" then
        showLogin()
        return
    end
    
    if currentScreen and currentScreen ~= dashboardScreen and currentScreen.destroy then
        currentScreen:destroy()
    end
    
    currentScreen = PlotReview.create(main, currentAccount, function()
        -- Always recreate dashboard to ensure it exists
        showDashboard()
    end)
end

-- Show create mayor screen
showCreateMayor = function()
    if not currentAccount or currentAccount.accountType ~= "admin" then
        showLogin()
        return
    end
    
    if currentScreen and currentScreen ~= dashboardScreen and currentScreen.destroy then
        currentScreen:destroy()
    end
    
    currentScreen = CreateMayor.create(main, currentAccount, function()
        -- Always recreate dashboard to ensure it exists
        showDashboard()
    end)
end

-- Show info tabs management screen
showInfoTabs = function()
    if not currentAccount or currentAccount.accountType ~= "admin" then
        showLogin()
        return
    end
    
    if currentScreen and currentScreen ~= dashboardScreen and currentScreen.destroy then
        currentScreen:destroy()
    end
    
    currentScreen = InfoTabs.create(main, currentAccount, function()
        -- Go back to dashboard
        showDashboard()
    end)
end

-- Start with login
local success, err = pcall(function()
    showLogin()
    
    -- Run the GUI
    basalt.run()
end)

if not success then
    print("Fatal error occurred: " .. tostring(err))
end

