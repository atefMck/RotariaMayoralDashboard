-- Bundled Rotaria City Mayor Client
-- This file contains all mayor client modules bundled together

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

-- ============================================================================
-- Header Component
-- ============================================================================
local Header = {}
-- Utils module loaded above

function Header.create(parent, onLogout)
    local layout = Utils.getResponsiveLayout()
    
    local header = parent:addFrame()
        :setSize("{parent.width}", 3)
        :setPosition(1, 1)
        :setBackground(colors.gray)
    
    -- Rotaria City title in orange
    local title = header:addLabel()
        :setText("Rotaria City")
        :setPosition(2, 2)
        :setForeground(colors.orange)
        :setBackground(colors.gray)
    
    -- Powered by CogCorp
    local poweredBy = header:addLabel()
        :setText("powered by CogCorp")
        :setPosition(2, 3)
        :setForeground(colors.lightGray)
        :setBackground(colors.gray)
    
    -- Logout button
    local logoutBtn = header:addButton()
        :setText("Logout")
        :setPosition("{parent.width - 9}", 2)
        :setSize(8, 1)
        :setBackground(colors.red)
        :setForeground(colors.white)
        :onClick(function()
            if onLogout then
                onLogout()
            end
            return true
        end)
    
    return header
end

-- ============================================================================
-- Login Screen
-- ============================================================================
local Login = {}
-- Network, Utils modules loaded above

function Login.create(mainFrame, onSuccess, onBackToLogin)
    local layout = Utils.getResponsiveLayout()
    local screen = mainFrame:addFrame()
        :setSize("{parent.width}", "{parent.height}")
        :setPosition(1, 1)
        :setBackground(colors.black)
    
    -- Calculate positions
    local titleY = math.max(2, math.floor(layout.height / 4))
    local usernameLabelY = titleY + 2
    local usernameInputY = usernameLabelY + 1
    local passwordLabelY = usernameInputY + 2
    local passwordInputY = passwordLabelY + 1
    local statusY = passwordInputY + 2
    local buttonY = math.max(statusY + 2, layout.height - 3)
    
    -- Title
    screen:addLabel()
        :setText("Rotaria City Login")
        :setPosition(layout.margin, titleY)
        :setForeground(colors.orange)
    
    -- Username input
    screen:addLabel()
        :setText("Username:")
        :setPosition(layout.margin, usernameLabelY)
        :setForeground(colors.lightGray)
    local usernameInput = screen:addInput()
        :setPosition(layout.margin, usernameInputY)
        :setSize(layout.inputWidth, layout.inputHeight)
        :setBackground(colors.gray)
        :setForeground(colors.white)
    
    -- Password input
    screen:addLabel()
        :setText("Password:")
        :setPosition(layout.margin, passwordLabelY)
        :setForeground(colors.lightGray)
    local passwordInput = screen:addInput()
        :setPosition(layout.margin, passwordInputY)
        :setSize(layout.inputWidth, layout.inputHeight)
        :setBackground(colors.gray)
        :setForeground(colors.white)
        :setReplaceChar("*")
    
    -- Status label
    local statusLabel = screen:addLabel()
        :setText("")
        :setPosition(layout.margin, statusY)
        :setSize(layout.inputWidth, 1)
        :setForeground(colors.red)
    
    -- Login button
    local loginBtn = screen:addButton()
        :setText("Login")
        :setPosition(layout.margin, buttonY)
        :setSize(layout.buttonWidth, layout.buttonHeight)
        :setBackground(colors.green)
        :setForeground(colors.white)
        :onClick(function()
            local username = usernameInput:getText() or ""
            local password = passwordInput:getText() or ""
            
            if not username or username == "" then
                statusLabel:setText("Username cannot be empty")
                    :setForeground(colors.red)
                return
            end
            
            if not password or password == "" then
                statusLabel:setText("Password cannot be empty")
                    :setForeground(colors.red)
                return
            end
            
            statusLabel:setText("Logging in...")
                :setForeground(colors.yellow)
            
            local basalt = require("basalt")
            basalt.schedule(function()
                local success, result = Network.login(username, password)
                
                if success then
                    statusLabel:setText("Login successful!")
                        :setForeground(colors.green)
                    sleep(0.5)
                    if onSuccess then
                        onSuccess(result)
                    end
                else
                    local errorMsg = tostring(result or "Unknown error")
                    statusLabel:setText("Error: " .. errorMsg)
                        :setForeground(colors.red)
                end
            end)
        end)
    
    
    return screen
