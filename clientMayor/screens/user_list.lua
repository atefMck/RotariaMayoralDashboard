-- Mayor Accounts List Screen (Admin only)
local UserList = {}
local Network = require("network")
local Utils = require("utils")

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

return UserList

