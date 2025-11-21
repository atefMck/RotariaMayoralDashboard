-- Mayor Dashboard Screen
local MayorDashboard = {}
local Header = require("components.header")
local Utils = require("utils")

function MayorDashboard.create(mainFrame, account, onLogout, onCreateMayorClick, onAllMayorsClick, onPlotsClick, onInfoTabsClick)
    local layout = Utils.getResponsiveLayout()
    local screen = mainFrame:addFrame()
        :setSize("{parent.width}", "{parent.height}")
        :setPosition(1, 1)
        :setBackground(colors.black)
    
    -- Create header
    local header = Header.create(screen, onLogout)
    
    -- Content area (positioned below header which is 3 lines tall)
    local content = screen:addFrame()
        :setSize("{parent.width}", "{parent.height - 3}")
        :setPosition(1, 4)
        :setBackground(colors.black)
    
    -- Title
    content:addLabel()
        :setText("Mayor Dashboard")
        :setPosition(layout.margin, 2)
        :setForeground(colors.orange)
    
    -- Welcome message
    content:addLabel()
        :setText("Welcome, Mayor " .. (account.username or "Admin") .. "!")
        :setPosition(layout.margin, 4)
        :setForeground(colors.lightGray)
    
    -- Buttons
    local buttonStartY = 6
    local buttonSpacing = 3
    local buttonWidth = math.max(15, math.floor(layout.width / 2) - 2)
    local buttonHeight = 3
    
    -- Create Mayor Account button
    local createMayorBtn = content:addButton()
        :setText("Create Mayor Account")
        :setPosition(layout.margin, buttonStartY)
        :setSize(buttonWidth, buttonHeight)
        :setBackground(colors.blue)
        :setForeground(colors.white)
    
    if onCreateMayorClick and type(onCreateMayorClick) == "function" then
        createMayorBtn:onClick(function()
            onCreateMayorClick()
            return true
        end)
    end
    
    -- All Mayor Accounts button
    local allMayorsBtn = content:addButton()
        :setText("All Mayor Accounts")
        :setPosition(layout.margin + buttonWidth + 2, buttonStartY)
        :setSize(buttonWidth, buttonHeight)
        :setBackground(colors.orange)
        :setForeground(colors.white)
    
    if onAllMayorsClick and type(onAllMayorsClick) == "function" then
        allMayorsBtn:onClick(function()
            onAllMayorsClick()
            return true
        end)
    end
    
    -- Plot Applications button
    local plotsBtn = content:addButton()
        :setText("Plot Applications")
        :setPosition(layout.margin, buttonStartY + buttonSpacing)
        :setSize(buttonWidth, buttonHeight)
        :setBackground(colors.green)
        :setForeground(colors.white)
    
    if onPlotsClick and type(onPlotsClick) == "function" then
        plotsBtn:onClick(function()
            onPlotsClick()
            return true
        end)
    end
    
    -- Info Tabs button
    local infoTabsBtn = content:addButton()
        :setText("Info Tabs")
        :setPosition(layout.margin + buttonWidth + 2, buttonStartY + buttonSpacing)
        :setSize(buttonWidth, buttonHeight)
        :setBackground(colors.cyan)
        :setForeground(colors.white)
    
    if onInfoTabsClick and type(onInfoTabsClick) == "function" then
        infoTabsBtn:onClick(function()
            onInfoTabsClick()
            return true
        end)
    end
    
    -- Return screen object
    local screenObj = {
        frame = screen,
        setVisible = function(visible)
            if screen and screen.setVisible then
                local success, err = pcall(function()
                    screen:setVisible(visible ~= nil and visible or true)
                end)
                if not success then
                    -- Screen might be destroyed, ignore error
                end
            end
        end,
        destroy = function()
            if screen and screen.destroy then
                screen:destroy()
            end
        end
    }
    
    return screenObj
end

return MayorDashboard