end

-- ============================================================================
-- CreateMayor Screen
-- ============================================================================
local CreateMayor = {}
-- Header, Network, Utils modules loaded above

function CreateMayor.create(mainFrame, account, onBack)
    local layout = Utils.getResponsiveLayout()
    local screen = mainFrame:addFrame()
        :setSize("{parent.width}", "{parent.height}")
        :setPosition(1, 1)
        :setBackground(colors.black)
    
    -- Create header
    local header = Header.create(screen, function()
        if onBack then
            onBack()
        end
    end)
    
    -- Content area (positioned below header which is 3 lines tall)
    local content = screen:addScrollFrame()
        :setSize("{parent.width}", "{parent.height - 3}")
        :setPosition(1, 4)
        :setBackground(colors.black)
        :setScrollBarBackgroundColor(colors.gray)
        :setScrollBarColor(colors.lightGray)
    
    local yPos = 2
    
    -- Title
    content:addLabel()
        :setText("Create Mayor Account")
        :setPosition(layout.margin, yPos)
        :setForeground(colors.orange)
    yPos = yPos + 2
    
    -- Username input
    content:addLabel()
        :setText("Username:")
        :setPosition(layout.margin, yPos)
        :setForeground(colors.orange)
    yPos = yPos + 1
    local usernameInput = content:addInput()
        :setPosition(layout.margin, yPos)
        :setSize(layout.inputWidth, 1)
        :setBackground(colors.gray)
        :setForeground(colors.white)
    yPos = yPos + 2
    
    -- Password input
    content:addLabel()
        :setText("Password:")
        :setPosition(layout.margin, yPos)
        :setForeground(colors.orange)
    yPos = yPos + 1
    local passwordInput = content:addInput()
        :setPosition(layout.margin, yPos)
        :setSize(layout.inputWidth, 1)
        :setBackground(colors.gray)
        :setForeground(colors.white)
        :setReplaceChar("*")
    yPos = yPos + 2
    
    -- Confirm Password input
    content:addLabel()
        :setText("Confirm Password:")
        :setPosition(layout.margin, yPos)
        :setForeground(colors.orange)
    yPos = yPos + 1
    local confirmPasswordInput = content:addInput()
        :setPosition(layout.margin, yPos)
        :setSize(layout.inputWidth, 1)
        :setBackground(colors.gray)
        :setForeground(colors.white)
        :setReplaceChar("*")
    yPos = yPos + 3
    
    -- Status label
    local statusLabel = content:addLabel()
        :setText("")
        :setPosition(layout.margin, yPos)
        :setSize(layout.inputWidth, 2)
        :setForeground(colors.red)
    yPos = yPos + 3
    
    -- Create button
    local createBtn = content:addButton()
        :setText("Create Mayor Account")
        :setPosition(layout.margin, yPos)
        :setSize(layout.buttonWidth, layout.buttonHeight)
        :setBackground(colors.green)
        :setForeground(colors.white)
        :onClick(function()
            local username = usernameInput:getText() or ""
            local password = passwordInput:getText() or ""
            local confirmPassword = confirmPasswordInput:getText() or ""
            
            if not username or username == "" then
                statusLabel:setText("Username cannot be empty")
                    :setForeground(colors.red)
                return
            end
            
            if not password or password == "" then
                statusLabel:setText("Password cannot be empty")
                    :setForeground(colors.red)
                return
            end
            
            if password ~= confirmPassword then
                statusLabel:setText("Passwords do not match")
                    :setForeground(colors.red)
                return
            end
            
            statusLabel:setText("Creating account...")
                :setForeground(colors.yellow)
            
            local basalt = require("basalt")
            basalt.schedule(function()
                local success, result = Network.createAccount(username, password, "admin")
                
                if success then
                    statusLabel:setText("Mayor account created successfully!")
                        :setForeground(colors.green)
                    usernameInput:setText("")
                    passwordInput:setText("")
                    confirmPasswordInput:setText("")
                    sleep(2)
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
            if onBack then
                onBack()
            end
        end)
    
    return screen
end

-- ============================================================================
-- EditInfoTab Screen
-- ============================================================================
local EditInfoTab = {}
-- Network, Utils modules loaded above

function EditInfoTab.create(mainFrame, account, tab, onBack)
    local layout = Utils.getResponsiveLayout()
    local isEdit = tab ~= nil
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
        :setText(isEdit and "Edit Info Tab" or "Create Info Tab")
        :setPosition(layout.margin, yPos)
        :setForeground(colors.orange)
    yPos = yPos + 2
    
    -- Title input
    content:addLabel()
        :setText("Title:")
        :setPosition(layout.margin, yPos)
        :setForeground(colors.orange)
    yPos = yPos + 1
    local titleInput = content:addInput()
        :setPosition(layout.margin, yPos)
        :setSize(layout.inputWidth, 1)
        :setBackground(colors.gray)
        :setForeground(colors.white)
    if tab and tab.title then
        titleInput:setText(tab.title)
    end
    yPos = yPos + 2
    
    -- Content input
    content:addLabel()
        :setText("Content:")
        :setPosition(layout.margin, yPos)
        :setForeground(colors.orange)
    yPos = yPos + 1
    local contentInput = content:addTextBox()
        :setPosition(layout.margin, yPos)
        :setSize(layout.inputWidth, 8)
        :setBackground(colors.gray)
        :setForeground(colors.white)
    if tab and tab.content then
        contentInput:setText(tab.content)
    end
    yPos = yPos + 10
    
    -- Status label
    local statusLabel = content:addLabel()
        :setText("")
        :setPosition(layout.margin, yPos)
        :setSize(layout.inputWidth, 1)
        :setForeground(colors.red)
    yPos = yPos + 2
    
    -- Buttons
    local saveBtn = content:addButton()
        :setText(isEdit and "Update Tab" or "Create Tab")
        :setPosition(layout.margin, yPos)
        :setSize(layout.buttonWidth, layout.buttonHeight)
        :setBackground(colors.green)
        :setForeground(colors.white)
    
    local backBtn = content:addButton()
        :setText("Cancel")
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
    
    -- Save button handler
    saveBtn:onClick(function()
        local title = titleInput:getText() or ""
        local contentText = contentInput:getText() or ""
        
        if title == "" then
            statusLabel:setText("Title cannot be empty")
                :setForeground(colors.red)
            return true
        end
        
        statusLabel:setText(isEdit and "Updating tab..." or "Creating tab...")
            :setForeground(colors.yellow)
        
        local basalt = require("basalt")
        basalt.schedule(function()
            local success, result
            if isEdit then
                success, result = Network.updateInfoTab(account.id, tab.id, title, contentText)
            else
                success, result = Network.createInfoTab(account.id, title, contentText)
            end
            
            if success then
                statusLabel:setText(isEdit and "Tab updated successfully!" or "Tab created successfully!")
                    :setForeground(colors.green)
                sleep(1)
                if onBack then
                    onBack()
                end
            else
                statusLabel:setText("Error: " .. tostring(result or "Unknown error"))
                    :setForeground(colors.red)
            end
        end)
        return true
    end)
    
    return screen
end

-- ============================================================================
-- InfoTabs Screen
-- ============================================================================
local InfoTabs = {}
-- Network, Utils, EditInfoTab modules loaded above

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

-- ============================================================================
-- UserList Screen
-- ============================================================================
local UserList = {}
-- Network, Utils modules loaded above

function UserList.create(mainFrame, account, onBack)
    local layout = Utils.getResponsiveLayout()
    local screen = mainFrame:addFrame()
        :setSize("{parent.width}", "{parent.height}")
        :setPosition(1, 1)
        :setBackground(colors.black)
    
    -- Simple header (same as plot_application.lua)
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
    
    -- Title (positioned at top of content area)
    content:addLabel()
        :setText("All Mayor Accounts")
        :setPosition(layout.margin, yPos)
        :setForeground(colors.orange)
    yPos = yPos + 2
    
    -- User list
    local userList = content:addList()
        :setPosition(layout.margin, yPos)
        :setSize(layout.width - 4, math.max(6, layout.height - 20))
        :setBackground(colors.gray)
        :setForeground(colors.white)
    yPos = yPos + math.max(6, layout.height - 20) + 2
    
    -- Details frame (not scrollable - parent handles scrolling)
    local detailsFrame = content:addFrame()
        :setPosition(layout.margin, yPos)
        :setSize(layout.width - 4, 12)
        :setBackground(colors.black)
        :addBorder(colors.gray)
    yPos = yPos + 12 + 2
    
    -- Details label with text wrapping (autoSize false = wrap text and expand vertically)
    local detailsLabel = detailsFrame:addLabel()
        :setText("Select an account to view details")
        :setPosition(2, 2)
        :setSize(layout.width - 6, 1)  -- Fixed width, height auto-adjusts (no scrollbar needed)
        :setForeground(colors.lightGray)
        :setAutoSize(false)  -- false = wrap text and expand height
    
    -- Delete button (initially hidden) - positioned at bottom of scroll frame
    local deleteBtn = detailsFrame:addButton()
        :setText("Delete Account")
        :setPosition(2, "{parent.height - 2}")
        :setSize(15, 1)
        :setBackground(colors.red)
        :setForeground(colors.white)
        :setVisible(false)
    
    -- Status label
    local statusLabel = content:addLabel()
        :setText("Loading mayor accounts...")
        :setPosition(layout.margin, yPos)
        :setForeground(colors.yellow)
    yPos = yPos + 2
    
    -- Back button
    local backBtn = content:addButton()
        :setText("Back")
        :setPosition(layout.margin, yPos)
        :setSize(layout.buttonWidth, layout.buttonHeight)
        :setBackground(colors.gray)
        :setForeground(colors.white)
        :onClick(function()
            if onBack then
                onBack()
            end
            return true
        end)
    
    local selectedUser = nil
    local adminUsers = {}
    
    -- Function to reload users
    local function reloadUsers()
        local basalt = require("basalt")
        basalt.schedule(function()
            local success, userListData = Network.getAllUsers(account.id)
            
            if success and userListData then
                -- Filter only admin accounts
                adminUsers = {}
                userList:clear()
                for _, user in ipairs(userListData) do
                    if user.accountType == "admin" then
                        table.insert(adminUsers, user)
                        userList:addItem(user.username)
                    end
                end
                statusLabel:setText("Total mayor accounts: " .. #adminUsers)
                    :setForeground(colors.green)
                selectedUser = nil
                detailsLabel:setText("Select an account to view details")
                    :setForeground(colors.lightGray)
                    :setSize(layout.width - 6, 1)
                    :setAutoSize(false)
                deleteBtn:setVisible(false)
                deleteBtn:setPosition(2, 3)
            else
                statusLabel:setText("Failed to load accounts: " .. tostring(userListData or "Unknown error"))
                    :setForeground(colors.red)
            end
        end)
    end
    
    -- Function to display user details
    local function showUserDetails(user)
        selectedUser = user
        local details = "Username: " .. user.username .. "\n"
        details = details .. "Account Type: Mayor (Admin)\n"
        details = details .. "Account ID: " .. user.id
        
        -- Update label with wrapped text (autoSize false wraps and expands height)
        detailsLabel:setText(details)
            :setForeground(colors.white)
            :setSize(layout.width - 6, 1)  -- Fixed width for wrapping
            :setAutoSize(false)  -- Wrap text and expand vertically
        
        -- Position delete button below the text
        local wrappedLines = detailsLabel:getWrappedText()
        local textHeight = #wrappedLines
        deleteBtn:setPosition(2, textHeight + 3)
        
        -- Don't allow deleting your own account
        if user.id == account.id then
            deleteBtn:setVisible(false)
        else
            deleteBtn:setVisible(true)
        end
    end
    
    -- Handle user selection
    userList:onSelect(function(self, index, item)
        if index and type(index) == "number" and adminUsers[index] then
            showUserDetails(adminUsers[index])
        end
    end)
    
    -- Delete button handler
    deleteBtn:onClick(function()
        if not selectedUser then return end
        
        statusLabel:setText("Deleting account...")
            :setForeground(colors.yellow)
        
        local basalt = require("basalt")
        basalt.schedule(function()
            local success, result = Network.deleteAccount(account.id, selectedUser.id)
            
            if success then
                statusLabel:setText("Account deleted successfully!")
                    :setForeground(colors.green)
                sleep(1)
                reloadUsers()
            else
                local errorMsg = tostring(result or "Unknown error")
                statusLabel:setText("Error: " .. errorMsg)
                    :setForeground(colors.red)
            end
        end)
    end)
    
    -- Load users initially
    reloadUsers()
    
    return screen
end

-- ============================================================================
-- PlotReview Screen
-- ============================================================================
local PlotReview = {}
-- Network, Utils modules loaded above

function PlotReview.create(mainFrame, account, onBack)
    local layout = Utils.getResponsiveLayout()
    local screen = mainFrame:addFrame()
        :setSize("{parent.width}", "{parent.height}")
        :setPosition(1, 1)
        :setBackground(colors.black)
    
    -- Simple header (same as plot_application.lua)
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
    
    -- Title (positioned at top of content area)
    content:addLabel()
        :setText("Plot Applications Review")
        :setPosition(layout.margin, yPos)
        :setForeground(colors.orange)
    yPos = yPos + 2
    
    -- Plot list
    local plotList = content:addList()
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
    
    -- Details label with text wrapping (autoSize false = wrap text and expand vertically)
    local detailsLabel = detailsFrame:addLabel()
        :setText("Select an application to view details")
        :setPosition(2, 2)
        :setSize(layout.width - 6, 1)  -- Fixed width, height auto-adjusts (no scrollbar needed)
        :setForeground(colors.lightGray)
        :setAutoSize(false)  -- false = wrap text and expand height
    
    -- Action buttons (initially hidden) - positioned dynamically
    local acceptBtn = detailsFrame:addButton()
        :setText("Accept")
        :setPosition(2, "{parent.height - 2}")
        :setSize(10, 1)
        :setBackground(colors.green)
        :setForeground(colors.white)
        :setVisible(false)
    
    local rejectBtn = detailsFrame:addButton()
        :setText("Reject")
        :setPosition(14, "{parent.height - 2}")
        :setSize(10, 1)
        :setBackground(colors.red)
        :setForeground(colors.white)
        :setVisible(false)
    
    -- Status label
    local statusLabel = content:addLabel()
        :setText("Loading applications...")
        :setPosition(layout.margin, yPos)
        :setForeground(colors.yellow)
    yPos = yPos + 2
    
    -- Back button
    local backBtn = content:addButton()
        :setText("Back")
        :setPosition(layout.margin, yPos)
        :setSize(layout.buttonWidth, layout.buttonHeight)
        :setBackground(colors.gray)
        :setForeground(colors.white)
        :onClick(function()
            if onBack then
                onBack()
            end
            return true
        end)
    
    local selectedPlot = nil
    local plots = {}
    
    -- Function to display plot details
    local function showPlotDetails(plot)
        selectedPlot = plot
        local details = "Applicant: " .. (plot.applicantUsername or "Unknown") .. "\n"
        details = details .. "In-game name: " .. (plot.inGameName or "N/A") .. "\n"
        details = details .. "Plot: " .. (plot.plotNumber or "N/A") .. "\n"
        details = details .. "Build: " .. (plot.buildDescription or "N/A") .. "\n"
        details = details .. "Size & Style: " .. (plot.estimatedSize or "N/A") .. "\n"
        details = details .. "Reason: " .. (plot.reason or "N/A")
        
        -- Update label with wrapped text (autoSize false wraps and expands height)
        detailsLabel:setText(details)
            :setForeground(colors.white)
            :setSize(layout.width - 6, 1)  -- Fixed width for wrapping
            :setAutoSize(false)  -- Wrap text and expand vertically
        
        -- Position buttons below the text
        local wrappedLines = detailsLabel:getWrappedText()
        local textHeight = #wrappedLines
        acceptBtn:setPosition(2, textHeight + 3)
        rejectBtn:setPosition(14, textHeight + 3)
        
        if plot.status == "pending" then
            acceptBtn:setVisible(true)
            rejectBtn:setVisible(true)
        else
            acceptBtn:setVisible(false)
            rejectBtn:setVisible(false)
        end
    end
    
    -- Handle plot selection
    plotList:onSelect(function(self, index, item)
        if index and type(index) == "number" and plots[index] then
            showPlotDetails(plots[index])
        end
    end)
    
    -- Accept button handler
    acceptBtn:onClick(function()
        if not selectedPlot then return end
        
        statusLabel:setText("Processing...")
            :setForeground(colors.yellow)
        
        local basalt = require("basalt")
        basalt.schedule(function()
            local success, result = Network.updatePlotStatus(account.id, selectedPlot.id, "approved")
            
            if success then
                    statusLabel:setText("Application approved!")
                        :setForeground(colors.green)
                    sleep(1)
                    -- Reload applications
                    local success2, newPlots = Network.getPlotApplications(account.id)
                    if success2 then
                        plots = {}
                        plotList:clear()
                        for _, plot in ipairs(newPlots) do
                            table.insert(plots, plot)
                            plotList:addItem("Plot " .. plot.plotNumber .. " - " .. plot.applicantUsername)
                        end
                        statusLabel:setText("Total pending: " .. #newPlots)
                            :setForeground(colors.green)
                        detailsLabel:setText("Select an application to view details")
                            :setForeground(colors.lightGray)
                            :setSize(layout.width - 6, 1)
                            :setAutoSize(false)
                        acceptBtn:setVisible(false)
                        rejectBtn:setVisible(false)
                        acceptBtn:setPosition(2, 3)
                        rejectBtn:setPosition(14, 3)
                        selectedPlot = nil
                    end
            else
                statusLabel:setText("Error: " .. tostring(result or "Unknown error"))
                    :setForeground(colors.red)
            end
        end)
    end)
    
    -- Reject button handler
    rejectBtn:onClick(function()
        if not selectedPlot then return end
        
        statusLabel:setText("Processing...")
            :setForeground(colors.yellow)
        
        local basalt = require("basalt")
        basalt.schedule(function()
            local success, result = Network.updatePlotStatus(account.id, selectedPlot.id, "rejected")
            
            if success then
                    statusLabel:setText("Application rejected!")
                        :setForeground(colors.green)
                    sleep(1)
                    -- Reload applications
                    local success2, newPlots = Network.getPlotApplications(account.id)
                    if success2 then
                        plots = {}
                        plotList:clear()
                        for _, plot in ipairs(newPlots) do
                            table.insert(plots, plot)
                            plotList:addItem("Plot " .. plot.plotNumber .. " - " .. plot.applicantUsername)
                        end
                        statusLabel:setText("Total pending: " .. #newPlots)
                            :setForeground(colors.green)
                        detailsLabel:setText("Select an application to view details")
                            :setForeground(colors.lightGray)
                            :setSize(layout.width - 6, 1)
                            :setAutoSize(false)
                        acceptBtn:setVisible(false)
                        rejectBtn:setVisible(false)
                        acceptBtn:setPosition(2, 3)
                        rejectBtn:setPosition(14, 3)
                        selectedPlot = nil
                    end
            else
                statusLabel:setText("Error: " .. tostring(result or "Unknown error"))
                    :setForeground(colors.red)
            end
        end)
    end)
    
    -- Load plot applications
    local basalt = require("basalt")
    basalt.schedule(function()
        local success, plotApplications = Network.getPlotApplications(account.id)
        
        if success and plotApplications then
            plots = {}
            plotList:clear()
            for _, plot in ipairs(plotApplications) do
                table.insert(plots, plot)
                plotList:addItem("Plot " .. plot.plotNumber .. " - " .. plot.applicantUsername)
            end
            statusLabel:setText("Total pending: " .. #plotApplications)
                :setForeground(colors.green)
        else
            statusLabel:setText("Failed to load applications: " .. tostring(plotApplications or "Unknown error"))
                :setForeground(colors.red)
        end
    end)
    
    return screen
end

-- ============================================================================
-- MayorDashboard Screen
-- ============================================================================
local MayorDashboard = {}
-- Header, Utils modules loaded above

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

-- Network, Login, MayorDashboard, UserList, PlotReview, CreateMayor, InfoTabs modules loaded above

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

end

return Client
