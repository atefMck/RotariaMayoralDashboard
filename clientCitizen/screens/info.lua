-- City Info Screen (Tabbed - Buttons)
local Info = {}
local Network = require("network")
local Utils = require("utils")
local InfoTabDetail = require("screens/info_tab_detail")

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

return Info

