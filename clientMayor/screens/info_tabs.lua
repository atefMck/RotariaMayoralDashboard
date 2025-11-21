-- Info Tabs Management Screen (Admin only)
local InfoTabs = {}
local Network = require("network")
local Utils = require("utils")
local EditInfoTab = require("screens/edit_info_tab")

function InfoTabs.create(mainFrame, account, onBack)
    local layout = Utils.getResponsiveLayout()
    local screen = mainFrame:addFrame()
        :setSize("{parent.width}", "{parent.height}")
        :setPosition(1, 1)
        :setBackground(colors.black)
    
    -- Simple header (same as plot_review.lua)
    screen:addLabel()
        :setText("Rotaria City")
        :setPosition(2, 1)
        :setForeground(colors.orange)
    
    screen:addLabel()
        :setText("powered by CogCorp")
        :setPosition(2, 2)
        :setForeground(colors.lightGray)
    
    -- Logout button
    local logoutBtn = screen:addButton()
        :setText("Logout")
        :setPosition("{parent.width - 9}", 2)
        :setSize(8, 1)
        :setBackground(colors.red)
        :setForeground(colors.white)
        :onClick(function()
            if onBack then
                onBack()
            end
            return true
        end)
    
    -- Content area (scrollable, positioned below header which is 3 lines tall)
    local content = screen:addScrollFrame()
        :setSize("{parent.width}", "{parent.height - 3}")
        :setPosition(1, 4)
        :setBackground(colors.black)
        :setScrollBarBackgroundColor(colors.gray)
        :setScrollBarColor(colors.lightGray)
    
    local yPos = 2
    
    -- Title
    content:addLabel()
        :setText("Info Tabs Management")
        :setPosition(layout.margin, yPos)
        :setForeground(colors.orange)
    yPos = yPos + 2
    
    -- Tab list
    local tabList = content:addList()
        :setPosition(layout.margin, yPos)
        :setSize(layout.width - 4, math.max(8, layout.height - 20))
        :setBackground(colors.gray)
        :setForeground(colors.white)
    yPos = yPos + math.max(8, layout.height - 20) + 2
    
    -- Details frame (not scrollable - parent handles scrolling)
    local detailsFrame = content:addFrame()
        :setPosition(layout.margin, yPos)
        :setSize(layout.width - 4, 12)
        :setBackground(colors.black)
        :addBorder(colors.gray)
    yPos = yPos + 12 + 2
    
    -- Details label with text wrapping
    local detailsLabel = detailsFrame:addLabel()
        :setText("Select a tab to view details")
        :setPosition(2, 2)
        :setSize(layout.width - 6, 1)
        :setForeground(colors.lightGray)
        :setAutoSize(false)
    
    -- Action buttons (initially hidden)
    local editBtn = detailsFrame:addButton()
        :setText("Edit")
        :setPosition(2, "{parent.height - 2}")
        :setSize(10, 1)
        :setBackground(colors.blue)
        :setForeground(colors.white)
        :setVisible(false)
    
    local deleteBtn = detailsFrame:addButton()
        :setText("Delete")
        :setPosition(14, "{parent.height - 2}")
        :setSize(10, 1)
        :setBackground(colors.red)
        :setForeground(colors.white)
        :setVisible(false)
    
    -- Status label
    local statusLabel = content:addLabel()
        :setText("Loading tabs...")
        :setPosition(layout.margin, yPos)
        :setForeground(colors.yellow)
    yPos = yPos + 2
    
    -- Buttons
    local createBtn = content:addButton()
        :setText("Create New Tab")
        :setPosition(layout.margin, yPos)
        :setSize(layout.buttonWidth, layout.buttonHeight)
        :setBackground(colors.green)
        :setForeground(colors.white)
    
    local backBtn = content:addButton()
        :setText("Back")
        :setPosition(layout.margin + layout.buttonWidth + 2, yPos)
        :setSize(layout.buttonWidth, layout.buttonHeight)
        :setBackground(colors.gray)
        :setForeground(colors.white)
        :onClick(function()
            if onBack then
                onBack()
            end
            return true
        end)
    
    local tabs = {}
    local selectedTab = nil
    
    -- Function to recreate this screen (for nested screens)
    local function recreateScreen()
        if screen and screen.destroy then
            screen:destroy()
        end
        local newScreen = InfoTabs.create(mainFrame, account, onBack)
        if newScreen then
            screen = newScreen
        end
    end
    
    -- Function to display tab details
    local function showTabDetails(tab)
        selectedTab = tab
        local details = "Title: " .. (tab.title or "Untitled") .. "\n"
        details = details .. "ID: " .. (tab.id or "N/A") .. "\n"
        details = details .. "Content: " .. (tab.content or "No content")
        
        detailsLabel:setText(details)
            :setForeground(colors.white)
            :setSize(layout.width - 6, 1)
            :setAutoSize(false)
        
        editBtn:setVisible(true)
        deleteBtn:setVisible(true)
    end
    
    -- Function to reload tabs
    local function reloadTabs()
        local basalt = require("basalt")
        basalt.schedule(function()
            local success, tabsData = Network.getAllInfoTabs(account.id)
            
            if success and tabsData then
                tabs = tabsData
                tabList:clear()
                for _, tab in ipairs(tabs) do
                    tabList:addItem(tab.title or "Untitled")
                end
                statusLabel:setText("Total tabs: " .. #tabs)
                    :setForeground(colors.green)
                detailsLabel:setText("Select a tab to view details")
                    :setForeground(colors.lightGray)
                    :setSize(layout.width - 6, 1)
                    :setAutoSize(false)
                editBtn:setVisible(false)
                deleteBtn:setVisible(false)
                selectedTab = nil
            else
                statusLabel:setText("Failed to load tabs: " .. tostring(tabsData or "Unknown error"))
                    :setForeground(colors.red)
            end
        end)
    end
    
    -- Tab list selection
    tabList:onSelect(function(self, index, item)
        if tabs[index] then
            showTabDetails(tabs[index])
        end
        return true
    end)
    
    -- Create button
    createBtn:onClick(function()
        if screen and screen.destroy then
            screen:destroy()
        end
        EditInfoTab.create(mainFrame, account, nil, function()
            -- Go back to info tabs screen (recreate it)
            recreateScreen()
        end)
        return true
    end)
    
    -- Edit button
    editBtn:onClick(function()
        if selectedTab then
            if screen and screen.destroy then
                screen:destroy()
            end
            EditInfoTab.create(mainFrame, account, selectedTab, function()
                -- Go back to info tabs screen (recreate it)
                recreateScreen()
            end)
        end
        return true
    end)
    
    -- Delete button
    deleteBtn:onClick(function()
        if selectedTab then
            statusLabel:setText("Deleting tab...")
                :setForeground(colors.yellow)
            
            local basalt = require("basalt")
            basalt.schedule(function()
                local success, result = Network.deleteInfoTab(account.id, selectedTab.id)
                
                if success then
                    statusLabel:setText("Tab deleted successfully!")
                        :setForeground(colors.green)
                    sleep(1)
                    reloadTabs()
                else
                    statusLabel:setText("Error: " .. tostring(result or "Unknown error"))
                        :setForeground(colors.red)
                end
            end)
        end
        return true
    end)
    
    -- Load tabs on startup
    reloadTabs()
    
    return screen
end

return InfoTabs

